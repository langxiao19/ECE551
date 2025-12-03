# ModelSim DO file for inertial_integrator simulation

# Create work library if it doesn't exist
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compile source files
vlog -sv inertial_integrator.sv
vlog -sv inertial_integrator_tb.sv

# Start simulation
vsim -voptargs=+acc work.inertial_integrator_tb

# Add waves
add wave -position insertpoint sim:/inertial_integrator_tb/*
add wave -position insertpoint sim:/inertial_integrator_tb/iDUT/*

# Configure ptch as analog waveform (decimal display)
add wave -radix decimal -format analog -height 300 -min -1000 -max 1000 sim:/inertial_integrator_tb/ptch

# Run simulation
run -all

# Zoom to fit
wave zoom full
