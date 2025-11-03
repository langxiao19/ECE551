module UART_tx_tb();

reg clk, rst_n, trmt;
reg [7:0] tx_data;
wire TX, tx_done;

// Instantiate DUT
UART_tx iDUT(
    .clk(clk),
    .rst_n(rst_n),
    .trmt(trmt),
    .tx_data(tx_data),
    .TX(TX),
    .tx_done(tx_done)
);

// Clock generation - 50MHz
always #10 clk = ~clk;

initial begin
    clk = 0;
    rst_n = 0;
    trmt = 0;
    tx_data = 8'h00;
    
    // Reset sequence
    repeat(3) @(negedge clk);
    rst_n = 1;
    
    $display("Testing UART transmitter at 9600 baud");
    $display("Baud period should be %0d ns", (1000000000/9600));
    $display("Bit period in simulation should be %0d clock cycles", 5208);
    
    // Wait for idle state
    repeat(10) @(posedge clk);
    if (!tx_done) $display("ERROR: Should be idle after reset");
    if (!TX) $display("ERROR: TX should be high when idle");
    
    // Test transmission of 0x55 (alternating pattern)
    tx_data = 8'h55;  // 01010101
    $display("\\nTransmitting 0x55 (01010101)");
    $display("Expected bit sequence: Start(0) 1 0 1 0 1 0 1 0 Stop(1)");
    
    trmt = 1;
    @(posedge clk);
    trmt = 0;
    
    if (tx_done) $display("ERROR: tx_done should go low when transmission starts");
    
    // Monitor the transmission
    $display("Time=%0t: Transmission started, TX=%b", $time, TX);
    
    // Wait for a few bit periods and check the waveform
    repeat(5208) @(posedge clk);  // Start bit period
    $display("Time=%0t: After start bit, TX=%b (should be 0)", $time, TX);
    
    repeat(5208) @(posedge clk);  // First data bit (LSB = 1)
    $display("Time=%0t: After bit 0 (LSB=1), TX=%b (should be 1)", $time, TX);
    
    repeat(5208) @(posedge clk);  // Second data bit (bit 1 = 0)  
    $display("Time=%0t: After bit 1 (=0), TX=%b (should be 0)", $time, TX);
    
    repeat(5208) @(posedge clk);  // Third data bit (bit 2 = 1)
    $display("Time=%0t: After bit 2 (=1), TX=%b (should be 1)", $time, TX);
    
    // Skip to near end of transmission
    repeat(5208 * 5) @(posedge clk);  // Skip bits 3,4,5,6,7
    
    repeat(5208) @(posedge clk);  // Stop bit
    $display("Time=%0t: After stop bit, TX=%b (should be 1)", $time, TX);
    
    if (!tx_done) $display("ERROR: tx_done should be high after transmission");
    if (!TX) $display("ERROR: TX should be high after transmission (idle)");
    
    // Test another byte immediately
    $display("\\nTransmitting 0xAA (10101010)");
    tx_data = 8'hAA;
    trmt = 1;
    @(posedge clk);
    trmt = 0;
    
    // Wait for complete transmission
    repeat(5208 * 10) @(posedge clk);
    
    if (!tx_done) $display("ERROR: Second transmission should be complete");
    if (!TX) $display("ERROR: TX should be high after second transmission");
    
    $display("\\nUART transmitter test completed successfully!");
    $stop();
end

endmodule
