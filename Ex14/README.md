# Exercise 14 - UART Receiver Implementation

## Overview
This exercise implements a UART receiver module (`UART_rx.sv`) that can receive 8-bit data at 9600 baud rate with a 50MHz system clock. The implementation includes a comprehensive testbench that uses the UART transmitter from Exercise 13 for self-checking functionality.

## Files Included
- `UART_rx.sv` - UART receiver module implementation
- `UART_tb.sv` - Comprehensive testbench with self-checking capability
- `Ex14.mpf` - ModelSim project file
- `sim_commands.do` - ModelSim DO script for simulation
- `run_sim.bat` - Windows batch file for compilation and simulation
- `run_sim.sh` - Linux/Unix shell script for compilation and simulation

## UART Receiver Specifications

### Interface
- **Clock**: 50MHz system clock (`clk`)
- **Reset**: Active low reset (`rst_n`)
- **Input**: Serial data input (`RX`)
- **Control**: Clear ready signal (`clr_rdy`)
- **Outputs**: 
  - 8-bit received data (`rx_data[7:0]`)
  - Ready flag (`rdy`)

### Functionality
- **Baud Rate**: 9600 bps (5208 clock cycles per bit at 50MHz)
- **Frame Format**: 1 start bit + 8 data bits + 1 stop bit (no parity)
- **Data Order**: LSB first
- **Start Detection**: Falling edge detection on RX line
- **Sampling**: Samples data at center of bit time (after 1/2 bit delay from start bit)
- **Ready Flag**: Asserted when complete byte received, cleared by `clr_rdy` or new start bit

### State Machine
1. **IDLE**: Monitors for start bit (falling edge on RX)
2. **START**: Waits for 1/2 bit time to center sampling
3. **RECEIVING**: Samples and shifts in 10 bits total (start + 8 data + stop)

### Key Features
- Metastability protection with dual flip-flop synchronizer for RX input
- Precise timing with baud rate counter
- 9-bit shift register for data collection
- Robust start bit detection
- Self-clearing ready flag

## Testbench Features

The testbench (`UART_tb.sv`) provides comprehensive testing including:

1. **Loopback Testing**: Connects UART TX output to UART RX input for self-verification
2. **Multiple Test Patterns**: Tests various data patterns (0x55, 0xAA, 0x00, 0xFF, random)
3. **Control Signal Testing**: Verifies `clr_rdy` functionality
4. **Back-to-back Transmissions**: Tests continuous operation
5. **Automatic Checking**: Compares transmitted vs received data
6. **Error Reporting**: Counts and reports any mismatches

### Test Cases
- Single byte transmission
- Multiple different byte patterns
- Clear ready flag functionality
- Back-to-back transmissions
- Random data patterns

## Running the Simulation

### Using ModelSim GUI
1. Open ModelSim
2. Load the project file: `File > Open > Ex14.mpf`
3. Compile all files
4. Start simulation: `vsim work.UART_tb`
5. Add waves and run

### Using Command Line (Windows)
```batch
run_sim.bat
```

### Using Command Line (Linux/Unix)
```bash
chmod +x run_sim.sh
./run_sim.sh
```

### Using DO Script
```tcl
do sim_commands.do
```

## Implementation Details

### Timing Analysis
- **Bit Time**: 5208 clocks @ 50MHz = 104.16µs
- **Half Bit**: 2604 clocks = 52.08µs
- **Frame Time**: 10 bits × 104.16µs = 1.0416ms

### Error Handling
- Metastability protection on RX input
- Robust state machine with proper reset handling
- Clear error recovery paths

### Resource Utilization
- Small footprint design suitable for FPGA implementation
- Minimal logic resources required
- Efficient state encoding

## Verification Results

The testbench thoroughly verifies:
- ✅ Correct data reception at 9600 baud
- ✅ Proper timing alignment
- ✅ Start bit detection
- ✅ Stop bit handling
- ✅ Ready flag operation
- ✅ Clear ready functionality
- ✅ Continuous operation capability

## Integration Notes

This UART receiver is designed to work with:
- The UART transmitter from Exercise 13
- Standard RS-232 signal levels (with appropriate level shifters)
- Any UART-compatible device operating at 9600 baud, 8N1 format

The module can be easily integrated into larger systems requiring serial communication capabilities.
