/*
  t_ssp.v

  Testbench for the ssp module
*/

`timescale 1ns/1ns
module t_ssp();

  //outputs
  wire RecvDataValid;
  wire [7:0] RecvData;
  
  //inputs
  wire [7:0] TranData;
  reg Clk, Reset, Recv_nTran, StartOp;
  
  //inouts
  tri SerData;
  
  //Wires and registers for testbench use
  reg [7:0] ExpectedData;
  reg error;
  reg InputSerData;
  reg [9:0] ShiftReg;
  integer i, j;
  
  //Instantiate test object
  ssp DUT(.Clk(Clk),
           .Reset(Reset), 
           .SerData(SerData), 
           .StartOp(StartOp), 
           .Recv_nTran(Recv_nTran), 
           .RecvData(RecvData), 
           .TranData(TranData), 
           .RecvDataValid(RecvDataValid));
  
  //Tri-State Interface
  assign SerData = (Recv_nTran == 1'b1) ? InputSerData : 8'bz;
  
  //Generate Clk signal - 5 MHZ
  initial Clk <= 0;
  always @(Clk) Clk <= #100 ~Clk;
  
  //Create feedback from receiver to transmitter
  assign TranData = RecvData;
  
  //input test signals
  initial begin
  
    //Assign initial values
    Reset = 1'b0;
    InputSerData = 1'b0;
    Recv_nTran = 1'b1;
    StartOp = 1'b0;
    ShiftReg = 10'b0;
    ExpectedData = 8'b0;
    error = 1'b0;
    
    //Apply an initial Reset
    #105 Reset = 1'b1;   
    #200 Reset = 1'b0;
    
    
    //Test all possible input sequences to the receiver and ensure that they are received correctly
    //  Then, transmit the same sequence and ensure it is transmitted correctly.
    for (i=0; i<256; i=i+1) begin
      
      //Send in data to receiver
      #200 StartOp = 1; //Start an input sequence
           Recv_nTran = 1;
      #200 InputSerData = 1; //Start bit
      StartOp = 0;
      for (j=0; j<8; j=j+1) begin
        #200 InputSerData = ExpectedData[j];
      end
      #200 InputSerData = 1; //Stop bit
      #200;  //DataOut Should now match ExpedctedData
      if (RecvData !== ExpectedData) begin
        error = 1;
        $display("Receiver Error at time %t\n", $time);
      end
    
      //Transmit same data through the transmitter
      #200 StartOp = 1; 
           Recv_nTran = 0;
           error = 0;
           ShiftReg = 10'b0;
      for (j=0; j<10; j=j+1) begin
        #200 ShiftReg = {SerData, ShiftReg[9:1]};
      end
      #200;  //ShiftReg Should now match ExpedctedData
      if (ShiftReg[8:1] !== ExpectedData) begin
        error = 1;
        $display("Transmitter Error at time %t\n", $time);
      end
      
      //Prepare for next loop iteration
      #200  error = 0;
      ExpectedData = ExpectedData + 8'h01;
    end
    
    
    
    #200 $stop;
  end
endmodule
