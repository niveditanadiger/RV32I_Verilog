//Modelled as a Rom  
`timescale 1ns/1ns

module Instruction_mem(clk,address,instr);

input clk;
input [14:0]address;
output reg[31:0]instr;
reg [31:0] instruction_memory [0:32767]; //Total memory size: 16KB, capable of storing 2048 instructions.

initial $readmemh("debugger.txt",instruction_memory);//instructions are stored in 'ISA1.txt', loading instrns into the instruction_memory

always@(negedge clk)
begin
     instr <= instruction_memory[address];
end

endmodule