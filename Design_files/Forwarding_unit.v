`timescale 1ns / 1ps

module Forwarding_unit(Op,CSR_Rs,EX_MEM_Rd,MEM_WB_Rd,ID_EX_Rs1,ID_EX_Rs2,EX_MEM_reg_wr,MEM_WB_reg_wr,ForwardA,ForwardB);
    input [6:0]Op,CSR_Rs;
    input [4:0]EX_MEM_Rd, MEM_WB_Rd, ID_EX_Rs1, ID_EX_Rs2;
    input EX_MEM_reg_wr,MEM_WB_reg_wr;
    output reg[1:0]ForwardA,ForwardB;
 
 always@(*)
 begin 
//ForwardA 
//Dealing with EX hazards
    if (EX_MEM_reg_wr & (EX_MEM_Rd != 0) & (EX_MEM_Rd == ID_EX_Rs1))
         ForwardA <= 2'b10;
//Dealing with Memory Hazards
    else if (MEM_WB_reg_wr & (MEM_WB_Rd != 0) & !(EX_MEM_reg_wr & (EX_MEM_Rd != 0) & (EX_MEM_Rd == ID_EX_Rs1)) & (MEM_WB_Rd == ID_EX_Rs1)) 
        ForwardA <= 2'b01;
    else
         ForwardA <= 2'b00;
 
//ForwardB   
//Dealing with EX hazards
    if (EX_MEM_reg_wr & (EX_MEM_Rd != 0) & 
            ((EX_MEM_Rd == ID_EX_Rs2) | ((EX_MEM_Rd == ID_EX_Rs2) & (Op == 7'b1110011) & (CSR_Rs == 1'b1))))
         ForwardB <= 2'b10;
//Dealing with Memory Hazards
    else if (MEM_WB_reg_wr & (MEM_WB_Rd != 0) & !(EX_MEM_reg_wr & (EX_MEM_Rd != 0) & (EX_MEM_Rd == ID_EX_Rs2) | 
                                                  ((Op == 7'b1110011) & (CSR_Rs == 1'b1) & (EX_MEM_Rd == ID_EX_Rs2))) & 
            ((MEM_WB_Rd == ID_EX_Rs2) | ((Op == 7'b1110011) & (CSR_Rs == 1'b1) & (MEM_WB_Rd == ID_EX_Rs2))))
        ForwardB <= 2'b01;
    else
         ForwardB <= 2'b00;

end       
endmodule
