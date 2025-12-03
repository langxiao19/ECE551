# Exercise 23: Segway Top-Level Testing

## Overview
Complete top-level test of the Segway self-balancing system. Tests the integration of all subsystems including:
- Authentication/command processing (Auth_blk)
- Inertial sensor interface (inert_intf)
- A2D converter interface (A2D_intf)
- Balance controller (balance_cntrl, PID, SegwayMath)
- Steering enable logic (steer_en, steer_en_SM)
- Motor driver (mtr_drv, PWM11)
- Piezo buzzer driver (piezo_drv)
- Reset synchronizer (rst_synch)

## Files Created
- `steer_en.sv` - Wrapper for steering enable state machine with timer and comparators
- `A2D_intf.sv` - Interface to ADC128S A2D converter for load cells, battery, and steering pot
- `compile.do` - Complete compilation script for ModelSim
- Modified `Segway.sv` - Changed fast_sim from 0 to 1 for simulation
- Modified `Segway_tb.sv` - Added comprehensive test stimulus

## How to Run
**Option 1 - Using batch file:**
```
run_sim.bat
```

**Option 2 - Using ModelSim directly:**
1. Open ModelSim in the Ex23 directory
2. Run: `do compile.do`
3. The simulation will run all tests automatically

**Option 3 - Command line:**
```
vsim -c -do "do compile.do; quit -f"
```

## Tests Performed
1. **Power Up Test**: Sends 'G' command via UART, waits for steering enable
2. **Forward Lean Test**: Applies forward rider lean, monitors platform angle
3. **Backward Lean Test**: Applies backward lean, monitors response
4. **Steering Test**: Tests left/right steering with neutral lean
5. **Power Down Test**: Sends 'S' command, verifies shutdown

## Expected Behavior
- After 'G' command: pwr_up asserted, steering enables after ~300k cycles
- With rider lean: theta_platform should be controlled near zero by balance system
- PWM outputs should be active during operation
- System should respond smoothly to steering inputs
- After 'S' command: pwr_up deasserted, motors stop

## Key Signals to Monitor
- `iDUT.pwr_up` - Power enabled
- `iDUT.en_steer` - Steering enabled
- `iPHYS.theta_platform` - Platform tilt angle (should stay near zero)
- `PWM1_lft`, `PWM2_lft`, `PWM1_rght`, `PWM2_rght` - Motor PWM signals
- `iDUT.lft_spd`, `iDUT.rght_spd` - Motor speed commands

## Dependencies
All required modules are compiled from previous exercises:
- Ex14: UART_tx, UART_rx
- Ex16: SPI_mnrch
- Ex18: PID, SegwayMath, balance_cntrl
- Ex20: piezo_drv, rst_synch
- Ex22: PWM11, mtr_drv
- HW3: steer_en_SM
- HW4: Auth_blk

## Notes
- fast_sim parameter set to 1 for faster simulation
- SegwayModel provides physics simulation of platform dynamics
- ADC128S_FC provides A2D converter model
