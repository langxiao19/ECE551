// balance_cntrl.sv - Balance control module combining PID and SegwayMath
// This module integrates the PID controller with the Segway motor control math

module balance_cntrl #(
  parameter fast_sim = 1  // Parameter to speed up simulation, defaulted to 1
)(
  input  logic                        clk,        // 50MHz system clock
  input  logic                        rst_n,      // active low reset
  input  logic                        vld,        // High when new inertial sensor reading is ready
  input  logic signed [15:0]          ptch,       // Pitch of Segway from inertial_intf
  input  logic signed [15:0]          ptch_rt,    // Pitch rate (degrees/sec) for D_term of PID
  input  logic                        pwr_up,     // Asserted when Segway balance control is powered up
  input  logic                        rider_off,  // Asserted when no rider detected
  input  logic [11:0]                 steer_pot,  // From A2D_intf (converted from steering potentiometer)
  input  logic                        en_steer,   // Enables steering control
  
  output logic signed [11:0]          lft_spd,    // 12-bit signed speed of left motor
  output logic signed [11:0]          rght_spd,   // 12-bit signed speed of right motor
  output logic                        too_fast    // Rider approaching point of minimal control margin
);

  // Internal signals connecting PID to SegwayMath
  logic signed [11:0] PID_cntrl;  // PID controller output
  logic [7:0] ss_tmr;             // Soft start timer output

  // Instantiate PID controller  
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
    .PID_cntrl(PID_cntrl),
    .ss_tmr(ss_tmr),
    .steer_pot(steer_pot),
    .en_steer(en_steer),
    .pwr_up(pwr_up),
    .lft_spd(lft_spd),
    .rght_spd(rght_spd),
    .too_fast(too_fast)
  );

endmodule
