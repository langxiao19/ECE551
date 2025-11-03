`timescale 1ns/1ps
module arith_tb;

  reg  [7:0] A, B;
  reg        SUB;
  wire [7:0] SUM;
  wire       OV;

  // Instantiate DUT
  arith dut (.A(A), .B(B), .SUB(SUB), .SUM(SUM), .OV(OV));

  // Task for quick PASS/FAIL reporting
  task check(input [7:0] exp_sum, input exp_ov, input string msg);
    begin
      if (SUM === exp_sum && OV === exp_ov)
        $display("PASS: %s  (SUM=%0d, OV=%0b)", msg, $signed(SUM), OV);
      else
        $display("FAIL: %s  (Got SUM=%0d, OV=%0b, Exp SUM=%0d, OV=%0b)",
                  msg, $signed(SUM), OV, $signed(exp_sum), exp_ov);
    end
  endtask

  initial begin
    // ---------------- Addition Tests ----------------
    A=8'd5;  B=8'd7; SUB=0; #5;     
    check(8'd12, 0, "5 + 7, no overflow");

    A=8'd120; B=8'd120; SUB=0; #5; 
    check(8'd240, 1, "120 + 120, positive overflow");

    A=8'h80; B=8'h80; SUB=0; #5;   
    check(8'h00, 1, "-128 + -128, negative overflow");

    // ---------------- Subtraction Tests ----------------
    A=8'd7; B=8'd5; SUB=1; #5;     
    check(8'd2, 0, "7 - 5, no overflow");

    A=8'd50; B=8'd100; SUB=1; #5;  
    check(8'd206, 0, "50 - 100 = -50, no overflow");

    A=8'd100; B=-8'sd50; SUB=1; #5; 
    check(8'd150, 1, "100 - (-50), overflow (buggy case)");

    A=-8'sd128; B=8'd1; SUB=1; #5; 
    check(8'd127, 1, "-128 - 1, overflow");

    $display("Testbench finished.");
    $stop;
  end

endmodule
