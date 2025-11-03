#!/bin/bash
# Compilation and simulation script for UART receiver

echo "=== UART Receiver Simulation ==="
echo "Compiling source files..."

# Create work library
vlib work

# Compile UART transmitter (from Ex13)
echo "Compiling UART transmitter..."
vlog +incdir+../Ex13 ../Ex13/UART_tx.sv
if [ $? -ne 0 ]; then
    echo "Error compiling UART_tx.sv"
    exit 1
fi

# Compile UART receiver
echo "Compiling UART receiver..."
vlog UART_rx.sv
if [ $? -ne 0 ]; then
    echo "Error compiling UART_rx.sv"
    exit 1
fi

# Compile testbench
echo "Compiling testbench..."
vlog UART_tb.sv
if [ $? -ne 0 ]; then
    echo "Error compiling UART_tb.sv"
    exit 1
fi

echo "Starting simulation..."
# Run simulation
vsim -c -do "run -all; quit" work.UART_tb

echo "Simulation complete!"
