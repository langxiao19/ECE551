 Exercise 19: Gated Clocks Comparison

## Design Overview

### Original Design (mult_accum.sv) - Recirculating Flops
- Uses `if (en)` inside always_ff blocks
- Synthesizes to 2:1 muxes feeding flops for enable functionality
- Two enabled blocks:
  - prod_reg: 32-bit wide (16x16 multiplication result)
  - accum: 64-bit wide accumulator
- One free-running block:
  - en_stg2: single bit pipeline register

### Gated Clock Design (mult_accum_gated.sv)
- Uses latched enable signals to gate the clock
- Two gated clocks:
  - clk_prod_gated: for prod_reg (gated by en_lat)
  - clk_accum_gated: for accum (gated by en_stg2_or_clr_lat)
- Enable low latches prevent glitches
- en_stg2 remains free-running (not gated)

## Synthesis Results

### Original Design (Recirculating Flops)
Run synthesis command:
```
design_vision -shell dc_shell -f mult_accum_fixed.dc
```

**Area:** 8367.000000 (lsi_10k units)
**Dynamic Power:** 1.0798 mW
**Timing:** Met (slack positive)

**Cell Counts:**
- Total cells: 759
- Sequential cells: 100
- Combinational cells: 650 (includes 2:1 muxes for recirculation)

### Gated Clock Design
Run synthesis command:
```
design_vision -shell dc_shell -f mult_accum_gated_fixed.dc
```

**Area:** 7938.000000 (lsi_10k units)
**Dynamic Power:** 1.0359 mW
**Timing:** Met (slack positive)

**Cell Counts:**
- Uses latches for enable signal capture
- Uses AND gates for clock gating instead of 2:1 muxes

## Analysis

### Expected Results:
- **Area:** Gated clock should be smaller (no 2:1 muxes, just AND gates for gating)
- **Power:** Gated clock should consume less dynamic power (clock network not toggling when disabled)
- **Timing:** Should be similar or slightly better with gated clocks

### Actual Results:
✅ **Area Reduction:** 
- Original: 8367 units
- Gated: 7938 units
- **Savings: 429 units (5.1% reduction)**

✅ **Power Reduction:**
- Original: 1.0798 mW
- Gated: 1.0359 mW  
- **Savings: 0.0439 mW (4.1% reduction)**

✅ **Timing:** Both designs meet timing requirements

## Conclusion

Clock gating proved beneficial for this design:

1. **Area savings of 5.1%**: Replacing 2:1 recirculation muxes (96 bits total: 32-bit prod_reg + 64-bit accum) with simple AND gates for clock gating resulted in measurable area reduction. The latches added for glitch-free gating are smaller than the eliminated muxes.

2. **Power savings of 4.1%**: The gated clock prevents the clock tree from toggling to 96 flip-flops when they're not being updated (when en=0). This reduces dynamic switching power in both the clock network and the register cells themselves.

3. **Design trade-offs**: Clock gating requires careful design (enable-low latches to avoid glitches) but provides tangible benefits. The savings scale with:
   - Width of gated registers (more bits = more savings)
   - Duty cycle of enable signal (lower duty cycle = more savings)
   - In this design with en having 10% activity factor, we see modest but real savings.

**Recommendation:** For designs with wide data paths and infrequently enabled registers, clock gating is worthwhile for both area and power optimization.
