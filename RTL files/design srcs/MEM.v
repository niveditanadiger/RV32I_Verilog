`timescale 1ns/1ns

module MEM(mem_address_1_0,in_data_read,funct,mem_data_read);

input [31:0]in_data_read;
input [1:0]mem_address_1_0;
input [2:0]funct;
output [31:0]mem_data_read;

LU LU(.funct(funct),.mem_address(mem_address_1_0),.mem_out(mem_data_read),.mem_in(in_data_read));

endmodule
