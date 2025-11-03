`timescale 1ns/1ps
// implement a ring oscillator that has en enable, with a nand gate, then 2 inverters, only one input to the nand gate is en, the other input is tied to the result of the last inverter, each inverter should have a 5 time unit delay
module top (
    input wire en,
    output wire out
);
    wire nand_out;
    wire inv1_out;

    // NAND gate with one input as 'en' and the other as the output of the last inverter
    nand #(5) u_nand (nand_out, en, out);

    // First inverter
    not #(5) u_inv1 (inv1_out, nand_out);

    // Second inverter
    not #(5) u_inv2 (out, inv1_out);

endmodule
