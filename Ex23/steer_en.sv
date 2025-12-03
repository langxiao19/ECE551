module steer_en #(parameter fast_sim = 1) (
  input        clk,
  input        rst_n,
  input [11:0] lft_ld,      // Left load cell reading
  input [11:0] rght_ld,     // Right load cell reading
  output       en_steer,    // Enables steering
  output       rider_off    // Asserted when rider is off
);

  ///////////////////////////////////////////////////
  // Internal signals                              //
  ///////////////////////////////////////////////////
  wire [12:0] sum;              // Sum of load cells
  wire signed [12:0] diff;      // Difference of load cells
  wire sum_gt_min;              // Sum greater than minimum
  wire sum_lt_min;              // Sum less than minimum  
  wire diff_gt_1_4;             // Difference > 1/4 of sum (not balanced)
  wire diff_gt_15_16;           // Difference > 15/16 of sum (stepping off)
  wire tmr_full;                // Timer full signal
  wire clr_tmr;                 // Clear timer signal
  
  ///////////////////////////////////////////////////
  // Comparisons for sum                           //
  ///////////////////////////////////////////////////
  localparam MIN_RIDER_WEIGHT = 13'h600;  // Minimum weight threshold
  
  assign sum = {1'b0, lft_ld} + {1'b0, rght_ld};
  assign sum_gt_min = (sum > (MIN_RIDER_WEIGHT + 13'h080)) ? 1'b1 : 1'b0;  // Hysteresis
  assign sum_lt_min = (sum < (MIN_RIDER_WEIGHT - 13'h080)) ? 1'b1 : 1'b0;  // Hysteresis
  
  ///////////////////////////////////////////////////
  // Comparisons for difference                    //
  ///////////////////////////////////////////////////
  assign diff = $signed({1'b0, lft_ld}) - $signed({1'b0, rght_ld});
  
  // diff_gt_1_4: abs(diff) > sum/4 (rider not balanced)
  wire [12:0] abs_diff = (diff[12]) ? -diff : diff;
  wire [12:0] quarter_sum = sum >> 2;
  assign diff_gt_1_4 = (abs_diff > quarter_sum) ? 1'b1 : 1'b0;
  
  // diff_gt_15_16: abs(diff) > 15*sum/16 (rider stepping off)
  wire [16:0] fifteen_sixteenth_sum = (sum * 15) >> 4;
  assign diff_gt_15_16 = (abs_diff > fifteen_sixteenth_sum[12:0]) ? 1'b1 : 1'b0;
  
  ///////////////////////////////////////////////////
  // Timer (1.3 seconds with fast_sim support)    //
  ///////////////////////////////////////////////////
  localparam TIMER_FULL = (fast_sim) ? 24'h000800 : 24'h3E7FB0;  // 1.3s @ 50MHz or fast
  
  logic [23:0] tmr;
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      tmr <= 24'h000000;
    else if (clr_tmr)
      tmr <= 24'h000000;
    else if (!tmr_full)
      tmr <= tmr + 1;
  end
  
  assign tmr_full = (tmr >= TIMER_FULL) ? 1'b1 : 1'b0;
  
  ///////////////////////////////////////////////////
  // Instantiate state machine                     //
  ///////////////////////////////////////////////////
  steer_en_SM iSM(
    .clk(clk),
    .rst_n(rst_n),
    .tmr_full(tmr_full),
    .sum_gt_min(sum_gt_min),
    .sum_lt_min(sum_lt_min),
    .diff_gt_1_4(diff_gt_1_4),
    .diff_gt_15_16(diff_gt_15_16),
    .clr_tmr(clr_tmr),
    .en_steer(en_steer),
    .rider_off(rider_off)
  );

endmodule
