module mux(i0, i1, sel, o);
  input i0, i1, sel;
  output reg o;
  
  always@(i0, i1, sel) begin
    o = sel ? i1 : i0;
  end
endmodule
