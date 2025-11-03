module up_dwn_cnt4(
    input en,           // Enable signal from PB_release
    input dwn,          // Direction: 1 = down, 0 = up  
    input clk,          // Clock
    input rst_n,        // Active low reset
    output reg [3:0] cnt // 4-bit counter output
);

    // 4-bit up/down counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset counter to 0
            cnt <= 4'b0000;
        end else if (en) begin
            // Counter updates only when enabled (button release pulse)
            if (dwn) begin
                // Count down
                cnt <= cnt - 1'b1;
            end else begin
                // Count up
                cnt <= cnt + 1'b1;
            end
        end
        // Counter holds value when not enabled
    end

endmodule
