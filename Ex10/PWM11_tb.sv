module PWM11_tb();

// Testbench signals
reg clk, rst_n;
reg [10:0] duty;
wire PWM1, PWM2, PWM_synch, ovr_I_blank;

// Instantiate the PWM11 module
PWM11 iDUT (
    .clk(clk),
    .rst_n(rst_n),
    .duty(duty),
    .PWM1(PWM1),
    .PWM2(PWM2),
    .PWM_synch(PWM_synch),
    .ovr_I_blank(ovr_I_blank)
);

// Clock generation (50MHz = 20ns period)
initial begin
    clk = 0;
    forever #10 clk = ~clk;  // 50MHz clock
end

// Test stimulus
initial begin
    // Initialize signals
    rst_n = 0;
    duty = 11'h000;
    
    // Apply reset
    @(posedge clk);
    @(negedge clk);
    rst_n = 1;
    
    // Test Case 1: 50% duty cycle (duty = 0x400 = 1024)
    $display("Testing 50%% duty cycle (duty = 0x400)");
    duty = 11'h400;  // 1024 decimal
    repeat(4096) @(posedge clk);  // Run for 2 full PWM cycles
    
    // Test Case 2: 25% duty cycle (duty = 0x200 = 512) 
    $display("Testing 25%% duty cycle (duty = 0x200)");
    duty = 11'h200;  // 512 decimal
    repeat(4096) @(posedge clk);  // Run for 2 full PWM cycles
    
    // Test Case 3: 75% duty cycle (duty = 0x600 = 1536)
    $display("Testing 75%% duty cycle (duty = 0x600)");
    duty = 11'h600;  // 1536 decimal
    repeat(4096) @(posedge clk);  // Run for 2 full PWM cycles
    
    // Test Case 4: Very low duty cycle (less than NONOVERLAP)
    $display("Testing very low duty cycle (duty = 0x020)");
    duty = 11'h020;  // 32 decimal (less than NONOVERLAP = 64)
    repeat(4096) @(posedge clk);  // Run for 2 full PWM cycles
    
    // Test Case 5: Very high duty cycle
    $display("Testing very high duty cycle (duty = 0x780)");
    duty = 11'h780;  // 1920 decimal
    repeat(4096) @(posedge clk);  // Run for 2 full PWM cycles
    
    $display("Simulation completed");
    $stop;
end

// Generate VCD file for waveform viewing
initial begin
    $dumpfile("PWM11_tb.vcd");
    $dumpvars(0, PWM11_tb);
end

// Display key signal changes at specific times
always @(posedge PWM_synch) begin
    $display("Time=%0t: PWM cycle start - duty=%h PWM1=%b PWM2=%b ovr_I_blank=%b", 
             $time, duty, PWM1, PWM2, ovr_I_blank);
end

endmodule
