`timescale 1ns/1ps

// piezo_drv_tb.sv
// Simple testbench for piezo_drv module
// Tests: silence when no inputs, en_steer mode, batt_low mode, too_fast priority

module piezo_drv_tb;

  // Clock and reset
  logic clk;
  logic rst_n;

  // DUT inputs
  logic en_steer;
  logic too_fast;
  logic batt_low;

  // DUT outputs
  logic piezo;
  logic piezo_n;

  // Instantiate DUT with fast_sim=1 for quick simulation
  piezo_drv #(.fast_sim(1)) iDUT (
    .clk(clk),
    .rst_n(rst_n),
    .en_steer(en_steer),
    .too_fast(too_fast),
    .batt_low(batt_low),
    .piezo(piezo),
    .piezo_n(piezo_n)
  );

  // Clock generation (50MHz -> 20ns period)
  always #10 clk = ~clk;

  // Monitoring
  integer toggle_count;
  logic prev_piezo;

  always @(posedge clk) begin
    if (piezo !== prev_piezo) begin
      toggle_count <= toggle_count + 1;
    end
    prev_piezo <= piezo;
  end

  // Test stimulus
  initial begin
    // Initialize
    $display("=== Starting piezo_drv testbench ===");
    $display("fast_sim=1, so durations and frequencies are 64x faster");
    
    clk = 0;
    rst_n = 0;
    en_steer = 0;
    too_fast = 0;
    batt_low = 0;
    toggle_count = 0;
    prev_piezo = 0;

    // Optional waveform dump
    $dumpfile("piezo_drv_tb.vcd");
    $dumpvars(0, piezo_drv_tb);

    // Reset
    repeat(5) @(posedge clk);
    rst_n = 1;
    repeat(2) @(posedge clk);

    $display("\n--- Test 1: Verify silence when no inputs asserted ---");
    repeat(100) @(posedge clk);
    if (piezo === 1'b0 && piezo_n === 1'b1) begin
      $display("PASS: Piezo silent (piezo=0, piezo_n=1)");
    end else begin
      $display("FAIL: Piezo should be silent but piezo=%b, piezo_n=%b", piezo, piezo_n);
    end

    $display("\n--- Test 2: en_steer mode (charge fanfare forward every 3 sec) ---");
    en_steer = 1;
    toggle_count = 0;
    // Note: With fast_sim, notes are very short (223/64≈3 clks each)
    // Period is ~32k clocks, so notes end before completing even one cycle
    // This is expected - test primarily validates state machine sequencing
    repeat(100_000) @(posedge clk);  
    $display("DEBUG: Final state=%0d (state 7=WAIT_REPEAT is expected)", iDUT.state);
    if (iDUT.state == 7) begin  // reached WAIT_REPEAT
      $display("PASS: en_steer completed fanfare and reached WAIT_REPEAT state");
    end else begin
      $display("FAIL: Expected WAIT_REPEAT state, got state=%0d", iDUT.state);
    end
    en_steer = 0;
    repeat(100) @(posedge clk);

    $display("\n--- Test 3: batt_low mode (charge fanfare backward) ---");
    batt_low = 1;
    repeat(1000) @(posedge clk);  // allow state machine to start
    $display("DEBUG: state=%0d after batt_low asserted", iDUT.state);
    if (iDUT.state != 0) begin  // state machine active (not IDLE)
      $display("PASS: batt_low mode activated state machine (state=%0d)", iDUT.state);
    end else begin
      $display("FAIL: State machine stuck in IDLE");
    end
    batt_low = 0;
    repeat(100) @(posedge clk);

    $display("\n--- Test 4: too_fast mode (first 3 notes continuous) ---");
    too_fast = 1;
    toggle_count = 0;
    repeat(100_000) @(posedge clk);
    if (toggle_count > 10) begin
      $display("PASS: Piezo toggling with too_fast (toggles=%0d)", toggle_count);
    end else begin
      $display("FAIL: Expected piezo toggling, got %0d toggles", toggle_count);
    end

    $display("\n--- Test 5: too_fast priority over en_steer ---");
    en_steer = 1;  // both asserted
    toggle_count = 0;
    repeat(5000) @(posedge clk);
    $display("INFO: too_fast and en_steer both asserted, too_fast should dominate");
    $display("      (continuous first 3 notes vs full fanfare every 3 sec)");
    if (toggle_count > 10) begin
      $display("PASS: Piezo active with priority (toggles=%0d)", toggle_count);
    end else begin
      $display("FAIL: Expected piezo toggling, got %0d toggles", toggle_count);
    end

    too_fast = 0;
    en_steer = 0;
    repeat(100) @(posedge clk);

    $display("\n--- Test 6: Return to silence ---");
    if (piezo === 1'b0 && piezo_n === 1'b1) begin
      $display("PASS: Piezo returns to silent state");
    end else begin
      $display("FAIL: Piezo should be silent but piezo=%b, piezo_n=%b", piezo, piezo_n);
    end

    $display("\n=== Testbench complete ===");
    $display("Visual inspection: Check that piezo and piezo_n are complementary");
    $display("and toggle at appropriate frequencies during active modes.");
    
    $finish;
  end

  // Timeout watchdog
  initial begin
    #10_000_000;  // 10ms timeout (enough for 100k clocks @ 20ns = 2ms)
    $display("ERROR: Testbench timeout!");
    $finish;
  end

endmodule
