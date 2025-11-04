module PID_fastsim_tb();

    // Testbench signals
    reg clk, rst_n;
    reg vld;
    reg signed [15:0] ptch, ptch_rt;
    reg pwr_up, rider_off;
    wire signed [11:0] PID_normal, PID_fast;
    wire [7:0] ss_tmr_normal, ss_tmr_fast;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    // Instantiate PID modules - one normal, one with fast_sim
    PID #(.fast_sim(0)) iPID_normal (
        .clk(clk),
        .rst_n(rst_n),
        .vld(vld),
        .ptch(ptch),
        .ptch_rt(ptch_rt),
        .pwr_up(pwr_up),
        .rider_off(rider_off),
        .PID_cntrl(PID_normal),
        .ss_tmr(ss_tmr_normal)
    );
    
    PID #(.fast_sim(1)) iPID_fast (
        .clk(clk),
        .rst_n(rst_n),
        .vld(vld),
        .ptch(ptch),
        .ptch_rt(ptch_rt),
        .pwr_up(pwr_up),
        .rider_off(rider_off),
        .PID_cntrl(PID_fast),
        .ss_tmr(ss_tmr_fast)
    );
    
    // Test stimulus
    initial begin
        // Initialize signals
        rst_n = 0;
        vld = 0;
        ptch = 16'h0000;
        ptch_rt = 16'h0000;
        pwr_up = 0;
        rider_off = 0;
        
        // Reset sequence
        repeat(5) @(posedge clk);
        rst_n = 1;
        
        // Power up sequence
        repeat(10) @(posedge clk);
        pwr_up = 1;
        
        // Start providing valid data
        repeat(5) @(posedge clk);
        vld = 1;
        
        // Test with some pitch error
        ptch = 16'h0100;  // Small positive pitch error
        ptch_rt = 16'h0050; // Small pitch rate
        
        // Run for many cycles to observe integrator behavior
        repeat(1000) @(posedge clk);
        
        // Change pitch to negative
        ptch = -16'h0200;
        ptch_rt = -16'h0080;
        
        repeat(1000) @(posedge clk);
        
        // Test rider off functionality
        rider_off = 1;
        repeat(100) @(posedge clk);
        rider_off = 0;
        
        repeat(500) @(posedge clk);
        
        $display("Testbench completed");
        $finish;
    end
    
    // Monitor outputs
    initial begin
        $monitor("Time=%0t: ptch=%h, PID_normal=%h, PID_fast=%h, ss_tmr_normal=%h, ss_tmr_fast=%h", 
                 $time, ptch, PID_normal, PID_fast, ss_tmr_normal, ss_tmr_fast);
    end

endmodule