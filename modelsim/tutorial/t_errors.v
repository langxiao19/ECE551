
module t_errors();
  //Declare Testbench wires and regs
  reg i0, i1;
  reg [1:0] sel;
  wire o;

  //Instantiate the DUT
  mux DUT(.i0(i0), .i1(i1), .sel(sel), .o(o));
  
  //Run Tests
  initial begin
    i0 = 0;
    i1 = 1;
    sel = 0;
    
    #100 sel = 1;
    #100 $stop;
  end
endmodule