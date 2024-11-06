`timescale 1ns/1ns

//`include "Instruction_mem.v"

module IF #(parameter BOOT_ADDRESS=32'b0)
           (clk,rst,instr,pc,target_pc,Branch_taken,EPC_OUT,MTVEC,Take_trap,PCWrite,Ra,Rb,Rd,Trap_Return,CSR_ADDR,CSR_funct3,is_mret,is_fence,is_ecall_ebreak,is_illegal_instr);

input clk,rst,Branch_taken,Take_trap,PCWrite,Trap_Return;
input [31:0]target_pc,EPC_OUT,MTVEC;
input [31:0]instr;
output reg [31:0]pc;
output reg[4:0]Ra,Rb,Rd; 
output reg [11:0]CSR_ADDR;
output reg [2:0]CSR_funct3;
output reg is_mret,is_fence,is_ecall_ebreak,is_illegal_instr;

/*PC*/
always@(posedge clk)
begin
    if(rst)
        pc <= BOOT_ADDRESS;
    else 
         begin 
            if (Trap_Return)
                pc <= EPC_OUT;    
            else if(Take_trap)
                pc <= MTVEC;
            else if(Branch_taken)
                pc <= target_pc;
            else if(PCWrite)
                pc <= pc+4;
        end
end


/*Early Decode Unit*/
always@(*)                          
    begin
        case(instr[6:0])
            7'b0110011: //R format
                begin
                    is_illegal_instr<=1'b0;
                    Ra<=instr[19:15];
                    Rb<=instr[24:20];
                    Rd<=instr[11:7];
                    CSR_ADDR<=12'b0;/**/
                    CSR_funct3<=3'b0;/**/
                    is_mret<=1'b0;
                    is_fence<=1'b0;
                    is_ecall_ebreak<=1'b0;
                end
             7'b0010011: //I-format
                begin
                    is_illegal_instr<=1'b0;
                    Ra<=instr[19:15];
                    Rb<=5'b0000z;/**/
                    Rd<=instr[11:7];
                    CSR_ADDR<=12'b0;/**/
                    CSR_funct3<=3'b0;/**/
                    is_mret<=1'b0;
                    is_fence<=1'b0;
                    is_ecall_ebreak<=1'b0;
                end
             7'b0000011: //lw format
                begin
                    is_illegal_instr<=1'b0;
                    Ra<=instr[19:15];
                    Rb<=5'b0000z;/**/
                    Rd<=instr[11:7];
                    CSR_ADDR<=12'b0;/**/
                    CSR_funct3<=3'b0;/**/
                    is_mret<=1'b0;
                    is_fence<=1'b0;
                    is_ecall_ebreak<=1'b0;
                end
             7'b0100011: //S type
                begin
                    is_illegal_instr<=1'b0;
                    Ra<=instr[19:15];
                    Rb<=instr[24:20];
                    Rd<=5'b0000z;/**/
                    CSR_ADDR<=12'b0;/**/
                    CSR_funct3<=3'b0;/**/
                    is_mret<=1'b0;
                    is_fence<=1'b0;
                    is_ecall_ebreak<=1'b0;
                end
             7'b0110111,7'b0010111,7'b1101111: //LUI, AUIPC, jal
                begin
                    is_illegal_instr<=1'b0;
                    Ra<=5'b0000z;/**/
                    Rb<=5'b0000z;/**/
                    Rd<=instr[11:7];
                    CSR_ADDR<=12'b0;/**/
                    CSR_funct3<=3'b0;/**/
                    is_mret<=1'b0;
                    is_fence<=1'b0;
                    is_ecall_ebreak<=1'b0;
                end
             7'b1100011: //B type
                begin
                    is_illegal_instr<=1'b0;
                    Ra<=instr[19:15];
                    Rb<=instr[24:20];
                    Rd<=5'b0000z;/**/
                    CSR_ADDR<=12'b0;/**/
                    CSR_funct3<=3'b0;/**/
                    is_mret<=1'b0;
                    is_fence<=1'b0;
                    is_ecall_ebreak<=1'b0;            
                end
             7'b1100111: //jalr
                begin
                    is_illegal_instr<=1'b0;
                    Ra<=instr[19:15];
                    Rb<=5'b0000z;/**/
                    Rd<=instr[11:7];
                    CSR_ADDR<=12'b0;/**/
                    CSR_funct3<=3'b0;/**/
                    is_mret<=1'b0;
                    is_fence<=1'b0;
                    is_ecall_ebreak<=1'b0;
                end
 ///               
            7'b0001011: //Custom
                begin
                    is_illegal_instr<=1'b0;
                    Ra<=instr[19:15];
                    Rb<=instr[24:20];
                    Rd<=instr[24:20];
                    CSR_ADDR<=12'b0;
                    CSR_funct3<=3'b0;
                    is_mret<=1'b0;
                    is_fence<=1'b0;
                    is_ecall_ebreak<=1'b0;
                end
 ///               
            7'b0001111: //FENCE
                begin
                    is_illegal_instr<=1'b0;
                    Ra<=instr[19:15];
                    Rb<=5'b0000z;/**/
                    Rd<=instr[11:7];
                    CSR_ADDR<=12'b0;/**/
                    CSR_funct3<=3'b0;/**/
                    is_mret<=1'b0;
                    is_fence<=1'b1;
                    is_ecall_ebreak<=1'b0;
                end
            7'b1110011: //CSR              
                begin
                    is_illegal_instr<=1'b0;
                    if(|instr[14:12])
                    begin
                        CSR_ADDR<=instr[31:20];
                        CSR_funct3<=instr[14:12];
                        Rd<=instr[11:7];
                        Ra<=5'b0000z;/**/
                        is_mret<=1'b0;
                        is_fence<=1'b0;
                        is_ecall_ebreak<=1'b0;
                        if(instr[14])
                            Rb<=5'b0000z;/**/    
                        else
                            Rb<=instr[19:15];
                    end
                    else
                    begin
                        CSR_ADDR<=12'b0;/**/
                        CSR_funct3<=3'b0;/**/
                        Ra<=instr[19:15];
                        Rd<=instr[11:7];
                        case(instr[31:25])
                            7'b0011000: //mret
                                begin
                                Rb<=instr[24:20];
                                is_mret<=1'b1;
                                is_fence<=1'b0;
                                is_ecall_ebreak<=1'b0;
                                end
//                            7'b0001000: //wfi
//                                begin
//                                Rb<=instr[24:20];
//                                is_mret<=1'b0;
//                                is_fence<=1'b1;
//                                is_ecall_ebreak<=1'b0;
//                                end
                            7'b0000000: //ecall,ebreak
                                begin
                                Rb<=5'b0000z;/**/
                                is_mret<=1'b0;
                                is_fence<=1'b0;
                                is_ecall_ebreak<=1'b1;
                                end
                             default:
                                begin
                                Rb<=5'b0000z;/**/
                                is_mret<=1'b0;/**/
                                is_fence<=1'b0;/**/
                                is_ecall_ebreak<=1'b0;/**/
                                end
                        endcase        
                    end 
                end
             default:
                begin
                    is_illegal_instr<=1'b1;
                    Ra<=5'b0000z;/**/
                    Rb<=5'b0000z;/**/
                    Rd<=5'b0000z;/**/
                    CSR_ADDR<=12'b0;/**/
                    CSR_funct3<=3'b0;/**/
                    is_mret<=1'b0;
                    is_fence<=1'b0;
                    is_ecall_ebreak<=1'b0;
                end
        endcase
    end

endmodule