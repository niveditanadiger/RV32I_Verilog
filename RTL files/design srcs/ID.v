`timescale 1ns/1ns

module ID(clk,EX_pc_31_2,reg_write_data,reg_write_addr,reg_wr,reg_read_data1,reg_read_data2,instr_OP,instr_funct3_1_0,instr,IF_ID_Write,Ra,Rb,imm_ext,I_or_E,cause_in,cause_set,mepc_set,exception_intr_address_in,Result_1_0,I_or_E_occurred,is_mret,is_ecall_ebreak,Take_trap,is_illegal_instr,ADDR_Misallign);

input clk;
input [29:0]EX_pc_31_2;                   
input [31:0]reg_write_data;
input reg_wr;
input [6:0] instr_OP;
input [1:0] instr_funct3_1_0;
input [31:0] instr;
input IF_ID_Write;
input [4:0]reg_write_addr;
input [1:0]Result_1_0;
input Take_trap;
input is_mret,is_ecall_ebreak,is_illegal_instr; 
input [4:0]Ra;
input [4:0]Rb;
output [31:0]reg_read_data1;
output [31:0]reg_read_data2;
output [31:0]imm_ext;


/*Interfaces to CSR Unit*/            
output reg I_or_E;
output reg [3:0]cause_in;
output reg cause_set,mepc_set;
output reg [29:0]exception_intr_address_in;
output I_or_E_occurred;


/*Internal wires and regs*/             
output reg ADDR_Misallign;
reg [6:0]prev_instr_OP;
reg [1:0]prev_instr_funct3_1_0;


/*Exception Detect Unit*/
always@(posedge clk)
begin
    prev_instr_OP<=instr_OP;
    prev_instr_funct3_1_0<=instr_funct3_1_0;
end

assign I_or_E_occurred=(ADDR_Misallign)|(is_ecall_ebreak)|(is_illegal_instr)|(Take_trap);
 
//always@(*)
//begin
//    case(prev_instr_OP)
//        7'b0000011://Load
//            case(prev_instr_funct3_1_0)
//                2'b10://lw
//                    ADDR_Misallign=(Result_1_0[0] || Result_1_0[1]);
//                2'b01://lh,lhu
//                    ADDR_Misallign=Result_1_0[0];
//            endcase
//        7'b0100011://Store
//            case(prev_instr_funct3_1_0)
//                2'b10://sw
//                    ADDR_Misallign=(Result_1_0[0] || Result_1_0[1]);
//                2'b01://sh
//                    ADDR_Misallign=Result_1_0[0];
//            endcase
//        default:
//            ADDR_Misallign<=1'b0;
//    endcase
    
//    if(is_mret)
//    begin
//        cause_set<=1'b0;
//        mepc_set<=1'b0;   
//        I_or_E<=1'bz;/**/
//        exception_intr_address_in<={29'b0,1'bz};/**/
//        cause_in<=4'b0000z;/**/
//    end
//    else if(!ADDR_Misallign & !is_ecall_ebreak & !is_illegal_instr)
//    begin
//        cause_set<=1'b0;
//        mepc_set<=1'b0;   
//        I_or_E<=1'bz;/**/
//        exception_intr_address_in<={29'b0,1'bz};/**/
//        cause_in<=4'b0000z;/**/
//    end
//    else
//    begin
//        I_or_E<=0;
//        cause_set<=1'b1;
//        mepc_set<=1'b1;
//        exception_intr_address_in<=EX_pc_31_2;
//        if(ADDR_Misallign)
//            if(prev_instr_OP[5])
//                cause_in<=4'b0110;//Store address misallign exception
//            else
//                cause_in<=4'b0100;//Load address misallign exception
//        else if(is_ecall_ebreak)
//            cause_in<=4'b1011; //ecall exceptionn
//        else
//            cause_in<=4'b0010;//Illegal instruction exception
//    end
//end 

always@(negedge clk)
begin
    case(prev_instr_OP)
        7'b0000011://Load
            case(prev_instr_funct3_1_0)
                2'b10://lw
                    ADDR_Misallign=(Result_1_0[0] || Result_1_0[1]);
                2'b01://lh,lhu
                    ADDR_Misallign=Result_1_0[0];
            endcase
        7'b0100011://Store
            case(prev_instr_funct3_1_0)
                2'b10://sw
                    ADDR_Misallign=(Result_1_0[0] || Result_1_0[1]);
                2'b01://sh
                    ADDR_Misallign=Result_1_0[0];
            endcase
        default:
            ADDR_Misallign<=1'b0;
    endcase
end

always@(*)
begin
    if(is_mret)
    begin
        cause_set<=1'b0;
        mepc_set<=1'b0;   
        I_or_E<=1'bz;/**/
        exception_intr_address_in<={29'b0,1'bz};/**/
        cause_in<=4'b0000z;/**/
    end
    else if(!ADDR_Misallign & !is_ecall_ebreak & !is_illegal_instr)
    begin
        cause_set<=1'b0;
        mepc_set<=1'b0;   
        I_or_E<=1'bz;/**/
        exception_intr_address_in<={29'b0,1'bz};/**/
        cause_in<=4'b0000z;/**/
    end
    else
    begin
        I_or_E<=0;
        cause_set<=1'b1;
        mepc_set<=1'b1;
        exception_intr_address_in<=EX_pc_31_2;
        if(ADDR_Misallign)
            if(prev_instr_OP[5])
                cause_in<=4'b0110;//Store address misallign exception
            else
                cause_in<=4'b0100;//Load address misallign exception
        else if(is_ecall_ebreak)
            cause_in<=4'b1011; //ecall exceptionn
        else
            cause_in<=4'b0010;//Illegal instruction exception
    end
end 

/*Component instantiations*/
reg_file reg_file(.clk(clk),.reg_out_1(reg_read_data1),.reg_out_2(reg_read_data2),.reg_addr1(Ra),.reg_addr2(Rb),.reg_write_addr(reg_write_addr),.reg_wr(reg_wr),.reg_din(reg_write_data));
sign_ext sign_ext(.clk(clk),.instr(instr),.IF_ID_Write(IF_ID_Write),.imm_ext(imm_ext));


endmodule