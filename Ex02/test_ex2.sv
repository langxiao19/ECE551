module basic_test_bench(); // a testbench is self-contained (has no inputs/outputs)
    reg clk;
    reg rst_n;
    reg stim1, stim2; // stimulus to DUT declared as type reg or logic

    // Instantiate DUT = Device Under Test //
    DUT_module iNAME(
        .clk(clk),
        .rst_n(rst_n),
        .in1(stim1),
        .in2(stim2),
        .out1()
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #2 rst_n = 1;
    end

    // Stimulus
    initial begin
        stim1 = 0;
        stim2 = 1;
        #5; // wait 5 time units then change stimulus
        stim1 = 1;
        #5 $stop(); // wait 5 more time units then stop the simulation
    end
endmodule