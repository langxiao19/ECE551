//////////////////////////////////////////////////////////
//  Transmit buffer module
//
//   transmit.v
//
//////////////////////////////////////////////////////////

`timescale 1ns/1ns
module transmit(Clk, Reset, SerData, StartOp, DataIn);
 
   input Clk, Reset, StartOp;
   input [7:0] DataIn;
   output SerData;
   
   reg SerData, TBR;
   reg [3:0] state, next_state;
   reg [7:0] buffer;
   reg load_buffer, shift_buffer;
   
   always @(posedge Clk or posedge Reset) begin
   
     //Reset has been pressed -> initialize registers
     if(Reset == 1'b1) begin
       buffer <= 8'b0;
       state <= 4'b0;
     end else begin
       state <= next_state;
       if (load_buffer) begin
          buffer <= DataIn;
       end else if (shift_buffer) begin
          buffer <= {1'b0, buffer[7:1]};
       end
     end 
   end
   
   //if the address, write signal, and chip select are right
   always @(*) begin  
     next_state = state;
     load_buffer = 1'b0;
     shift_buffer = 1'b0;
     SerData = 1'b0;
     
     case(state)
     
       //If we get a StartOp, store the input byte and start transmitting
       4'd0:  begin
                if(StartOp == 1'b1) begin
                  next_state = 4'd1;
                  load_buffer = 1'b1;
                end
              end
              
       //transmit the start bit
       4'd1:  begin
                SerData = 1'b1;
                next_state = 4'd2;
              end
       
       //transmit the first bit       
       4'd2:  begin
                SerData = buffer[0];
                shift_buffer = 1'b1;
                next_state = 4'd3;
              end
              
       //transmit the second bit
       4'd3:  begin
                SerData = buffer[0];
                shift_buffer = 1'b1;
                next_state = 4'd4;
              end
       
       //transmit the third bit
       4'd4:  begin
                SerData = buffer[0];
                shift_buffer = 1'b1;
                next_state = 4'd5;
              end
       
       //transmit the fourth bit
       4'd5:  begin
                SerData = buffer[0];
                shift_buffer = 1'b1;
                next_state = 4'd6;
              end
       
       //transmit the fifth bit
       4'd6:  begin
                SerData = buffer[0];
                shift_buffer = 1'b1;
                next_state = 4'd7;
              end
       
       //transmit the sixth bit
       4'd7:  begin
                SerData = buffer[0];
                shift_buffer = 1'b1;
                next_state = 4'd8;
              end
       
       //transmit the seventh bit
       4'd8:  begin
                SerData = buffer[0];
                shift_buffer = 1'b1;
                next_state = 4'd9;
              end

       //transmit the last bit
       4'd9:  begin
                SerData = buffer[0];
                shift_buffer = 1'b1;
                next_state = 4'd10;
              end
       
       //output the stop bit
       4'd10:  begin
                SerData = 1'b1;
                next_state = 4'd0;
              end
     endcase
   end
 endmodule
