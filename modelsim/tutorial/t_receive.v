/*
  t_receive.v

  Testbench for the receiver module
  
*/


`timescale 1ns/1ns
module t_receive();
  reg [7:0] ExpectedDataOut;
  wire [7:0] DataOut;
  wire DataValid;
  reg Clk, Reset, StartOp;
  reg SerData;
  integer i;
  
  //Instantiate test object
  Receive DUT (Clk, Reset, StartOp, SerData, DataValid, DataOut);
  
  //Generate Clk signal - 5 MHZ
  initial Clk <= 0;
  always @(Clk) Clk <= #100 ~Clk;
  
  //input test signals
  initial begin
    //Assign initial values
    Reset = 0;
    SerData = 0;
    ExpectedDataOut = 0;
    StartOp = 0;
    
    #105 Reset = 1;   //Apply an initial Reset
    #200 Reset = 0;
    
    #200 StartOp = 1; //Start an input of 0x55
    ExpectedDataOut = 8'h55;
    #200 SerData = 1; //Start bit
    StartOp = 0;
    for (i=0; i<8; i=i+1) begin
      #200 SerData = ExpectedDataOut[i];
    end
    #200 SerData = 1; //Stop bit
    #200;  //DataOut Should now be 0x55
    
    #200 StartOp = 1; //Start an input of 0x00
    ExpectedDataOut = 8'h00;
    #200 SerData = 1; //Start bit
    StartOp = 0;
    for (i=0; i<8; i=i+1) begin
      #200 SerData = ExpectedDataOut[i];
    end
    #200 SerData = 1; //Stop bit
    #200;  //DataOut Should now be 0x00
    
    #200 StartOp = 1; //Start an input of 0xff
    ExpectedDataOut = 8'hff;
    #200 SerData = 1; //Start bit
    StartOp = 0;
    for (i=0; i<8; i=i+1) begin
      #200 SerData = ExpectedDataOut[i];
    end
    #200 SerData = 1; //Stop bit
    #200;  //DataOut Should now be 0xff
    
    #400 $stop;
  end
endmodule