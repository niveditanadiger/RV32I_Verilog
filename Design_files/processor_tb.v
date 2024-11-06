`timescale 1ns/1ps
//`include "processor.v"

module processor_tb;

reg clk;
reg rst;

/*Interface to the core*/
wire [31:0]data_in,data_out;
wire [31:0]address_out;
wire mem_read_ctrl;
wire mem_write_ctrl;
wire [1:0]addr_allign;
wire B,H;

/*Interface to Instruction memory*/
wire [31:0]instr;
wire [14:0]instr_addr;

/*Interface to UART*/
wire Tx_Done, Tx_Active, Tx_req;

/*Interface to Bus Arbiter*/
wire [10:0]Data_addr;
wire [31:0]Data_mem_data;
wire [7:0]Uart_data;
wire Data_mem_write_ctrl;

parameter BOOT_ADDRESS=32'b0;
parameter CLKS_PER_BIT=260;

processor #(.BOOT_ADDRESS(BOOT_ADDRESS))
          processor(.clk(clk),.rst(rst),.data_in(data_in),.instr_in(instr),.mem_read_ctrl(mem_read_ctrl),.mem_write_ctrl(mem_write_ctrl),.address_out(address_out),.data_out(data_out),.addr_allign(addr_allign),.B(B),.H(H),.instr_addr(instr_addr));

Instruction_mem inst_mem(.clk(clk),.address(instr_addr),.instr(instr));//setting lower bound on the address to '2' implies dvide by 4(mappiing {0,1,2,3,4,5,6..} to {0,0,0,0,4,4,4,..}) But what about the upper bound '12'(maybe as the max no. of instructions in the ROM is 2K, u need atleast 11 bits in the address.) 

data_mem data_mem(.clk(clk),.mem_read_ctrl(mem_read_ctrl),.mem_write_ctrl(Data_mem_write_ctrl),.mem_address(Data_addr),.mem_data_write(Data_mem_data),.mem_data_read(data_in),.addr_allign(addr_allign),.B(B),.H(H));

uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) uart_tx(.i_Clock(clk) ,
.i_Tx_DV(Tx_req) ,
.i_Tx_Byte(Uart_data) ,.o_Tx_Active(Tx_Active) ,
.o_Tx_Serial(out) ,
.o_Tx_Done(Tx_Done));

bus_arbiter bus_arbiter(.data_out(data_out),.address_out(address_out),.Tx_Active(Tx_Active),.Tx_req(Tx_req),.Data_addr(Data_addr),.Data_mem_data(Data_mem_data),.Uart_data(Uart_data),.mem_write_ctrl(mem_write_ctrl),.Data_mem_write_ctrl(Data_mem_write_ctrl));

/*Simulation*/
always #20 clk=~clk;  //Need to decide the time period 

initial begin
    rst=1;
    clk=0;
    #30 rst=0;
    #5000
    $finish;
end


endmodule