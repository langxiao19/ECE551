module PWM11_tb();

reg clk, rst_n;
reg [10:0] duty;
wire PWM1, PWM2, PWM_synch, ovr_I_blank;

// Instantiate DUT
PWM11 iDUT(
    .clk(clk),
    .rst_n(rst_n), 
    .duty(duty),
    .PWM1(PWM1),
    .PWM2(PWM2),
    .PWM_synch(PWM_synch),
    .ovr_I_blank(ovr_I_blank)
);

// Clock generation
always #10 clk = ~clk;

initial begin
    clk = 0;
    rst_n = 0;
    duty = 11'h200;  // 25% duty cycle
    
    // Reset sequence
    repeat(2) @(negedge clk);
    rst_n = 1;
    
    $display("Testing PWM with duty = 0x%03x", duty);
    
    // Run for one complete PWM cycle plus some extra to see rollover
    repeat(2060) @(posedge clk);
    
    $display("PWM timing verification complete!");
    $stop();
end

// Monitor PWM signals - show key transitions only
always @(posedge clk) begin
    if (PWM_synch || (iDUT.cnt >= 510 && iDUT.cnt <= 516) || 
        (iDUT.cnt >= 574 && iDUT.cnt <= 580) || (iDUT.cnt >= 2045) ||
        (iDUT.cnt <= 5)) begin  // Show rollover behavior
        $display("Time=%0d cnt=%0d PWM1=%0d PWM2=%0d PWM_synch=%0d", 
                 $time, iDUT.cnt, PWM1, PWM2, PWM_synch);
    end
end

endmodule
