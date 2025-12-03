## Compile script for Exercise 23 - Segway Top-Level Test
## Run with: vsim -do compile.do

# Create work library
vlib work

# Compile supporting modules (order matters for dependencies)
vlog -sv ../Ex20/rst_synch.sv
vlog -sv ../Ex14/UART_rx.sv
vlog -sv ../Ex14/UART_tx.sv
vlog -sv ../HW4/Auth_blk.sv

# Compile SPI modules  
vlog -sv ../Ex16/SPI_mnrch.sv

# Compile inertial interface and supporting modules
vlog -sv ../Ex21/inertial_integrator.sv
vlog -sv ./inert_intf.sv
vlog -sv ./SPI_ADC128S.sv

# Compile A2D interface (newly created)
vlog -sv ./A2D_intf.sv

# Compile motor control modules
vlog -sv ../Ex22/PWM11.sv
vlog -sv ../Ex22/mtr_drv.sv

# Compile PID and balance control
vlog -sv ../Ex18/PID.sv
vlog -sv ../Ex18/SegwayMath.sv
vlog -sv ../Ex18/balance_cntrl.sv

# Compile steering enable modules
vlog -sv ../HW3/steer_en_SM.sv
vlog -sv ./steer_en.sv

# Compile piezo driver
vlog -sv ../Ex20/piezo_drv.sv

# Compile top-level DUT
vlog -sv ./Segway.sv

# Compile physics model and A2D model
vlog -sv ./SegwayModel.sv
vlog -sv ./ADC128S_FC.sv

# Compile testbench
vlog -sv ./Segway_tb.sv

# Start simulation
vsim -voptargs=+acc Segway_tb

# Add waves
add wave -position insertpoint sim:/Segway_tb/*
add wave -position insertpoint sim:/Segway_tb/iDUT/*
add wave -position insertpoint sim:/Segway_tb/iPHYS/theta_platform

# Run until $stop is hit (testbench controls duration)
run -all
