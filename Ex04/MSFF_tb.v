`timescale 1ns / 1ps

module MSFF_tb;

    // Testbench signals
    reg d;
    reg clk;
    wire q;

    // Instantiate the Device Under Test (DUT)
    MSFF dut (
        .d(d),
        .clk(clk),
        .q(q)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock period
    end

    // Stimulus
    initial begin
        $display("Time\tclk\td\tq");
        $monitor("%g\t%b\t%b\t%b", $time, clk, d, q);

        // Initialize input
        d = 0;

        // Apply test vectors
        #3  d = 1;   // Change before clk edge
        #10 d = 0;   // Change again
        #10 d = 1;
        #10 d = 0;
        #10 d = 1;
        #10 d = 1;
        #10 d = 0;
        #10 $finish;
    end

endmodule
