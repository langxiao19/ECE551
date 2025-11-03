module Auth_blk(
    input        clk,         // 50MHz system clock
    input        rst_n,       // Active low reset
    input        RX,          // UART RX line from BLE module
    input        rider_off,   // Signal indicating rider weight below threshold
    output       pwr_up       // Power up signal to balance controller
);

//////////////////////////////////////////////////
// Internal signals from UART_rx
//////////////////////////////////////////////////
wire [7:0] rx_data;
wire       rx_rdy;
reg        clr_rx_rdy;
reg        shutdown_pending;  // Flag to track if shutdown was requested

//////////////////////////////////////////////////
// State machine states
//////////////////////////////////////////////////
typedef enum reg {
    PWR_DWN,     // Power down state
    PWR_UP       // Power up state
} state_t;

state_t state, nxt_state;

//////////////////////////////////////////////////
// State machine registers
//////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        state <= PWR_DWN;
        shutdown_pending <= 1'b0;
    end else begin
        state <= nxt_state;
        
        // Update shutdown_pending flag based on current state and reception
        if (state == PWR_UP && rx_rdy && rx_data == 8'h53) begin
            shutdown_pending <= 1'b1;  // 'S' received, mark shutdown pending
        end else if (state == PWR_UP && rx_rdy && rx_data == 8'h47) begin
            shutdown_pending <= 1'b0;  // 'G' received, clear shutdown pending
        end else if (state == PWR_DWN) begin
            shutdown_pending <= 1'b0;  // Clear when powered down
        end
    end
end

//////////////////////////////////////////////////
// Separate clr_rx_rdy logic to avoid race conditions
//////////////////////////////////////////////////
always_comb begin
    clr_rx_rdy = rx_rdy;  // Clear rx_rdy immediately when it's asserted
end

//////////////////////////////////////////////////
// State machine logic (Mealy machine)
//////////////////////////////////////////////////
always_comb begin
    // Default outputs
    nxt_state = state;
    
    case (state)
        PWR_DWN: begin
            if (rx_rdy && (rx_data == 8'h47)) begin  // 'G' received (0x47)
                nxt_state = PWR_UP;
            end
            // Stay in PWR_DWN for any other character or no reception
        end
        
        PWR_UP: begin
            if (rx_rdy && (rx_data == 8'h53) && rider_off) begin  // 'S' received and rider off
                nxt_state = PWR_DWN;
            end else if (shutdown_pending && rider_off) begin
                // Rider got off after shutdown was requested
                nxt_state = PWR_DWN;
            end
            // Stay PWR_UP for all other cases
        end
        
        default: nxt_state = PWR_DWN;
    endcase
end

//////////////////////////////////////////////////
// Output logic (simple state-based)
//////////////////////////////////////////////////
assign pwr_up = (state == PWR_UP);

//////////////////////////////////////////////////
// UART receiver instantiation
//////////////////////////////////////////////////
UART_rx iUART_rx(
    .clk(clk),
    .rst_n(rst_n),
    .RX(RX),
    .clr_rdy(clr_rx_rdy),
    .rx_data(rx_data),
    .rdy(rx_rdy)
);

endmodule
