`timescale 1ns / 1ns

module bus_arbiter(data_out,address_out_31_2,Tx_Active,Tx_req,LED_wr,Data_addr,Uart_data,Data_mem_data,mem_write_ctrl,Data_mem_write_ctrl);
input [31:0]data_out;
input [29:0]address_out_31_2;
input mem_write_ctrl;
input Tx_Active;
output Tx_req;
output LED_wr;
output [9:0]Data_addr;
output [7:0]Uart_data;
output [31:0]Data_mem_data;
output Data_mem_write_ctrl;

//UART
assign Tx_req = ~Tx_Active && (address_out_31_2[29:10] == 20'h05000);
assign Uart_data = (Tx_req)? data_out[7:0] : 8'b0;

//LED
assign LED_wr = ~Tx_req && (address_out_31_2[29:10] == 20'h00800) && mem_write_ctrl;

//Data Memory
assign Data_addr = (~Tx_req && ~LED_wr)? address_out_31_2[9:0] : 10'b0;
assign Data_mem_data = (~Tx_req && ~LED_wr)? data_out  : 32'b0;
assign Data_mem_write_ctrl = (~Tx_req && ~LED_wr)? mem_write_ctrl : 1'b0; 

endmodule
