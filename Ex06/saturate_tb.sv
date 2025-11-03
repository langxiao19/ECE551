module saturate_tb;
    reg  [15:0] unsigned_err;
    wire [9:0]  unsigned_err_sat;
    reg  [15:0] signed_err;
    wire [9:0]  signed_err_sat;
    reg  [9:0]  signed_D_diff;
    wire [6:0]  signed_D_diff_sat;

    saturate dut(
        .unsigned_err(unsigned_err),
        .unsigned_err_sat(unsigned_err_sat),
        .signed_err(signed_err),
        .signed_err_sat(signed_err_sat),
        .signed_D_diff(signed_D_diff),
        .signed_D_diff_sat(signed_D_diff_sat)
    );

    // Helper function for signed_err expected value
    function [9:0] signed_err_expected;
        input [15:0] val;
        reg signed [15:0] s;
        begin
            s = val;
            // Use explicit 16-bit signed constants to avoid width/negation ambiguity
            if (s < -16'sd512) signed_err_expected = 10'h200;
            else if (s > 16'sd511) signed_err_expected = 10'h1FF;
            else signed_err_expected = s[9:0];
        end
    endfunction

    // Helper function for unsigned_err expected value
    function [9:0] unsigned_err_expected;
        input [15:0] val;
        begin
            if (val > 10'h3FF) unsigned_err_expected = 10'h3FF;
            else unsigned_err_expected = val[9:0];
        end
    endfunction

    // Helper function for signed_D_diff expected value
    function [6:0] signed_D_diff_expected;
        input [9:0] val;
        reg signed [9:0] s;
        begin
            s = val;
            // Match widths with 10-bit signed to avoid constant overflow surprises
            if (s < -10'sd64) signed_D_diff_expected = 7'h40;
            else if (s > 10'sd63) signed_D_diff_expected = 7'h3F;
            else signed_D_diff_expected = s[6:0];
        end
    endfunction

    integer i;
    integer fails;
    reg signed [15:0] test_signed_err[0:6];
    reg signed [9:0] test_signed_D_diff[0:6];
    initial begin
        fails = 0;
        $display("Testing saturate module...");
        // Test unsigned_err
        for (i = 0; i < 5; i = i + 1) begin
            case (i)
                0: unsigned_err = 16'h0000; // 0
                1: unsigned_err = 16'h03FF; // max in range
                2: unsigned_err = 16'h0400; // just above
                3: unsigned_err = 16'hFFFF; // way above
                4: unsigned_err = 16'h0001; // small value
            endcase
            #1;
            if (unsigned_err_sat !== unsigned_err_expected(unsigned_err)) begin
                $display("FAIL unsigned_err=%h, got=%h, expected=%h", unsigned_err, unsigned_err_sat, unsigned_err_expected(unsigned_err));
                fails = fails + 1;
            end else begin
                $display("PASS unsigned_err=%h, got=%h", unsigned_err, unsigned_err_sat);
            end
        end

        // Test signed_err
        test_signed_err[0] = 16'sh0000; // 0
        test_signed_err[1] = 16'sh01FF; // max positive in range
        test_signed_err[2] = 16'sh0200; // just above positive
        test_signed_err[3] = -16'sh0200; // min negative in range
        test_signed_err[4] = -16'sh0201; // just below negative
        test_signed_err[5] = 16'sh7FFF; // way above
        test_signed_err[6] = -16'sh8000; // way below
        for (i = 0; i < 7; i = i + 1) begin
            signed_err = test_signed_err[i];
            #1;
            if (signed_err_sat !== signed_err_expected(signed_err)) begin
                $display("FAIL signed_err=%h, got=%h, expected=%h", signed_err, signed_err_sat, signed_err_expected(signed_err));
                fails = fails + 1;
            end else begin
                $display("PASS signed_err=%h, got=%h", signed_err, signed_err_sat);
            end
        end

        // Test signed_D_diff
        test_signed_D_diff[0] = 10'sd0;
        test_signed_D_diff[1] = 10'sd63; // max positive in range
        test_signed_D_diff[2] = 10'sd64; // just above positive
        test_signed_D_diff[3] = -10'sd64; // min negative in range
        test_signed_D_diff[4] = -10'sd65; // just below negative
        test_signed_D_diff[5] = 10'sd511; // way above
        test_signed_D_diff[6] = -10'sd512; // way below
        for (i = 0; i < 7; i = i + 1) begin
            signed_D_diff = test_signed_D_diff[i];
            #1;
            if (signed_D_diff_sat !== signed_D_diff_expected(signed_D_diff)) begin
                $display("FAIL signed_D_diff=%h, got=%h, expected=%h", signed_D_diff, signed_D_diff_sat, signed_D_diff_expected(signed_D_diff));
                fails = fails + 1;
            end else begin
                $display("PASS signed_D_diff=%h, got=%h", signed_D_diff, signed_D_diff_sat);
            end
        end
        if (fails == 0)
            $display("ALL TESTS PASSED.");
        else
            $display("Testing complete with %0d failure(s).", fails);
        $finish;
    end
endmodule
