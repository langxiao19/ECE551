module rst_synch(
    input RST_n,     // raw input from push button
    input clk,       // clock, we use negative edge
    output rst_n     // our synchronized output which will form the global reset
);

    // Internal signals for the two flip-flops
    reg ff1, ff2;
    
    // Double flop synchronizer using negative edge triggered flip-flops
    // When RST_n is pressed (low), both flops are asynchronously reset to 0
    // When RST_n is released, we get double flopping for metastability prevention
    always_ff @(negedge clk or negedge RST_n) begin
        if (!RST_n) begin
            // Asynchronous reset - button pressed
            ff1 <= 1'b0;
            ff2 <= 1'b0;
        end else begin
            // Synchronous operation - double flop 1'b1 through the chain
            ff1 <= 1'b1;
            ff2 <= ff1;
        end
    end
    
    // Output is the second flip-flop output
    assign rst_n = ff2;

endmodule
