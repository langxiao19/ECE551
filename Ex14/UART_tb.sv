module UART_tb();

// Testbench signals
reg clk, rst_n;
reg trmt, clr_rdy;
reg [7:0] tx_data;
wire TX, tx_done;
wire [7:0] rx_data;
wire rdy;

// Test variables
reg [7:0] test_data;
integer test_count;
integer errors;

// Instantiate UART transmitter
UART_tx iTX (
    .clk(clk),
    .rst_n(rst_n),
    .trmt(trmt),
    .tx_data(tx_data),
    .TX(TX),
    .tx_done(tx_done)
);

// Instantiate UART receiver
UART_rx iRX (
    .clk(clk),
    .rst_n(rst_n),
    .RX(TX),        // Connect TX output to RX input for loopback
    .clr_rdy(clr_rdy),
    .rx_data(rx_data),
    .rdy(rdy)
);

// Clock generation - 50MHz
always #10 clk = ~clk;

// Test sequence
initial begin
    // Initialize signals
    clk = 0;
    rst_n = 0;
    trmt = 0;
    clr_rdy = 0;
    tx_data = 8'h00;
    test_count = 0;
    errors = 0;
    
    // Reset sequence
    repeat(5) @(posedge clk);
    rst_n = 1;
    repeat(10) @(posedge clk);
    
    $display("=== UART Receiver Testbench ===");
    $display("Testing UART RX with loopback from UART TX");
    $display("Baud rate: 9600, Clock: 50MHz");
    $display("Expected bit time: 5208 clocks (104.16us)");
    $display("");
    
    // Test 1: Single byte transmission
    $display("Test 1: Single byte transmission (0x55)");
    test_data = 8'h55;
    send_byte(test_data);
    check_received_byte(test_data);
    
    // Test 2: Multiple different bytes
    $display("Test 2: Multiple byte transmissions");
    test_data = 8'hAA;
    send_byte(test_data);
    check_received_byte(test_data);
    
    test_data = 8'h00;
    send_byte(test_data);
    check_received_byte(test_data);
    
    test_data = 8'hFF;
    send_byte(test_data);
    check_received_byte(test_data);
    
    test_data = 8'h5A;
    send_byte(test_data);
    check_received_byte(test_data);
    
    // Test 3: Test clr_rdy functionality
    $display("Test 3: Testing clr_rdy functionality");
    test_data = 8'h3C;
    send_byte(test_data);
    wait_for_rdy();
    
    // Verify data is correct before clearing
    if (rx_data !== test_data) begin
        $display("ERROR: Data mismatch before clr_rdy. Expected: 0x%02X, Got: 0x%02X", test_data, rx_data);
        errors = errors + 1;
    end else begin
        $display("PASS: Data correct before clr_rdy: 0x%02X", rx_data);
    end
    
    // Test clr_rdy
    @(posedge clk);
    clr_rdy = 1;
    @(posedge clk);
    clr_rdy = 0;
    @(posedge clk);
    
    if (rdy == 1'b0) begin
        $display("PASS: clr_rdy successfully cleared rdy flag");
    end else begin
        $display("ERROR: clr_rdy failed to clear rdy flag");
        errors = errors + 1;
    end
    
    // Test 4: Back-to-back transmissions
    $display("Test 4: Back-to-back transmissions");
    test_data = 8'h12;
    send_byte(test_data);
    check_received_byte(test_data);
    
    // Send immediately after first completes
    test_data = 8'h34;
    send_byte(test_data);
    check_received_byte(test_data);
    
    // Test 5: Random data pattern
    $display("Test 5: Random data patterns");
    repeat(10) begin
        test_data = $random;
        send_byte(test_data);
        check_received_byte(test_data);
    end
    
    // Test summary
    repeat(100) @(posedge clk);
    $display("");
    $display("=== Test Summary ===");
    $display("Total tests: %0d", test_count);
    $display("Errors: %0d", errors);
    if (errors == 0) begin
        $display("ALL TESTS PASSED!");
    end else begin
        $display("SOME TESTS FAILED!");
    end
    
    $stop;
end

// Task to send a byte via UART transmitter
task send_byte(input [7:0] data);
begin
    tx_data = data;
    @(posedge clk);
    trmt = 1;
    @(posedge clk);
    trmt = 0;
    
    // Wait for transmission to start
    wait(tx_done == 1'b0);
    $display("  Transmitting byte: 0x%02X", data);
    
    // Wait for transmission to complete
    wait(tx_done == 1'b1);
    $display("  Transmission complete");
end
endtask

// Task to wait for receiver ready
task wait_for_rdy();
begin
    wait(rdy == 1'b1);
    $display("  Byte received, rdy asserted");
end
endtask

// Task to check received byte
task check_received_byte(input [7:0] expected);
begin
    test_count = test_count + 1;
    
    // Wait for receiver to indicate ready
    wait_for_rdy();
    
    // Check if received data matches expected
    if (rx_data === expected) begin
        $display("  PASS: Test %0d - Expected: 0x%02X, Received: 0x%02X", test_count, expected, rx_data);
    end else begin
        $display("  FAIL: Test %0d - Expected: 0x%02X, Received: 0x%02X", test_count, expected, rx_data);
        errors = errors + 1;
    end
    
    // Clear rdy flag after checking data
    @(posedge clk);
    clr_rdy = 1;
    @(posedge clk);
    clr_rdy = 0;
    @(posedge clk);
    
    // Small delay before next test
    repeat(50) @(posedge clk);
end
endtask

// Monitor for debugging
initial begin
    $monitor("Time: %0t | TX: %b | rdy: %b | rx_data: 0x%02X | receiving: %b", 
             $time, TX, rdy, rx_data, iRX.receiving);
end

// Timeout watchdog
initial begin
    #50000000; // 50ms timeout
    $display("ERROR: Testbench timeout!");
    $stop;
end

endmodule
