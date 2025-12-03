@echo off
REM Batch script to compile and simulate inertial_integrator

echo Compiling inertial_integrator.sv...
vlog -sv inertial_integrator.sv

echo Compiling inertial_integrator_tb.sv...
vlog -sv inertial_integrator_tb.sv

echo Starting simulation...
vsim -voptargs=+acc work.inertial_integrator_tb -do "add wave -radix decimal sim:/inertial_integrator_tb/ptch; add wave sim:/inertial_integrator_tb/*; add wave -radix decimal sim:/inertial_integrator_tb/iDUT/*; run -all"

echo Simulation complete!
