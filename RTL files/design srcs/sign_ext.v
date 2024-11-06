`timescale 1ns/1ns

module sign_ext(clk,instr,IF_ID_Write,imm_ext);

input clk;
input [31:0] instr;
input IF_ID_Write;
output reg [31:0] imm_ext;

always@(posedge clk)
 if(IF_ID_Write)
 begin
    case(instr[6:0]) 
        7'b0100011,7'b0001011: //sw , Custom
                begin
                    if(instr[31])
                        imm_ext={20'hfffff,instr[31:25],instr[11:7]};
                    else
                        imm_ext={20'b0,instr[31:25],instr[11:7]};
                end
        7'b0000011: //lw
                begin
                    if(instr[31])
                        imm_ext={20'hfffff,instr[31:20]};
                    else
                        imm_ext={20'b0,instr[31:20]};
                 end
        7'b0010011://addimm
                begin
                    if(instr[31])
                        imm_ext={20'hfffff,instr[31:20]};
                    else
                        imm_ext={20'b0,instr[31:20]};
                 end
        7'b1100011: //branch
                begin
                    if(instr[31])
                        imm_ext={20'hfffff,instr[31],instr[7],instr[30:25],instr[11:8]};
                    else
                        imm_ext={20'b0,instr[31],instr[7],instr[30:25],instr[11:8]};
                end
        7'b0110111: //lui
                imm_ext={instr[31:12],12'b0};
        7'b0010111: //auipc
                imm_ext={instr[31:12],12'b0};//+pc;
        7'b1101111: //jal
                begin
                    if(instr[31])
                        imm_ext={12'hfff,instr[31],instr[19:12],instr[20],instr[30:21]};
                    else    
                        imm_ext={12'b0,instr[31],instr[19:12],instr[20],instr[30:21]};
                end
        7'b1100111: //jalr
                begin
                    if(instr[31])
                        imm_ext={20'hfffff,instr[31:20]};
                    else
                        imm_ext={20'b0,instr[31:20]};
                end
        7'b1110011: //CSR
                imm_ext={27'b0,instr[19:15]};
        default:
                imm_ext=32'b0;/**/
    endcase

 end


endmodule