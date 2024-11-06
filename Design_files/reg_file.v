`timescale 1ns / 1ns
module reg_file(clk,reg_out_1,reg_out_2,reg_addr1,reg_addr2,reg_write_addr,reg_wr,reg_din);
    input clk;
	input [4:0] reg_addr1,reg_addr2,reg_write_addr;
	input [31:0] reg_din;
	input reg_wr;
	output reg [31:0] reg_out_1,reg_out_2;
	reg [31:0] registers [31:0];
	   
always @(*)
	begin
	   if(reg_addr1==5'b0)
	       reg_out_1 <= 32'b0;
	   else
	       reg_out_1 <= registers[reg_addr1];

	   if(reg_addr2==5'b0)
	       reg_out_2 <= 32'b0;
	    else
		    reg_out_2 <= registers[reg_addr2];
	end
	
always@(negedge clk)
	begin
	   if(reg_wr && reg_write_addr!=5'b0)
	       registers[reg_write_addr]=reg_din;
	end

//comment while synthesising 	
//always@(*)
//begin
//    for(i=0;i<32;i=i+1)
//    begin
//        $display("%d",registers[i]);
//    end
//    $display();
//end
//initial
//begin
//    registers[5'b00011]=32'h00000002;
//end

endmodule