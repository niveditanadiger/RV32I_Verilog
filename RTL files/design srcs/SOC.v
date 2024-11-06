`timescale 1ns / 1ns
module SOC(clk, rst, Tx, Tx_Done, Tx_Active, LED);


input clk;
input rst;
output Tx,Tx_Done,Tx_Active;
output reg LED;

/*Clock derive*/
reg clk1;
always@(posedge clk)
    clk1=~clk1;
//always@(posedge clk1)
//    clk2=~clk2;

/*Interface to Core*/
wire [31:0]data_in,data_out;
wire [31:0]address_out;
wire mem_read_ctrl;
wire mem_write_ctrl;
wire B,H;

/*Interface to Instruction memory*/
wire [31:0]instr;
wire [9:0]instr_addr;

/*Interface to UART*/
wire Tx_Active, Tx_req;

/*Interface to Bus Arbiter*/
wire [9:0]Data_addr;
wire [31:0]Data_mem_data;
wire [7:0]Uart_data;
wire Data_mem_write_ctrl;
wire LED_wr;

parameter BOOT_ADDRESS=32'b0;
parameter CLKS_PER_BIT=260;

processor #(.BOOT_ADDRESS(BOOT_ADDRESS))
          processor(.clk(clk1),.rst(rst),.data_in(data_in),.instr_in(instr),.mem_read_ctrl(mem_read_ctrl),.mem_write_ctrl(mem_write_ctrl),.address_out(address_out),.data_out(data_out),.B(B),.H(H),.instr_addr(instr_addr));

Instruction_mem inst_mem(.clk(clk1),.address(instr_addr),.instr(instr));//setting lower bound on the address to '2' implies dvide by 4(mappiing {0,1,2,3,4,5,6..} to {0,0,0,0,4,4,4,..}) But what about the upper bound '12'(maybe as the max no. of instructions in the ROM is 2K, u need atleast 11 bits in the address.) 

data_mem data_mem(.clk(clk1),.mem_read_ctrl(mem_read_ctrl),.mem_write_ctrl(Data_mem_write_ctrl),.mem_address(Data_addr),.mem_data_write(Data_mem_data),.mem_data_read(data_in),.B(B),.H(H));

uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) uart_tx(.clk(clk1) ,.rst(rst),
.data_valid(Tx_req) ,
.data(Uart_data) ,.tx(Tx_Active) ,
.serial(Tx) ,
.tx_complete(Tx_Done));

bus_arbiter bus_arbiter(.data_out(data_out),.address_out_31_2(address_out[31:2]),.Tx_Active(Tx_Active),.Tx_req(Tx_req),.Data_addr(Data_addr),.Data_mem_data(Data_mem_data),.Uart_data(Uart_data),.mem_write_ctrl(mem_write_ctrl),.Data_mem_write_ctrl(Data_mem_write_ctrl),.LED_wr(LED_wr));


//LED
always@(posedge clk1)
begin
if(LED_wr)
LED<=data_out[0];
end

endmodule
