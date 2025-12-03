////////////////////////////////////////////////////////////////////////////////
// Test 5: Stop Command Test
// 
// This test verifies:
// - 'G' command starts the system
// - 'S' command stops the system
// - PWM signals go inactive after stop
// - System can be restarted after stop
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps
import tb_tasks::*;

module Segway_test5();

  // Include the main testbench
  Segway_tb tb();
  
  // Override test sequence
  initial begin
    $display("\n");
    $display("========================================");
    $display("  TEST 5: Stop Command");
    $display("========================================");
    
    // Initialize
    Initialize(tb.clk, tb.RST_n, tb.rider_lean, tb.ld_cell_lft, 
               tb.ld_cell_rght, tb.batt_V, tb.steer_pot);
    
    // Enable Segway
    $display("\n[%0t] *** FIRST START - Sending 'G' ***", $time);
    SendCmd(tb.clk, tb.send_cmd, tb.cmd, 8'h47, tb.cmd_sent);
    
    WaitCycles(tb.clk, 100000, "Waiting for first startup");
    
    // Check PWM is active
    bit pwm_active_1;
    Monitor_PWM(tb.clk, tb.PWM_lft, tb.PWM_rght, 20000, pwm_active_1);
    
    if (pwm_active_1)
      $display("[%0t] PASS: PWM active after first 'G' command", $time);
    else
      $display("[%0t] FAIL: PWM not active after first 'G' command", $time);
    
    // Send stop command
    $display("\n[%0t] *** SENDING STOP COMMAND 'S' ***", $time);
    SendCmd(tb.clk, tb.send_cmd, tb.cmd, 8'h53, tb.cmd_sent);
    
    WaitCycles(tb.clk, 50000, "Waiting for stop to take effect");
    
    // Check PWM becomes inactive (or minimal activity)
    bit pwm_active_2;
    Monitor_PWM(tb.clk, tb.PWM_lft, tb.PWM_rght, 20000, pwm_active_2);
    
    if (!pwm_active_2)
      $display("[%0t] PASS: PWM inactive after 'S' command", $time);
    else
      $display("[%0t] WARNING: PWM still showing activity after 'S' command", $time);
    
    // Try to restart
    $display("\n[%0t] *** RESTARTING - Sending 'G' again ***", $time);
    SendCmd(tb.clk, tb.send_cmd, tb.cmd, 8'h47, tb.cmd_sent);
    
    WaitCycles(tb.clk, 100000, "Waiting for restart");
    
    // Check PWM is active again
    bit pwm_active_3;
    Monitor_PWM(tb.clk, tb.PWM_lft, tb.PWM_rght, 20000, pwm_active_3);
    
    if (pwm_active_3)
      $display("[%0t] PASS: PWM active after restart", $time);
    else
      $display("[%0t] FAIL: PWM not active after restart", $time);
    
    // Final stop
    $display("\n[%0t] *** FINAL STOP ***", $time);
    SendCmd(tb.clk, tb.send_cmd, tb.cmd, 8'h53, tb.cmd_sent);
    WaitCycles(tb.clk, 10000, "");
    
    // Summary
    if (pwm_active_1 && !pwm_active_2 && pwm_active_3) begin
      $display("\n*** TEST 5 PASSED: Start/Stop commands working correctly ***\n");
    end else begin
      $display("\n*** TEST 5 FAILED: Start/Stop sequence issues detected ***\n");
    end
    
    $display("========================================");
    $display("  TEST 5 Complete");
    $display("========================================\n");
    
    $stop;
  end

endmodule
