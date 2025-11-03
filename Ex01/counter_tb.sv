module up_dwn_tb();

/// Declare stimulus to DUT ///
logic clk, rst_n;
logic en, up_dwn_n;

wire [3:0] cnt_monitor;     // monitor DUT output

// Instantiate DUT //
counter iDUT(.clk(clk), .rst_n(rst_n), .en(en), .up_dwn_n(up_dwn_n), .cnt(cnt_monitor));

initial begin
  clk = 0;
  rst_n = 0;				// assert reset
  en = 0;					// start with it disabled
  up_dwn_n = 1;				// count up at first
  @(negedge clk) rst_n = 1;	// deassert reset on negative edge (typically good practice)
  @(negedge clk);
  //// Test 1 test that it does not count if not enabled
  if (cnt_monitor!==4'h0) begin
    $display("ERR: counter is not enabled, and has just been reset so should be at zero");
    $stop();
  end
  //// Test 2 test that it counts up when enabled and up_dwn_n = 1;
  en = 1;
  repeat (5)@(negedge clk);	// wait 5 clock cycles
  if (cnt_monitor!==4'h5) begin
    $display("ERR: counter should have a value of 5");
    $stop();
  end    
  //// Test 3 test that it counts down when enabled and up_dwn_n = 0;
  up_dwn_n = 0;				// start counting backwards
  repeat(2) @(negedge clk);	// wait 2 clock cycles
  if (cnt_monitor!==4'h3) begin
    $display("ERR: counter should have counted back to 3");
    $stop();
  end
  
  $display("YAHOO! all tests passed!");
  $stop();  
end

always
  #5 clk = ~clk;

endmodule  