//Modelled as a RAM
`timescale 1ns/1ns

module data_mem(clk,mem_read_ctrl,mem_write_ctrl,mem_address,mem_data_write,mem_data_read,addr_allign,B,H);

input mem_read_ctrl;
input mem_write_ctrl;
input B,H;
input clk;
input [1:0]addr_allign;
input [14:0] mem_address;//We need atleast 11 bits in the address to access 2K data words. Word alligned addressing followed by mapping +4 to +1
input [31:0] mem_data_write;
output reg [31:0]mem_data_read;


/*clock bar*/
wire clk_bar; 
assign clk_bar=~clk;


/*RAM*/
reg [31:0] mem_ram [0:32767];              //8KB of data memory, 2048 data words present in the memory

always@(posedge clk_bar)
begin
    if(mem_read_ctrl && !mem_write_ctrl) //load the data from memory
        mem_data_read=mem_ram[mem_address];
    if(!mem_read_ctrl && mem_write_ctrl) //store the data into the memory
    begin
        if(B==1 && H==0)
//            case(addr_allign)
//                2'b00: mem_ram[mem_address][7:0]=mem_data_write[7:0];
//                2'b01: mem_ram[mem_address][15:8]=mem_data_write[15:8];
//                2'b10: mem_ram[mem_address][23:16]=mem_data_write[23:16];
//                2'b11: mem_ram[mem_address][31:24]=mem_data_write[31:24];
//            endcase
            case(addr_allign)
                2'b00: mem_ram[mem_address][7:0]=mem_data_write[7:0];
                2'b01: mem_ram[mem_address][15:8]=mem_data_write[7:0];
                2'b10: mem_ram[mem_address][23:16]=mem_data_write[7:0];
                2'b11: mem_ram[mem_address][31:24]=mem_data_write[7:0];
            endcase
        else if(B==0 && H==1)
//            case(addr_allign)
//                2'b00: mem_ram[mem_address][15:0]=mem_data_write[15:0];
//                2'b10: mem_ram[mem_address][31:16]=mem_data_write[31:16];
//            endcase
            case(addr_allign)
                2'b00: mem_ram[mem_address][15:0]=mem_data_write[15:0];
                2'b10: mem_ram[mem_address][31:16]=mem_data_write[15:0];
            endcase
        else
            mem_ram[mem_address]=mem_data_write;
    end
end

//always@*
//for(i=0;i<40;i=i+1)
//begin
//    $display("%d",mem_ram[i]);
//end

/* to verify sb,sh etc
always@(*)
$display("%h",mem_ram[1]);
*/

//To get simulaton waveforms
//initial begin
//		mem_ram[11'h000001]<=32'h50000009;
//        end


endmodule
