`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.07.2021 00:21:24
// Design Name: 
// Module Name: post_synth_compliance_tb
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

   `include "CSR_ADDR.vh"
    module post_synth_UnitTest_tb;



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
    /*                          Tests                        */
    reg [8*70:0] tests[0:36]={

    "../../../../../../UnitTest-files/text_files/rv32ui-p-add.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-addi.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-and.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-andi.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-auipc.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-beq.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-bge.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-bgeu.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-blt.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-bltu.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-bne.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-jal.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-jalr.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-lb.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-lbu.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-lh.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-lhu.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-lui.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-lw.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-or.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-ori.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-sb.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-sh.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-sll.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-slli.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-slt.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-slti.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-sltiu.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-sltu.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-sw.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-sra.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-srai.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-srl.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-srli.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-sub.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-xor.txt",
    "../../../../../../UnitTest-files/text_files/rv32ui-p-xori.txt"
        };

    
    
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
                  case(address_out[1:0])
                        2'b00: mem_ram[address_out[16:2]][7:0]=data_out[7:0];
                        2'b01: mem_ram[address_out[16:2]][15:8]=data_out[7:0];
                        2'b10: mem_ram[address_out[16:2]][23:16]=data_out[7:0];
                        2'b11: mem_ram[address_out[16:2]][31:24]=data_out[7:0];
                    endcase
            else if(B==0 && H==1)
                case(address_out[1])
                      2'b0: mem_ram[address_out[16:2]][15:0]=data_out[15:0];
                      2'b1: mem_ram[address_out[16:2]][31:16]=data_out[15:0];
                endcase
            else
                mem_ram[address_out[16:2]]=data_out;
        end
    end
    
    
    
    ////////////////////////////////////////////////////////////////////
    /*                        Instruction Memory                      */
    reg [31:0] instruction_memory [0:4095]; //Total memory size: 16KB, capable of storing 2048 instructions.

    always@(negedge clk)
    begin
         instr <= instruction_memory[instr_addr]; 
    end
    
    
    
    ///////////////////////////////////////////////////////////////////
    /*                              Test                            */
    always
        #5 clk = ~clk;
            
    initial begin
        $display("Test Started......\n");
        for(m = 0; m < 37; m = m+1)
        begin
                    for(n = 0; n < 32767; n = n+1)
                    begin
                        instruction_memory[n] = 1'b0;
                        mem_ram[n] = 1'b0;
                    end
                    if(m==13) //lb
                        mem_ram[2048] = 32'h0ff000ff;
                    else if(m==14) //lbu
                        mem_ram[2048] = 32'h0ff000ff;
                    else if(m==15) //lh
                        begin
                        mem_ram[2048] = 32'hff0000ff;
                        mem_ram[2049] = 32'hf00f0ff0;                       
                        end
                    else if(m==16) //lhu
                        begin
                        mem_ram[2048] = 32'hff0000ff; 
                        mem_ram[2049] = 32'hf00f0ff0;
                        end
                    else if(m==18) //lw
                        begin
                        mem_ram[2048] = 32'h00ff00ff;
                        mem_ram[2049] = 32'hff00ff00;
                        mem_ram[2050] = 32'h0ff00ff0;
                        mem_ram[2051] = 32'hf00ff00f;
                        end    
                    else if(m==21) //sb
                        begin
                        mem_ram[2048] = 32'hefefefef;
                        mem_ram[2049] = 32'hefefefef;
                        mem_ram[2050] = 32'h0000efef;
                        end                    
                    else if(m==22) //sh
                        begin
                        mem_ram[2048] = 32'hbeefbeef;
                        mem_ram[2049] = 32'hbeefbeef;
                        mem_ram[2050] = 32'hbeefbeef;
                        mem_ram[2051] = 32'hbeefbeef;
                        mem_ram[2052] = 32'hbeefbeef;                        
                        end
                    else if(m==29) //sw
                        begin
                        mem_ram[2048] = 32'hdeadbeef;
                        mem_ram[2049] = 32'hdeadbeef;
                        mem_ram[2050] = 32'hdeadbeef;
                        mem_ram[2051] = 32'hdeadbeef;
                        mem_ram[2052] = 32'hdeadbeef;
                        mem_ram[2053] = 32'hdeadbeef;
                        mem_ram[2054] = 32'hdeadbeef;
                        mem_ram[2055] = 32'hdeadbeef;
                        mem_ram[2056] = 32'hdeadbeef;
                        mem_ram[2057] = 32'hdeadbeef; 
                        end
        $readmemh(tests[m],instruction_memory);
        $display("Running... %s...\n", tests[m]);
        rst=1;
        clk=0;
        #10 rst=0;
                    // one second loop
                    for(j = 0; j < 50000000; j = j + 1)
                    begin
                        #20;
                        if(mem_write_ctrl == 1'b1 && address_out == 32'h00001000)
                        begin           
                            if(data_out==32'b1)//gp
                                    $display("Test passed!\n\n");
                                else
                                    $display("Test failed!\n\n");
                            #20;
                            j = 50000000;
                        end
                    end
        end
        #100;
        $display("Test Finished!!");

 
        $finish;
        end
       
       
    /////////////////////////////////////////    
    /*             Instantiation           */    
    processor #(.BOOT_ADDRESS(BOOT_ADDRESS))
          processor(.clk(clk),.rst(rst),.data_in(data_in),.instr_in(instr),.mem_read_ctrl(mem_read_ctrl),.mem_write_ctrl(mem_write_ctrl),.address_out(address_out),.data_out(data_out),.B(B),.H(H),.instr_addr(instr_addr));

endmodule
