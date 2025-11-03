module test_PID();

reg clk, rst_n;
reg vld;
reg pwr_up;
reg rider_off;
reg [15:0] ptch, ptch_rt;

wire signed [11:0] PID_cntrl;
wire [7:0] ss_tmr;

// Instantiate DUT
PID iDUT(.clk(clk), .rst_n(rst_n), .vld(vld), .ptch(ptch), .ptch_rt(ptch_rt),
     .pwr_up(pwr_up), .rider_off(rider_off), .PID_cntrl(PID_cntrl), .ss_tmr(ss_tmr));

// Test helper functions
task reset_system();
  begin
  clk = 0;
  rst_n = 0;
  ptch = 16'h0000;
  ptch_rt = 16'h0000;
  vld = 1;
  rider_off = 1;
  pwr_up = 0;
  repeat(2) @(negedge clk);
  rst_n = 1;
  @(negedge clk);
  end
endtask

task display_debug_info(input string test_name);
  begin
  $display("=== %s Debug Info ===", test_name);
  $display("  ptch=%h (%d), ptch_rt=%h (%d)", ptch, $signed(ptch), ptch_rt, $signed(ptch_rt));
  $display("  ptch_err_sat=%h (%d)", iDUT.ptch_err_sat, $signed(iDUT.ptch_err_sat));
  $display("  integrator=%h (%d)", iDUT.integrator, $signed(iDUT.integrator));
  $display("  prev_ptch_rt=%h (%d)", iDUT.prev_ptch_rt, $signed(iDUT.prev_ptch_rt));
  $display("  P_term=%h (%d)", iDUT.P_term, $signed(iDUT.P_term));
  $display("  I_term=%h (%d)", iDUT.I_term, $signed(iDUT.I_term));
  $display("  D_term=%h (%d)", iDUT.D_term, $signed(iDUT.D_term));
  $display("  PID_sum=%h (%d)", iDUT.PID_sum, $signed(iDUT.PID_sum));
  $display("  PID_cntrl=%h (%d)", PID_cntrl, $signed(PID_cntrl));
  $display("  rider_off=%b, vld=%b, pwr_up=%b", rider_off, vld, pwr_up);
  end
endtask

task test_good1();
  begin
  $display("\n--- Testing GOOD1: Zero input ---");
  reset_system();
  display_debug_info("GOOD1");
  
  if ((PID_cntrl === 12'h000) || (PID_cntrl === 12'hFFF))
    $display("PASS: GOOD1 - zero in gives zero out");
  else begin
    $display("FAIL: GOOD1 - Expected ~0, got %h", PID_cntrl);
    $display("ERROR: PID_cntrl should be near zero");
  end
  end
endtask

task test_good2();
  begin
  $display("\n--- Testing GOOD2: P_term only ---");
  ptch = 16'h0002;
  @(negedge clk);
  display_debug_info("GOOD2");
  
  if ((PID_cntrl >= (9*2-1)) && (PID_cntrl <= (9*2)))
    $display("PASS: GOOD2 - P_term only");
  else begin
    $display("FAIL: GOOD2 - Expected %d-%d, got %d", (9*2-1), (9*2), PID_cntrl);
    $display("ERROR: Output should be determined by P_term");
  end
  end
endtask

task test_good4();
  begin
  $display("\n--- Testing GOOD4: D_term check ---");
  pwr_up = 1;
  ptch_rt = 16'h0100;
  @(negedge clk);
  display_debug_info("GOOD4");
  
  if ((PID_cntrl > (9*2-5)) && (PID_cntrl <= (9*2-2)))
    $display("PASS: GOOD4 - D_term in proper range");
  else begin
    $display("FAIL: GOOD4 - Expected %d-%d, got %d", (9*2-5), (9*2-2), PID_cntrl);
    $display("ERROR: D_term should be -4 or -5");
  end
  end
endtask

task test_good10();
  begin
  $display("\n--- Testing GOOD10: Negative ptch with 50% vld ---");
  
  // Setup for GOOD10 - need to have integrator partially wound up first
  // and then switch to negative pitch with 50% valid
  vld = 0;  // Use 50% duty cycle
  ptch = 16'hFF80;  // -128 decimal
  ptch_rt = 16'h0000;
  
  // Need to simulate the vld_tggle behavior from testbench
  repeat(3) begin
    vld = 1;
    @(negedge clk);
    vld = 0; 
    @(negedge clk);
  end
  
  display_debug_info("GOOD10");
  
  $display("  Expected I_term: 0x7FFA (%d)", -12'h6);
  $display("  Expected P_term: 0x7B80 (%d)", 16'h7B80);
  $display("  Expected PID_cntrl range: 0xB7A-0xB7C");
  
  if ((PID_cntrl === 12'hB7B) || (PID_cntrl === 12'hB7A) || (PID_cntrl === 12'hB7C))
    $display("PASS: GOOD10 - Correct range");
  else begin
    $display("FAIL: GOOD10 - Expected B7A-B7C, got %h", PID_cntrl);
    $display("ERROR: I_term should be 0x7FFA with P_term 0x7B80");
  end
  end
endtask

task test_integrator_buildup();
  begin
  $display("\n--- Testing Integrator Buildup ---");
  reset_system();
  
  // Build up integrator like in GOOD5 scenario
  ptch = 16'h007F;
  rider_off = 0;
  pwr_up = 1;
  ptch_rt = 16'h0100;
  @(negedge clk); // Let D_term settle
  
  repeat(3) @(negedge clk);
  display_debug_info("Integrator Buildup");
  
  $display("  After 3 clocks with ptch=0x007F:");
  $display("  Expected integrator ~= 3 * 127 = 381");
  $display("  Expected I_term ~= 381/76 = 5");
  end
endtask

task test_saturation_cases();
  begin
  $display("\n--- Testing Saturation Cases ---");
  
  // Test positive saturation
  ptch = 16'h003F;  // 63 decimal
  rider_off = 0;
  repeat(2400) @(negedge clk);
  
  display_debug_info("Positive Saturation");
  $display("  Should reach positive saturation at 0x7FF");
  
  // Test the transition case
  ptch = 16'h0000;
  @(negedge clk);
  display_debug_info("After Saturation with ptch=0");
  end
endtask

// Main test sequence
initial begin
  test_good1();
  test_good2();
  test_good4();
  test_integrator_buildup();
  test_saturation_cases();
  test_good10();  // Test the problematic case last
  
  $display("\n=== Test Summary ===");
  $display("Check individual test results above");
  $stop();
end

always #5 clk = ~clk;

endmodule