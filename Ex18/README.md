# Exercise 18 - Synthesizing balance_cntrl

## Files in this directory:
- `balance_cntrl.sv` - Top-level balance control module
- `PID.sv` - PID controller module  
- `SegwayMath.sv` - Segway motor control math module
- `balance_cntrl.dc` - Synthesis script for Design Compiler

## Synthesis Script Features:
The synthesis script (`balance_cntrl.dc`) performs the following operations:

1. **Clock Definition**: Creates a 125MHz clock (8ns period) and sets don't touch on clock network
2. **Input Constraints**: 
   - 0.3ns input delay on all inputs except clock
   - Drive strength equivalent to NAND2X2_RVT for inputs except clk and rst_n
3. **Output Constraints**:
   - 0.75ns output delay on all outputs
   - 50fF (0.05pF) load on all outputs
4. **Design Constraints**:
   - Max transition time of 0.15ns on all nodes
   - Wire load model for 16000 sq microns block size
5. **Compilation**: Two-pass compilation with flattening between passes
6. **Reports**: Generates min_delay, max_delay, and area reports
7. **Netlist**: Outputs gate-level verilog netlist (balance_cntrl.vg)

## How to run:
1. Make sure you have the Synopsys 32nm library loaded in your dc_shell environment
2. Navigate to this directory in dc_shell
3. Run the script with: `source balance_cntrl.dc`

## Expected Output Files:
- `min_delay.txt` - Minimum delay timing report
- `max_delay.txt` - Maximum delay timing report  
- `area.txt` - Area utilization report
- `balance_cntrl.vg` - Gate-level verilog netlist

## Notes:
- The script reads SystemVerilog files in dependency order (children first)
- The design is flattened to remove hierarchy for better optimization
- All timing constraints follow industry standard practices for synthesis
