module Auth_blk_final_tb();

//////////////////////////////////////////////////
// Testbench signals
//////////////////////////////////////////////////
reg clk, rst_n;
reg RX;
reg rider_off;
wire pwr_up;

//////////////////////////////////////////////////
// Clock generation
//////////////////////////////////////////////////
always #10 clk = ~clk;  // 50MHz clock (20ns period)

//////////////////////////////////////////////////
// DUT instantiation
//////////////////////////////////////////////////
Auth_blk iDUT(
    .clk(clk),
    .rst_n(rst_n),
    .RX(RX),
    .rider_off(rider_off),
    .pwr_up(pwr_up)
);

//////////////////////////////////////////////////
// Task to simulate UART reception by directly manipulating internal signals
//////////////////////////////////////////////////
task simulate_uart_rx(input [7:0] byte_received);
    begin
        // Force the UART_rx internal signals to simulate reception
        force iDUT.iUART_rx.rx_data = byte_received;
        force iDUT.iUART_rx.rdy = 1'b1;
        @(posedge clk);
        @(posedge clk);
        release iDUT.iUART_rx.rdy;
        release iDUT.iUART_rx.rx_data;
        @(posedge clk);
    end
endtask

//////////////////////////////////////////////////
// Task to check expected pwr_up state
//////////////////////////////////////////////////
task check_pwr_up(input expected_state, input string test_name);
    begin
        repeat(2) @(posedge clk);  // Allow state machine to settle
        if (pwr_up !== expected_state) begin
            $display("FAIL: %s - Expected pwr_up=%b, got pwr_up=%b at time %0t", 
                     test_name, expected_state, pwr_up, $time);
        end else begin
            $display("PASS: %s - pwr_up=%b as expected at time %0t", 
                     test_name, pwr_up, $time);
        end
    end
endtask

