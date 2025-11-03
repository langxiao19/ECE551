module saturate(
    input  [15:0]          unsigned_err,
    output [9:0]           unsigned_err_sat,
    input  signed [15:0]   signed_err,
    output       [9:0]     signed_err_sat,
    input  signed [9:0]    signed_D_diff,
    output       [6:0]     signed_D_diff_sat
);
    // Unsigned saturation: clamp 16-bit to 10-bit [0 .. 1023]
    assign unsigned_err_sat = (|unsigned_err[15:10]) ? 10'h3FF : unsigned_err[9:0];

    // Signed saturation from 16-bit to 10-bit in two's complement
    // Target range: [-512 .. +511]
    // Encode in 10-bit two's complement (0x200 = -512, 0x1FF = +511)
    wire signed [15:0] s_err;
    assign s_err = signed_err;
    assign signed_err_sat =
        (s_err >  16'sd511)   ? 10'h1FF :
        (s_err < -16'sd512)   ? 10'h200 :
                                s_err[9:0];

    // Signed D diff saturation from 10-bit to 7-bit in two's complement
    // Target range: [-64 .. +63] (0x40 = -64, 0x3F = +63)
    wire signed [9:0] d_diff;
    assign d_diff = signed_D_diff;
    assign signed_D_diff_sat =
        (d_diff >  10'sd63)   ? 7'h3F :
        (d_diff < -10'sd64)   ? 7'h40 :
                                d_diff[6:0];
endmodule
