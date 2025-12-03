
//////////////////////////////////////////////////////
// inertial_integrator.sv
// Integrates pitch rate from gyro and fuses with 
// accelerometer readings to prevent long-term drift
// Team: Langlang Xiao, Matthew Ye
//////////////////////////////////////////////////////

module inertial_integrator(
  input clk,                    // 50MHz clock
  input rst_n,                  // active low reset
  input vld,                    // high for 1 clock when new inertial readings valid
  input signed [15:0] ptch_rt,  // 16-bit signed raw pitch rate from inertial sensor
  input signed [15:0] AZ,       // acceleration in Z direction (for sensor fusion)
  output signed [15:0] ptch     // fully compensated and fused 16-bit signed pitch
);

  ///////////////////////////////////////////
  // Local parameters for offset compensation
  ///////////////////////////////////////////
  localparam signed PTCH_RT_OFFSET = 16'h0050;  // pitch rate offset compensation
  localparam signed AZ_OFFSET = 16'h00A0;       // AZ offset compensation
  
  ///////////////////////////////////////////
  // Internal signals
  ///////////////////////////////////////////
  logic signed [15:0] ptch_rt_comp;       // compensated pitch rate
  logic signed [15:0] AZ_comp;            // compensated AZ reading
  logic signed [26:0] ptch_int;           // pitch integrating accumulator
  logic signed [26:0] fusion_ptch_offset; // fusion correction term
  logic signed [25:0] ptch_acc_product;   // intermediate product for ptch_acc calculation
  logic signed [15:0] ptch_acc;           // pitch angle calculated from accelerometer only
  
  ///////////////////////////////////////////
  // Compensate raw sensor readings
  ///////////////////////////////////////////
  assign ptch_rt_comp = ptch_rt - PTCH_RT_OFFSET;
  assign AZ_comp = AZ - AZ_OFFSET;
  
  ///////////////////////////////////////////
  // Calculate pitch from accelerometer
  ///////////////////////////////////////////
  assign ptch_acc_product = AZ_comp * $signed(327);  // 327 is fudge factor
  assign ptch_acc = {{3{ptch_acc_product[25]}}, ptch_acc_product[25:13]};  // sign extend and scale
  
  ///////////////////////////////////////////
  // Determine fusion offset correction
  ///////////////////////////////////////////
  always_comb begin
    if (ptch_acc > ptch)
      fusion_ptch_offset = 27'sd1024;   // leak toward more positive pitch
    else
      fusion_ptch_offset = -27'sd1024;  // leak toward more negative pitch
  end
  
  ///////////////////////////////////////////
  // Pitch integrator with fusion correction
  ///////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      ptch_int <= 27'sd0;
    else if (vld)
      // Integrate negative of compensated pitch rate + fusion correction
      ptch_int <= ptch_int - {{11{ptch_rt_comp[15]}}, ptch_rt_comp} + fusion_ptch_offset;
  end
  
  ///////////////////////////////////////////
  // Output scaled pitch (divide by 2^11)
  ///////////////////////////////////////////
  assign ptch = ptch_int[26:11];

endmodule
