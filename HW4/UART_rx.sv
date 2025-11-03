module UART_rx(
    input        clk,        // 50MHz system clock
    input        rst_n,      // Active low reset
    input        RX,         // Serial data input
    input        clr_rdy,    // Knocks down rdy when asserted
    output [7:0] rx_data,    // Byte received
    output       rdy         // Asserted when byte received
);

//////////////////////////////////////////////////
// Parameters - Matched to UART_tx for loopback testing
//////////////////////////////////////////////////
localparam BAUD_CNT_MAX = 13'd5207;    // Match UART_tx: 50MHz/9600 - 1 = 5207
localparam FIRST_SAMPLE = 13'd3905;    // 1.5 bit periods = center of first data bit  
localparam ONE_AND_HALF_BAUD = 14'd7811; // 1.5 bit periods = 5207 * 1.5

//////////////////////////////////////////////////
// Internal signals
//////////////////////////////////////////////////
reg [13:0] baud_cnt;          // Extended baud rate counter for 1.5 bit timing
reg [3:0]  bit_cnt;           // Bit counter (0-8: start + 8 data bits)
reg [7:0]  rx_data_reg;       // Latched received data
reg        rdy_ff;            // Ready flag
reg        receiving;         // State flag: high during data reception
reg        RX_ff1, RX_ff2;    // Metastability protection flops

//////////////////////////////////////////////////
// Metastability protection for RX input
//////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        RX_ff1 <= 1'b1;      // Idle state is high
        RX_ff2 <= 1'b1;
    end else begin
        RX_ff1 <= RX;
        RX_ff2 <= RX_ff1;
    end
end

//////////////////////////////////////////////////
// Start bit detection (falling edge on synchronized RX)
//////////////////////////////////////////////////
wire start_detected = (RX_ff2 & ~RX_ff1) & ~receiving;

//////////////////////////////////////////////////
// Timing control signals - proper UART timing
//////////////////////////////////////////////////
wire baud_tick = (baud_cnt == BAUD_CNT_MAX);
wire first_sample_tick = (baud_cnt == FIRST_SAMPLE);  // 1.5 bit periods for first data bit center

//////////////////////////////////////////////////
// Baud rate counter - simplified timing
//////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        baud_cnt <= 14'h0000;
    else if (start_detected)
        baud_cnt <= 14'h0000;  // Reset counter when start bit detected
    else if (receiving) begin
        if (baud_cnt == BAUD_CNT_MAX)  // Reset every full bit period
            baud_cnt <= 14'h0000;
        else
            baud_cnt <= baud_cnt + 1'b1;  // Count when receiving
    end else
        baud_cnt <= 14'h0000;  // Reset when idle
end

//////////////////////////////////////////////////  
// Main receiver state machine
//////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        receiving    <= 1'b0;
        bit_cnt      <= 4'h0;
        rx_data_reg  <= 8'h00;
        rdy_ff       <= 1'b0;
    end else if (clr_rdy) begin
        rdy_ff <= 1'b0;  // Clear ready flag
    end else if (start_detected & ~receiving) begin
        // Start bit detected while idle - begin reception
        receiving   <= 1'b1;
        bit_cnt     <= 4'hF;  // Special state to wait for first half-bit
        rdy_ff      <= 1'b0;  
    end else if (receiving) begin
        // Handle timing for data sampling  
        if (bit_cnt == 4'hF && first_sample_tick) begin
            // Ready to start sampling - move to bit 0
            bit_cnt <= 4'h0;
        end else if (bit_cnt <= 4'd7 && baud_tick) begin
            // Sample data bits
            case (bit_cnt)
                4'd0: rx_data_reg[0] <= RX_ff2;  // LSB
                4'd1: rx_data_reg[1] <= RX_ff2;
                4'd2: rx_data_reg[2] <= RX_ff2;
                4'd3: rx_data_reg[3] <= RX_ff2;
                4'd4: rx_data_reg[4] <= RX_ff2;
                4'd5: rx_data_reg[5] <= RX_ff2;
                4'd6: rx_data_reg[6] <= RX_ff2;
                4'd7: rx_data_reg[7] <= RX_ff2;  // MSB
            endcase
            bit_cnt <= bit_cnt + 1'b1;
        end else if (bit_cnt == 4'd8 && baud_tick) begin
            // Check stop bit and complete reception
            if (RX_ff2 == 1'b1) begin  // Valid stop bit
                receiving <= 1'b0;
                rdy_ff <= 1'b1;
            end else begin
                // Invalid stop bit - still complete but could flag error
                receiving <= 1'b0;
                rdy_ff <= 1'b1;
            end
        end
    end
end

//////////////////////////////////////////////////
// Output assignments  
//////////////////////////////////////////////////
assign rx_data = rx_data_reg;
assign rdy = rdy_ff;

endmodule
