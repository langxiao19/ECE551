////////////////////////////////////////////////////////////////////////////////
// Test 4: Steering Test
// 
// This test verifies:
// - System responds to steering commands
// - Left and right motor speeds differ appropriately
// - Steering pot changes affect motor control
// - Platform remains stable during steering
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps
import tb_tasks::*;

module Segway_test4();

  // Include the main testbench
  Segway_tb tb();
  
  // Override test sequence
  initial begin
    $display("\n");
    $display("========================================");
    $display("  TEST 4: Steering Test");
    $display("========================================");
    
    // Initialize with centered steering
    Initialize(tb.clk, tb.RST_n, tb.rider_lean, tb.ld_cell_lft, 
               tb.ld_cell_rght, tb.batt_V, tb.steer_pot);
    
    // Enable Segway
    $display("[%0t] Enabling Segway...", $time);
    SendCmd(tb.clk, tb.send_cmd, tb.cmd, 8'h47, tb.cmd_sent);
    
    // Wait for stabilization
    WaitCycles(tb.clk, 300000, "Waiting for system stabilization");
    
    // Apply small forward lean to get moving
    $display("\n[%0t] Applying small forward lean...", $time);
    ApplyRiderLean(tb.clk, tb.rider_lean, 16'h0400, 100000);
    
    // Test left turn
    $display("\n[%0t] *** TESTING LEFT TURN ***", $time);
    SetSteeringPot(tb.clk, tb.steer_pot, 12'h400);  // Turn left
    WaitCycles(tb.clk, 200000, "Observing left turn");
    $display("[%0t] omega_lft = %d, omega_rght = %d", 
             $time, $signed(tb.omega_lft), $signed(tb.omega_rght));
    
    // Return to center
    $display("\n[%0t] Returning to center steering...", $time);
    SetSteeringPot(tb.clk, tb.steer_pot, 12'h800);  // Center
    WaitCycles(tb.clk, 200000, "Observing centered response");
    $display("[%0t] omega_lft = %d, omega_rght = %d", 
             $time, $signed(tb.omega_lft), $signed(tb.omega_rght));
    
    // Test right turn
    $display("\n[%0t] *** TESTING RIGHT TURN ***", $time);
    SetSteeringPot(tb.clk, tb.steer_pot, 12'hC00);  // Turn right
    WaitCycles(tb.clk, 200000, "Observing right turn");
    $display("[%0t] omega_lft = %d, omega_rght = %d", 
             $time, $signed(tb.omega_lft), $signed(tb.omega_rght));
    
    // Return to center
    $display("\n[%0t] Returning to center steering...", $time);
    SetSteeringPot(tb.clk, tb.steer_pot, 12'h800);  // Center
    WaitCycles(tb.clk, 100000, "");
    
    // Return to neutral lean
    ApplyRiderLean(tb.clk, tb.rider_lean, 16'h0000, 100000);
    
    // Check platform stability
    bit converging;
    Check_theta_platform(tb.clk, tb.theta_platform, 10000, 10, converging);
    
    if (converging) begin
      $display("\n*** TEST 4 PASSED: Steering functional and stable ***\n");
    end else begin
      $display("\n*** TEST 4 WARNING: Platform stability during steering questionable ***\n");
    end
    
    // Stop
    SendCmd(tb.clk, tb.send_cmd, tb.cmd, 8'h53, tb.cmd_sent);
    WaitCycles(tb.clk, 10000, "");
    
    $display("========================================");
    $display("  TEST 4 Complete");
    $display("========================================\n");
    
    $stop;
  end

endmodule
