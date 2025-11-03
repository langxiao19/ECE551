@echo off
echo === UART Receiver Simulation ===

rem Set ModelSim paths
set MODELSIM_PATH=C:\intelFPGA_lite\24.1std\questa_fse\win64
set PATH=%MODELSIM_PATH%;%PATH%

echo Compiling source files...

rem Create work library
vlib work

rem Compile UART transmitter
echo Compiling UART transmitter...
vlog UART_tx.sv
if errorlevel 1 (
    echo Error compiling UART_tx.sv
    pause
    exit /b 1
)

rem Compile UART receiver
echo Compiling UART receiver...
vlog UART_rx.sv
if errorlevel 1 (
    echo Error compiling UART_rx.sv
    pause
    exit /b 1
)

rem Compile testbench
echo Compiling testbench...
vlog UART_tb.sv
if errorlevel 1 (
    echo Error compiling UART_tb.sv
    pause
    exit /b 1
)

echo Starting simulation...
rem Run simulation
vsim -c -do "run -all; quit" work.UART_tb

echo Simulation complete!
pause
