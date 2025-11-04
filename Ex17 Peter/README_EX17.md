# Exercise 17 - Balance Control Random Testing

## Files Created:
- `balance_cntrl_chk_tb.sv` - Testbench for random vector testing
- `balance_cntrl.sv` - Already created in Exercise 15
- `PID.sv` - Modified with fast_sim parameter

## Setup Verification:

### 1. Check PID.sv Parameters:
✅ `localparam P_COEFF = 5'h09` (already set correctly)
✅ `parameter fast_sim = 0` (default, but will be overridden to 1 in balance_cntrl)

### 2. Check balance_cntrl.sv:
✅ `parameter fast_sim = 1` (already set correctly)

## Running the Test:

### Method 1: Copy hex files to ex15 directory
```powershell
cd c:\Users\peter\ece551\ex15
copy ..\17\balance_cntrl_stim.hex .
copy ..\17\balance_cntrl_resp.hex .
```

### Method 2: Run from 17 directory with ex15 files
```powershell
cd c:\Users\peter\ece551\17
copy ..\ex15\PID.sv .
copy ..\ex15\SegwayMath.sv .
copy ..\ex15\balance_cntrl.sv .
copy ..\ex15\balance_cntrl_chk_tb.sv .
```

### Compile and Run:
```powershell
vlog PID.sv
vlog SegwayMath.sv
vlog balance_cntrl.sv
vlog balance_cntrl_chk_tb.sv
vsim -c work.balance_cntrl_chk_tb -do "run -all; quit"
```

Or with GUI:
```powershell
vsim -gui work.balance_cntrl_chk_tb
# In ModelSim console: run -all
```

## Testbench Features:

1. **Loads 1500 test vectors** from hex files
2. **Forces ss_tmr to 0xFF** to simulate steady state
3. **Self-checking** - compares outputs automatically
4. **Error reporting** - displays mismatches with details
5. **Success message** if all vectors pass

## Expected Output:
```
=========================================
SUCCESS! All 1500 vectors passed!
=========================================
```

## Troubleshooting:

If tests fail:
1. Run `PID_fastsim_tb.sv` first to verify PID works
2. Check that `fast_sim = 1` in balance_cntrl
3. Verify `P_COEFF = 5'h09` in PID.sv
4. Check that hex files are in the correct directory
5. Ensure force statement is working: `force iDUT.iPID.ss_tmr = 8'hFF;`

## Submission Files:
- `balance_cntrl.sv`
- `balance_cntrl_chk_tb.sv`
