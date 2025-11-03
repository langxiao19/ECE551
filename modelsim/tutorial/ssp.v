/*
  ssp.v
  
  This module is the top-level for the example Synchronous Serial Port(ssp)
*/

`timescale 1ns/1ns
module ssp(Clk, Reset, SerData, StartOp, Recv_nTran, RecvData, TranData, RecvDataValid);
  input Clk, Reset, StartOp, Recv_nTran;
  inout SerData;
  input [7:0] TranData;
  output [7:0] RecvData;
  output RecvDataValid;
  
  //Instantiate Bus Interface Unit to handle tri-states
  wire RecvStartOp, TranStartOp, RecvSerData, TranSerData;
  BusInt BusIntUnit(.SerData(SerData), 
                    .StartOp(StartOp), 
                    .Recv_nTran(Recv_nTran), 
                    .RecvStartOp(RecvStartOp), 
                    .TranStartOp(TranStartOp), 
                    .RecvSerData(RecvSerData), 
                    .TranSerData(TranSerData)
                   );
  
  //Instantiate the Receiver unit
  Receive ReceiveUnit(.Clk(Clk), 
                      .Reset(Reset), 
                      .StartOp(RecvStartOp), 
                      .SerData(RecvSerData), 
                      .DataValid(RecvDataValid), 
                      .DataOut(RecvData)
                      );
  
  //instantiate the transmit unit
  transmit TransmitUnit(.Clk(Clk), 
                        .Reset(Reset), 
                        .SerData(TranSerData), 
                        .StartOp(TranStartOp), 
                        .DataIn(TranData)
                        );
  
endmodule
