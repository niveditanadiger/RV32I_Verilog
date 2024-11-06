`timescale 1ns/1ns

module EX(clk,A,B,imm_ext,Instr,ALUSrc,is_Branch,ALUOp,EX_Result,Branch_taken,pc,target_pc,mem_data_write,ForwardA,ForwardB,EX_MEM_res,MEM_WB_res,CSR_ADDR,CSR_funct3,CSR_re_enable,CSR_wr_enable,EX_res_select,I_or_E,cause_in,cause_set,mepc_set,exception_intr_address_in,Result_1_0,EPC_OUT,Take_trap,MTVEC,is_mret,Trap_Return);

input clk;
input is_Branch;
input[1:0] ALUSrc;
input [31:0]A,B,Instr;
input [1:0]ALUOp;
input [31:0]imm_ext,pc;
input EX_res_select;


/*Interfaces to Forwarding Unit*/
input [1:0]ForwardA,ForwardB;
input [31:0]EX_MEM_res,MEM_WB_res;


/*Interfaces to CSR Unit*/
input [11:0]CSR_ADDR;
input [2:0]CSR_funct3;
input CSR_re_enable;
input CSR_wr_enable;
input I_or_E;
input is_mret;
input [3:0]cause_in;
input cause_set,mepc_set;
input [29:0]exception_intr_address_in;


/*Outputs of EX stage*/
output [31:0]EX_Result;
output [31:0]target_pc;
output [31:0]mem_data_write;
output reg Branch_taken;
output [1:0]Result_1_0;
output [31:0]EPC_OUT;
output [31:0]MTVEC;
output Take_trap;
output Trap_Return;


/*Internal wires and reg's*/
wire [3:0]ALU_SEL;
reg [31:0]operand1,operand2;
reg [31:0]inp1,inp2;
wire [31:0]inp_A_final,inp_B_final;
wire zero;
wire [31:0]CSR_DATA_OUT;
wire [31:0]Result;

/*ALU Unit and ALU-Control-Unit*/
alu_control alu_control(.func_field({Instr[31:25],Instr[14:12]}),.ALUOp(ALUOp),.ALU_SEL(ALU_SEL)); 
ALU_32bit alu(.ALU_SEL(ALU_SEL),.A(inp_A_final),.B(inp_B_final),.ALU_OUT(Result),.carry(),.zero(zero),.negative(),.overflow(),.underflow());


/*CSR Unit*/
CSR CSR(.clk(clk),.CSR_ADDR(CSR_ADDR),.CSR_DATA_IN(inp2),.CSR_funct3(CSR_funct3),.re_enable(CSR_re_enable),.wr_enable(CSR_wr_enable),.cause_in(cause_in),.cause_set(cause_set),.I_or_E_in(I_or_E),.mepc_set(mepc_set),.exception_intr_address_in(exception_intr_address_in),.CSR_DATA_OUT(CSR_DATA_OUT),.EPC_OUT(EPC_OUT),.Take_trap(Take_trap),.MTVEC(MTVEC),.is_mret(is_mret),.Trap_Return(Trap_Return));
                                                    

/*Forwarding Unit*/
always@(*)
begin
    case(ForwardA)
        2'b00:  begin if(ALUSrc==2'b10)inp1=A; else inp1=operand1; end
        2'b10:  inp1=EX_MEM_res;
        2'b01:  inp1=MEM_WB_res;
        default: inp1=32'b0;/**/
    endcase
    case(ForwardB)
        2'b00:  inp2=operand2;
        2'b10:  inp2=EX_MEM_res;
        2'b01:  inp2=MEM_WB_res;
        default: inp2=32'b0;/**/
    endcase
end
assign inp_A_final = (ALUSrc==2'b10) ? operand1 : inp1;
assign inp_B_final = (ALUSrc==2'b01) ? operand2 : inp2;
assign mem_data_write = (ForwardB==2'b00) ? B : inp2;//for store instructions, data in Rs2 is the store value(Done to implement forwarding for store value)

/*choose operand1 and operand2*/
//operand1: pc ,A,0
//operand2: imm_ext,B,4
    //lui: 0+imm_ext :11 instr[5]=1
    //R or branch :A+B :00
    //auipc: pc+imm_ext :11 instr[5]=0
    //UJ: pc+4 :10
    //I or lw or sw: A+imm_ext :01
always@(*)
begin
    case(ALUSrc)
        2'b00: //R-type or SB-type
            begin
                operand1=A;
                operand2=B;
            end 
        2'b01: //I-type(incl lw) or S-type 
            begin
                operand1=A;
                operand2=imm_ext;
            end 
        2'b10: //jal or jalr
            begin
                operand1=pc;
                operand2=4;
            end 
        2'b11: //U-type 
            begin
                operand1=Instr[5]?0:pc;
                operand2=imm_ext;
            end 
        default: begin 
                    operand1=A;    
                    operand2=B;
                 end
      endcase
end


/*EX Stage Outputs*/
assign EX_Result=(EX_res_select)?Result:CSR_DATA_OUT;
assign Result_1_0=Result[1:0];


//Adder for branch target address calculation
assign target_pc = (Branch_taken)? ((ALUSrc==2'b10 && ~Instr[3])? (inp1 + imm_ext):(pc + (imm_ext<<1))):32'b0;//imm is twice the number of instructions we want to jump //jal and branch


//Is branch taken? {and gate}
always @(*) 
    begin
        if(ALUSrc==2'b10) //UJ type(jal),I type(jalr)
            Branch_taken=is_Branch;
        else
           case (Instr[14:12])//funct3
                   3'b000: Branch_taken = is_Branch & zero;//eq
                   3'b001: Branch_taken = is_Branch & ~zero;//ne
                   3'b100: Branch_taken = is_Branch & Result[0];//lt
                   3'b101: Branch_taken = is_Branch & ~Result[0];//ge
                   3'b110: Branch_taken = is_Branch & Result[0];//ltu
                   3'b111: Branch_taken = is_Branch & ~Result[0];//geu
                   default: Branch_taken = 1'b0;
            endcase
    end


endmodule