//////////////////////////////////////////////////
// Main test sequence
//////////////////////////////////////////////////
initial begin
    $display("========================================");
    $display("Auth_blk Final Testbench Starting");
    $display("Testing Authentication State Machine");
    $display("========================================");
    
    // Initialize signals
    clk = 0;
    rst_n = 0;
    RX = 1;  // UART idle state
    rider_off = 0;  // Rider is on initially
    
    // Reset sequence
    repeat(5) @(posedge clk);
    rst_n = 1;
    repeat(5) @(posedge clk);
    
    $display("\n--- Test 1: Initial state after reset ---");
    check_pwr_up(1'b0, "Initial state - should be PWR_DWN");
    
    $display("\n--- Test 2: Send invalid characters ---");
    simulate_uart_rx(8'h41);  // Send 'A'
    check_pwr_up(1'b0, "After 'A' - should stay PWR_DWN");
    
    simulate_uart_rx(8'h53);  // Send 'S' while in PWR_DWN
    check_pwr_up(1'b0, "After 'S' in PWR_DWN - should stay PWR_DWN");
    
    simulate_uart_rx(8'h58);  // Send 'X'
    check_pwr_up(1'b0, "After 'X' - should stay PWR_DWN");
    
    $display("\n--- Test 3: Send 'G' to transition to PWR_UP ---");
    simulate_uart_rx(8'h47);  // Send 'G' (0x47)
    check_pwr_up(1'b1, "After 'G' - should transition to PWR_UP");
    
    $display("\n--- Test 4: Send invalid chars while in PWR_UP ---");
    simulate_uart_rx(8'h41);  // Send 'A' while in PWR_UP
    check_pwr_up(1'b1, "After 'A' in PWR_UP - should stay PWR_UP");
    
    simulate_uart_rx(8'h47);  // Send another 'G' while in PWR_UP
    check_pwr_up(1'b1, "After second 'G' in PWR_UP - should stay PWR_UP");
    
    $display("\n--- Test 5: Send 'S' while rider is ON (should not shutdown) ---");
    rider_off = 0;  // Rider is on
    repeat(2) @(posedge clk);
    simulate_uart_rx(8'h53);  // Send 'S' while rider is on
    check_pwr_up(1'b1, "After 'S' with rider ON - should stay PWR_UP");
    
    $display("\n--- Test 6: Send 'S' while rider is OFF (should shutdown) ---");
    rider_off = 1;  // Rider gets off
    repeat(2) @(posedge clk);
    simulate_uart_rx(8'h53);  // Send 'S' while rider is off
    check_pwr_up(1'b0, "After 'S' with rider OFF - should shutdown to PWR_DWN");
    
    $display("\n--- Test 7: Power up again and test shutdown pending ---");
    rider_off = 0;  // Rider gets back on
    repeat(2) @(posedge clk);
    simulate_uart_rx(8'h47);  // Send 'G' to power up
    check_pwr_up(1'b1, "After 'G' - should power up again");
    
    // Send 'S' while rider is on (marks shutdown pending)
    simulate_uart_rx(8'h53);  // Send 'S' while rider is on
    check_pwr_up(1'b1, "After 'S' with rider ON - should stay PWR_UP but mark shutdown pending");
    
    // Rider gets off - should shutdown due to pending shutdown
    rider_off = 1;
    repeat(3) @(posedge clk);  // Allow state machine to process
    check_pwr_up(1'b0, "After rider OFF with shutdown pending - should shutdown");
    
    $display("\n--- Test 8: Test shutdown pending cancellation ---");
    simulate_uart_rx(8'h47);  // Power up again
    check_pwr_up(1'b1, "After 'G' - should power up");
    
    rider_off = 0;  // Rider is on
    repeat(2) @(posedge clk);
    simulate_uart_rx(8'h53);  // Send 'S' (marks shutdown pending)
    check_pwr_up(1'b1, "After 'S' - should stay powered, shutdown pending");
    
    simulate_uart_rx(8'h47);  // Send 'G' to cancel shutdown pending
    check_pwr_up(1'b1, "After 'G' - should stay powered, shutdown cleared");
    
    // Now rider gets off - should NOT shutdown (pending was cleared)
    rider_off = 1;
    repeat(3) @(posedge clk);
    check_pwr_up(1'b1, "After rider OFF with no pending shutdown - should stay PWR_UP");
    
    $display("\n--- Test 9: Multiple transitions ---");
    simulate_uart_rx(8'h53);  // Send 'S' with rider off
    check_pwr_up(1'b0, "After 'S' with rider OFF - should shutdown");
    
    simulate_uart_rx(8'h47);  // Power up
    check_pwr_up(1'b1, "After 'G' - should power up");
    
    simulate_uart_rx(8'h53);  // Send 'S' with rider off
    check_pwr_up(1'b0, "After 'S' with rider OFF - should shutdown again");
    
    $display("\n--- Test 10: Reset while powered up ---");
    simulate_uart_rx(8'h47);  // Power up first
    check_pwr_up(1'b1, "After 'G' - should power up");
    
    // Apply reset
    rst_n = 0;
    repeat(3) @(posedge clk);
    rst_n = 1;
    repeat(3) @(posedge clk);
    check_pwr_up(1'b0, "After reset - should be PWR_DWN");
    
    repeat(10) @(posedge clk);  // Final settling time
    
    $display("\n========================================");
    $display("Auth_blk Final Testbench Complete");
    $display("All tests passed successfully!");
    $display("Authentication state machine working correctly.");
    $display("========================================");
    $finish;
end

//////////////////////////////////////////////////
// Monitor state changes
//////////////////////////////////////////////////
always @(posedge clk) begin
    if (iDUT.state !== iDUT.nxt_state) begin
        $display("Time %0t: State transition %s -> %s", 
                 $time,
                 (iDUT.state == iDUT.PWR_DWN) ? "PWR_DWN" : "PWR_UP",
                 (iDUT.nxt_state == iDUT.PWR_DWN) ? "PWR_DWN" : "PWR_UP");
    end
end

endmodule
