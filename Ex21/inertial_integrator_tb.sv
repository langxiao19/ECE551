//////////////////////////////////////////////////////
// inertial_integrator_tb.sv
// Test bench for inertial_integrator module
// Tests integration and sensor fusion behavior
//////////////////////////////////////////////////////

module inertial_integrator_tb();

  ///////////////////////////////////////////
  // Local parameters
  ///////////////////////////////////////////
  localparam signed PTCH_RT_OFFSET = 16'h0050;
  
  ///////////////////////////////////////////
  // Testbench signals
  ///////////////////////////////////////////
  logic clk, rst_n;
  logic vld;
  logic signed [15:0] ptch_rt, AZ;
  logic signed [15:0] ptch;
  
  ///////////////////////////////////////////
  // Instantiate DUT
  ///////////////////////////////////////////
  inertial_integrator iDUT(
    .clk(clk),
    .rst_n(rst_n),
    .vld(vld),
    .ptch_rt(ptch_rt),
    .AZ(AZ),
    .ptch(ptch)
  );
  
  ///////////////////////////////////////////
  // Clock generation (50MHz)
  ///////////////////////////////////////////
  initial begin
    clk = 0;
    forever #10 clk = ~clk;
  end
  
  ///////////////////////////////////////////
  // Main test sequence
  ///////////////////////////////////////////
  initial begin
    // Initialize signals
    rst_n = 0;
    vld = 0;
    ptch_rt = PTCH_RT_OFFSET;
    AZ = 16'h0000;
    
    // Apply reset
    @(posedge clk);
    @(negedge clk);
    rst_n = 1;
    @(posedge clk);
    
    $display("==========================================");
    $display("Test 1: Positive pitch rate for 500 clocks");
    $display("==========================================");
    // Apply positive pitch rate
    ptch_rt = 16'h1000 + PTCH_RT_OFFSET;
    AZ = 16'h0000;
    vld = 1;
    
    repeat(500) @(posedge clk);
    $display("After 500 clocks with positive ptch_rt, ptch = %d (should be trending negative)", $signed(ptch));
    
    $display("\n==========================================");
    $display("Test 2: Zero pitch rate for 1000 clocks (fusion correction)");
    $display("==========================================");
    // Zero out pitch rate
    ptch_rt = PTCH_RT_OFFSET;
    
    repeat(1000) @(posedge clk);
    $display("After 1000 clocks with zero ptch_rt, ptch = %d (should be trending back toward zero)", $signed(ptch));
    
    $display("\n==========================================");
    $display("Test 3: Negative pitch rate for 500 clocks");
    $display("==========================================");
    // Apply negative pitch rate
    ptch_rt = PTCH_RT_OFFSET - 16'h1000;
    
    repeat(500) @(posedge clk);
    $display("After 500 clocks with negative ptch_rt, ptch = %d (should be trending positive)", $signed(ptch));
    
    $display("\n==========================================");
    $display("Test 4: Zero pitch rate for 1000 clocks (fusion correction)");
    $display("==========================================");
    // Zero out pitch rate again
    ptch_rt = PTCH_RT_OFFSET;
    
    repeat(1000) @(posedge clk);
    $display("After 1000 clocks with zero ptch_rt, ptch = %d (should be trending back toward zero)", $signed(ptch));
    
    $display("\n==========================================");
    $display("Test 5: Apply AZ offset and observe fusion stabilization");
    $display("==========================================");
    // Apply AZ offset
    AZ = 16'h0800;
    
    // Continue for additional clocks to observe stabilization around ptch = 100
    repeat(2000) @(posedge clk);
    $display("After 2000 clocks with AZ = 0x0800, ptch = %d (should stabilize around 100)", $signed(ptch));
    
    // Check if ptch has stabilized around expected value
    if (ptch > 16'sd50 && ptch < 16'sd150) begin
      $display("\n==========================================");
      $display("SUCCESS: Pitch stabilized in expected range (50 to 150)");
      $display("==========================================");
    end else begin
      $display("\n==========================================");
      $display("WARNING: Pitch = %d, expected around 100", $signed(ptch));
      $display("==========================================");
    end
    
    $display("\nTest completed. Examine waveform for detailed behavior.");
    $display("Recommended waveform settings:");
    $display("  - Display ptch as analog waveform");
    $display("  - Format: Custom Analog, Range: -1000 to +1000");
    $display("  - Height: 300px");
    
    $stop;
  end
  
  ///////////////////////////////////////////
  // Monitor key signals
  ///////////////////////////////////////////
  initial begin
    $monitor("Time=%0t | ptch_rt=%h | AZ=%h | ptch=%d", 
             $time, ptch_rt, AZ, $signed(ptch));
  end

endmodule
