// PID.sv - Full PID controller (adapted interface for Ex17 New)
// Based on provided PID from Ex17, adjusted to keep ports/param compatible

module PID #(
    parameter FAST_SIM = 0
) (
    input  logic                        clk,
    input  logic                        rst_n,     // async active-low
    input  logic                        vld,       // new sensor sample valid

    input  logic signed [15:0]          ptch,      // pitch
    input  logic signed [15:0]          ptch_rt,   // pitch rate
    input  logic                        pwr_up,    // power-up enable
    input  logic                        rider_off, // no rider detected

    output logic signed [11:0]          PID_cntrl, // PID output
    output logic [7:0]                  ss_tmr,    // soft-start timer
    output logic signed [17:0]          integrator // expose integrator for debug
);

    // Gain
    localparam int P_COEFF = 9;

    // State
    logic signed [9:0]   ptch_err_sat;
    logic signed [15:0]  ptch_err;
    logic signed [15:0]  P_term;
    logic signed [15:0]  I_term;
    logic signed [15:0]  D_term;
    logic signed [17:0]  PID_sum;
    logic signed [17:0]  integrator_next;
    logic signed [15:0]  prev_ptch_rt;
    logic                prev_vld;
    logic [26:0]         long_tmr, long_tmr_next;

    // Saturate pitch error to 10-bit signed
    function automatic logic signed [9:0] sat_err(input logic signed [15:0] e);
        if (e > 16'sd511)        sat_err = 10'sd511;
        else if (e < -16'sd512)  sat_err = -10'sd512;
        else                     sat_err = e[9:0];
    endfunction

    // Core combinational math
    always_comb begin
        // Error and P
        ptch_err     = ptch;
        ptch_err_sat = sat_err(ptch_err);
        P_term       = $signed(ptch_err_sat) * P_COEFF;

        // D: simple discrete derivative of pitch rate
        D_term = ($signed(prev_ptch_rt) - $signed(ptch_rt)) >>> 6;

        // I update
        if (rider_off) begin
            integrator_next = 18'sd0;
        end else if (vld) begin
            logic signed [18:0] tmp;
            tmp = {{1{integrator[17]}}, integrator} + {{9{ptch_err_sat[9]}}, ptch_err_sat};
            if (tmp > 19'sd131071)       integrator_next = 18'sd131071;
            else if (tmp < -19'sd131072) integrator_next = -18'sd131072;
            else                         integrator_next = tmp[17:0];
        end else begin
            integrator_next = integrator;
        end

        // Soft-start timer advance
        if (!pwr_up) begin
            long_tmr_next = 27'd0;
        end else if (&long_tmr[18:11]) begin
            long_tmr_next = long_tmr; // freeze when ss_tmr hits 0xFF
        end else begin
            long_tmr_next = long_tmr + (FAST_SIM ? 27'd256 : 27'd1);
        end

        // Sum P + I + D (I_term is assigned in generate below)
        PID_sum = {{2{P_term[15]}}, P_term}
                        + {{2{I_term[15]}}, I_term}
                        + {{2{D_term[15]}}, D_term};
    end

    // I term shaping depends on FAST_SIM
    generate
        if (FAST_SIM) begin : G_FS
            always_comb begin
                // use [15:1] with saturation on extreme values
                if (integrator[17:15] == 3'b000 || integrator[17:15] == 3'b111)
                    I_term = {{1{integrator[15]}}, integrator[15:1]};
                else if (integrator[17])
                    I_term = 16'h8000;
                else
                    I_term = 16'h7FFF;
            end
        end else begin : G_NORM
            // nominal: divide by 2
            assign I_term = integrator >>> 1;
        end
    endgenerate

    // Output saturation to 12-bit signed
    always_comb begin
        if ($signed(PID_sum) > 18'sd2047)         PID_cntrl = 12'sh7FF;
        else if ($signed(PID_sum) < -18'sd2048)   PID_cntrl = 12'sh800;
        else                                      PID_cntrl = PID_sum[11:0];
    end

    // State registers
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            integrator   <= 18'sd0;
            prev_ptch_rt <= 16'sd0;
            long_tmr     <= 27'd0;
            prev_vld     <= 1'b0;
        end else begin
            integrator   <= integrator_next;
            if (vld && !prev_vld) prev_ptch_rt <= ptch_rt;
            prev_vld     <= vld;
            long_tmr     <= long_tmr_next;
        end
    end

    // Soft-start timer exposes middle bits for 0..255 ramp
    assign ss_tmr = long_tmr[18:11];

endmodule