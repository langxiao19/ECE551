# Exercise 15: Balance Control with Fast Simulation

This implementation includes the complete balance control system with fast simulation capabilities.

## Files Created:

### 1. `balance_cntrl.sv`
- Main balance control module that combines PID and SegwayMath
- Includes `fast_sim` parameter (default = 0)
- Interface matches the specification with all required signals

### 2. `PID.sv`
- Enhanced PID controller with fast simulation support
- **Fast simulation features implemented:**
  - **SS Timer acceleration**: When `fast_sim=1`, increments by 256 instead of 1
  - **Integrator fast mode**: When `fast_sim=1`, taps bits [15:1] instead of [17:6]
  - **Saturation logic**: Includes proper saturation checking for fast mode I_term
- Uses SystemVerilog `generate` conditionals as requested

### 3. `SegwayMath.sv`
- Combines PID output with steering control
- Calculates left and right motor speeds
- Includes `too_fast` detection

### 4. Test Benches:
- `PID_fastsim_tb.sv`: Tests PID module with both normal and fast simulation
- `balance_cntrl_tb.sv`: Tests complete balance control system

### 5. `compile_and_run.ps1`
- PowerShell script for compilation and simulation
- Supports ModelSim/QuestaSim and Icarus Verilog

## Key Fast Simulation Features:

### SS Timer Acceleration:
```systemverilog
generate
    if (fast_sim) begin : FAST_SS_TMR
        ss_tmr <= ss_tmr + 256;  // 256x faster
    end else begin : NORMAL_SS_TMR
        ss_tmr <= ss_tmr + 1;    // Normal speed
    end
endgenerate
```

### Integrator Fast Mode with Saturation:
```systemverilog
generate
    if (fast_sim) begin : FAST_I_TERM
        // Tap bits [15:1] with saturation checking
        if (integrator[17:15] == 3'b000 || integrator[17:15] == 3'b111) begin
            I_term = {{3{integrator[15]}}, integrator[15:1]};  // No saturation
        end else if (integrator[17]) begin
            I_term = 12'h800;  // Negative saturation
        end else begin
            I_term = 12'h7FF;  // Positive saturation
        end
    end else begin : NORMAL_I_TERM
        I_term = {{3{integrator[17]}}, integrator[17:6]};  // Normal mode
    end
endgenerate
```

## Usage:

1. To use normal simulation: `balance_cntrl #(.fast_sim(0)) instance_name (...);`
2. To use fast simulation: `balance_cntrl #(.fast_sim(1)) instance_name (...);`

The fast simulation mode significantly reduces simulation time by:
- Speeding up the steady-state timer by 256x
- Making the integrator more responsive by using different bit tapping
- Maintaining proper saturation to prevent overflow issues

All modules follow the interface specifications provided in the exercise.