module SegwayMath(
i    input signed [11:0] PID_cntrl,  // Signed 12-bit control from PID
    input [7:0] ss_tmr,             // Unsigned 8-bit soft-start timer
    input [11:0] steer_pot,         // 12-bit unsigned steering potentiometer
    input en_steer,                 // Steering enable signal
    input pwr_up,                   // Power up signal
    output signed [11:0] lft_spd,   // Left motor speed (signed 12-bit)
    output signed [11:0] rght_spd,  // Right motor speed (signed 12-bit)
    output too_fast                 // Over-speed detection flag
);

// Local parameters
localparam MIN_DUTY = 13'h0A8;
localparam LOW_TORQUE_BAND = 7'h2A;
localparam GAIN_MULT = 4'h4;

// Internal signals
reg signed [19:0] product;          // 20-bit product from PID_cntrl * ss_tmr
wire signed [11:0] PID_ss;          // PID scaled by soft-start timer
reg [11:0] steer_pot_limited;       // Steering pot limited to 0x200-0xE00
wire signed [11:0] steer_signed;    // Signed steering value
wire signed [13:0] steer_influence; // 3/16 of steering offset
wire signed [13:0] almost_torque;   // Differential torque from steering
wire signed [12:0] PID_ss_extended; // Sign-extended PID_ss to 13 bits
wire signed [12:0] lft_torque;      // Left torque before shaping
wire signed [12:0] rght_torque;     // Right torque before shaping
wire signed [12:0] lft_shaped;      // Left torque after deadzone shaping
wire signed [12:0] rght_shaped;     // Right torque after deadzone shaping
wire signed [12:0] lft_torque_comp; // Left torque compensation
wire signed [12:0] rght_torque_comp; // Right torque compensation
wire lft_in_deadzone, rght_in_deadzone; // Deadzone detection flags
wire lft_pwr_up_mux, rght_pwr_up_mux;   // Power up mux selection

// Step 1: Scale PID_cntrl by ss_tmr (soft start)
// Zero extend ss_tmr to 9 bits and cast to signed, then multiply
always_comb begin
    product = PID_cntrl * $signed({1'b0, ss_tmr});
end

// Divide by 256 (right shift by 8) to get PID_ss
assign PID_ss = product[19:8];

// Step 2: Limit steering potentiometer to range 0x200 to 0xE00
always_comb begin
    if (steer_pot < 12'h200)
        steer_pot_limited = 12'h200;
    else if (steer_pot > 12'hE00)
        steer_pot_limited = 12'hE00;
    else
        steer_pot_limited = steer_pot;
end

// Convert to signed by subtracting 0x7FF (center point, 2047 in decimal)
assign steer_signed = steer_pot_limited - 12'h7FF;

// Calculate steering influence: 3/16 of steering offset
assign steer_influence = (steer_signed * 3) >>> 4;

// Create differential torque based on steering sign
// This creates the base differential that will be applied
assign almost_torque = steer_influence[13] ? ($signed({1'b0, PID_ss}) - steer_influence) : ($signed({1'b0, PID_ss}) + steer_influence);

// Step 3: Sign extend PID_ss to 13 bits
assign PID_ss_extended = {PID_ss[11], PID_ss};

// Step 4: Apply steering differential if enabled
// Left gets PID + almost_torque, Right gets PID - almost_torque
assign lft_torque = en_steer ? (PID_ss_extended + almost_torque[12:0]) : PID_ss_extended;
assign rght_torque = en_steer ? (PID_ss_extended - almost_torque[12:0]) : PID_ss_extended;

// Step 5: Deadzone compensation
// Check if torque magnitude is within LOW_TORQUE_BAND
assign lft_in_deadzone = (lft_torque[12] ? (-lft_torque) : lft_torque) < LOW_TORQUE_BAND;
assign rght_in_deadzone = (rght_torque[12] ? (-rght_torque) : rght_torque) < LOW_TORQUE_BAND;

// Calculate compensation values
assign lft_torque_comp = lft_in_deadzone ? 
    (lft_torque * $signed(GAIN_MULT)) :
    (lft_torque[12] ? (lft_torque - MIN_DUTY) : (lft_torque + MIN_DUTY));

assign rght_torque_comp = rght_in_deadzone ? 
    (rght_torque * $signed(GAIN_MULT)) :
    (rght_torque[12] ? (rght_torque - MIN_DUTY) : (rght_torque + MIN_DUTY));

// Power up mux - set to zero if not powered up
assign lft_pwr_up_mux = pwr_up;
assign rght_pwr_up_mux = pwr_up;

assign lft_shaped = lft_pwr_up_mux ? lft_torque_comp : 13'h0000;
assign rght_shaped = rght_pwr_up_mux ? rght_torque_comp : 13'h0000;

// Step 6: 12-bit signed saturation
function signed [11:0] saturate_12bit;
    input signed [12:0] value;
    begin
        if (value > $signed(12'h7FF))
            saturate_12bit = 12'h7FF;
        else if (value < $signed(12'h800))
            saturate_12bit = 12'h800;
        else
            saturate_12bit = value[11:0];
    end
endfunction

assign lft_spd = saturate_12bit(lft_shaped);
assign rght_spd = saturate_12bit(rght_shaped);

// Step 7: Over-speed detection
// too_fast is asserted if magnitude of either shaped value exceeds 1536
assign too_fast = ((lft_shaped[12] ? -lft_shaped : lft_shaped) > $signed(13'd1536)) ||
                  ((rght_shaped[12] ? -rght_shaped : rght_shaped) > $signed(13'd1536));

endmodule
