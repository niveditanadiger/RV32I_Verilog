//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.07.2021 22:23:56
// Design Name: 
// Module Name: compliance_trial_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ns
`include "CSR_ADDR.vh"

 module UnitTest_SingleInstr_tb;

    reg clk;
    reg rst;              
   

    //assuming o/ps of processor should be wires
    wire [31:0] address_out;
    wire [31:0] data_out,data_in;
    wire B;
    wire H;
    wire [11:0]instr_addr;
    reg [31:0]instr;
    wire mem_read_ctrl;
    wire mem_write_ctrl;
    
    parameter BOOT_ADDRESS=32'b0;
    
    /*Internals*/
    integer f,j,m,n;
    
    
    
    ///////////////////////////////////////////////////////////
    /*                         Data Memory                   */
    reg [31:0]read_data;
    assign data_in=read_data;
    
    //RAM
    reg [31:0] mem_ram [0:32767];              //64KB of data memory, 2048 data words present in the memory
    
    always@(posedge clk)
    begin
        if(mem_read_ctrl && !mem_write_ctrl) //load the data from memory
            read_data=mem_ram[address_out[16:2]];
        if(!mem_read_ctrl && mem_write_ctrl) //store the data into the memory
        begin
            if(B==1 && H==0)
//                case(addr_allign)
//                    2'b00: mem_ram[address_out[16:2]][7:0]=data_out[7:0];
//                    2'b01: mem_ram[address_out[16:2]][15:8]=data_out[15:8];
//                    2'b10: mem_ram[address_out[16:2]][23:16]=data_out[23:16];
//                    2'b11: mem_ram[address_out[16:2]][31:24]=data_out[31:24];
//                endcase
                    case(address_out[1:0])
                        2'b00: mem_ram[address_out[16:2]][7:0]=data_out[7:0];
                        2'b01: mem_ram[address_out[16:2]][15:8]=data_out[7:0];
                        2'b10: mem_ram[address_out[16:2]][23:16]=data_out[7:0];
                        2'b11: mem_ram[address_out[16:2]][31:24]=data_out[7:0];
                    endcase
            else if(B==0 && H==1)
                case(address_out[1])
//                    2'b00: mem_ram[address_out[16:2]][15:0]=data_out[15:0];
//                    2'b10: mem_ram[address_out[16:2]][31:16]=data_out[31:16];
                      2'b0: mem_ram[address_out[16:2]][15:0]=data_out[15:0];
                      2'b1: mem_ram[address_out[16:2]][31:16]=data_out[15:0];
                endcase
            else
                mem_ram[address_out[16:2]]=data_out;
        end
    end
    
    
    
    
    ////////////////////////////////////////////////////////////////////
    /*                        Instruction Memory                      */
    reg [31:0] instruction_memory [0:4095]; //Total memory size: 16KB, capable of storing 4096 instructions.
    initial $readmemh("rv32ui-p-lb.txt",instruction_memory);//instructions are stored in 'ISA1.txt', loading instrns into the instruction_memory
    
    always@(negedge clk)
    begin
         instr <= instruction_memory[instr_addr]; 
    end
    
    
    
    ///////////////////////////////////////////////////////////////////
    /*                              Test                            */
    always
        #10 clk = ~clk;
            
    initial begin
        rst=1;
        clk=0;
        #20 rst=0;
        //comment if test is not for lb
        mem_ram[2048] = 32'h0ff000ff;
        //comment if test is not for sb
//        mem_ram[2048]=32'hefefefef;
//        mem_ram[2049]=32'hefefefef;
//        mem_ram[2050]=32'h0000efef;
                    // one second loop
                    for(j = 0; j < 50000000; j = j + 1)
                    begin
                        #20;
                        if(mem_write_ctrl == 1'b1 && address_out == 32'h00001000)
                        begin           
                            if(processor.ID.reg_file.registers[5'b00011]==32'b1) //Global Pointer
                                if(processor.ID.reg_file.registers[5'b01010]==32'b0) //Function Return a0
                                    $display("Test passed");
                                else
                                    $display("Test failed");
                            else
                                begin
                                    $display("Global Pointer: %d",processor.ID.reg_file.registers[3]);
                                    processor.ID.reg_file.registers[3]=processor.ID.reg_file.registers[3]>>1;
                                    $display("Test Case%d Failed: Trace and correct the code",processor.ID.reg_file.registers[3]); 
                                end
                            #20;
                            j = 50000000;
                        end
                    end
        #100
        $display("Test Finished");
        $finish;
        end
       
       
    /////////////////////////////////////////    
    /*             Instantiation           */    
    processor #(.BOOT_ADDRESS(BOOT_ADDRESS))
          processor(.clk(clk),.rst(rst),.data_in(data_in),.instr_in(instr),.mem_read_ctrl(mem_read_ctrl),.mem_write_ctrl(mem_write_ctrl),.address_out(address_out),.data_out(data_out),.B(B),.H(H),.instr_addr(instr_addr));

endmodule
