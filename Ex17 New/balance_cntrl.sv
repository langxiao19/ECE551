// balance_cntrl.sv
// Same interface and hierarchy; rewritten comments/formatting only.
module balance_cntrl #(
    parameter FAST_SIM = 1
) (
    // Inputs
    input  wire                clk,
    input  wire                rst_n,
    input  wire                vld,
    input  wire signed [15:0]  ptch,
    input  wire signed [15:0]  ptch_rt,
    input  wire                pwr_up,
    input  wire                rider_off,
    input  wire [11:0]         steer_pot,
    input  wire                en_steer,

    // Outputs
    output wire signed [11:0]  lft_spd,
    output wire signed [11:0]  rght_spd,
    output wire                too_fast
);

    // Interconnect between PID and math block
    wire [7:0]           ss_tmr;       // soft-start timer
    wire signed [11:0]   PID_cntrl;    // PID control effort
    wire signed [17:0]   integrator;   // exposed for debug

    // Control law (PID)
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

    // Speed shaping and overspeed detection
    wire raw_too_fast;  // un-gated overspeed indication from math
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

    // Gate the overspeed alert with input validity to match reference behavior
    wire too_fast_masked = vld ? raw_too_fast : 1'b0;
    assign too_fast = too_fast_masked;

endmodule
