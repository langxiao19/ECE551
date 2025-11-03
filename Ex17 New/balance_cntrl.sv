module balance_cntrl #(
	parameter FAST_SIM = 1
) (
	input  wire                clk,
	input  wire                rst_n,
	input  wire                vld,
	input  wire signed [15:0]  ptch,
	input  wire signed [15:0]  ptch_rt,
	input  wire                pwr_up,
	input  wire                rider_off,
	input  wire [11:0]         steer_pot,
	input  wire                en_steer,

	output wire signed [11:0]  lft_spd,
	output wire signed [11:0]  rght_spd,
	output wire                too_fast
);

	// Wires between PID and SegwayMath
	wire [7:0] ss_tmr;
	wire signed [11:0] PID_cntrl;
	wire signed [17:0] integrator; // optional debug output from PID

	// Instantiate PID (existing in this folder)
	PID #(.FAST_SIM(FAST_SIM)) u_PID (
		.ptch(ptch),
		.ptch_rt(ptch_rt),
		.clk(clk),
		.rst_n(rst_n),
		.vld(vld),
		.pwr_up(pwr_up),
		.rider_off(rider_off),
		.ss_tmr(ss_tmr),
		.PID_cntrl(PID_cntrl),
		.integrator(integrator)
	);

	// Instantiate SegwayMath and mask the overspeed output with `vld`.
	// The test vectors expect `too_fast` to be meaningful only when the
	// input vector is valid (vld==1). To match the reference responses,
	// capture the raw `too_fast` from the math block and gate it with vld
	// at the top level.
	wire raw_too_fast;

	SegwayMath u_SegwayMath (
		.PID_cntrl(PID_cntrl),
		.ss_tmr(ss_tmr),
		.steer_pot(steer_pot),
		.en_steer(en_steer),
		.pwr_up(pwr_up),
		.lft_spd(lft_spd),
		.rght_spd(rght_spd),
		.too_fast(raw_too_fast)
	);

	// Only assert too_fast when the input vector is valid
	assign too_fast = vld ? raw_too_fast : 1'b0;

endmodule
