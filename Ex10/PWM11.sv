module PWM11(
    input clk,              // 50MHz system clock
    input rst_n,            // Asynchronous active low reset
    input [10:0] duty,      // Specifies duty cycle (unsigned 11-bit)
    output PWM1,            // Complementary glitch free PWM signals
    output PWM2,            // with non-overlap
    output PWM_synch,       // Use to synch changes in duty
    output ovr_I_blank      // Used to blank out over current mitigation
);

// Local parameter for non-overlap time
localparam NONOVERLAP = 11'h040;  // 64 clock cycles of non-overlap

// 11-bit free-running counter
reg [10:0] cnt;

// Counter logic - counts from 0 to 2047 then rolls over
always @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        cnt <= 11'h000;
    else
        cnt <= cnt + 1;
end

// PWM_synch signal - high when counter is all zeros
assign PWM_synch = ~|cnt;  // NOR of all bits (true when cnt == 0)

// Set/Reset combinational logic for PWM signals
wire set_PWM1, reset_PWM1;
wire set_PWM2, reset_PWM2;

// PWM1 logic: runs from NONOVERLAP to duty
assign set_PWM1 = (cnt >= NONOVERLAP);
assign reset_PWM1 = (cnt >= duty);

// PWM2 logic: runs from duty+NONOVERLAP to 2047 (wraps to 0)
assign set_PWM2 = (cnt >= (duty + NONOVERLAP));
assign reset_PWM2 = ~|cnt;  // Reset when counter rolls over to 0

// SR Flip-flops for PWM1 and PWM2
reg PWM1_reg, PWM2_reg;

// PWM1 SR flip-flop
always @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        PWM1_reg <= 1'b0;
    else if (reset_PWM1)
        PWM1_reg <= 1'b0;
    else if (set_PWM1)
        PWM1_reg <= 1'b1;
end

// PWM2 SR flip-flop  
always @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        PWM2_reg <= 1'b0;
    else if (reset_PWM2)
        PWM2_reg <= 1'b0;
    else if (set_PWM2)
        PWM2_reg <= 1'b1;
end

// Output assignments
assign PWM1 = PWM1_reg;
assign PWM2 = PWM2_reg;

// Over current blanking signal
// Blank during first 128 clocks of either PWM1 or PWM2 pulse
assign ovr_I_blank = ((cnt >= NONOVERLAP) && (cnt < (NONOVERLAP + 128))) ||
                     ((cnt >= (duty + NONOVERLAP)) && (cnt < (duty + NONOVERLAP + 128)));

endmodule
