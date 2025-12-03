# HW5 Problem 1: Post-Synthesis Simulation Instructions

## Overview
This document explains how to perform post-synthesis simulation of your `balance_cntrl` design.

## Files Modified/Created

### 1. `balance_cntrl_chk_tb.sv` (Modified)
- **Change**: Commented out the `force iDUT.ss_tmr = 8'hFF;` statement
- **Reason**: After synthesis, signal names may be optimized/renamed (e.g., `ss_tmr[7:0]` bits might become `n471`, `n472`, etc.)
- The new test vectors (`balance_cntrl_stim.hex` and `balance_cntrl_resp.hex`) were generated without this force

### 2. `run_post_synth.do` (Created)
- ModelSim DO script for post-synthesis simulation
- **IMPORTANT**: You must edit this file to specify the correct path to your standard cell library

## Steps to Complete HW5 Problem 1

### Step 1: Run Synthesis (if not already done)
If you haven't created `balance_cntrl.vg` yet, you need to run synthesis:

1. Copy your synthesis script from Ex18 or create a new one:
   ```bash
   # Copy the synthesis script
   cp ../Ex18/balance_cntrl.dc .
   ```

2. Make sure you have the required files in HW5:
   - `balance_cntrl.sv`
   - `PID.sv`
   - `SegwayMath.sv`

3. Run Design Compiler synthesis:
   ```bash
   dc_shell -f balance_cntrl.dc
   ```
   
   This should generate `balance_cntrl.vg` (the gate-level netlist)

### Step 2: Locate Your Standard Cell Library

The post-synthesis simulation needs the Verilog model of your standard cell library. You need to find the `.v` file that corresponds to the library used in synthesis.

**Common library locations on ECE servers:**

For SAED32nm (32nm educational library):
```
/cae/apps/data/synopsys-2025/SAED32_EDK/lib/stdcell_rvt/verilog/saed32nm.v
```

For lsi_10k library:
```
/cae/apps/data/synopsys-2025/syn/X-2025.06/libraries/syn/lsi_10k.v
```

**How to determine which library you used:**
- Look at your synthesis script (`.dc` file)
- Check the `set target_library` or `set_driving_cell -lib_cell` commands
- If you see `NAND2X2_RVT`, you're likely using SAED32nm
- If you see `AN2` or `IV`, you're likely using lsi_10k

### Step 3: Edit the Simulation Script

1. Open `run_post_synth.do`
2. Find the section that compiles the standard cell library (around line 16-20)
3. Uncomment the appropriate `vlog` command for your library
4. Or add your own path if different

Example:
```tcl
# For SAED32nm library
vlog /cae/apps/data/synopsys-2025/SAED32_EDK/lib/stdcell_rvt/verilog/saed32nm.v
```

### Step 4: Run Post-Synthesis Simulation

1. Make sure you're in the HW5 directory
2. Run ModelSim with the DO script:
   ```bash
   vsim -c -do run_post_synth.do
   ```

   **Alternative (with GUI):**
   ```bash
   vsim
   # Then in ModelSim: do run_post_synth.do
   ```

3. The simulation should:
   - Load the standard cell library
   - Compile the gate-level netlist (`balance_cntrl.vg`)
   - Compile the testbench
   - Run 1500 test vectors
   - Report success or failures

### Step 5: Verify Success

Look for this in the transcript:
```
✅ All 1500 vectors matched expected response.
```

The transcript should also show:
- Your username (to prove you ran it)
- Evidence of loading library cells (e.g., "Compiling module DFFX1_RVT")

### Step 6: Capture Screenshot

Take a screenshot of the ModelSim transcript window showing:
1. Your username in the window title or transcript
2. Library cells being loaded
3. Successful completion message

## What to Submit

1. **`balance_cntrl.vg`** - Your gate-level netlist
2. **Screenshot** - ModelSim transcript showing:
   - Library cells loading
   - Your username
   - All 1500 vectors passing

## Troubleshooting

### Problem: "Unable to read file balance_cntrl.vg"
**Solution**: Run synthesis first (Step 1)

### Problem: "Unable to locate ... in design library"
**Solution**: Your standard cell library path is wrong. Check Step 2.

### Problem: Simulation takes very long
**Solution**: This is normal! Post-synthesis simulation is much slower than RTL simulation because it simulates every gate. Without the `ss_tmr` force, the PID controller needs to count through its start-up timer naturally.

### Problem: Some vectors fail
**Solution**: 
- Verify you're using the NEW `balance_cntrl_stim.hex` and `balance_cntrl_resp.hex` files (from Canvas)
- Verify the `force` statement is commented out in the testbench
- Check if synthesis introduced timing issues (unlikely with proper constraints)

## Notes

- Post-synthesis simulation is MUCH slower than RTL simulation
- This is because every gate and flip-flop is simulated individually
- Be patient - 1500 vectors with the full PID startup sequence may take several minutes
- The simulation validates that your synthesized design behaves identically to the RTL version
