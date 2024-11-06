//Modelled as a RAM
`timescale 1ns/1ns

module data_mem(clk,mem_read_ctrl,mem_write_ctrl,mem_address,mem_data_write,mem_data_read,B,H);

input mem_read_ctrl;
input mem_write_ctrl;
input B,H;
input clk;
input [9:0] mem_address;//We need atleast 12 bits in the address to access 4K data words. Word alligned addressing followed by mapping +4 to +1
input [31:0] mem_data_write;
output reg [31:0]mem_data_read;
reg [31:0]mem_data_custom;
reg [9:0]mem_address_custom;
reg custom;

/*RAM*/
reg [31:0] mem_ram [0:1023];              //8KB of data memory, 2048 data words present in the memory


always@(posedge clk)
begin
    if(mem_read_ctrl || mem_write_ctrl)
    begin
        if(mem_read_ctrl) 
            mem_data_read=mem_ram[mem_address]; //load and Custom
        else
            mem_data_read=32'b0;//In case of store
            
        
        if(!mem_read_ctrl && mem_write_ctrl) //store the data into the memory
        begin
            if(B==1 && H==0)
                case(mem_address[1:0])
                    2'b00: mem_ram[mem_address][7:0]=mem_data_write[7:0];
                    2'b01: mem_ram[mem_address][15:8]=mem_data_write[7:0];
                    2'b10: mem_ram[mem_address][23:16]=mem_data_write[7:0];
                    2'b11: mem_ram[mem_address][31:24]=mem_data_write[7:0];
                endcase
            else if(B==0 && H==1)
                case(mem_address[1])
                    2'b0: mem_ram[mem_address][15:0]=mem_data_write[15:0];
                    2'b1: mem_ram[mem_address][31:16]=mem_data_write[15:0];
                endcase
            else
                mem_ram[mem_address]=mem_data_write;
        end
    end
end

always @(posedge clk)
begin
    if(mem_read_ctrl && mem_write_ctrl)
        begin
            custom<=1;
            mem_data_custom<=mem_data_write;
            mem_address_custom<=mem_address; 
        end
    else
        begin
            custom<=0;
            mem_data_custom<=32'b0;
            mem_address_custom<=10'b0;
        end
end

always @ (negedge clk)
begin
    if(custom)
        mem_ram[mem_address_custom]=mem_data_custom;
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
//		mem_ram[12'h000001]<=32'h00000005;
//        end


endmodule
