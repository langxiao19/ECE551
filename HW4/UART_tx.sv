module UART_tx(
    input        clk,       // 50MHz system clock
    input        rst_n,     // Asynchronous active low reset
    input        trmt,      // Assert to initiate transmission (ignored if busy)
    input  [7:0] tx_data,   // Byte to transmit (LSB first)
    output       TX,        // Serial data output (idle high)
    output       tx_done    // High when idle, low while transmitting
);

//////////////////////////////////////////////////
// Internal signals
//////////////////////////////////////////////////
reg [12:0] baud_cnt;          // Baud rate counter (counts 0 to 5207)
reg [3:0]  bit_cnt;           // Bit counter (counts 0 to 9)
reg [8:0]  shift_reg;         // Shift register: [stop|data7:data0|start]
reg        transmitting;      // State flag: high during transmission

//////////////////////////////////////////////////
// Parameters
//////////////////////////////////////////////////
localparam BAUD_CNT_MAX = 13'd5207;  // 50MHz/9600 - 1 = 5207

//////////////////////////////////////////////////
// Baud rate generator
//////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        baud_cnt <= 13'h0000;
    else if (!transmitting)
        baud_cnt <= 13'h0000;  // Reset counter when idle
    else if (baud_cnt == BAUD_CNT_MAX)
        baud_cnt <= 13'h0000;  // Reset at terminal count
    else
        baud_cnt <= baud_cnt + 1'b1;
end

//////////////////////////////////////////////////
// Generate shift enable pulse at baud rate
//////////////////////////////////////////////////
wire shift = transmitting & (baud_cnt == BAUD_CNT_MAX);

//////////////////////////////////////////////////
// Main state machine and shift register
//////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        shift_reg    <= 9'h1FF;    // Idle high
        bit_cnt      <= 4'h0;
        transmitting <= 1'b0;
    end else if (trmt & ~transmitting) begin
        // Load new transmission
        shift_reg    <= {1'b1, tx_data, 1'b0};  // [stop|data7:0|start]
        bit_cnt      <= 4'h0;
        transmitting <= 1'b1;
    end else if (shift) begin
        // Shift data at baud rate
        shift_reg <= {1'b1, shift_reg[8:1]};    // Shift right, fill with 1's
        bit_cnt   <= bit_cnt + 1'b1;
        
        // Check for completion (transmitted start + 8 data bits)
        if (bit_cnt == 4'd8)
            transmitting <= 1'b0;
    end
end

//////////////////////////////////////////////////
// Output assignments
//////////////////////////////////////////////////
assign TX = shift_reg[0];       // LSB of shift register drives TX
assign tx_done = ~transmitting; // Done when not transmitting

endmodule
