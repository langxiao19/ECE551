module mtr_drv_tb();

  /////////////////////////////
  // Testbench Signals      //
  ///////////////////////////
  logic clk, rst_n;
  logic [11:0] lft_spd, rght_spd;
  logic OVR_I_lft, OVR_I_rght;
  logic PWM1_lft, PWM2_lft, PWM1_rght, PWM2_rght;
  logic OVR_I_shtdwn;
  
  // Counter to track PWM cycles
  integer pwm_cycle_count;
  
  /////////////////////////////
  // Instantiate DUT        //
  ///////////////////////////
  mtr_drv iDUT(
    .clk(clk),
    .rst_n(rst_n),
    .lft_spd(lft_spd),
    .rght_spd(rght_spd),
    .OVR_I_lft(OVR_I_lft),
    .OVR_I_rght(OVR_I_rght),
    .PWM1_lft(PWM1_lft),
    .PWM2_lft(PWM2_lft),
    .PWM1_rght(PWM1_rght),
    .PWM2_rght(PWM2_rght),
    .OVR_I_shtdwn(OVR_I_shtdwn)
  );
  
  ///////////////////////////
  // Clock Generation     //
  /////////////////////////
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 50MHz clock (10ns period)
  end
  
  ///////////////////////////
  // Test Sequence        //
  /////////////////////////
  initial begin
    // Initialize signals
    rst_n = 0;
    lft_spd = 12'h000;   // Neutral speed
    rght_spd = 12'h000;
    OVR_I_lft = 0;
    OVR_I_rght = 0;
    pwm_cycle_count = 0;
    
    // Apply reset
    @(posedge clk);
    @(negedge clk) rst_n = 1;
    
    $display("========================================");
    $display("Starting mtr_drv testbench");
    $display("========================================\n");
    
    // Set moderate duty cycle for testing
    lft_spd = 12'h200;   // Some positive speed
    rght_spd = 12'h200;
    
    // Wait a few cycles for system to stabilize
    repeat(5) @(posedge clk);
    
    ////////////////////////////////////////////////////////////////
    // TEST 1: OVR_I pulses INSIDE blanking window              //
    // Should NOT cause shutdown even after 40+ PWM cycles      //
    ////////////////////////////////////////////////////////////////
    $display("========================================");
    $display("TEST 1: OVR_I inside blanking window");
    $display("========================================");
    
    pwm_cycle_count = 0;
    
    // Apply OVR_I pulses during blanking window for 45 PWM cycles
    repeat(45) begin
      // Wait for PWM_synch (start of new PWM cycle)
      wait_for_pwm_synch();
      pwm_cycle_count++;
      
      // Wait a few clocks, then pulse OVR_I_lft during blanking window
      // Blanking occurs during first 128 clocks of PWM1 or PWM2
      repeat(20) @(posedge clk);  // Wait 20 clocks into blanking period
      
      // Apply OVR_I pulse (should be ignored due to blanking)
      @(negedge clk) OVR_I_lft = 1;
      repeat(10) @(posedge clk);  // Hold for 10 clocks
      @(negedge clk) OVR_I_lft = 0;
      
      $display("  PWM Cycle %0d: Applied OVR_I during blanking. OVR_I_cnt=%0d, shtdwn=%b", 
               pwm_cycle_count, iDUT.OVR_I_cnt, OVR_I_shtdwn);
    end
    
    // Wait a few more PWM cycles to ensure no delayed shutdown
    repeat(5) begin
      wait_for_pwm_synch();
      pwm_cycle_count++;
      $display("  PWM Cycle %0d: Post-test monitoring. OVR_I_cnt=%0d, shtdwn=%b", 
               pwm_cycle_count, iDUT.OVR_I_cnt, OVR_I_shtdwn);
    end
    
    // Check results for Test 1
    if (OVR_I_shtdwn == 0) begin
      $display("\n>>> TEST 1 PASSED: No shutdown after 45 OVR_I pulses inside blanking window\n");
    end else begin
      $display("\n>>> TEST 1 FAILED: Unexpected shutdown occurred!\n");
      $stop;
    end
    
    // Reset for next test
    @(negedge clk) rst_n = 0;
    repeat(3) @(posedge clk);
    @(negedge clk) rst_n = 1;
    repeat(10) @(posedge clk);
    
    ////////////////////////////////////////////////////////////////
    // TEST 2: OVR_I pulses OUTSIDE blanking window            //
    // Should cause shutdown after reaching count of 31        //
    ////////////////////////////////////////////////////////////////
    $display("========================================");
    $display("TEST 2: OVR_I outside blanking window");
    $display("========================================");
    
    pwm_cycle_count = 0;
    
    // Apply OVR_I pulses outside blanking window for 45 PWM cycles
    repeat(45) begin
      // Wait for PWM_synch (start of new PWM cycle)
      wait_for_pwm_synch();
      pwm_cycle_count++;
      
      // Wait until well outside blanking window
      // Blanking is first 128 clocks, so wait ~200 clocks
      repeat(200) @(posedge clk);
      
      // Apply OVR_I pulse (should be counted)
      @(negedge clk) OVR_I_rght = 1;
      repeat(10) @(posedge clk);  // Hold for 10 clocks
      @(negedge clk) OVR_I_rght = 0;
      
      $display("  PWM Cycle %0d: Applied OVR_I outside blanking. OVR_I_cnt=%0d, shtdwn=%b", 
               pwm_cycle_count, iDUT.OVR_I_cnt, OVR_I_shtdwn);
      
      // Check if shutdown has occurred
      if (OVR_I_shtdwn) begin
        $display("  >>> Shutdown detected at PWM cycle %0d with OVR_I_cnt=%0d", 
                 pwm_cycle_count, iDUT.OVR_I_cnt);
        break;
      end
    end
    
    // Wait a few more cycles to observe steady state
    repeat(5) @(posedge clk);
    
    // Check results for Test 2
    if (OVR_I_shtdwn == 1) begin
      $display("\n>>> TEST 2 PASSED: Shutdown occurred after excessive OVR_I events outside blanking\n");
    end else begin
      $display("\n>>> TEST 2 FAILED: Expected shutdown did not occur!\n");
      $display("    Final OVR_I_cnt = %0d (expected >= 31)\n", iDUT.OVR_I_cnt);
      $stop;
    end
    
    ////////////////////////////////////////////////////////////////
    // Additional Test: Verify Counter Decrement              //
    ////////////////////////////////////////////////////////////////
    $display("========================================");
    $display("Additional verification of counter behavior");
    $display("========================================");
    
    // Reset again
    @(negedge clk) rst_n = 0;
    repeat(3) @(posedge clk);
    @(negedge clk) rst_n = 1;
    repeat(10) @(posedge clk);
    
    // Build up count to ~20, then stop and verify decay
    repeat(20) begin
      wait_for_pwm_synch();
      repeat(200) @(posedge clk);
      @(negedge clk) OVR_I_lft = 1;
      repeat(5) @(posedge clk);
      @(negedge clk) OVR_I_lft = 0;
    end
    
    $display("  Built up OVR_I_cnt to %0d", iDUT.OVR_I_cnt);
    
    // Now wait 16 PWM cycles and verify decrement
    repeat(16) begin
      wait_for_pwm_synch();
    end
    
    $display("  After 16 PWM cycles, OVR_I_cnt = %0d (should have decremented by 1)", 
             iDUT.OVR_I_cnt);
    
    ////////////////////////////////////////////////////////////////
    // All Tests Complete                                       //
    ////////////////////////////////////////////////////////////////
    $display("\n========================================");
    $display("ALL TESTS PASSED!");
    $display("========================================\n");
    
    $stop;
  end
  
  ///////////////////////////
  // Helper Task          //
  /////////////////////////
  task wait_for_pwm_synch();
    // Wait for PWM_synch signal (counter rolls over to 0)
    // PWM cycle is 2048 clocks, so PWM_synch occurs when cnt == 0
    @(posedge clk);
    while (iDUT.iPWM_lft.cnt != 11'h000) begin
      @(posedge clk);
    end
  endtask
  
  ///////////////////////////
  // Watchdog Timer       //
  /////////////////////////
  initial begin
    #50000000;  // 50ms timeout
    $display("\n>>> ERROR: Testbench timeout!");
    $stop;
  end
  
endmodule
