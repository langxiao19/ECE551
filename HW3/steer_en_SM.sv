module steer_en_SM(clk,rst_n,tmr_full,sum_gt_min,sum_lt_min,diff_gt_1_4,
                   diff_gt_15_16,clr_tmr,en_steer,rider_off);

  input clk;				// 50MHz clock
  input rst_n;				// Active low asynch reset
  input tmr_full;			// asserted when timer reaches 1.3 sec
  input sum_gt_min;			// asserted when left and right load cells together exceed min rider weight
  input sum_lt_min;			// asserted when left_and right load cells are less than min_rider_weight

  /////////////////////////////////////////////////////////////////////////////
  // HEY HOFFMAN...you are a moron.  sum_gt_min would simply be ~sum_lt_min. 
  // Why have both signals coming to this unit??  ANSWER: What if we had a rider
  // (a child) who's weigth was right at the threshold of MIN_RIDER_WEIGHT?
  // We would enable steering and then disable steering then enable it again,
  // ...  We would make that child crash(children are light and flexible and 
  // resilient so we don't care about them, but it might damage our Segway).
  // We can solve this issue by adding hysteresis.  So sum_gt_min is asserted
  // when the sum of the load cells exceeds MIN_RIDER_WEIGHT + HYSTERESIS and
  // sum_lt_min is asserted when the sum of the load cells is less than
  // MIN_RIDER_WEIGHT - HYSTERESIS.  Now we have noise rejection for a rider
  // who's weight is right at the threshold.  This hysteresis trick is as old
  // as the hills, but very handy...remember it.
  //////////////////////////////////////////////////////////////////////////// 

  input diff_gt_1_4;		// asserted if load cell difference exceeds 1/4 sum (rider not situated)
  input diff_gt_15_16;		// asserted if load cell difference is great (rider stepping off)
  output logic clr_tmr;		// clears the 1.3sec timer
  output logic en_steer;	// enables steering (goes to balance_cntrl)
  output logic rider_off;	// held high in intitial state when waiting for sum_gt_min
  
  //////////////////////////
  // Define state encoding //
  /////////////////////////
  typedef enum reg [1:0] {
    INITIAL = 2'b00,        // Waiting for rider to get on (sum_gt_min)
    WAIT_BALANCE = 2'b01,   // Waiting for rider to balance and 1.3sec timer
    STEER_EN = 2'b10        // Steering enabled - normal operation
  } state_t;
  
  state_t state, nxt_state;
  
  /////////////////////////////////////
  // State machine sequential logic //
  ///////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      state <= INITIAL;
    else
      state <= nxt_state;
  end
  
  ///////////////////////////////////////
  // State machine combinational logic //
  /////////////////////////////////////
  always_comb begin
    // Default assignments
    nxt_state = state;
    clr_tmr = 1'b0;
    en_steer = 1'b0;
    rider_off = 1'b0;
    
    case (state)
      INITIAL: begin
        rider_off = 1'b1;  // Assert rider_off in initial state
        if (sum_gt_min) begin
          nxt_state = WAIT_BALANCE;
          clr_tmr = 1'b1;  // Clear timer when transitioning to wait for balance
        end
      end
      
      WAIT_BALANCE: begin
        if (sum_lt_min) begin
          // Rider stepped off completely - go back to initial
          nxt_state = INITIAL;
        end else if (diff_gt_1_4) begin
          // Rider not balanced - stay in this state and clear timer
          clr_tmr = 1'b1;
        end else if (tmr_full) begin
          // Rider is balanced and timer expired - enable steering
          nxt_state = STEER_EN;
        end
      end
      
      STEER_EN: begin
        en_steer = 1'b1;  // Enable steering in this state
        if (sum_lt_min) begin
          // Rider fell off suddenly - highest priority - go to initial
          nxt_state = INITIAL;
        end else if (diff_gt_15_16) begin
          // Rider stepping off - go to wait for balance state
          nxt_state = WAIT_BALANCE;
        end
      end
      
      default: begin
        nxt_state = INITIAL;
      end
    endcase
  end
  
endmodule