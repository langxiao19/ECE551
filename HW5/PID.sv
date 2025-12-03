// PID.sv - Full PID controller for Segway
// Includes integrator accumulator and soft start timer

module PID #(parameter fast_sim = 0) (
  input  logic                        clk,
  input  logic                        rst_n,   // async active-low
  input  logic                        vld,      // valid signal for new inertial sensor reading

  input  logic signed [15:0]          ptch,     // pitch from inertial sensor
  input  logic signed [15:0]          ptch_rt,  // pitch rate (degrees/sec) for D_term
  input  logic                        pwr_up,   // asserted when balance control is powered up
  input  logic                        rider_off, // asserted when no rider detected

  output logic signed [11:0]          PID_cntrl, // main PID output
  output logic [7:0]                  ss_tmr     // soft start timer
);
  // PID constants
  localparam P_COEFF = 9;  // From testbench P_COEFF = 5'h09
  
  // State registers
  logic signed [9:0] ptch_err_sat;       // saturated pitch error (10-bit signed)
  logic signed [17:0] integrator;        // 18-bit integrator accumulator
  logic signed [15:0] prev_ptch_rt;      // previous pitch rate for derivative
  logic [26:0] long_tmr;                 // 27-bit timer for soft start
  logic prev_vld;                         // previous vld for edge detection
  
  // Intermediate signals
  logic signed [15:0] ptch_err;          // current pitch error
  logic signed [15:0] P_term;           // proportional term
  logic signed [15:0] I_term;           // integral term 
  logic signed [15:0] D_term;           // derivative term
  logic signed [17:0] PID_sum;          // sum of P+I+D terms
  logic signed [17:0] integrator_next;  // next integrator value
  logic [26:0] long_tmr_next;           // next timer value

  // Saturation function for pitch error (to 10-bit signed)
  function automatic logic signed [9:0] saturate_ptch_err(
      input logic signed [15:0] err
  );
    if (err > 16'sd511)        // greater than +511
      saturate_ptch_err = 10'sd511;
    else if (err < -16'sd512)  // less than -512
      saturate_ptch_err = -10'sd512;
    else
      saturate_ptch_err = err[9:0];
  endfunction

  // Combinational PID calculation
  always_comb begin
    // Calculate saturated pitch error first
    ptch_err = ptch;  // Error is pitch deviation from 0
    ptch_err_sat = saturate_ptch_err(ptch_err);
    
    // P_term calculation: P_COEFF * ptch_err_sat
    P_term = $signed(ptch_err_sat) * P_COEFF;
    
    // I_term calculation - scale integrator (different for fast_sim)
    // Generate conditional handled below
    
    // D_term calculation: derivative of pitch rate
    // (prev_ptch_rt - ptch_rt) / 64
    D_term = ($signed(prev_ptch_rt) - $signed(ptch_rt)) >>> 6;
    
    // Sum all terms: P + I + D
    PID_sum = {{2{P_term[15]}}, P_term} + {{2{I_term[15]}}, I_term} + {{2{D_term[15]}}, D_term};
    
    // Integrator update logic
    if (rider_off) begin
      // Zero integrator when no rider
      integrator_next = 18'h00000;
    end else if (vld) begin
      // Accumulate saturated pitch error into integrator 
      logic signed [18:0] temp_sum;
      temp_sum = {{1{integrator[17]}}, integrator} + {{9{ptch_err_sat[9]}}, ptch_err_sat};
      
      // Check for overflow and clamp
      if (temp_sum > 19'sd131071)  // positive overflow  
        integrator_next = 18'sd131071;  // clamp to max
      else if (temp_sum < -19'sd131072)  // negative overflow
        integrator_next = -18'sd131072;  // clamp to min
      else  
        integrator_next = temp_sum[17:0];
    end else begin
      // Hold current value
      integrator_next = integrator;
    end
    
    // Soft start timer logic
    if (!pwr_up) begin
      long_tmr_next = 27'h0000000;
    end else if (&long_tmr[18:11]) begin
      // Timer upper bits are full, freeze it
      long_tmr_next = long_tmr;
    end else begin
      // Increment timer - by 256 in fast_sim mode, by 1 otherwise
      if (fast_sim)
        long_tmr_next = long_tmr + 27'd256;
      else
        long_tmr_next = long_tmr + 27'd1;
    end
  end  // end of always_comb block

  // Generate conditional for I_term calculation based on fast_sim
  generate
    if (fast_sim) begin : FAST_SIM_MODE
      // Fast simulation mode: tap bits [15:1] with saturation
      always_comb begin
        // Check for saturation by inspecting bits [17:15]
        if (integrator[17:15] == 3'b111)  // Negative, no saturation
          I_term = {{1{integrator[15]}}, integrator[15:1]};
        else if (integrator[17:15] == 3'b000)  // Positive, no saturation  
          I_term = {{1{integrator[15]}}, integrator[15:1]};
        else if (integrator[17])  // Negative saturation (17=1, but not all 1's in [17:15])
          I_term = 16'h8000;  // Most negative 16-bit value
        else  // Positive saturation
          I_term = 16'h7FFF;  // Most positive 16-bit value
      end
    end else begin : NORMAL_MODE
      // Normal mode: tap bits [17:6] with sign extension, but we actually use [17:1] divided by 2
      // Original working code used integrator >>> 1
      assign I_term = integrator >>> 1;
    end
  endgenerate

  // PID_cntrl output assignment with saturation  
  always_comb begin    
    // Saturate to 12-bit signed range
    if ($signed(PID_sum) > $signed(18'sd2047))       
      PID_cntrl = 12'h7FF;           // +2047
    else if ($signed(PID_sum) < $signed(-18'sd2048)) 
      PID_cntrl = 12'h800;           // -2048
    else
      PID_cntrl = PID_sum[11:0];     // Take lower 12 bits directly
  end

  // Sequential logic for state updates
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      integrator <= 18'h00000;
      prev_ptch_rt <= 16'h0000;
      long_tmr <= 27'h0000000;
      prev_vld <= 1'b0;
    end else begin
      integrator <= integrator_next;
      // Update prev_ptch_rt on rising edge of vld
      if (vld && !prev_vld)
        prev_ptch_rt <= ptch_rt;
      prev_vld <= vld;
      long_tmr <= long_tmr_next;
    end
  end

  // Soft start timer output
  assign ss_tmr = long_tmr[18:11];

endmodule

