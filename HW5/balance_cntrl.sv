// balance_cntrl.sv - Top-level balance controller
// Wires PID outputs into SegwayMath motor control

module balance_cntrl #(
  parameter fast_sim = 1   // Passed down to PID for fast simulation
)(
  input  logic                        clk,        // 50MHz system clock
  input  logic                        rst_n,      // active-low reset
  input  logic                        vld,        // new inertial sensor reading
  input  logic signed [15:0]          ptch,       // pitch from inertial_intf
  input  logic signed [15:0]          ptch_rt,    // pitch rate (deg/sec) for D term
  input  logic                        pwr_up,     // balance control powered up
  input  logic                        rider_off,  // no rider detected
  input  logic [11:0]                 steer_pot,  // steering pot from A2D_intf
  input  logic                        en_steer,   // steering enable

  output logic signed [11:0]          lft_spd,    // left motor speed
  output logic signed [11:0]          rght_spd,   // right motor speed
  output logic                        too_fast    // speed safety flag
);

  // Internal wires between PID and SegwayMath
  logic signed [11:0] PID_cntrl;
  logic        [7:0]  ss_tmr;

  // =========================
  // PID controller instance
  // =========================
  PID #(
    .fast_sim(fast_sim)
  ) iPID (
    .clk      (clk),
    .rst_n    (rst_n),
    .vld      (vld),
    .ptch     (ptch),
    .ptch_rt  (ptch_rt),
    .pwr_up   (pwr_up),
    .rider_off(rider_off),
    .PID_cntrl(PID_cntrl),
    .ss_tmr   (ss_tmr)
  );

  // =========================
  // Segway motor math
  // =========================
  SegwayMath iSegwayMath (
    .PID_cntrl(PID_cntrl),
    .ss_tmr   (ss_tmr),
    .steer_pot(steer_pot),
    .en_steer (en_steer),
    .pwr_up   (pwr_up),
    .rider_off(rider_off),
    .lft_spd  (lft_spd),
    .rght_spd (rght_spd),
    .too_fast (too_fast)
  );

endmodule

