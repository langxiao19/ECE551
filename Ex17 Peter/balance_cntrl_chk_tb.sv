module balance_cntrl_chk_tb();

    //======================================
    // Signal Declarations
    //======================================
    reg clk;
    reg [48:0] stim;                      // 49-bit stimulus vector
    reg [24:0] resp;                      // 25-bit expected response vector
    wire [24:0] actual_resp;              // Actual DUT response
    
    // Stimulus and response memories
    reg [48:0] stim_mem [0:1499];         // 1500 entries of 49-bit stimulus
    reg [24:0] resp_mem [0:1499];         // 1500 entries of 25-bit response
    
    // Break out stimulus bits to individual signals
    wire rst_n      = stim[48];
    wire vld        = stim[47];
    wire [15:0] ptch     = stim[46:31];
    wire [15:0] ptch_rt  = stim[30:15];
    wire pwr_up     = stim[14];
    wire rider_off  = stim[13];
    wire [11:0] steer_pot = stim[12:1];
    wire en_steer   = stim[0];
    
    // DUT outputs
    wire [11:0] lft_spd;
    wire [11:0] rght_spd;
    wire too_fast;
    
    // Concatenate actual response for comparison
    assign actual_resp = {lft_spd, rght_spd, too_fast};
    
    //======================================
    // Clock Generation
    //======================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;            // 10 time unit period (100 MHz)
    end
    
    //======================================
    // DUT Instantiation
    //======================================
    balance_cntrl #(.fast_sim(1)) iDUT (
        .clk(clk),
        .rst_n(rst_n),
        .vld(vld),
        .ptch(ptch),
        .ptch_rt(ptch_rt),
        .pwr_up(pwr_up),
        .rider_off(rider_off),
        .steer_pot(steer_pot),
        .en_steer(en_steer),
        .lft_spd(lft_spd),
        .rght_spd(rght_spd),
        .too_fast(too_fast)
    );
    
    //======================================
    // Test Stimulus and Checking
    //======================================
    integer i;
    integer errors;
    
    initial begin
        // Initialize stimulus first
        stim = 49'h0;
        
        // Force ss_tmr to 0xFF to simulate steady state (must be done before any clocks)
        force iDUT.ss_tmr = 8'hFF;
        
        // Load stimulus and response files
        $readmemh("balance_cntrl_stim.hex", stim_mem);
        $readmemh("balance_cntrl_resp.hex", resp_mem);
        
        // Initialize error counter
        errors = 0;
        
        // Wait for initial setup - give a few clock cycles for initialization
        repeat(3) @(posedge clk);
        
        // Loop through all 1500 test vectors
        for (i = 0; i < 1500; i = i + 1) begin
            // Apply stimulus BEFORE the clock edge
            stim = stim_mem[i];
            
            // Wait for clock edge - DUT will process inputs
            @(posedge clk);
            
            // Now get the expected response for this clock cycle
            // Note: The response file might be aligned with when outputs update
            resp = resp_mem[i];
            
            #1;  // Wait 1 time unit after clock edge for signals to settle
            
            // Check if actual response matches expected response
            // Skip checking first 3 vectors (initialization/reset period)
            if (i >= 3 && actual_resp !== resp) begin
                $display("ERROR at vector %0d:", i);
                $display("  Stimulus: rst_n=%b vld=%b ptch=%h ptch_rt=%h pwr_up=%b rider_off=%b steer_pot=%h en_steer=%b",
                         rst_n, vld, ptch, ptch_rt, pwr_up, rider_off, steer_pot, en_steer);
                $display("  Raw Expected resp: %h", resp);
                $display("  Raw Actual resp:   %h", actual_resp);
                $display("  Expected: lft_spd=%h rght_spd=%h too_fast=%b", 
                         resp[24:13], resp[12:1], resp[0]);
                $display("  Actual:   lft_spd=%h rght_spd=%h too_fast=%b", 
                         lft_spd, rght_spd, too_fast);
                $display("  PID_cntrl=%h (decimal: %d)", iDUT.PID_cntrl, $signed(iDUT.PID_cntrl));
                $display("  SegwayMath lft_torque=%h (%d), rght_torque=%h (%d)", 
                         iDUT.iSegwayMath.lft_torque, $signed(iDUT.iSegwayMath.lft_torque),
                         iDUT.iSegwayMath.rght_torque, $signed(iDUT.iSegwayMath.rght_torque));
                errors = errors + 1;
                if (errors >= 10) begin
                    $display("\nStopping after 10 errors for debugging...");
                    $stop;
                end
            end
        end
        
        // Report results
        if (errors == 0) begin
            $display("\n=========================================");
            $display("SUCCESS! All 1500 vectors passed!");
            $display("=========================================\n");
        end else begin
            $display("\n=========================================");
            $display("FAILED: %0d errors out of 1500 vectors", errors);
            $display("=========================================\n");
        end
        
        $stop;
    end

endmodule
