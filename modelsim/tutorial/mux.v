module mux(out,in1,in2,sel);
    
    output out;
    input in1,in2,sel;
    
    assign out = sel ? in1 : in2;
    
endmodule