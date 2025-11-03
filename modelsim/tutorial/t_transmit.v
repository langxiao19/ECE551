/*
  t_transmit.v

  Testbench for the transmit buffer module
  
  Team Members: Brian Hickmann and Jason Larson
  ECE554
  Mini-project
*/


`timescale 1ns/1ns
module t_transmit();

  wire SerData;
  reg [7:0] DataIn;
  reg Clk, Reset, StartOp;
  
  //Instantiate test object
  transmit DUT (Clk, Reset, SerData, StartOp, DataIn);
  
  //Generate Clk signal - 5 MHZ
  initial Clk <= 0;
  always @(Clk) Clk <= #100 ~Clk;
  
  //input test signals
  initial begin
    //Assign initial values
    StartOp = 1'b0;
    Reset = 1'b0;
    
    #105 Reset = 1;   //Apply an initial Reset
    #200 Reset = 0;
    
    //initially signal that we want to transmit 0xAB
    #200 DataIn = 8'hAB;
    StartOp = 1'b1;
    #200 StartOp = 1'b0;
    
    //try to give it new data while it still is working on 0xAB
    #1000 DataIn = 8'h78;
    
    //see if it gets the new data after the old data is done
    #2000;
    
    #200 $stop;
  end
endmodule