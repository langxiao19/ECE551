module PID(
    input signed [15:0] ptch,        // This IS the P term (after saturation and multiplication)
    input signed [15:0] ptch_rt,     // This IS the D term 
    input clk, 
    input rst_n,
    input vld,
    input pwr_up,
    input rider_off,
    output logic [7:0] ss_tmr,
    output signed [11:0] PID_cntrl,
    output signed [17:0] integrator  // Added integrator as output for debugging
);

    parameter FAST_SIM = 1; // Set to 1 for fast simulation (increment timer by 1), 0 for normal operation (multiply by 256)
    logic signed [14:0] p_term;
    logic signed [14:0] i_term;
    logic signed [12:0] d_term;
    logic signed [15:0] PID_mid;
    logic signed [9:0] ptch_err_sat;
    logic signed [19:0] sum_for_integrator;  // Wider to prevent overflow
    logic signed [17:0] integrator_reg;
    logic rider_off_ff1, rider_off_ff2;
    logic [26:0] soft_start_timer;
    logic [26:0] additive;
    logic signed [14:0] i_term_temp;
     
    localparam P_COEFF = 5'h09;

//P TERM=============================================================
    assign ptch_err_sat = ((ptch[15] == 1'b0 && |ptch[14:9])||(ptch[15] == 1'b1 && ~&ptch[14:9])) ? {ptch[15], {9{~ptch[15]}}} : ptch[9:0];
    assign p_term = $signed(ptch_err_sat) * $signed(P_COEFF);

//I TERM=============================================================
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            integrator_reg <= 18'h00000;
        else if (!pwr_up || rider_off)  
            integrator_reg <= 18'h00000;
        else if (vld) begin

            sum_for_integrator = {{2{integrator_reg[17]}}, integrator_reg} + {{10{ptch_err_sat[9]}}, ptch_err_sat};
            
            if (sum_for_integrator > 20'sd131071)  begin
                integrator_reg <= 18'sh1FFFF;   // +131071 (max positive for 18-bit signed)
            end else if (sum_for_integrator < -20'sd131072) begin 
                integrator_reg <= 18'sh20000;   // -131072 (max negative for 18-bit signed)
            end else begin
                integrator_reg <= sum_for_integrator[17:0];
            end
        end
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            rider_off_ff1 <= 1'b0;
            rider_off_ff2 <= 1'b0;
        end else begin
            rider_off_ff1 <= rider_off;
            rider_off_ff2 <= rider_off_ff1;
        end
    end
    assign integrator = integrator_reg;
    
    // I term is bits [17:6] of integrator (divide by 64)
    assign i_term = i_term_temp;
    

//D TERM=============================================================
    assign d_term = ~{{3{ptch_rt[15]}}, ptch_rt[15:6]} + 1'b1; 
    //move over by 6... 2^6 is 64... mind blown. (again)... also squiggly makes it negative!!
 
    assign PID_mid = {p_term[14], 
                      p_term[14:0]} + {i_term[14], 
                      i_term[14:0]} + {{3{d_term[12]}}, 
                      d_term[12:0]};
                      


    // Saturate to 12-bit signed range: -2048 to +2047
    logic signed [11:0] PID_saturated;
    
    always_comb begin
        if (PID_mid > $signed(16'd2047)) begin
            PID_saturated = 12'sh7FF;    // +2047
        end else if (PID_mid < $signed(-16'd2048)) begin 
            PID_saturated = 12'sh800;    // -2048  
        end else begin
            PID_saturated = PID_mid[11:0];  // This should be the signed 12-bit value
        end
    end
    
    assign PID_cntrl = PID_saturated;

//SOFT START TIMER===================================================
    // 27-bit timer for soft start - one shot timer that freezes when near full
    logic [26:0] long_tmr;
    logic tmr_full;
    
    // Check if timer is near full (bits [26:19] are all 1's)
    // This creates the "freeze" condition when ss_tmr reaches 0xFF
    assign tmr_full = &long_tmr[26:19];  // All upper 8 bits are 1

    generate 
        if(FAST_SIM) begin : gen_fast_sim
            // Fast sim: Set additive to 256 for timer
            assign additive = 27'd256;
            
            // Fast sim I_term: tap bits [15:1] with saturation
            always_comb begin
                if (integrator_reg[17:15] == 3'b000 || integrator_reg[17:15] == 3'b111) begin
                    // No saturation needed - use bits [15:1] (tap by 1) to form I_term in FAST_SIM
                    // integrator_reg[15:1] is 15 bits and matches i_term_temp [14:0]
                    i_term_temp = integrator_reg[15:1];
                end else begin
                    // Saturation needed - saturate based on sign
                    i_term_temp = integrator_reg[17] ? 15'sh4000 : 15'sh3FFF;
                end
            end
        end else begin : gen_normal
            // Normal: Set additive to 1 for timer
            assign additive = 27'd1;
            
            // Normal I_term: tap bits [17:6] (divide by 64)
            always_comb begin
                i_term_temp = {{3{integrator_reg[17]}}, integrator_reg[17:6]};
            end
        end
    endgenerate
    
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            long_tmr <= 27'h0000000;
        else if (!pwr_up)
            long_tmr <= 27'h0000000;  
        else if (!tmr_full) 
            long_tmr <= long_tmr + additive;
        
        end
    
    
    // Output upper 8 bits [26:19] of 27-bit timer
    assign ss_tmr = long_tmr[26:19];

endmodule