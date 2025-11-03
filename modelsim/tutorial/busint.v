/*
  busint.v

  This file takes care of the bus interface with the bidirectional bus
  
*/

`timescale 1ns/1ns
module BusInt(SerData, StartOp, Recv_nTran, RecvStartOp, TranStartOp, RecvSerData, TranSerData);
inout SerData;
input TranSerData, StartOp, Recv_nTran;
output RecvStartOp, TranStartOp, RecvSerData;

//Mux the StartOp Signal to the appropriate module based on what mode we are in
assign RecvStartOp = (Recv_nTran == 1'b1) ? StartOp : 1'b0;
assign TranStartOp = (Recv_nTran == 1'b0) ? StartOp : 1'b0;

//Create the tri-state drivers for the SerData line
assign SerData = (Recv_nTran == 1'b0) ? TranSerData : 1'bZ;
//assign RecvSerData = (Recv_nTran == 1'b1) ? SerData : 1'bZ;
assign RecvSerData = SerData;
  
endmodule
  