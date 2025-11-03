module SegwayMath(
input signed [11:0] PID_cntrl,
input [7:0] ss_tmr,
input [11:0] steer_pot,
input en_steer,
input pwr_up,
output signed [11:0] lft_spd,
output signed [11:0] rght_spd,
output too_fast
);

localparam signed [12:0] MIN_DUTY = 13'sd168;    // 0x0A8
localparam signed [12:0] LOW_TORQUE_BAND = 13'sd42; // 0x2A
localparam signed [12:0] GAIN_MULT = 13'sd4;

wire signed [11:0] PID_ss;

wire signed [12:0] lft_torque;   
wire signed [12:0] rght_torque;             

wire signed [12:0] lft_torque_comp;
wire signed [12:0] mult_resultl;                //value comparison to see if segway is in deadzone (L side)
wire signed [12:0] lft_shaped;

wire signed [12:0] rght_torque_comp;
wire signed [12:0] mult_resultr;                //value comparison to see if segway is in deadzone (R side)
wire signed [12:0] rght_shaped;

wire signed [13:0] signineer;
wire signed [13:0] almost_torque;

wire [11:0] steer_pot_sat;  // Intermediate signal for debugging

// Convert steer pot to a signed offset from center (0x7FF) so further
// steering math uses a proper signed quantity regardless of the raw
// unsigned steer_pot value. steer_offset is 13 bits to avoid overflow
// during multiplication by small constants.
wire signed [12:0] steer_offset = $signed({1'b0, steer_pot_sat}) - 13'sd2047;

//SOFT START++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//SOFT START:===========================================================================================

wire signed [19:0] temp_mult = PID_cntrl * $signed({1'b0, ss_tmr});
assign PID_ss = temp_mult[19:8];

//=======================================================================================================
//STEERING CALCULATION+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//THE CALCULATION:=======================================================================================

// Saturate steer_pot between 0x200 and 0xE00 (intermediate signal for visibility)
assign steer_pot_sat = (steer_pot < 12'h200) ? 12'h200 : (steer_pot > 12'hE00) ? 12'hE00 : steer_pot;
// Compute steering influence (signineer) from steer_offset (signed)
assign signineer = (3 * steer_offset) >>> 4; // scaled and shifted
assign almost_torque = signineer[13] ? (PID_ss - signineer) : (PID_ss + signineer);
assign lft_torque = en_steer ? (PID_ss + almost_torque) : PID_ss;
assign rght_torque = en_steer ? (PID_ss - almost_torque) : PID_ss;


//=======================================================================================================
//DEADZONE AND GAIN COMPENSATION+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//LEFT SIDE:=============================================================================================

//lft_torque's sign determines if the compensated torque is to be subtracted or added
assign lft_torque_comp = lft_torque[12] ? lft_torque - MIN_DUTY : lft_torque + MIN_DUTY;

//if device is in the steep part of compensation, the torque is scaled by the gain multiplier
assign mult_resultl = ((lft_torque[12] ? -lft_torque : lft_torque) > LOW_TORQUE_BAND) ? lft_torque_comp : lft_torque*$signed(GAIN_MULT);

//check if the segway is POWERED UP!!!!1!!!
assign lft_shaped[12:0] = pwr_up ? mult_resultl : 13'h0000; 


//RIGHT SIDE:============================================================================================

//rght_torque's sign determines if the compensated torque is to be subtracted or added
assign rght_torque_comp = rght_torque[12] ? rght_torque - MIN_DUTY : rght_torque + MIN_DUTY;

//if device is in the steep part of compensation, the torque is scaled by the gain multiplier
assign mult_resultr = ((rght_torque[12] ? -rght_torque : rght_torque) > LOW_TORQUE_BAND) ? rght_torque_comp : rght_torque*$signed(GAIN_MULT);

//check if the segway is POWERED UP!!!!1!!!
assign rght_shaped[12:0] = pwr_up ? mult_resultr : 13'h0000;


//=======================================================================================================
//OVER SPEED DETECT++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//FINAL SATURATION=======================================================================================

//signed 12 bit signals lft_spd and rght_spd are formed by signed 12 bit saturation of lft_shaped and rght_shaped, in addition, too fast is set if they are going too fast and pushing the control limits of the segway. If it is >$signed(12'd1536) than its too fast. must use >$signed(12'd1536)
assign lft_spd = (lft_shaped > 13'sh7FF) ? 12'sh7FF : (lft_shaped < -13'sh800) ? -12'sh800 : lft_shaped[11:0];
assign rght_spd = (rght_shaped > 13'sh7FF) ? 12'sh7FF : (rght_shaped < -13'sh800) ? -12'sh800 : rght_shaped[11:0];
assign too_fast = ((lft_shaped[12] ? -lft_shaped : lft_shaped) > $signed(12'd1536)) | ((rght_shaped[12] ? -rght_shaped : rght_shaped) > $signed(12'd1536));


//=======================================================================================================   

endmodule


