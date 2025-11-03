module UART_tx_detailed_tb();

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

// Monitor key signals
always @(posedge clk) begin
    if (trmt || !tx_done || (iDUT.bit_cnt != 0)) begin
        $display("Time=%0t: trmt=%b tx_done=%b transmitting=%b TX=%b bit_cnt=%0d baud_cnt=%0d", 
                 $time, trmt, tx_done, iDUT.transmitting, TX, iDUT.bit_cnt, iDUT.baud_cnt);
    end
end

initial begin
    clk = 0;
    rst_n = 0;
    trmt = 0;
    tx_data = 8'h55;  // 01010101
    
    // Reset sequence
    repeat(3) @(negedge clk);
    rst_n = 1;
    
    $display("Starting detailed UART test with tx_data=0x55");
    
    // Wait and initiate transmission
    repeat(5) @(posedge clk);
    
    $display("\\nInitiating transmission...");
    trmt = 1;
    @(posedge clk);
    trmt = 0;
    
    // Watch for 20 clock cycles
    repeat(20) @(posedge clk);
    
    $display("\\nSkipping ahead to see bit transitions...");
    
    // Wait for a few baud periods
    repeat(5200) @(posedge clk);
    $display("Near first bit transition...");
    repeat(16) @(posedge clk);
    
    $stop();
end

endmodule
