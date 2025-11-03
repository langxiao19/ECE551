/*
  receive.v

  This file implements the control, registers, and state machine for the receive module
  
  Team Members: Brian Hickmann and Jason Larson
  ECE554
  Mini-project
*/

`timescale 1ns/1ns
module Receive(Clk, Reset, StartOp, SerData, DataValid, DataOut);
input Clk, Reset, StartOp, SerData;
output DataValid;
output [7:0] DataOut;

//State machine states
parameter   IDLE = 4'b0000,
    START_BIT = 4'b0001,
    BIT_0 = 4'b0010,
    BIT_1 = 4'b0011,
    BIT_2 = 4'b0100,
    BIT_3 = 4'b0101,
    BIT_4 = 4'b0110,
    BIT_5 = 4'b0111,
    BIT_6 = 4'b1000,
    BIT_7 = 4'b1001,
    STOP_BIT = 4'b1010;
    
reg DataValid;
reg [7:0] DataOut;
reg [3:0] State, NextState;
reg [7:0] RBufShiftReg;
reg RBufLoad, RBufShift;

//Receiver buffer and shift register as well as the RDA signal
always @(posedge Clk or posedge Reset) begin
  if (Reset == 1'b1) begin
    DataOut <= 8'b0;
    RBufShiftReg <= 8'b0;
    DataValid <= 1'b0;
  end else begin
    //If told to shift, shift in data
    if (RBufShift == 1'b1) begin
      RBufShiftReg <= {SerData, RBufShiftReg[7:1]};
    end 
    
    //When done, we load the shift register into the output register, otherwise we make sure data valid is low
    if (RBufLoad == 1'b1) begin
      DataOut <= RBufShiftReg;
      DataValid <= 1'b1;
    end else begin
      DataValid <=0;
    end
  end
end

//State Machine FFs
always @(posedge Clk or posedge Reset) begin
  if (Reset == 1'b1) begin
    State <= IDLE;
  end else begin
    State <= NextState;
  end
end

//State Machine Logic
always @(*) begin
  RBufLoad = 1'b0;
  RBufShift = 1'b0;
  NextState = State;
  
  case (State)
    IDLE:     
      begin
        if (StartOp == 1'b1) begin 
          NextState = START_BIT;
        end
      end
      
    START_BIT:
      begin
          NextState = BIT_0;
      end
      
    BIT_0:
      begin
          RBufShift = 1'b1;
          NextState = BIT_1;
      end
      
    BIT_1:
      begin
          RBufShift = 1'b1;
          NextState = BIT_2;
      end
      
    BIT_2:
      begin
          RBufShift = 1'b1;
          NextState = BIT_3;
      end
      
    BIT_3:
      begin
          RBufShift = 1'b1;
          NextState = BIT_4;
      end
      
    BIT_4:
      begin
          RBufShift = 1'b1;
          NextState = BIT_5;
      end
      
    BIT_5:
      begin
          RBufShift = 1'b1;
          NextState = BIT_6;
      end
      
    BIT_6:
      begin
          RBufShift = 1'b1;
          NextState = BIT_7;
      end
      
    BIT_7:
      begin
          RBufShift = 1'b1;
          NextState = STOP_BIT;
      end
      
    STOP_BIT:
      begin
          RBufLoad = 1'b1;
          NextState = IDLE;
      end
  endcase
end

endmodule
