//////////////////////////////////////////////////////
// piezo_drv.sv
// Piezo driver with charge fanfare for Segway warnings
// Plays tones at specified frequencies for rider presence, low battery, and overspeed alerts
// Team: Your Team Name Here
//////////////////////////////////////////////////////

module piezo_drv #(
  parameter fast_sim = 1  // 1=fast sim (64x speed), 0=real timing
) (
  input  logic clk,
  input  logic rst_n,
  input  logic en_steer,   // normal operation - charge fanfare every 3 sec
  input  logic too_fast,   // priority - first 3 notes continuously
  input  logic batt_low,   // charge fanfare backwards every 3 sec
  output logic piezo,
  output logic piezo_n
);

  //////////////////////////////////////////////////////
  // Note frequencies (Period = 50MHz / frequency)
  //////////////////////////////////////////////////////
  localparam int G6_PERIOD = 50_000_000 / 1568;  // G6 = ~31,888 clocks
  localparam int C7_PERIOD = 50_000_000 / 2093;  // C7 = ~23,888 clocks
  localparam int E7_PERIOD = 50_000_000 / 2637;  // E7 = ~18,960 clocks
  localparam int G7_PERIOD = 50_000_000 / 3136;  // G7 = ~15,943 clocks

  //////////////////////////////////////////////////////
  // Note durations (powers of 2 for efficiency)
  //////////////////////////////////////////////////////
  localparam int DUR_223 = 2**23;  // 8,388,608 clocks
  localparam int DUR_222 = 2**22;  // 4,194,304 clocks
  localparam int DUR_225 = 2**25;  // 33,554,432 clocks

  //////////////////////////////////////////////////////
  // 3 second repeat period (50MHz clocks)
  //////////////////////////////////////////////////////
  localparam int REPEAT_3SEC = 150_000_000;

  //////////////////////////////////////////////////////
  // State machine - 7 states for charge fanfare
  //////////////////////////////////////////////////////
  typedef enum logic [2:0] {
    IDLE,         // 0: Silent, waiting
    NOTE1,        // 1: G6
    NOTE2,        // 2: C7
    NOTE3,        // 3: E7 (223)
    NOTE4,        // 4: G7 (445)
    NOTE5,        // 5: E7 (222)
    NOTE6,        // 6: G7 (225)
    WAIT_REPEAT   // 7: 3 second pause
  } state_t;
  
  state_t state, nxt_state;

  //////////////////////////////////////////////////////
  // Counters
  //////////////////////////////////////////////////////
  logic [27:0] duration_cnt;   // counts note duration
  logic [27:0] repeat_cnt;     // 3-second repeat timer
  logic [15:0] freq_cnt;       // frequency/period counter

  //////////////////////////////////////////////////////
  // Control signals
  //////////////////////////////////////////////////////
  logic [27:0] duration_target;
  logic [15:0] period_target;
  logic duration_done;
  logic repeat_done;
  
  //////////////////////////////////////////////////////
  // Generate increment amounts based on fast_sim
  //////////////////////////////////////////////////////
  logic [6:0] dur_incr, rep_incr;
  logic [15:0] period_scaled;  // Scaled period for fast_sim
  
  generate
    if (fast_sim) begin : g_fast
      assign dur_incr  = 7'd64;
      assign rep_incr  = 7'd64;
      // Scale period down by 64 in fast_sim so we can hear tones
      assign period_scaled = period_target >> 6;
    end else begin : g_norm
      assign dur_incr  = 7'd1;
      assign rep_incr  = 7'd1;
      // No scaling in real mode
      assign period_scaled = period_target;
    end
  endgenerate

  //////////////////////////////////////////////////////
  // State machine - infer state register
  //////////////////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;
  end

  //////////////////////////////////////////////////////
  // State machine - combinational next state logic
  //////////////////////////////////////////////////////
  always_comb begin
    // Default: stay in current state
    nxt_state = state;
    
    case (state)
      IDLE: begin
        // Check for any active mode
        if (too_fast || en_steer)
          nxt_state = NOTE1;  // Start forward (too_fast or en_steer)
        else if (batt_low)
          nxt_state = NOTE6;  // Start backward (batt_low)
      end
      
      NOTE1: begin  // G6
        if (duration_done) begin
          if (too_fast || en_steer)
            nxt_state = NOTE2;  // Forward: NOTE1 -> NOTE2
          else if (batt_low)
            nxt_state = WAIT_REPEAT;  // Backward: NOTE1 is last, go to wait
          else
            nxt_state = IDLE;
        end
      end
      
      NOTE2: begin  // C7
        if (duration_done) begin
          if (too_fast || en_steer)
            nxt_state = NOTE3;  // Forward: NOTE2 -> NOTE3
          else if (batt_low)
            nxt_state = NOTE1;  // Backward: NOTE2 -> NOTE1
          else
            nxt_state = IDLE;
        end
      end
      
      NOTE3: begin  // E7 (223)
        if (duration_done) begin
          if (too_fast)
            nxt_state = NOTE1;  // too_fast loops first 3 notes
          else if (en_steer)
            nxt_state = NOTE4;  // Forward: NOTE3 -> NOTE4
          else if (batt_low)
            nxt_state = NOTE2;  // Backward: NOTE3 -> NOTE2
          else
            nxt_state = IDLE;
        end
      end
      
      NOTE4: begin  // G7 (445)
        if (duration_done) begin
          if (en_steer)
            nxt_state = NOTE5;  // Forward: NOTE4 -> NOTE5
          else if (batt_low)
            nxt_state = NOTE3;  // Backward: NOTE4 -> NOTE3
          else
            nxt_state = IDLE;
        end
      end
      
      NOTE5: begin  // E7 (222)
        if (duration_done) begin
          if (en_steer)
            nxt_state = NOTE6;  // Forward: NOTE5 -> NOTE6
          else if (batt_low)
            nxt_state = NOTE4;  // Backward: NOTE5 -> NOTE4
          else
            nxt_state = IDLE;
        end
      end
      
      NOTE6: begin  // G7 (225)
        if (duration_done) begin
          if (en_steer)
            nxt_state = WAIT_REPEAT;  // Forward: NOTE6 is last
          else if (batt_low)
            nxt_state = NOTE5;  // Backward: NOTE6 -> NOTE5
          else
            nxt_state = IDLE;
        end
      end
      
      WAIT_REPEAT: begin
        if (repeat_done) begin
          if (too_fast || en_steer)
            nxt_state = NOTE1;  // Restart forward
          else if (batt_low)
            nxt_state = NOTE6;  // Restart backward
          else
            nxt_state = IDLE;
        end
      end
      
      default: nxt_state = IDLE;
    endcase
  end

  //////////////////////////////////////////////////////
  // Set duration and period targets based on state
  //////////////////////////////////////////////////////
  always_comb begin
    // Defaults
    duration_target = 28'd0;
    period_target = 16'd0;
    
    case (state)
      NOTE1: begin  // G6, 223
        period_target = G6_PERIOD;
        duration_target = DUR_223;
      end
      NOTE2: begin  // C7, 223
        period_target = C7_PERIOD;
        duration_target = DUR_223;
      end
      NOTE3: begin  // E7, 223
        period_target = E7_PERIOD;
        duration_target = DUR_223;
      end
      NOTE4: begin  // G7, 445 (223+222)
        period_target = G7_PERIOD;
        duration_target = DUR_223 + DUR_222;
      end
      NOTE5: begin  // E7, 222
        period_target = E7_PERIOD;
        duration_target = DUR_222;
      end
      NOTE6: begin  // G7, 225
        period_target = G7_PERIOD;
        duration_target = DUR_225;
      end
      default: begin
        period_target = 16'd0;
        duration_target = 28'd0;
      end
    endcase
  end

  //////////////////////////////////////////////////////
  // Duration counter - tracks note length
  //////////////////////////////////////////////////////
  assign duration_done = (duration_target > 0) && (duration_cnt >= duration_target);
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      duration_cnt <= 28'd0;
    else if (state != nxt_state)  // Reset on state change
      duration_cnt <= 28'd0;
    else if ((state != IDLE) && (state != WAIT_REPEAT) && (duration_target > 0))
      duration_cnt <= duration_cnt + dur_incr;
  end

  //////////////////////////////////////////////////////
  // Repeat timer - 3 second pause between fanfares
  //////////////////////////////////////////////////////
  assign repeat_done = (repeat_cnt >= REPEAT_3SEC);
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      repeat_cnt <= 28'd0;
    else if (state != WAIT_REPEAT)
      repeat_cnt <= 28'd0;
    else
      repeat_cnt <= repeat_cnt + rep_incr;
  end

  //////////////////////////////////////////////////////
  // Frequency counter - generates square wave by counting period
  // Counter counts up to period_scaled to create one full cycle
  //////////////////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      freq_cnt <= 16'd0;
    else if ((state == IDLE) || (state == WAIT_REPEAT))
      freq_cnt <= 16'd0;
    else if (period_scaled == 0)
      freq_cnt <= 16'd0;
    else if (freq_cnt >= period_scaled - 1)
      freq_cnt <= 16'd0;  // Wrap around after completing one period
    else
      freq_cnt <= freq_cnt + 16'd1;  // Always increment by 1
  end

  //////////////////////////////////////////////////////
  // Piezo output - differential drive
  // Toggle at half the period to create 50% duty cycle
  //////////////////////////////////////////////////////
  logic piezo_reg;
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      piezo_reg <= 1'b0;
    else if ((state == IDLE) || (state == WAIT_REPEAT))
      piezo_reg <= 1'b0;  // Silent
    else if (period_scaled > 0) begin
      // Generate square wave based on counter position
      if (freq_cnt < (period_scaled >> 1))
        piezo_reg <= 1'b0;
      else
        piezo_reg <= 1'b1;
    end
  end

  assign piezo   = piezo_reg;
  assign piezo_n = ~piezo_reg;

endmodule
