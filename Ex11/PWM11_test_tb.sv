module PWM11_test_tb();

reg clk, RST_n;
reg inc;
wire [7:0] LED;

// Instantiate DUT
PWM11_test iDUT(
    .clk(clk),
    .RST_n(RST_n),
    .inc(inc),
    .LED(LED)
);

// Clock generation
always #10 clk = ~clk;

initial begin
    clk = 0;
    RST_n = 0;
    inc = 0;
    
    // Reset sequence
    repeat(3) @(negedge clk);
    RST_n = 1;
    
    $display("Testing PWM11_test system");
    $display("Initial state: inc=%b, LED=%b", inc, LED);
    
    // Let system stabilize
    repeat(100) @(posedge clk);
    $display("After stabilization: inc=%b, LED=%b", inc, LED);
    
    // Press button to increase duty (simulate button press and release)
    inc = 1;
    repeat(10) @(posedge clk);
    inc = 0;
    repeat(100) @(posedge clk);
    $display("After button press 1: inc=%b, LED=%b", inc, LED);
    
    // Press button to increase duty again
    inc = 1;
    repeat(10) @(posedge clk);
    inc = 0;
    repeat(100) @(posedge clk);
    $display("After button press 2: inc=%b, LED=%b", inc, LED);
    
    // Press button multiple times to see the counter behavior
    inc = 1;
    repeat(10) @(posedge clk);
    inc = 0;
    repeat(100) @(posedge clk);
    $display("After button press 3: inc=%b, LED=%b", inc, LED);
    
    $display("PWM11_test system verification complete!");
    $stop();
end

endmodule
