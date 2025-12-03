module SegwayMath (
    input  signed [11:0] PID_cntrl,  // Signed 12-bit control from PID
    input         [7:0]  ss_tmr,     // Unsigned 8-bit soft-start timer
    input        [11:0]  steer_pot,  // 12-bit unsigned steering potentiometer
    input                en_steer,   // Steering enable signal
    input                pwr_up,     // Power up signal
    input                rider_off,  // Rider not present
    output signed [11:0] lft_spd,    // Left motor speed (signed 12-bit)
    output signed [11:0] rght_spd,   // Right motor speed (signed 12-bit)
    output               too_fast    // Over-speed detection flag
);

// Local parameters
localparam MIN_DUTY        = 13'h0A8;
localparam LOW_TORQUE_BAND = 7'h2A;
localparam GAIN_MULT       = 4'h4;

// Internal signals
reg  signed [19:0] product;          // 20-bit product from PID_cntrl * ss_tmr
wire signed [11:0] PID_ss;           // PID scaled by soft-start timer
reg  [11:0]        steer_pot_limited;// Steering pot limited to 0x200-0xE00
// Steering offset and contribution with explicit sizing to match Ex15/Ex17 reference
wire signed [12:0] steer_offset;     // Signed 13-bit steering offset from center (0x7FF)
wire signed [13:0] steer_scaled;     // 14-bit intermediate for 3/16 scaling
wire signed [12:0] steer_contribution; // 13-bit contribution after truncation
wire signed [12:0] PID_ss_extended;  // Sign-extended PID_ss to 13 bits
// Base torque (pre-steer)
wire signed [12:0] base_torque;
// Post-steer (side-specific) commands
wire signed [12:0] lft_cmd;
wire signed [12:0] rght_cmd;
// Per-side shaping signals
wire               lft_in_deadzone;
wire               rght_in_deadzone;
wire signed [12:0] lft_comp;
wire signed [12:0] rght_comp;
// Post-shape (pre-saturation) torques
wire signed [12:0] lft_pre_sat;
wire signed [12:0] rght_pre_sat;
// Intermediate post-steer before power/rider gating
wire signed [12:0] lft_post_steer;
wire signed [12:0] rght_post_steer;

// Step 1: Scale PID_cntrl by ss_tmr (soft start)
// Zero extend ss_tmr to 9 bits and cast to signed, then multiply
always_comb begin
    product = PID_cntrl * $signed({1'b0, ss_tmr});
end

// Divide by 256 with round-to-nearest (restores prior 281-mismatch baseline)
assign PID_ss = (product + 20'sd128) >>> 8;

// Step 2: Limit steering potentiometer to range 0x200 to 0xE00
always_comb begin
    if (steer_pot < 12'h200)
        steer_pot_limited = 12'h200;
    else if (steer_pot > 12'hE00)
        steer_pot_limited = 12'hE00;
    else
        steer_pot_limited = steer_pot;
end

// Convert to signed by subtracting 0x7FF (13-bit to avoid width/rounding artifacts)
assign steer_offset = $signed({1'b0, steer_pot_limited}) - 13'sd2047;

// Calculate steering contribution: 3/16 of steering offset (truncate), keep intermediate width
assign steer_scaled = (steer_offset * 14'sd3) >>> 4;
assign steer_contribution = steer_scaled[12:0];

// Step 3: Sign extend PID_ss to 13 bits
assign PID_ss_extended = {PID_ss[11], PID_ss};
assign base_torque     = PID_ss_extended;

// Step 4: Apply steering differential before shaping
// Match golden behavior: steering applies purely on en_steer; pwr_up is handled later
assign lft_post_steer  = en_steer ? (base_torque + steer_contribution) : base_torque;
assign rght_post_steer = en_steer ? (base_torque - steer_contribution) : base_torque;

// Step 5: Per-side deadzone and min-duty shaping AFTER steering
assign lft_in_deadzone  = (lft_post_steer[12] ? (-lft_post_steer) : lft_post_steer) < LOW_TORQUE_BAND;
assign rght_in_deadzone = (rght_post_steer[12] ? (-rght_post_steer) : rght_post_steer) < LOW_TORQUE_BAND;

assign lft_comp  = lft_in_deadzone  ? (lft_post_steer  * $signed(GAIN_MULT))
                                    : (lft_post_steer[12]  ? (lft_post_steer  - MIN_DUTY)
                                                         : (lft_post_steer  + MIN_DUTY));
assign rght_comp = rght_in_deadzone ? (rght_post_steer * $signed(GAIN_MULT))
                                    : (rght_post_steer[12] ? (rght_post_steer - MIN_DUTY)
                                                          : (rght_post_steer + MIN_DUTY));

// Power-up gate before saturation
assign lft_pre_sat  = pwr_up ? lft_comp  : 13'sd0;
assign rght_pre_sat = pwr_up ? rght_comp : 13'sd0;

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

assign lft_spd  = saturate_12bit(lft_pre_sat);
assign rght_spd = saturate_12bit(rght_pre_sat);

// Step 7: Over-speed detection  
// Positive-only detection (golden reference behavior for Ex17)
assign too_fast = (lft_pre_sat  > $signed(13'd1536)) ||
                  (rght_pre_sat > $signed(13'd1536));

endmodule
