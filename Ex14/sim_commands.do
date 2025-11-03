[Library]
vlib work

[Compile]
vlog +incdir+../Ex13 ../Ex13/UART_tx.sv
vlog UART_rx.sv
vlog UART_tb.sv

[Simulate]
vsim -voptargs=+acc work.UART_tb

[Wave]
add wave -radix hex /UART_tb/*
add wave -radix hex /UART_tb/iTX/*
add wave -radix hex /UART_tb/iRX/*

[Run]
run -all
