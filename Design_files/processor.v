`timescale 1ns/1ns
module processor #(parameter BOOT_ADDRESS=32'b0)
                  (clk,rst,data_in,instr_in,mem_read_ctrl,mem_write_ctrl,address_out,data_out,addr_allign,B,H,instr_addr);
input clk,rst;
input [31:0]data_in;
input [31:0]instr_in;
output wire mem_read_ctrl,mem_write_ctrl;
output wire [31:0]data_out;
output wire [31:0]address_out;
output wire [1:0]addr_allign;
output wire B,H;
output wire [14:0]instr_addr;


/*pipeline registers for storing data*/
wire [31:0]IF_ID_wire[0:1];                    //index0=instruction ,index1=pc 
assign IF_ID_wire[0]=instr_in;
reg [31:0]IF_ID[0:1];

wire [31:0]ID_EX_wire[0:4];                    //index0=instruction ,index1=Read_out_1 ,index2=Read_out2 , index3=imm_ext , index4=pc 
reg [31:0]ID_EX[0:4];

wire [31:0]EX_MEM_wire[0:2];                   //index0=UNUSED ,index1=ALUresult ,index2=forwarded store data 
reg [31:0]EX_MEM[0:2];                         //index0=instruction ,index1=ALUresult ,index2=MEM_data_in_for_store 

wire [31:0]MEM_WB_wire[0:2];                   //index0=UNUSED ,index1=UNUSED ,index2=MEM_read_data 
reg [31:0]MEM_WB[0:2];                         //index0=instruction ,index1=ALUresult ,index2=MEM_read_data

/*pipeline registers to store control signals*/
wire ID_EX_ctrl_wire[0:11];                          //index0=ALU_src[0], index1 and 2=ALUOp, index3=mem_write, index4=mem_Read, index5=mem_to_reg, index6=Reg_write, index7=ALUSrc[1] ,index8=Branch ,index9=CSR_re_enable ,index10=CSR_wr_enable ,index11=EX_res_select
reg ID_EX_ctrl[0:11];
reg EX_MEM_ctrl[0:3];                               //index0=mem_write, index1=mem_Read, index2=mem_to_reg, index3=Reg_write
wire Branch_taken;
wire [31:0]target_pc;
reg MEM_WB_ctrl[0:1];                               //index0=mem_to_reg, index1=Reg_write

/*Pipeline registers to store the address of the register operands [Data forwarding/stalling to avoid data hazards]*/
wire [1:0]ForwardA,ForwardB;                //Select lines for the multiplexors-->input to the ALU

/*pipeline register operands*/ 
wire [4:0]IF_ID_register_wire[2:0];                 
reg [4:0]IF_ID_register[2:0];                      // index0=Ra , index1=Rb , index2=Rd
wire [4:0]ID_EX_register_wire[2:0];
reg [4:0]ID_EX_register[2:0];                      // index0=Ra , index1=Rb , index2=Rd
reg [4:0]EX_MEM_register;                          //pipelined destination register Rd
reg [4:0]MEM_WB_register;                          //pipelined destination register Rd

/*control signals to deal with load-use data hazards*/
wire PCWrite,IF_ID_Write,select_control_unit;

/*Pipeline registers for CSR Unit*/
wire [11:0]CSR_ADDR_wire;   
wire [2:0]CSR_funct3_wire;  
wire cause_set_wire,mepc_set_wire,I_or_E_wire;
wire [3:0]cause_in_wire;
reg [18:0]IF_ID_CSR;    //[18]:is_illegal_instr   [17:6]: CSR_ADDR    [5:3]: CSR_funct3     [2:0]:is_mret,is_fence,is_ecall_ebreak
reg [24:0]ID_EX_CSR;    //[23:20]:cause_in      [19]:cause_set      [18]:mepc_set       [17]:I_or_E         [16:5]: CSR_ADDR    [4:2]: CSR_funct3     [1:0]:is_mret,is_ecall_ebreak
wire [29:0]exception_intr_address_in_wire;
reg [29:0]exception_intr_address_in;


/*Internal wires and registers*/
wire [31:0]temp1;
wire [1:0]Result_1_0;
wire [31:0]EPC_OUT;
wire [31:0]MTVEC;
wire Take_trap;
wire I_or_E_occurred,ADDR_Misallign;
wire is_mret_wire,is_fence_wire,is_ecall_ebreak_wire,is_illegal_instr;
wire Trap_Return;


/*Stages Instantiation*/
IF #(.BOOT_ADDRESS(BOOT_ADDRESS))IF(.clk(clk),.rst(rst),.instr(IF_ID_wire[0]),.pc(IF_ID_wire[1]),.target_pc(target_pc),.Branch_taken(Branch_taken),.EPC_OUT(EPC_OUT),.Take_trap(Take_trap),.MTVEC(MTVEC),.PCWrite(PCWrite),.Ra(IF_ID_register_wire[0]),.Rb(IF_ID_register_wire[1]),.Rd(IF_ID_register_wire[2]),.Trap_Return(Trap_Return),.CSR_ADDR(CSR_ADDR_wire),.CSR_funct3(CSR_funct3_wire),.is_mret(is_mret_wire),.is_fence(is_fence_wire),.is_ecall_ebreak(is_ecall_ebreak_wire),.is_illegal_instr(is_illegal_instr));
control_unit control(.Op(IF_ID[0][6:0]),.CSR_RW_RSC_select(IF_ID[0][13]),.CSR_reg_imm_select(IF_ID[0][14]),.CSR_src(IF_ID[0][19:15]),.CSR_dest(IF_ID[0][11:7]),.RegWrite(ID_EX_ctrl_wire[6]),.ALUOp({ID_EX_ctrl_wire[1],ID_EX_ctrl_wire[2]}),.MemRead(ID_EX_ctrl_wire[4]),.MemWrite(ID_EX_ctrl_wire[3]),.MemtoReg(ID_EX_ctrl_wire[5]),.is_Branch(ID_EX_ctrl_wire[8]),.ALUSrc({ID_EX_ctrl_wire[0],ID_EX_ctrl_wire[7]}),.EX_res_select(ID_EX_ctrl_wire[11]),.CSR_re_enable(ID_EX_ctrl_wire[9]),.CSR_wr_enable(ID_EX_ctrl_wire[10]),.select_control_unit(select_control_unit));
ID ID(.clk(clk),.EX_pc(ID_EX[4]),.reg_write_data(temp1),.reg_wr(MEM_WB_ctrl[1]),.reg_write_addr(MEM_WB_register),.reg_read_data1(ID_EX_wire[1]),.reg_read_data2(ID_EX_wire[2]),.instr(IF_ID[0]),.Ra(IF_ID_register[0]),.Rb(IF_ID_register[1]),.imm_ext(ID_EX_wire[3]),.I_or_E(I_or_E_wire),.cause_in(cause_in_wire),.cause_set(cause_set_wire),.mepc_set(mepc_set_wire),.exception_intr_address_in(exception_intr_address_in_wire),.Result_1_0(Result_1_0),.I_or_E_occurred(I_or_E_occurred),.is_mret(IF_ID_CSR[2]),.is_ecall_ebreak(IF_ID_CSR[0]),.Take_trap(Take_trap),.is_illegal_instr(IF_ID_CSR[18]),.ADDR_Misallign(ADDR_Misallign));
hazard_detection_unit hazard_detection(.ID_EX_MEMRead(ID_EX_ctrl[4]),.ID_EX_RegisterRd(ID_EX_register[2]),.IF_ID_RegisterRs1(IF_ID_register[0]),.IF_ID_RegisterRs2(IF_ID_register[1]),.PCWrite(PCWrite),.IF_ID_Write(IF_ID_Write),.select_control_unit(select_control_unit),.is_fence(IF_ID_CSR[1]));
EX EX(.clk(clk),.A(ID_EX[1]),.B(ID_EX[2]),.imm_ext(ID_EX[3]),.Instr(ID_EX[0]),.ALUSrc({ID_EX_ctrl[0],ID_EX_ctrl[7]}),.is_Branch(ID_EX_ctrl[8]),.ALUOp({ID_EX_ctrl[1],ID_EX_ctrl[2]}),.EX_Result(EX_MEM_wire[1]),.Branch_taken(Branch_taken),.pc(ID_EX[4]),.target_pc(target_pc),.mem_data_write(EX_MEM_wire[2]),.ForwardA(ForwardA),.ForwardB(ForwardB),.EX_MEM_res(EX_MEM[1]),.MEM_WB_res(temp1),.CSR_ADDR(ID_EX_CSR[16:5]),.CSR_funct3(ID_EX_CSR[4:2]),.CSR_re_enable(ID_EX_ctrl[9]),.CSR_wr_enable(ID_EX_ctrl[10]),.EX_res_select(ID_EX_ctrl[11]),.I_or_E(ID_EX_CSR[17]),.cause_in(ID_EX_CSR[23:20]),.cause_set(ID_EX_CSR[19]),.mepc_set(ID_EX_CSR[18]),.exception_intr_address_in(exception_intr_address_in),.Result_1_0(Result_1_0),.EPC_OUT(EPC_OUT),.Take_trap(Take_trap),.MTVEC(MTVEC),.is_mret(ID_EX_CSR[1]),.Trap_Return(Trap_Return));
Forwarding_unit Forwarding_unit(.Op(ID_EX[0][6:0]),.CSR_Rs(!ID_EX[0][14]),.EX_MEM_Rd(EX_MEM_register),.MEM_WB_Rd(MEM_WB_register),.ID_EX_Rs1(ID_EX_register[0]),.ID_EX_Rs2(ID_EX_register[1]),.EX_MEM_reg_wr(EX_MEM_ctrl[3]),.MEM_WB_reg_wr(MEM_WB_ctrl[1]),.ForwardA(ForwardA),.ForwardB(ForwardB));
MEM MEM(.mem_address_1_0(EX_MEM[1][1:0]),.in_data_read(data_in),.funct(EX_MEM[0][14:12]),.mem_data_read(MEM_WB_wire[2]),.addr_allign(addr_allign),.B(B),.H(H));
WB WB(.mem_to_reg(MEM_WB_ctrl[0]),.Mem_read_out(MEM_WB[2]),.ALUresult(MEM_WB[1]),.out(temp1));


/*Outputs of the Core*/
assign mem_read_ctrl=EX_MEM_ctrl[1];
assign mem_write_ctrl=EX_MEM_ctrl[0];
assign data_out=(EX_MEM_ctrl[0])?EX_MEM[2]:32'b0; 
assign address_out=(EX_MEM_ctrl[0]|EX_MEM_ctrl[1])?EX_MEM[1]:32'b0;
assign instr_addr=IF_ID_wire[1][16:2];

/*Pipelining*/ 
//synchronous reset
always@(posedge clk) begin
            if(rst)
            begin
                {IF_ID[0],IF_ID[1]}<={32'b0,32'h0000000z};
                {ID_EX[0],ID_EX[1],ID_EX[2],ID_EX[3],ID_EX[4]}<={32'b0,32'h0000000z,32'h0000000z,32'h0000000z,32'h0000000z}; //not sure if pc=ID_EX[4] shd be z or no!
                {EX_MEM[0],EX_MEM[1],EX_MEM[2]}<={32'b0,32'h0000000z,32'h0000000z};
                {MEM_WB[0],MEM_WB[1],MEM_WB[2]}<={32'b0,32'h0000000z,32'h0000000z};
                {ID_EX_ctrl[0],ID_EX_ctrl[1],ID_EX_ctrl[2],ID_EX_ctrl[3],ID_EX_ctrl[4],ID_EX_ctrl[5],ID_EX_ctrl[6],ID_EX_ctrl[7],ID_EX_ctrl[8],ID_EX_ctrl[9],ID_EX_ctrl[10],ID_EX_ctrl[11]}<={1'b0,1'b0,1'bz,1'b0,1'b0,1'bz,1'b0,1'bz,1'b0,1'b0,1'b0,1'b0};
                {EX_MEM_ctrl[0],EX_MEM_ctrl[1],EX_MEM_ctrl[2],EX_MEM_ctrl[3]}<={1'b0,1'b0,1'bz,1'b0};
                {MEM_WB_ctrl[0],MEM_WB_ctrl[1]}<={1'bz,1'b0};
                {IF_ID_register[0],IF_ID_register[1],IF_ID_register[2]}<={5'b0000z,5'b0000z,5'b0000z};
                {ID_EX_register[0],ID_EX_register[1],ID_EX_register[2],EX_MEM_register,MEM_WB_register}<={5'b0000z,5'b0000z,5'b0000z,5'b0000z,5'b0000z};
                {ID_EX_CSR[16:5],ID_EX_CSR[4:2],ID_EX_CSR[19],ID_EX_CSR[18],ID_EX_CSR[17],ID_EX_CSR[23:20],exception_intr_address_in}<={12'b0,3'b0,1'b0,1'b0,1'bz,4'b0,{29'b0,1'bz}};
                {ID_EX_CSR[1],ID_EX_CSR[0]}<={1'b0,1'b0};
                {IF_ID_CSR[18],IF_ID_CSR[17:6],IF_ID_CSR[5:3],IF_ID_CSR[2],IF_ID_CSR[1],IF_ID_CSR[0]}<={1'b0,12'b0,3'b0,1'b0,1'b0,1'b0};
            end
            else if(I_or_E_occurred)
            begin
                if(ADDR_Misallign)
                begin
                    {EX_MEM[0],EX_MEM[1],EX_MEM[2]}<={32'b0,32'h0000000z,32'h0000000z};
                    {EX_MEM_ctrl[0],EX_MEM_ctrl[1],EX_MEM_ctrl[2],EX_MEM_ctrl[3]}<={1'b0,1'b0,1'bz,1'b0};
                    {EX_MEM_register}<={5'b0000z};
                end
                else
                begin
                    {EX_MEM[0],EX_MEM[1],EX_MEM[2]}<={ID_EX[0],EX_MEM_wire[1],EX_MEM_wire[2]};
                    {EX_MEM_ctrl[0],EX_MEM_ctrl[1],EX_MEM_ctrl[2],EX_MEM_ctrl[3]}<={ID_EX_ctrl[3],ID_EX_ctrl[4],ID_EX_ctrl[5],ID_EX_ctrl[6]};
                    {EX_MEM_register}<={ID_EX_register[2]};
                end
                {IF_ID[0],IF_ID[1]}<={32'b0,32'h0000000z};
                {ID_EX[0],ID_EX[1],ID_EX[2],ID_EX[3],ID_EX[4]}<={32'b0,32'h0000000z,32'h0000000z,32'h0000000z,32'h0000000z}; //not sure if pc=ID_EX[4] shd be z or no!
                {ID_EX_ctrl[0],ID_EX_ctrl[1],ID_EX_ctrl[2],ID_EX_ctrl[3],ID_EX_ctrl[4],ID_EX_ctrl[5],ID_EX_ctrl[6],ID_EX_ctrl[7],ID_EX_ctrl[8],ID_EX_ctrl[9],ID_EX_ctrl[10],ID_EX_ctrl[11]}<={1'b0,1'b0,1'bz,1'b0,1'b0,1'bz,1'b0,1'bz,1'b0,1'b0,1'b0,1'b0};
                {IF_ID_CSR[18],IF_ID_CSR[17:6],IF_ID_CSR[5:0]}<={1'b0,12'b0,6'b0};
                {ID_EX_CSR[16:5],ID_EX_CSR[4:0]}<={12'b0,5'b0};
                {IF_ID_register[0],IF_ID_register[1],IF_ID_register[2]}<={5'b0000z,5'b0000z,5'b0000z};
                {ID_EX_register[0],ID_EX_register[1],ID_EX_register[2]}<={5'b0000z,5'b0000z,5'b0000z};
                
                {MEM_WB[0],MEM_WB[1],MEM_WB[2]}<={EX_MEM[0],EX_MEM[1],MEM_WB_wire[2]};
                {MEM_WB_ctrl[0],MEM_WB_ctrl[1]}<={EX_MEM_ctrl[2],EX_MEM_ctrl[3]};
                 MEM_WB_register<=EX_MEM_register;
                {ID_EX_CSR[19],ID_EX_CSR[18],ID_EX_CSR[17],ID_EX_CSR[23:20],exception_intr_address_in}<={cause_set_wire,mepc_set_wire,I_or_E_wire,cause_in_wire,exception_intr_address_in_wire};
                
           end 
           else if(Branch_taken & ~I_or_E_occurred) 
           begin
                {IF_ID[0],IF_ID[1]}<={32'b0,32'h0000000z};
                {ID_EX[0],ID_EX[1],ID_EX[2],ID_EX[3],ID_EX[4]}<={32'b0,32'h0000000z,32'h0000000z,32'h0000000z,32'h0000000z};
                {ID_EX_ctrl[0],ID_EX_ctrl[1],ID_EX_ctrl[2],ID_EX_ctrl[3],ID_EX_ctrl[4],ID_EX_ctrl[5],ID_EX_ctrl[6],ID_EX_ctrl[7],ID_EX_ctrl[8],ID_EX_ctrl[9],ID_EX_ctrl[10],ID_EX_ctrl[11]}<={1'b0,1'b0,1'bz,1'b0,1'b0,1'bz,1'b0,1'bz,1'b0,1'b0,1'b0,1'b0};
                {IF_ID_register[0],IF_ID_register[1],IF_ID_register[2]}<={5'b0000z,5'b0000z,5'b0000z};
                {ID_EX_register[0],ID_EX_register[1],ID_EX_register[2]}<={5'b0000z,5'b0000z,5'b0000z};
                {ID_EX_CSR[16:5],ID_EX_CSR[4:2],ID_EX_CSR[19],ID_EX_CSR[18],ID_EX_CSR[17],ID_EX_CSR[23:20],exception_intr_address_in}<={12'b0,3'b0,1'b0,1'b0,1'bz,4'b0,{29'b0,1'bz}};
                {ID_EX_CSR[1],ID_EX_CSR[0]}<={1'b0,1'b0};
                {IF_ID_CSR[18],IF_ID_CSR[17:6],IF_ID_CSR[5:3],IF_ID_CSR[2],IF_ID_CSR[1],IF_ID_CSR[0]}<={1'b0,12'b0,3'b0,1'b0,1'b0,1'b0};
                
                {EX_MEM[0],EX_MEM[1],EX_MEM[2]}<={ID_EX[0],EX_MEM_wire[1],EX_MEM_wire[2]};
                {EX_MEM_ctrl[0],EX_MEM_ctrl[1],EX_MEM_ctrl[2],EX_MEM_ctrl[3]}<={ID_EX_ctrl[3],ID_EX_ctrl[4],ID_EX_ctrl[5],ID_EX_ctrl[6]};
                {EX_MEM_register}<={ID_EX_register[2]};
                {MEM_WB[0],MEM_WB[1],MEM_WB[2]}<={EX_MEM[0],EX_MEM[1],MEM_WB_wire[2]};
                {MEM_WB_ctrl[0],MEM_WB_ctrl[1]}<={EX_MEM_ctrl[2],EX_MEM_ctrl[3]};
                 MEM_WB_register<=EX_MEM_register;
           end
           else 
           begin
           if(IF_ID_Write)
               begin
                {IF_ID[0],IF_ID[1]}<={IF_ID_wire[0],IF_ID_wire[1]};
                {IF_ID_register[0],IF_ID_register[1],IF_ID_register[2]}<={IF_ID_register_wire[0],IF_ID_register_wire[1],IF_ID_register_wire[2]};
               end
           {ID_EX[0],ID_EX[1],ID_EX[2],ID_EX[3],ID_EX[4]}<={IF_ID[0],ID_EX_wire[1],ID_EX_wire[2],ID_EX_wire[3],IF_ID[1]};
           {EX_MEM[0],EX_MEM[1],EX_MEM[2]}<={ID_EX[0],EX_MEM_wire[1],EX_MEM_wire[2]};
           {MEM_WB[0],MEM_WB[1],MEM_WB[2]}<={EX_MEM[0],EX_MEM[1],MEM_WB_wire[2]};
        
           {ID_EX_ctrl[0],ID_EX_ctrl[1],ID_EX_ctrl[2],ID_EX_ctrl[3],ID_EX_ctrl[4],ID_EX_ctrl[5],ID_EX_ctrl[6],ID_EX_ctrl[7],ID_EX_ctrl[8],ID_EX_ctrl[9],ID_EX_ctrl[10],ID_EX_ctrl[11]}<={ID_EX_ctrl_wire[0],ID_EX_ctrl_wire[1],ID_EX_ctrl_wire[2],ID_EX_ctrl_wire[3],ID_EX_ctrl_wire[4],ID_EX_ctrl_wire[5],ID_EX_ctrl_wire[6],ID_EX_ctrl_wire[7],ID_EX_ctrl_wire[8],ID_EX_ctrl_wire[9],ID_EX_ctrl_wire[10],ID_EX_ctrl_wire[11]};
           {EX_MEM_ctrl[0],EX_MEM_ctrl[1],EX_MEM_ctrl[2],EX_MEM_ctrl[3]}<={ID_EX_ctrl[3],ID_EX_ctrl[4],ID_EX_ctrl[5],ID_EX_ctrl[6]};
           {MEM_WB_ctrl[0],MEM_WB_ctrl[1]}<={EX_MEM_ctrl[2],EX_MEM_ctrl[3]};
            
           {ID_EX_register[0],ID_EX_register[1],ID_EX_register[2],EX_MEM_register,MEM_WB_register}<={IF_ID_register[0],IF_ID_register[1],IF_ID_register[2],ID_EX_register[2],EX_MEM_register};
           {IF_ID_CSR[18],IF_ID_CSR[2],IF_ID_CSR[1],IF_ID_CSR[0]}<={is_illegal_instr,is_mret_wire,is_fence_wire,is_ecall_ebreak_wire};
           {IF_ID_CSR[17:6],IF_ID_CSR[5:3],ID_EX_CSR[19],ID_EX_CSR[18],ID_EX_CSR[17],ID_EX_CSR[23:20],exception_intr_address_in}<={CSR_ADDR_wire,CSR_funct3_wire,cause_set_wire,mepc_set_wire,I_or_E_wire,cause_in_wire,exception_intr_address_in_wire};
           {ID_EX_CSR[16:0]}<={IF_ID_CSR[17:2],IF_ID_CSR[0]};
           end     
end

endmodule

