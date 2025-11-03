module synch_detect(
    input  wire asynch_sig_in,
    input  wire clk,
    input  wire rst_n,
    output wire rise_edge
);

    wire sync_ff1_out;
    wire sync_ff2_out;
    wire sync_ff2_out_prev;

    // First stage of synchronization
    dff u1 (
        .D   (asynch_sig_in),
        .clk (clk),
        .Q   (sync_ff1_out),
        .PRN (rst_n)
    );

    // Second stage of synchronization
    dff u2 (
        .D   (sync_ff1_out),
        .clk (clk),
        .Q   (sync_ff2_out),
        .PRN (rst_n)
    );

    // Register to hold previous value of sync_ff2_out
    reg sync_ff2_out_prev_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sync_ff2_out_prev_reg <= 1'b0;
        else
            sync_ff2_out_prev_reg <= sync_ff2_out;
    end

    assign rise_edge = sync_ff2_out & ~sync_ff2_out_prev_reg;

endmodule
