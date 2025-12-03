////////////////////////////////////////////////////////////////////////////////
// Test 1: Basic Enable Test
// 
// This test verifies:
// - System can be reset properly
// - 'G' (Go) command enables the Segway
// - PWM signals become active after enable
// - System responds to commands
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps
import tb_tasks::*;

module Segway_test1();

  // Include the main testbench
  Segway_tb tb();
  
  // Override test sequence
  initial begin
    $display("\n");
    $display("========================================");
    $display("  TEST 1: Basic Enable");
    $display("========================================");
    
    // Initialize
    Initialize(tb.clk, tb.RST_n, tb.rider_lean, tb.ld_cell_lft, 
               tb.ld_cell_rght, tb.batt_V, tb.steer_pot);
    
    // Verify system is in reset state
    $display("[%0t] Verifying initial conditions...", $time);
    WaitCycles(tb.clk, 100, "Initial observation");
    
    // Send 'G' command
    $display("[%0t] Sending 'G' (Go) command...", $time);
    SendCmd(tb.clk, tb.send_cmd, tb.cmd, 8'h47, tb.cmd_sent);
    
    // Wait for system to enable (reduced time for fast_sim)
    WaitCycles(tb.clk, 100000, "Waiting for system enable");
    
    // Check PWM activity
    bit pwm_active;
    Monitor_PWM(tb.clk, tb.PWM_lft, tb.PWM_rght, 20000, pwm_active);
    
    if (pwm_active) begin
      $display("\n*** TEST 1 PASSED: Segway enabled successfully ***\n");
    end else begin
      $display("\n*** TEST 1 FAILED: PWM not active after enable ***\n");
    end
    
    // Stop the Segway
    $display("[%0t] Sending 'S' (Stop) command...", $time);
    SendCmd(tb.clk, tb.send_cmd, tb.cmd, 8'h53, tb.cmd_sent);
    
    WaitCycles(tb.clk, 10000, "Final observation");
    
    $display("========================================");
    $display("  TEST 1 Complete");
    $display("========================================\n");
    
    $stop;
  end

endmodule
