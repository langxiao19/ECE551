module SegwayMath (
    input clk, rst_n,
    input signed [11:0] PID,
    input [11:0] steer_pot,
    input en_steer,
    output reg [11:0] lft_spd,
    output reg [11:0] rght_spd,
    output too_fast
);

    // Internal signals
    reg signed [11:0] steer_pot_signed;
    reg signed [12:0] lft_torque, rght_torque;
    wire signed [11:0] steer_offset;
    
    // Convert steer_pot to signed and create offset
    always_comb begin
        steer_pot_signed = {1'b0, steer_pot[10:0]} - 12'h800; // Convert to signed centered around 0x800
    end
    
    // Steering offset calculation (only when steering enabled)
    assign steer_offset = en_steer ? (steer_pot_signed >>> 3) : 12'h000;
    
    // Calculate left and right torques
    always_comb begin
        lft_torque = PID - steer_offset;
        rght_torque = PID + steer_offset;
    end
    
    // Saturate and assign outputs
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            lft_spd <= 12'h000;
            rght_spd <= 12'h000;
        end else begin
            // Saturate left speed
            if (lft_torque > 12'h7FF)
                lft_spd <= 12'h7FF;
            else if (lft_torque < -12'h800)
                lft_spd <= 12'h800;
            else
                lft_spd <= lft_torque[11:0];
                
            // Saturate right speed
            if (rght_torque > 12'h7FF)
                rght_spd <= 12'h7FF;
            else if (rght_torque < -12'h800)
                rght_spd <= 12'h800;
            else
                rght_spd <= rght_torque[11:0];
        end
    end
    
    // Too fast detection (when PID output is at extreme values)
    assign too_fast = (PID > 12'h600) || (PID < -12'h600);

endmodule