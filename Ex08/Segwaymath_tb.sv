`timescale 1ns/1ps

module Segwaymath_tb();

// Testbench signals
reg signed [11:0] PID_cntrl;
reg [7:0] ss_tmr;
reg [11:0] steer_pot;
reg en_steer;
reg pwr_up;
wire signed [11:0] lft_spd;
wire signed [11:0] rght_spd;
wire too_fast;

// Clock and reset (not used by DUT but useful for simulation timing)
reg clk;

// Instantiate DUT (Device Under Test)
SegwayMath DUT (
    .PID_cntrl(PID_cntrl),
    .ss_tmr(ss_tmr),
    .steer_pot(steer_pot),
    .en_steer(en_steer),
    .pwr_up(pwr_up),
    .lft_spd(lft_spd),
    .rght_spd(rght_spd),
    .too_fast(too_fast)
);

// Clock generation for timing reference
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz clock
end

// Test sequence
initial begin
    // Initialize signals
    PID_cntrl = 12'h000;
    ss_tmr = 8'h00;
    steer_pot = 12'h000;
    en_steer = 1'b0;
    pwr_up = 1'b0;
    
    $display("=== SegwayMath Testbench Starting ===");
    $display("Time\t\tPID_cntrl\tss_tmr\tsteer_pot\ten_steer\tpwr_up\tlft_spd\t\trght_spd\ttoo_fast");
    $display("====================================================================================================");
    
    // Wait for initial settling
    #10;
    
    // ==========================================
    // TEST 1: Recommended Test Scenario
    // PID_cntrl starts at 12'h5FF, ss_tmr ramps 0 to 8'hFF
    // Then PID_cntrl ramps from 12'h5FF to 12'hE00
    // steer_en = 0, pwr_up = 1
    // ==========================================
    
    $display("\n=== TEST 1: PID Control with Soft Start ===");
    
    // Initial conditions for Test 1
    PID_cntrl = 12'h5FF;  // +1535
    ss_tmr = 8'h00;
    steer_pot = 12'h7FF;  // Mid-range, but not used since en_steer = 0
    en_steer = 1'b0;
    pwr_up = 1'b1;
    
    #10;
    $display("%0t\t\t%h\t\t%h\t%h\t\t%b\t\t%b\t%d\t\t%d\t\t%b", 
             $time, PID_cntrl, ss_tmr, steer_pot, en_steer, pwr_up, lft_spd, rght_spd, too_fast);
    
    // Ramp ss_tmr from 0 to 0xFF slowly for smooth ramping
    $display("\n--- Ramping ss_tmr from 0x00 to 0xFF ---");
    for (int i = 0; i <= 255; i = i + 4) begin
        ss_tmr = i[7:0];
        #20;  // Slower timing for smoother waves
        if (i % 16 == 0 || i == 255) begin
            $display("%0t\t\t%h\t\t%h\t%h\t\t%b\t\t%b\t%d\t\t%d\t\t%b", 
                     $time, PID_cntrl, ss_tmr, steer_pot, en_steer, pwr_up, lft_spd, rght_spd, too_fast);
        end
    end
    
    // Now ramp PID_cntrl from 12'h5FF (+1535) to 12'hE00 (-512) slowly
    $display("\n--- Ramping PID_cntrl from 0x5FF (+1535) to 0xE00 (-512) ---");
    ss_tmr = 8'hFF; // Keep ss_tmr at maximum
    
    // Use a more gradual ramp with smaller steps
    for (int i = 0; i <= 64; i++) begin
        // Linear interpolation from 0x5FF to 0xE00
        // 0x5FF = 1535, 0xE00 = -512 (in 12-bit signed)
        // We need to go from +1535 to -512, which is a range of 2047
        automatic int signed start_val = 1535;
        automatic int signed end_val = -512;
        automatic int signed current_val = start_val + ((end_val - start_val) * i / 64);
        PID_cntrl = current_val[11:0];
        
        #20;  // Slower timing for smoother waves
        if (i % 8 == 0 || i == 64) begin
            $display("%0t\t\t%h\t\t%h\t%h\t\t%b\t\t%b\t%d\t\t%d\t\t%b", 
                     $time, PID_cntrl, ss_tmr, steer_pot, en_steer, pwr_up, lft_spd, rght_spd, too_fast);
        end
    end
    
    #100; // Wait between tests
    
    // ==========================================
    // TEST 2: Steering Test Scenario  
    // PID_cntrl starts at 12'h3FF (1023) and ramps to 12'hC00 (-1024)
    // ss_tmr stays at 8'hFF
    // steer_pot ramps from 12'h000 to 12'hFFE
    // steer_en = 1, pwr_up falls at end
    // ==========================================
    
    $display("\n\n=== TEST 2: Steering Control Test ===");
    
    // Initial conditions for Test 2
    PID_cntrl = 12'h3FF;  // +1023
    ss_tmr = 8'hFF;       // Maximum throughout
    steer_pot = 12'h000;
    en_steer = 1'b1;      // Enable steering
    pwr_up = 1'b1;
    
    #10;
    $display("%0t\t\t%h\t\t%h\t%h\t\t%b\t\t%b\t%d\t\t%d\t\t%b", 
             $time, PID_cntrl, ss_tmr, steer_pot, en_steer, pwr_up, lft_spd, rght_spd, too_fast);
    
    // Sweep both PID_cntrl and steer_pot simultaneously with smooth ramping
    $display("\n--- Sweeping PID_cntrl (0x3FF to 0xC00) and steer_pot (0x000 to 0xFFE) ---");
    
    for (int step = 0; step <= 64; step++) begin
        // Calculate PID_cntrl value (from 0x3FF to 0xC00)
        // Linear interpolation for smooth ramping
        automatic int signed start_pid = 1023;  // 0x3FF
        automatic int signed end_pid = -1024;   // 0xC00 in signed 12-bit
        automatic int signed current_pid = start_pid + ((end_pid - start_pid) * step / 64);
        PID_cntrl = current_pid[11:0];
        
        // Calculate steer_pot value (from 0x000 to 0xFFE) - smooth linear ramp
        steer_pot = (12'hFFE * step / 64);
        
        #15;  // Moderate timing for smooth waves
        
        // Print every 8th step to keep output manageable
        if (step % 8 == 0 || step == 64) begin
            $display("%0t\t\t%h\t\t%h\t%h\t\t%b\t\t%b\t%d\t\t%d\t\t%b", 
                     $time, PID_cntrl, ss_tmr, steer_pot, en_steer, pwr_up, lft_spd, rght_spd, too_fast);
        end
    end
    
    // Test power down at the end
    $display("\n--- Testing power down ---");
    #10;
    pwr_up = 1'b0;  // Power down
    #10;
    $display("%0t\t\t%h\t\t%h\t%h\t\t%b\t\t%b\t%d\t\t%d\t\t%b", 
             $time, PID_cntrl, ss_tmr, steer_pot, en_steer, pwr_up, lft_spd, rght_spd, too_fast);
    
    // ==========================================
    // Additional Edge Case Tests
    // ==========================================
    
    $display("\n\n=== ADDITIONAL EDGE CASE TESTS ===");
    
    // Test saturation cases
    pwr_up = 1'b1;
    en_steer = 1'b0;
    ss_tmr = 8'hFF;
    
    // Test maximum positive PID_cntrl
    PID_cntrl = 12'h7FF;  // Maximum positive
    #10;
    $display("Max Positive PID: %0t\t%h\t\t%h\t%h\t\t%b\t\t%b\t%d\t\t%d\t\t%b", 
             $time, PID_cntrl, ss_tmr, steer_pot, en_steer, pwr_up, lft_spd, rght_spd, too_fast);
    
    // Test maximum negative PID_cntrl  
    PID_cntrl = 12'h800;  // Maximum negative
    #10;
    $display("Max Negative PID: %0t\t%h\t\t%h\t%h\t\t%b\t\t%b\t%d\t\t%d\t\t%b", 
             $time, PID_cntrl, ss_tmr, steer_pot, en_steer, pwr_up, lft_spd, rght_spd, too_fast);
    
    // Test steering saturation
    en_steer = 1'b1;
    PID_cntrl = 12'h000;  // Zero PID to see steering effect clearly
    
    steer_pot = 12'h000;  // Minimum steering
    #10;
    $display("Min Steering:     %0t\t%h\t\t%h\t%h\t\t%b\t\t%b\t%d\t\t%d\t\t%b", 
             $time, PID_cntrl, ss_tmr, steer_pot, en_steer, pwr_up, lft_spd, rght_spd, too_fast);
    
    steer_pot = 12'hFFF;  // Maximum steering
    #10;
    $display("Max Steering:     %0t\t%h\t\t%h\t%h\t\t%b\t\t%b\t%d\t\t%d\t\t%b", 
             $time, PID_cntrl, ss_tmr, steer_pot, en_steer, pwr_up, lft_spd, rght_spd, too_fast);
    
    #100;
    
    $display("\n=== SegwayMath Testbench Complete ===");
    $finish;
end

// Monitor for too_fast assertions
initial begin
    forever begin
        @(posedge too_fast);
        $display("*** WARNING: too_fast asserted at time %0t ***", $time);
    end
end

// Optional: Generate VCD file for waveform viewing
initial begin
    $dumpfile("segwaymath_tb.vcd");
    $dumpvars(0, Segwaymath_tb);
end

endmodule