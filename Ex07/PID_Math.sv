
`timescale 1ns/1ps

// Exercise 7 - PID Math
// Implements the PID_Math block per requirements:
// - Saturate ptch (16-bit signed) to ptch_err_sat (10-bit signed)
// - P_term = ptch_err_sat * PCOEFF (5'sd9) --> 15-bit signed
// - I_term = integrator >>> 6               --> 15-bit signed
// - D_term = -(ptch_rt >>> 6)               --> 13-bit signed
// - PID_cntrl = P_term + I_term + D_term, saturated to 12-bit signed

module PID_Math
(
    input  logic signed [15:0] ptch,
    input  logic signed [15:0] ptch_rt,
    input  logic signed [17:0] integrator,
    output logic signed [11:0] PID_cntrl
);

    // Coefficient for P term
    localparam logic signed [4:0] PCOEFF = 5'sd9;

    // --- Internal signals with explicit signed widths ---
    logic signed [9:0]  ptch_err_sat;
    logic signed [14:0] P_term;
    logic signed [14:0] I_term;
    logic signed [12:0] D_term;

    // Wider extensions for safe accumulation (avoid overflow)
    logic signed [17:0] P_18, I_18, D_18, sum_18;

    // ---------- Helper: saturate 16-bit to 10-bit signed ----------
    function automatic logic signed [9:0] sat10(input logic signed [15:0] x);
        // 10-bit signed range is [-512, +511]
        if (x >  16'sd511)   return 10'sd511;
        else if (x < -16'sd512) return -10'sd512;
        else                 return x[9:0];  // value is within range; truncate is safe
    endfunction

    // ---------- Helper: saturate 18-bit to 12-bit signed ----------
    function automatic logic signed [11:0] sat12(input logic signed [17:0] x);
        // 12-bit signed range is [-2048, +2047]
        if (x >  18'sd2047)   return 12'sd2047;
        else if (x < -18'sd2048) return -12'sd2048;
        else                  return x[11:0]; // safe to truncate
    endfunction

    // ---------- Combinational math ----------
    always_comb begin
        // Saturate ptch to 10-bit signed
        ptch_err_sat = sat10(ptch);

        // P_term: 10b * 5b --> 15b signed
        P_term = ptch_err_sat * PCOEFF;

        // I_term: integrator >>> 6, keep 15b signed
        // (arithmetic shift maintains sign; cast/truncate to 15 bits)
        I_term = ( $signed(integrator) >>> 6 );

        // D_term: -(ptch_rt >>> 6), keep 13b signed
        D_term = - ( $signed(ptch_rt) >>> 6 );

        // Sign extend to 18 bits for accumulation
        P_18 = { {3{P_term[14]}}, P_term };   // 15 -> 18
        I_18 = { {3{I_term[14]}}, I_term };   // 15 -> 18
        D_18 = { {5{D_term[12]}}, D_term };   // 13 -> 18

        // Sum and saturate to 12-bit signed
        sum_18   = P_18 + I_18 + D_18;
        PID_cntrl = sat12(sum_18);
    end

endmodule
