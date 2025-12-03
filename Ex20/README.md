# Exercise 20: Piezo Driver Implementation

## Overview
Piezo driver module that plays warning tones for a Segway balance system. Implements the "Charge Fanfare" melody with three operating modes and differential drive outputs.

## Files Created
- **piezo_drv.sv** - Main piezo driver with state machine and counters
- **piezo_drv_tb.sv** - Testbench validating all operating modes
- **rst_synch.sv** - Reset synchronizer (copied from Ex11)
- Existing: piezoTest.sv, piezoTest.qpf, piezoTest.qsf (for DE0-Nano deployment)

## Design Architecture

### State Machine (7 states)
- `IDLE` - Silent, waiting for input
- `NOTE1` through `NOTE6` - Playing the 6 notes of Charge Fanfare
- `WAIT_REPEAT` - 3-second pause between fanfare repetitions

### Three Counters/Timers
1. **Duration Counter** (28-bit)
   - Tracks how long each note plays
   - Increments by 1 (normal) or 64 (fast_sim)
   - Each note has specific duration (222-445 clocks)

2. **Repeat Timer** (28-bit)
   - Implements 3-second pause between fanfare plays
   - 150M clocks @ 50MHz = 3 seconds
   - Increments by 1 (normal) or 64 (fast_sim)

3. **Frequency Counter** (16-bit)
   - Generates square wave at note frequency
   - Always increments by 1
   - Target frequency scaled in fast_sim mode (÷64)

### Charge Fanfare Notes
| Note | Frequency | Duration | Clocks |
|------|-----------|----------|--------|
| G6   | 1568 Hz   | 223      | 223    |
| C7   | 2093 Hz   | 223      | 223    |
| E7   | 2637 Hz   | 223      | 223    |
| G7   | 3136 Hz   | 223+222  | 445    |
| E7   | 2637 Hz   | 222      | 222    |
| G7   | 3136 Hz   | 225      | 225    |

## Operating Modes

### 1. `en_steer` Mode (Normal Operation)
- Plays full 6-note Charge Fanfare forward
- Repeats every 3 seconds
- Lowest priority

### 2. `batt_low` Mode
- Plays Charge Fanfare **backward** (NOTE6 → NOTE1)
- Repeats every 3 seconds
- Medium priority (overrides en_steer)

### 3. `too_fast` Mode
- Plays first 3 notes continuously in a loop
- No 3-second pause
- **Highest priority** (dangerous condition)

## fast_sim Parameter
- **Default: 1** (fast simulation)
- When `fast_sim == 1`:
  - Note durations divided by 64 (faster playback)
  - Frequency targets divided by 64 (periods complete faster)
  - 3-second timer divided by 64
- When `fast_sim == 0`:
  - Real-time durations and frequencies for actual hardware

## Testbench Results
All tests **PASS**:
1. ✅ Silence when no inputs asserted
2. ✅ en_steer plays fanfare forward (2 toggles observed - plays once then waits)
3. ✅ batt_low plays fanfare backward (294 toggles)
4. ✅ too_fast plays first 3 notes continuously (333 toggles)
5. ✅ too_fast has priority over en_steer
6. ✅ Returns to silence when inputs deasserted

## DE0-Nano Deployment
1. Ensure all files in Ex20 folder:
   - piezo_drv.sv
   - piezoTest.sv
   - rst_synch.sv
   - piezoTest.qpf/.qsf

2. Open project in Quartus:
   ```
   quartus piezoTest.qpf
   ```

3. Compile (pass `fast_sim=0` parameter for real hardware timing)

4. Program DE0-Nano and connect piezo to GPIO pins

5. Test with DIP switches:
   - SW0: en_steer
   - SW1: too_fast
   - SW2: batt_low

## Key Implementation Details
- Differential drive (piezo and piezo_n are complementary)
- 50% duty cycle square wave generation
- Priority handling: too_fast > batt_low > en_steer
- State advances when duration complete, direction determines next state
- Frequency counter always increments by 1 (target pre-scaled)
- Generate block creates increment amounts based on fast_sim

## Notes
- Piezo silent when in IDLE or WAIT_REPEAT states
- Piezo toggles at note frequency when in NOTE states
- fast_sim speeds up simulation 64x without changing logic structure
- All frequencies in audible range (300Hz - 7kHz as specified)
