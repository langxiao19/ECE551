module PID(ptch, ptch_rt, PID_cntrl, clk, rst_n, vld, ss_tmr, pwr_up, rider_off);
    // Inputs
    input [15:0] ptch;      // Signed 16-bit pitch signal from inertial_interface
    input [15:0] ptch_rt;   // Signed 16-bit pitch rate from inertial interface (for D_term)
    input        clk;       // System clock
    input        vld;       // Valid signal for integrator update
    input        rst_n;     // Active-low reset
    input        pwr_up;    // Power up signal
    input        rider_off; // Rider off signal (resets integrator)
    
    // Outputs
    output [7:0]  ss_tmr;    // Steady state timer (upper 8 bits of 27-bit counter)
    output [11:0] PID_cntrl; // 12-bit signed PID control output

    //======================================
    // Parameters and Internal Signals
    //======================================
    parameter fast_sim = 0;              // Fast simulation mode (default: 0 = normal, 1 = fast)
    localparam P_COEFF = 5'h09;          // Proportional coefficient (9)
    
    // PID calculation signals
    logic [9:0]  ptch_sat;               // Saturated pitch signal (10-bit signed)
    logic [14:0] p_term;                 // Proportional term (15-bit)
    logic [11:0] i_term;                 // Integral term (12-bit)
    logic [12:0] d_term;                 // Derivative term (13-bit)
    logic [15:0] total;                  // Sum of all PID terms
    
    // Integrator signals
    logic [17:0] integrator;             // 18-bit integrator accumulation register
    logic [17:0] sum;                    // Temporary sum for overflow detection
    logic        overflow;               // Overflow detection flag
    
    // Steady state timer
    logic [26:0] ss_tmr_full;            // Full 27-bit steady state timer

    //======================================
    // Pitch Signal Saturation
    //======================================
    // Saturate the 16-bit pitch signal to 10 bits using bitwise operations
    // If upper 7 bits match the sign bit (all 0s or all 1s), keep lower 10 bits
    // Otherwise saturate: negative -> 0x200 (-512), positive -> 0x1FF (+511)
    assign ptch_sat = (&ptch[14:9] | ~|ptch[14:9]) ? ptch[9:0] :                // No overflow: keep lower 10 bits
                      {ptch[15], {9{~ptch[15]}}};                                 // Overflow: saturate based on sign

    //======================================
    // Integral Term Calculation
    //======================================
    // Combinational logic for overflow detection
    assign sum = {{8{ptch_sat[9]}}, ptch_sat} + integrator;  // Sign-extend ptch_sat to 18 bits and add
    
    // Overflow occurs when operands have same sign but result has different sign
    assign overflow = (ptch_sat[9] == integrator[17]) & (ptch_sat[9] != sum[17]);
    
    // Integrator register with reset and overflow protection
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || rider_off)
            integrator <= 18'h0;              // Reset integrator on reset or rider off
        else if (vld && !overflow)
            integrator <= sum;                // Update only if valid and no overflow
        // If overflow detected, hold previous value
    end
    
    // Extract integral term (depends on fast_sim parameter)
    // Generate conditional for fast_sim mode
    generate
        if (fast_sim) begin : FAST_SIM_ITERM
            // Fast sim: tap bits [15:1], with saturation check on bits [17:15]
            // If [17:15] are all same as sign bit [15], no saturation needed
            // Otherwise saturate: negative -> 12'h800 (-2048), positive -> 12'h7FF (+2047)
            assign i_term = (&integrator[17:15] | ~|integrator[17:15]) ? {integrator[15], integrator[15:5]} :
                           {integrator[17], {11{~integrator[17]}}};
        end else begin : NORMAL_SIM_ITERM
            // Normal sim: tap bits [17:6] and sign-extend to 12 bits
            assign i_term = {{3{integrator[17]}}, integrator[17:6]};
        end
    endgenerate
    
    //======================================
    // Proportional Term Calculation
    //======================================
    // Multiply saturated pitch by proportional coefficient
    assign p_term = $signed(ptch_sat) * $signed(P_COEFF);
    
    //======================================
    // Derivative Term Calculation  
    //======================================
    // Take upper 9 bits of pitch rate, sign extend to 13 bits, then negate (2's complement)
    // This effectively creates: -(ptch_rt >> 6) scaled appropriately
    assign d_term = ~{{4{ptch_rt[15]}}, ptch_rt[14:6]} + 13'b1;
    
    //======================================
    // PID Output Calculation and Saturation
    //======================================
    // Sum all three PID terms
    assign total = $signed(p_term) + $signed(i_term) + $signed(d_term);
    
    // Saturate 16-bit total to 12-bit output using bitwise operations
    // If upper 5 bits match the sign bit (all 0s or all 1s), keep lower 12 bits
    // Otherwise saturate: negative -> 0x800 (-2048), positive -> 0x7FF (+2047)
    assign PID_cntrl = (&total[14:11] | ~|total[14:11]) ? total[11:0] :      // No overflow: keep lower 12 bits
                       {total[15], {11{~total[15]}}};                         // Overflow: saturate based on sign

    //======================================
    // Steady State Timer
    //======================================
    // 27-bit counter with fast_sim support
    // Normal mode: increment by 1 every clock
    // Fast sim mode: increment by 256 every clock (speeds up by 256x)
    generate
        if (fast_sim) begin : FAST_SIM_TIMER
            // Fast simulation: increment by 256 each clock cycle
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n || !pwr_up)
                    ss_tmr_full <= 27'h0;                    // Reset timer
                else if (~(&ss_tmr_full[26:8]))              // Count until upper 19 bits are all 1's
                    ss_tmr_full <= ss_tmr_full + 27'd256;    // Increment by 256
            end
        end else begin : NORMAL_SIM_TIMER
            // Normal simulation: increment by 1 each clock cycle
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n || !pwr_up)
                    ss_tmr_full <= 27'h0;                    // Reset timer
                else if (~(&ss_tmr_full[26:8]))              // Count until upper 19 bits are all 1's
                    ss_tmr_full <= ss_tmr_full + 27'h1;      // Increment by 1
            end
        end
    endgenerate
    
    // Output the upper 8 bits as the steady state timer value
    assign ss_tmr = ss_tmr_full[26:19];

endmodule