`timescale 1ns / 1ps
module MSFF(
    input wire d,
    input wire clk,
    output wire q
);

    wire md, mq, sd;
    wand md_weak, sd_weak;

    // Tri-state with 1 time unit delay
    notif1 #(1) iTRI1 (md, d, ~clk);
    not (mq, md);
    not (weak0,weak1) (md, mq);

    notif1 #(1) iTRI2 (sd, mq, clk);
    not (q, sd);
    not(weak0, weak1) (sd, q);

endmodule