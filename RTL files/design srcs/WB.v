`timescale 1ns/1ns

module WB(mem_to_reg,Mem_read_out,ALUresult,out);
input mem_to_reg;
input [31:0]Mem_read_out,ALUresult;
output [31:0]out;

assign out = mem_to_reg ? Mem_read_out : ALUresult;

endmodule
