@echo off
REM Quick compile and run script for Exercise 23
echo Compiling and simulating Segway top-level test...
vsim -c -do "do compile.do; quit -f"
