`timescale 1ns/1ps

module PID_Math_tb;

    // DUT I/O
    logic signed [15:0] ptch;
    logic signed [15:0] ptch_rt;
    logic signed [17:0] integrator;
    wire  signed [11:0] PID_cntrl;

    // Instantiate DUT
    PID_Math dut (
        .ptch(ptch),
        .ptch_rt(ptch_rt),
        .integrator(integrator),
        .PID_cntrl(PID_cntrl)
    );

    // Simple task to step simulation and print a few values
    task automatic step_and_print(input string tag);
        begin
            #1; // allow combinational to settle
            $display("%0t %s  ptch=%0d  ptch_rt=%0d  integ=%0d  -> PID=%0d",
                     $time, tag, ptch, ptch_rt, integrator, PID_cntrl);
        end
    endtask

    initial begin
        integer i, j;   // declare loop indices at start of block

        $dumpfile("pid_math.vcd");
        $dumpvars(0, PID_Math_tb);

        // Initial conditions
        ptch       = 16'shFF00;  // -256
        ptch_rt    = 16'sh0FFF;  // +4095
        integrator = 18'sh03FFF; // low start

        step_and_print("INIT");

        // 8 repeat loops × 64 iterations = 512 steps
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 64; j = j + 1) begin
                // ptch always increases by +1
                ptch = ptch + 16'sd1;

                // integrator ramps up/down depending on loop
                case (i)
                    0,1: integrator = integrator + 18'sh00080;
                    2,3: integrator = integrator - 18'sh00080;
                    4,5: integrator = integrator + 18'sh00080;
                    6,7: integrator = integrator - 18'sh00080;
                endcase

                // ptch_rt slope flips every loop
                if (i % 2 == 0)
                    ptch_rt = ptch_rt - 16'sh0100; // even loops: decreasing
                else
                    ptch_rt = ptch_rt + 16'sh0100; // odd loops: increasing

                step_and_print($sformatf("L%0d/%0d", i, j));
            end
        end

        step_and_print("DONE");
        $display("Simulation finished.");
        $finish;
    end

endmodule

