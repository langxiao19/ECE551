@echo off
REM Compile and simulate mtr_drv testbench

echo Cleaning up old simulation files...
if exist work rmdir /s /q work
if exist transcript del transcript
if exist vsim.wlf del vsim.wlf

echo Creating work library...
vlib work

echo Compiling design files...
vlog -sv PWM11.sv
vlog -sv mtr_drv.sv
vlog -sv mtr_drv_tb.sv

echo Running simulation...
vsim -c -do "run -all; quit" mtr_drv_tb

echo Simulation complete!
