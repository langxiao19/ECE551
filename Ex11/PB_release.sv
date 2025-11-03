module PB_release(
    input PB,           // Push button input (raw)
    input clk,          // Clock
    input rst_n,        // Reset (active low)
    output released     // High for one clock cycle when button is released
);

    // Internal signals for the three flip-flops
    reg ff1, ff2, ff3;
    
    // Three flip-flops with asynchronous preset (not reset)
    // When PB is low (button pressed), all flops are preset to 1
    // When PB is high (button not pressed), flops shift 0's through the chain
    always_ff @(posedge clk or negedge PB or negedge rst_n) begin
        if (!rst_n) begin
            // System reset - clear all flops
            ff1 <= 1'b0;
            ff2 <= 1'b0;
            ff3 <= 1'b0;
        end else if (!PB) begin
            // Asynchronous preset when button is pressed (PB low)
            ff1 <= 1'b1;
            ff2 <= 1'b1;
            ff3 <= 1'b1;
        end else begin
            // Synchronous operation - shift 0's through when button not pressed
            ff1 <= 1'b0;
            ff2 <= ff1;
            ff3 <= ff2;
        end
    end
    
    // Rising edge detection: PB is high (button released) AND ff3 is still low
    // This creates a one-clock pulse when the button is released
    assign released = PB & ~ff3;

endmodule
