`timescale 1ns / 1ns

module hazard_detection_unit(is_fence,ID_EX_MEMRead, ID_EX_RegisterRd,IF_ID_RegisterRs1,IF_ID_RegisterRs2,PCWrite,IF_ID_Write,select_control_unit);
input is_fence;
input ID_EX_MEMRead;
input [4:0]ID_EX_RegisterRd,IF_ID_RegisterRs1,IF_ID_RegisterRs2;
output reg PCWrite,IF_ID_Write,select_control_unit;

always@*
    if((ID_EX_MEMRead & ((ID_EX_RegisterRd==IF_ID_RegisterRs1) || (ID_EX_RegisterRd==IF_ID_RegisterRs2))) | is_fence )
        begin
            PCWrite<=0;
            IF_ID_Write<=0;
            select_control_unit<=0;
        end
    else 
        begin
            PCWrite<=1;
            IF_ID_Write<=1;
            select_control_unit<=1;
        end
endmodule