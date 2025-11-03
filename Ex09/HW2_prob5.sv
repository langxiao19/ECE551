/*
 * HW2 Problem 5 - SystemVerilog Flip-Flop and Latch Analysis
 * ECE551 Exercise 09
 * 
 * This file contains analysis of the provided D-latch code and implementations
 * of various flip-flop types using SystemVerilog always_ff constructs.
 */

/*
 * PART A: Analysis of the provided D-latch code
 * 
 * The given D-latch implementation:
 * module latch(d,clk,q);
 * input d, clk;
 * output reg q;
 * always @(clk)
 * if (clk)
 * q <= d;
 * endmodule
 *
 * Yeah, this code is correct - it does make a proper D-latch.
 *
 * Here's why it works:
 * - The @(clk) means the always block runs whenever clk changes (either edge)
 * - But the "if (clk)" only lets q update when clk is high
 * - So when clk goes high, q follows d (transparent mode)
 * - When clk goes low, q just holds whatever value it had (latch mode)
 * - That's exactly what a latch should do - it's level-sensitive, not edge-sensitive
 *
 * The main thing is it responds to clk being high or low (level), not to the 
 * rising/falling edges like a flip-flop would. If this were a flip-flop, 
 * we'd see @(posedge clk) instead.
 */

// PART B: D-FF with active high synchronous reset
module dff_sync_reset(
    input logic d,
    input logic clk,
    input logic reset,
    output logic q
);
    always_ff @(posedge clk) begin
        if (reset)
            q <= 1'b0;  // just clear it
        else
            q <= d;     // normal operation
    end
endmodule

// PART C: D-FF with asynchronous active low reset and active high enable
module dff_async_reset_enable(
    input logic d,
    input logic clk,
    input logic reset_n,  // active low reset
    input logic enable,   // active high enable
    output logic q
);
    always_ff @(posedge clk or negedge reset_n) begin
        if (~reset_n)
            q <= 1'b0;    // async reset kicks in immediately
        else if (enable)
            q <= d;       // only update when enabled
        // when enable is low, q just stays put
    end
endmodule

// PART D: SR FF with active high synchronous reset, active high synchronous set, 
//         and active low async reset
module sr_ff(
    input logic s,        // synchronous set
    input logic r,        // synchronous reset (has priority over set)
    input logic clk,
    input logic reset_n,  // asynchronous active low reset
    output logic q
);
    always_ff @(posedge clk or negedge reset_n) begin
        if (~reset_n)
            q <= 1'b0;  // async reset wins over everything
        else if (r)
            q <= 1'b0;  // sync reset beats sync set
        else if (s)
            q <= 1'b1;  // sync set
        // if neither s nor r, just hold the current state
    end
endmodule

/*
 * PART E: Analysis of always_ff construct
 *
 * Question: Does using always_ff guarantee the logic will infer a flip-flop?
 *
 * Nope! always_ff doesn't actually force the synthesis tool to make flip-flops.
 *
 * Here's the deal:
 * - always_ff is just a way to tell other people (and yourself later) that you 
 *   intended this to be sequential logic
 * - The synthesis tool still looks at what you actually wrote inside the block
 * - If you mess up the sensitivity list or coding style, you might still get 
 *   latches or weird combo logic
 *
 * What actually matters for getting flip-flops:
 * - Use @(posedge clk) or @(negedge clk) in the sensitivity list
 * - Make sure you handle all the cases properly (no incomplete if statements)
 * - Write it like sequential logic, not combinational
 *
 * The good thing about always_ff:
 * - Makes your code easier to read and understand
 * - Some tools can catch mistakes better and give you warnings
 * - Shows you know what you're trying to do
 *
 * But you can still screw it up:
 * - Write combo logic inside always_ff and the tool will still try to make combo logic
 * - Leave cases uncovered and you'll get unwanted latches
 * - Use the wrong sensitivity list and get unexpected behavior
 *
 * Bottom line: always_ff helps with intent and documentation, but proper coding 
 * style is what actually gets you the hardware you want.
 */
