# ===========================================================
# Post-Synthesis Simulation Script for balance_cntrl
# ECE 551 - HW5 Problem 1
# ===========================================================

# Clean up any previous work library
if {[file exists work]} {
    vdel -lib work -all
}

# Create fresh work library
vlib work

# ===========================================================
# Compile the standard cell library
# ===========================================================
# Note: Adjust the path to your standard cell library .v file
# Common locations on ECE department machines:
#   - /cae/apps/data/synopsys-2025/SAED32_EDK/lib/stdcell_rvt/verilog/saed32nm.v
#   - Or check your synthesis log for the library path used
echo "Compiling standard cell library..."

# Try typical paths - user may need to adjust this
# For SAED32nm library (32nm educational library)
# vlog /cae/apps/data/synopsys-2025/SAED32_EDK/lib/stdcell_rvt/verilog/saed32nm.v

# For lsi_10k library (if using that instead)
# vlog /cae/apps/data/synopsys-2025/syn/X-2025.06/libraries/syn/lsi_10k.v

# NOTE: If neither path works, you need to locate the .v file for your target library
# Check your synthesis script (.dc file) to see which library was used
# Then find the corresponding verilog (.v) file for that library

# ===========================================================
# Compile the gate-level netlist (balance_cntrl.vg)
# ===========================================================
echo "Compiling gate-level netlist..."
vlog balance_cntrl.vg

# ===========================================================
# Compile the testbench
# ===========================================================
echo "Compiling testbench..."
vlog -sv balance_cntrl_chk_tb.sv

# ===========================================================
# Start simulation with gate-level netlist
# ===========================================================
echo "Starting simulation..."
vsim -voptargs=+acc work.balance_cntrl_chk_tb

# ===========================================================
# Add waveforms (optional, comment out for faster sim)
# ===========================================================
# add wave -position insertpoint sim:/balance_cntrl_chk_tb/*
# add wave -position insertpoint sim:/balance_cntrl_chk_tb/iDUT/*

# ===========================================================
# Run simulation
# ===========================================================
echo "Running simulation..."
run -all

echo "Post-synthesis simulation complete!"
