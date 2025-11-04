module balance_cntrl_tb();

    // Testbench signals
    reg clk, rst_n;
    reg vld;
    reg signed [15:0] ptch, ptch_rt;
    reg pwr_up, rider_off;
    reg [11:0] steer_pot;
    reg en_steer;
    wire [11:0] lft_spd_normal, rght_spd_normal;
    wire [11:0] lft_spd_fast, rght_spd_fast;
    wire too_fast_normal, too_fast_fast;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    // Instantiate balance_cntrl modules - one normal, one with fast_sim
    balance_cntrl #(.fast_sim(0)) iBalance_normal (
        .clk(clk),
        .rst_n(rst_n),
        .vld(vld),
        .ptch(ptch),
        .ptch_rt(ptch_rt),
        .pwr_up(pwr_up),
        .rider_off(rider_off),
        .steer_pot(steer_pot),
        .en_steer(en_steer),
        .lft_spd(lft_spd_normal),
        .rght_spd(rght_spd_normal),
        .too_fast(too_fast_normal)
    );
    
    balance_cntrl #(.fast_sim(1)) iBalance_fast (
        .clk(clk),
        .rst_n(rst_n),
        .vld(vld),
        .ptch(ptch),
        .ptch_rt(ptch_rt),
        .pwr_up(pwr_up),
        .rider_off(rider_off),
        .steer_pot(steer_pot),
        .en_steer(en_steer),
        .lft_spd(lft_spd_fast),
        .rght_spd(rght_spd_fast),
        .too_fast(too_fast_fast)
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
        steer_pot = 12'h800;  // Center position
        en_steer = 0;
        
        // Reset sequence
        repeat(5) @(posedge clk);
        rst_n = 1;
        
        // Power up sequence
        repeat(10) @(posedge clk);
        pwr_up = 1;
        
        // Start providing valid data
        repeat(5) @(posedge clk);
        vld = 1;
        
        // Test with pitch error (leaning forward)
        ptch = 16'h0200;  // Positive pitch error
        ptch_rt = 16'h0100; // Positive pitch rate
        
        repeat(500) @(posedge clk);
        
        // Enable steering and turn left
        en_steer = 1;
        steer_pot = 12'h400;  // Turn left
        
        repeat(300) @(posedge clk);
        
        // Turn right
        steer_pot = 12'hC00;  // Turn right
        
        repeat(300) @(posedge clk);
        
        // Center steering
        steer_pot = 12'h800;
        
        // Test with negative pitch (leaning backward)
        ptch = -16'h0300;
        ptch_rt = -16'h0150;
        
        repeat(500) @(posedge clk);
        
        // Test rider off
        rider_off = 1;
        repeat(100) @(posedge clk);
        rider_off = 0;
        
        repeat(300) @(posedge clk);
        
        $display("Balance control testbench completed");
        $finish;
    end
    
    // Monitor outputs
    initial begin
        $monitor("Time=%0t: ptch=%h, lft_normal=%h, rght_normal=%h, lft_fast=%h, rght_fast=%h", 
                 $time, ptch, lft_spd_normal, rght_spd_normal, lft_spd_fast, rght_spd_fast);
    end

endmodule