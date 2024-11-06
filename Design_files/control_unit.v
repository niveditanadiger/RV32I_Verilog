`timescale 1ns/1ns

module control_unit(Op,CSR_RW_RSC_select,CSR_reg_imm_select,CSR_src,CSR_dest,RegWrite,ALUOp,MemRead,MemWrite,MemtoReg,is_Branch,ALUSrc,EX_res_select,CSR_re_enable,CSR_wr_enable,select_control_unit);

input [6:0]Op;    
input CSR_RW_RSC_select,CSR_reg_imm_select;
input [4:0]CSR_src,CSR_dest;
input select_control_unit;

output reg RegWrite;
output reg [1:0] ALUOp;
output reg MemRead;
output reg MemWrite;
output reg MemtoReg;
output reg is_Branch; 
output reg [1:0]ALUSrc;
output reg CSR_re_enable,CSR_wr_enable;
output reg EX_res_select;


always @(*)
begin
    if(select_control_unit) begin
        case(Op)
        7'b0110011: //R format
            begin
            RegWrite<=1;
            ALUOp<=2'b10;
            MemRead<=0;
            MemWrite<=0;
            MemtoReg<=0;
            is_Branch<=0;  
            ALUSrc<=2'b00;
            EX_res_select<=1'b1;
            end
        7'b0000011: //lw format
            begin
            RegWrite<=1;
            ALUOp<=2'b00;
            MemRead<=1;
            MemWrite<=0;
            MemtoReg<=1;
            is_Branch<=0;  
            ALUSrc<=2'b01;
            EX_res_select<=1'b1;
            end
         7'b0100011: //S type
            begin
            RegWrite<=0;
            ALUOp<=2'b00;
            MemRead<=0;
            MemWrite<=1;
            MemtoReg<=1'bz;/**/
            is_Branch<=0;  
            ALUSrc<=2'b01;
            EX_res_select<=1'b1;
            end
        7'b0110111: //LUI
            begin
            RegWrite<=1;
            ALUOp<=2'b00;
            MemRead<=0;
            MemWrite<=0;
            MemtoReg<=0;
            is_Branch<=0;  
            ALUSrc<=2'b11;
            EX_res_select<=1'b1;
            end
       7'b0010111: //AUIPC
            begin
            RegWrite<=1;
            ALUOp<=2'b00;
            MemRead<=0;
            MemWrite<=0;
            MemtoReg<=0;
            is_Branch<=0;  
            ALUSrc<=2'b11;
            EX_res_select<=1'b1;
            end
        7'b1100011: //SB type
            begin
            RegWrite<=0;
            ALUOp<=2'b01;
            MemRead<=0;
            MemWrite<=0;
            MemtoReg<=1'bz;/**/
            is_Branch<=1;  
            ALUSrc<=2'b00;
            EX_res_select<=1'b1;
            end 
        7'b0010011: //I-format 
            begin
            RegWrite<=1;
            ALUOp<=2'b11; 
            MemRead<=0;
            MemWrite<=0;
            MemtoReg<=0;
            is_Branch<=0;  
            ALUSrc<=2'b01;
            EX_res_select<=1'b1;
            end 
        7'b1101111: //jal 
            begin
            RegWrite<=1;
            ALUOp<=2'b00; 
            MemRead<=0;
            MemWrite<=0;
            MemtoReg<=0;
            is_Branch<=1;  
            ALUSrc<=2'b10;
            EX_res_select<=1'b1;
            end 
        7'b1100111: //jalr 
            begin
            RegWrite<=1;
            ALUOp<=2'b00; 
            MemRead<=0;
            MemWrite<=0;
            MemtoReg<=0;
            is_Branch<=1;  
            ALUSrc<=2'b10; 
            EX_res_select<=1'b1;
            end 
        7'b1110011: //CSR 
            begin
            case(CSR_RW_RSC_select) //instr[13]
                1'b0: 
                begin
                    CSR_wr_enable<=1'b1;
                    CSR_re_enable<=(CSR_dest==5'b0)?1'b0:1'b1;
                end
                1'b1: 
                begin
                    CSR_re_enable<=1'b1;
                    CSR_wr_enable<=(CSR_src==5'b0)?1'b0:1'b1;
                end   
            endcase
            if(CSR_reg_imm_select) //instr[14]
                ALUSrc<=2'b01; 
            else
                ALUSrc<=2'b00; 
            EX_res_select<=1'b0;
            RegWrite<=1'b1; //for mret, it shd be 0
            ALUOp<=2'bzz;/**/
            MemRead<=1'b0;
            MemWrite<=1'b0;
            MemtoReg<=1'b0;
            is_Branch<=1'b0;
            end
         default:/**/
            begin
            RegWrite<=1'b0;
            ALUOp<=2'bzz;
            MemRead<=1'b0;
            MemWrite<=1'b0;
            MemtoReg<=1'bz;
            is_Branch<=1'b0;  
            ALUSrc<=2'bzz;
            EX_res_select<=1'bz;
            CSR_wr_enable<=1'b0;
            CSR_re_enable<=1'b0;
            end   
        endcase
     end
     else
        begin/**/
            RegWrite<=1'b0;
            ALUOp<=2'bzz;
            MemRead<=1'b0;
            MemWrite<=1'b0;
            MemtoReg<=1'bz;
            is_Branch<=1'b0;  
            ALUSrc<=2'bzz;
            EX_res_select<=1'bz;
            CSR_wr_enable<=1'b0;
            CSR_re_enable<=1'b0;
        end
end

endmodule
