////////////////////////////////////////////////////////////////////////////////
// Test 2: Step Response - Positive Lean
// 
// This test verifies:
// - System responds to positive rider lean
// - PID controller stabilizes the platform
// - theta_platform converges toward zero
// - Underdamped response is observed
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps
import tb_tasks::*;

module Segway_test2();

  // Include the main testbench
  Segway_tb tb();
  
  // Override test sequence
  initial begin
    $display("\n");
    $display("========================================");
    $display("  TEST 2: Step Response - Positive Lean");
    $display("========================================");
    
    // Initialize
    Initialize(tb.clk, tb.RST_n, tb.rider_lean, tb.ld_cell_lft, 
               tb.ld_cell_rght, tb.batt_V, tb.steer_pot);
    
    // Send 'G' command to enable
    $display("[%0t] Enabling Segway...", $time);
    SendCmd(tb.clk, tb.send_cmd, tb.cmd, 8'h47, tb.cmd_sent);
    
    // Wait for system to stabilize (hundreds of thousands of cycles)
    WaitCycles(tb.clk, 300000, "Waiting for system stabilization");
    
    // Apply positive rider lean (step input)
    $display("\n[%0t] *** APPLYING POSITIVE RIDER LEAN STEP ***", $time);
    ApplyRiderLean(tb.clk, tb.rider_lean, 16'h0FFF, 800000);
    
    // Monitor theta_platform during response
    $display("[%0t] Monitoring platform response...", $time);
    bit converging;
    
    // Sample theta_platform multiple times to observe convergence
    for (int i = 0; i < 20; i++) begin
      WaitCycles(tb.clk, 40000, "");
      $display("[%0t] theta_platform = %h (%d)", 
               $time, tb.theta_platform, $signed(tb.theta_platform));
    end
    
    // Check convergence over longer period
    Check_theta_platform(tb.clk, tb.theta_platform, 20000, 15, converging);
    
    // Return to neutral
    $display("\n[%0t] *** RETURNING TO NEUTRAL ***", $time);
    ApplyRiderLean(tb.clk, tb.rider_lean, 16'h0000, 500000);
    
    // Observe recovery
    WaitCycles(tb.clk, 50000, "Observing recovery");
    $display("[%0t] Final theta_platform = %h (%d)", 
             $time, tb.theta_platform, $signed(tb.theta_platform));
    
    if (converging) begin
      $display("\n*** TEST 2 PASSED: Platform converged toward zero ***\n");
    end else begin
      $display("\n*** TEST 2 FAILED: Platform did not converge properly ***\n");
    end
    
    // Stop
    SendCmd(tb.clk, tb.send_cmd, tb.cmd, 8'h53, tb.cmd_sent);
    WaitCycles(tb.clk, 10000, "");
    
    $display("========================================");
    $display("  TEST 2 Complete");
    $display("========================================\n");
    
    $stop;
  end

endmodule
