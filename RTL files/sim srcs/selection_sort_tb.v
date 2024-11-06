`timescale 1ns / 1ns

module selection_sort_tb();

reg clk;
reg rst;
wire Tx,Tx_Done;
reg LED;

/*Interface to Core*/
wire [31:0]data_in,data_out;
wire [31:0]address_out;
wire mem_read_ctrl;
wire mem_write_ctrl;
wire [1:0]addr_allign;
wire B,H;

/*Interface to Instruction memory*/
wire [31:0]instr;
wire [9:0]instr_addr;//[11:0]instr_addr previously

/*Interface to UART*/
wire Tx_Active, Tx_req;

/*Interface to LED*/
wire LED_wr;

/*Interface to Bus Arbiter*/
wire [9:0]Data_addr;//[11:0]Data_addr previously
wire [31:0]Data_mem_data;
wire [7:0]Uart_data;
wire Data_mem_write_ctrl;

parameter BOOT_ADDRESS=32'b0;
parameter CLKS_PER_BIT=10415;

processor #(.BOOT_ADDRESS(BOOT_ADDRESS))
          processor(.clk(clk),.rst(rst),.data_in(data_in),.instr_in(instr),.mem_read_ctrl(mem_read_ctrl),.mem_write_ctrl(mem_write_ctrl),.address_out(address_out),.data_out(data_out),.B(B),.H(H),.instr_addr(instr_addr));

Instruction_mem inst_mem(.clk(clk),.address(instr_addr),.instr(instr));//setting lower bound on the address to '2' implies dvide by 4(mapping {0,1,2,3,4,5,6..} to {0,0,0,0,4,4,4,..}) But what about the upper bound '12'(maybe as the max no. of instructions in the ROM is 2K, u need atleast 11 bits in the address.) 

data_mem data_mem(.clk(clk),.mem_read_ctrl(mem_read_ctrl),.mem_write_ctrl(Data_mem_write_ctrl),.mem_address(Data_addr),.mem_data_write(Data_mem_data),.mem_data_read(data_in),.B(B),.H(H));

uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) uart_tx(.clk(clk) , .rst(rst),.data_valid(Tx_req) ,.data(Uart_data) ,.tx(Tx_Active) ,.serial(Tx) ,.tx_complete(Tx_Done));

bus_arbiter bus_arbiter(.data_out(data_out),.address_out_31_2(address_out[31:2]),.Tx_Active(Tx_Active),.Tx_req(Tx_req),.LED_wr(LED_wr),.Data_addr(Data_addr),.Data_mem_data(Data_mem_data),.Uart_data(Uart_data),.mem_write_ctrl(mem_write_ctrl),.Data_mem_write_ctrl(Data_mem_write_ctrl));


always #5 clk = ~clk;

integer f,n,j,k;


always@(posedge clk)
        f=f+1;          //counter

initial 
begin
	$display("Test Started......\n");
	f=0;
	rst=1;
        clk=0;
        #10 rst=0;

	for(j = 0; j < 50000000; j = j + 1)
            begin
                #10;
                if(mem_write_ctrl == 1'b1 && address_out == 32'h00000384)
                begin  
                   $display("Sorting complete!\n\n");  
                                    
                   for(k=50; k<150 ; k=k+1)
                       $display("%d ",data_mem.mem_ram[k]);

                   $display("Total No. of clock cycles taken: %d\n\n",f);         
                   #10;
                   j = 50000000;
                 end
             end

	#5000;
        //$display("Sorting test Finished!!");

        $finish;
end

//LED
always@(negedge clk)
if(LED_wr)
LED=data_out[0];

endmodule
