# Inertial Integrator - Exercise 21

## Files Created

1. **inertial_integrator.sv** - Main module implementing pitch integration with sensor fusion
2. **inertial_integrator_tb.sv** - Test bench that exercises all test scenarios
3. **sim_inertial.do** - ModelSim DO file for easy simulation
4. **run_inertial_sim.bat** - Batch script alternative for running simulation

## Module Description

The `inertial_integrator` module:
- Integrates pitch rate (ptch_rt) from the gyro into a 27-bit accumulator (ptch_int)
- Compensates for sensor offsets (PTCH_RT_OFFSET = 0x0050, AZ_OFFSET = 0x00A0)
- Calculates pitch from accelerometer (ptch_acc) for sensor fusion
- Applies fusion correction (+/- 1024) to prevent long-term drift
- Outputs scaled 16-bit pitch value (ptch_int[26:11])

## Test Sequence

The test bench validates:
1. **Positive pitch rate** (500 clocks) - ptch trends negative
2. **Zero pitch rate** (1000 clocks) - fusion correction brings ptch back toward zero
3. **Negative pitch rate** (500 clocks) - ptch trends positive  
4. **Zero pitch rate** (1000 clocks) - fusion correction brings ptch back toward zero
5. **AZ offset applied** (2000 clocks) - ptch stabilizes around 100

## Running the Simulation

### Option 1: Using ModelSim DO file (recommended)
```
vsim -do sim_inertial.do
```

### Option 2: Using batch script
```
run_inertial_sim.bat
```

### Option 3: Manual compilation
```
vlog -sv inertial_integrator.sv
vlog -sv inertial_integrator_tb.sv
vsim work.inertial_integrator_tb
```

## Viewing Waveforms

For best visualization of the pitch signal:
1. Right-click on the `ptch` signal in the wave window
2. Select **Format → Analog**
3. Configure:
   - Height: 300px
   - Min: -1000
   - Max: +1000
4. Set radix to **decimal**

This will show the pitch value as an analog waveform similar to the example in the exercise description.

## Expected Behavior

- During positive pitch rate: ptch decreases (integrating negative)
- During negative pitch rate: ptch increases
- During zero pitch rate: fusion correction slowly brings ptch toward ptch_acc value
- With AZ = 0x0800: ptch stabilizes around +100 when fusion reaches equilibrium

## Team Information

**Remember to update the team name** in the header comment of inertial_integrator.sv before submission!
