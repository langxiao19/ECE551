module mult_accum_gated(clk,clr,en,A,B,accum);

input clk,clr,en;
input [15:0] A,B;
output reg [63:0] accum;

reg [31:0] prod_reg;
reg en_stg2;

// Gated clock signals
logic clk_prod_gated;
logic clk_accum_gated;

// Enable latches for clock gating
logic en_lat, en_stg2_or_clr_lat;

///////////////////////////////////////////////////
// Enable low latches for clock gating
// These latch the enable signals during low phase
// of clock to avoid glitches
///////////////////////////////////////////////////
always_latch begin
  if (~clk)
    en_lat = en;
end

always_latch begin
  if (~clk)
    en_stg2_or_clr_lat = en_stg2 | clr;
end

///////////////////////////////////////////////////
// Gated clocks using latched enable signals
///////////////////////////////////////////////////
assign clk_prod_gated = clk & en_lat;
assign clk_accum_gated = clk & en_stg2_or_clr_lat;

///////////////////////////////////////////
// Generate and flop product with gated clock //
/////////////////////////////////////////
always_ff @(posedge clk_prod_gated)
    prod_reg <= A*B;

/////////////////////////////////////////////////////
// Pipeline the enable signal to accumulate stage //
// This is free-running, NOT gated //
///////////////////////////////////////////////////
always_ff @(posedge clk)
    en_stg2 <= en;

///////////////////////////////////////////////////
// Accumulator with gated clock
// Note: clr must allow clock through for clear to work
///////////////////////////////////////////////////
always_ff @(posedge clk_accum_gated)
    if (clr)
      accum <= 64'h0000000000000000;
    else
      accum <= accum + prod_reg;

endmodule
