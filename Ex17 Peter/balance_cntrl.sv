module balance_cntrl #(parameter fast_sim = 1) (
    input clk, rst_n,
    input vld,
    input signed [15:0] ptch,
    input signed [15:0] ptch_rt,
    input pwr_up,
    input rider_off,
    input [11:0] steer_pot,
    input en_steer,
    output [11:0] lft_spd,
    output [11:0] rght_spd,
    output too_fast
);

    // Internal signals between PID and SegwayMath
    wire signed [11:0] PID_cntrl;
    wire [7:0] ss_tmr;  // Steady state timer (not used in SegwayMath but part of PID interface)
    
    // Instantiate PID module with fast_sim parameter
    PID #(.fast_sim(fast_sim)) iPID (
        .clk(clk),
        .rst_n(rst_n),
        .vld(vld),
        .ptch(ptch),
        .ptch_rt(ptch_rt),
        .pwr_up(pwr_up),
        .rider_off(rider_off),
        .PID_cntrl(PID_cntrl),
        .ss_tmr(ss_tmr)
    );
    
    // Instantiate SegwayMath module
    SegwayMath iSegwayMath (
        .clk(clk),
        .rst_n(rst_n),
        .PID(PID_cntrl),
        .steer_pot(steer_pot),
        .en_steer(en_steer),
        .lft_spd(lft_spd),
        .rght_spd(rght_spd),
        .too_fast(too_fast)
    );

endmodule
