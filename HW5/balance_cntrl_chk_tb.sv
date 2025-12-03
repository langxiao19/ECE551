//==============================================================
// Balance Control Self-Checking Testbench
//==============================================================
`timescale 1ns/1ps

module balance_cntrl_chk_tb;

  // --- Clock & loop vars ---
  logic clk;
  integer i;
  integer errors = 0;
  integer shown  = 0;
  // Mismatch classification counters
  integer t_only = 0;
  integer l_only = 0;
  integer r_only = 0;
  integer lr_only = 0;
  integer lrt_all = 0;

  // --- Stimulus & response memories ---
  reg [48:0] stim_mem [0:1499];
  reg [24:0] resp_mem [0:1499];

  // --- Stimulus vector unpacking ---
  logic rst_n;
  logic vld;
  logic signed [15:0] ptch;
  logic signed [15:0] ptch_rt;
  logic pwr_up;
  logic rider_off;
  logic [11:0] steer_pot;
  logic en_steer;

  // --- DUT outputs ---
  wire signed [11:0] lft_spd;
  wire signed [11:0] rght_spd;
  wire too_fast;

  // --- Instantiate DUT ---
  balance_cntrl iDUT (
    .clk       (clk),
    .rst_n     (rst_n),
    .vld       (vld),
    .ptch      (ptch),
    .ptch_rt   (ptch_rt),
    .pwr_up    (pwr_up),
    .rider_off (rider_off),
    .steer_pot (steer_pot),
    .en_steer  (en_steer),
    .lft_spd   (lft_spd),
    .rght_spd  (rght_spd),
    .too_fast  (too_fast)
  );

  // --- Clock generation ---
  initial begin
    clk = 0;
    forever #5 clk = ~clk;   // 100 MHz sim clock
  end

  // --- Main test process ---
  initial begin
    // Local scratch for mismatch classification
    logic signed [11:0] exp_l, exp_r;
    bit exp_t, got_t;
    bit l_eq, r_eq, t_eq;
    // Load stimulus & response data
    $readmemh("balance_cntrl_stim.hex", stim_mem);
    $readmemh("balance_cntrl_resp.hex", resp_mem);

    // Force ss_tmr for fast simulation
    // NOTE: Commented out for post-synthesis simulation (signal may be renamed)
    // force iDUT.ss_tmr = 8'hFF;

    // Apply each vector
    for (i = 0; i < 1500; i++) begin
      {rst_n, vld, ptch, ptch_rt, pwr_up, rider_off, steer_pot, en_steer} = stim_mem[i];
      @(posedge clk);
      #1;

      if ({lft_spd, rght_spd, too_fast} !== resp_mem[i]) begin
        // Classify mismatch
        exp_l = $signed(resp_mem[i][24:13]);
        exp_r = $signed(resp_mem[i][12:1]);
        exp_t = resp_mem[i][0];
        got_t = too_fast;
        l_eq = (lft_spd === exp_l);
        r_eq = (rght_spd === exp_r);
        t_eq = (got_t === exp_t);
        if (l_eq && r_eq && !t_eq) t_only++;
        else if (!l_eq && r_eq && t_eq) l_only++;
        else if (l_eq && !r_eq && t_eq) r_only++;
        else if (!l_eq && !r_eq && t_eq) lr_only++;
        else lrt_all++;
        if (shown < 40) begin
          shown++;
          $display("[%0t] ❌ Vec %0d exp={L:%0d R:%0d T:%0b} got={L:%0d R:%0d T:%0b} raw_exp=%h raw_got=%h",
                   $time, i,
                   $signed(resp_mem[i][24:13]), $signed(resp_mem[i][12:1]), resp_mem[i][0],
                   $signed(lft_spd), $signed(rght_spd), too_fast,
                   resp_mem[i], {lft_spd, rght_spd, too_fast});
        end else begin
          $display("[%0t] ❌ Mismatch at vector %0d: expected=%h got=%h",
                   $time, i, resp_mem[i], {lft_spd, rght_spd, too_fast});
        end
        errors++;
      end
    end

    if (errors == 0)
      $display("\n✅ All 1500 vectors matched expected response.\n");
    else
      $display("\n❌ %0d mismatches detected out of 1500 vectors.\n", errors);

    if (errors) begin
      $display("Breakdown: T-only=%0d, L-only=%0d, R-only=%0d, L+R=%0d, L+R+T=%0d",
               t_only, l_only, r_only, lr_only, lrt_all);
    end

    $finish;
  end

endmodule
