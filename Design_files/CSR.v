`timescale 1ns/1ns
`include "CSR_ADDR.vh"

module CSR(clk,CSR_ADDR,CSR_DATA_IN,CSR_funct3,re_enable,wr_enable,cause_in,cause_set,I_or_E_in,mepc_set,exception_intr_address_in,CSR_DATA_OUT,EPC_OUT,Take_trap,MTVEC,is_mret,Trap_Return);

input clk,I_or_E_in;
//input S_irq,E_irq,T_irq;
input [3:0]cause_in;
input [11:0]CSR_ADDR;
input [31:0]CSR_DATA_IN;
input [2:0]CSR_funct3;
input re_enable,wr_enable;
input cause_set,mepc_set,is_mret;
input [29:0]exception_intr_address_in;
output reg [31:0]CSR_DATA_OUT;
output [31:0]EPC_OUT;
output Take_trap;
output Trap_Return;


/*CSR Registers*/
wire [31:0]MSTATUS;
wire [31:0]MISA;
/*
reg [31:0]MIE;
reg [31:0]MIP;
*/
wire [31:0]MCAUSE;
output [31:0]MTVEC;
wire [31:0]MEPC;
reg [31:0]MTVAL;
/*
reg [31:0]MSCRATCH;
reg [31:0]MCYCLE,MCYCLEH;
reg [31:0]MINSTRET,MINSTRETH;
//Hardwire the following to zero
reg [31:0]MVENDORID;
reg [31:0]MARCHID;
reg [31:0]MIMPID;
reg [31:0]MHARTID;
*/
/*Internal*/

reg mpie;
reg mie;
wire mie_set=1'b0;
wire mie_clear=1'b0; 
wire [1:0]mxl;
wire [25:0]mextensions;
reg [29:0]trap_addr;
/*
reg meie,mtie,msie;
reg meip,mtip,msip;
*/
reg I_or_E;
reg [26:0]cause_ext;
reg [3:0]cause;
reg [29:0]exception_intr_address;
wire [31:0]write_value_final;


/*write logic*/
assign write_value_final = (CSR_funct3[1:0]==`CSRRW)? CSR_DATA_IN : ((CSR_funct3[1:0]==`CSRRS)?(CSR_DATA_OUT | CSR_DATA_IN) : ((CSR_funct3[1:0]==`CSRRC)?(CSR_DATA_OUT & ~CSR_DATA_IN) : 32'b0));

/*
//MSTATUS(Machine Status, contains global intterupt enable bits)
always@(*)
begin
                   //MPP 
    MSTATUS={19'b0,2'b11,3'b0,mpie,3'b0,mie,3'b0};
    if(CSR_ADDR==`MSTATUS && re_enable)  //Note: re_enable and wr_enable signals are used bcoz in some cases these operations have to be stopped
        CSR_DATA_OUT=MSTATUS;
end
always@(negedge clk)
begin   
    if(CSR_ADDR==`MSTATUS && wr_enable)
        begin
            mpie<=write_value_final[7]; 
            mie<=write_value_final[3];
        end
    if(mie_set)
        begin
            mie<=mpie;
            mpie<=1'b1;
        end
    if(mie_clear)
        begin
            mpie<=mie; 
            mie<=1'b0; 
        end
end

//MIE(Machine Interrupts Enabled)
always @(*)
begin //probably as there are no external devices, meie may not be required.
    MIE={20'b0,meie,3'b0,mtie,3'b0,msie,3'b0};
    if(CSR_ADDR==`MIE && re_enable)
        CSR_DATA_OUT=MIE;
end
always@(negedge clk) 
begin
    if(CSR_ADDR==`MIE && wr_enable)
        begin
            meie=write_value_final[11];
            mtie=write_value_final[7];
            msie=write_value_final[3];
        end
end

//MIP(Machine Intterupts Pending)
always@(*) 
begin
    MIP={20'b0,meip,3'b0,mtip,3'b0,msip,3'b0};
    if(CSR_ADDR=`MIP && re_enable) 
    begin
        CSR_DATA_OUT=MIP;
    end   
end
always@(negedge clk)
begin
    meip<=E_irq;
    mtip<=T_irq;
    msip<=S_irq;
end
*/

/*CSR_DATA_OUT assignment*/
always@(posedge re_enable)/**/
begin
    if(re_enable)
    begin
        
        if(CSR_ADDR==`MCAUSE)
            CSR_DATA_OUT=MCAUSE;
        else if(CSR_ADDR==`MTVEC)
            CSR_DATA_OUT=MTVEC;
        else if(CSR_ADDR==`MTVAL)
            CSR_DATA_OUT=MTVAL;
        else if(CSR_ADDR==`MEPC)
            CSR_DATA_OUT=MEPC;
        else if(CSR_ADDR==`MSTATUS)
            CSR_DATA_OUT=MSTATUS;
        else if(CSR_ADDR==`MISA)
            CSR_DATA_OUT=MISA;
        else
            CSR_DATA_OUT=32'b0; /**/
    end
    else
        CSR_DATA_OUT=32'b0; /**/
end

//MSTATUS(Machine Status, contains global intterupt enable bits)
initial begin mpie=1'b1;  mie=1'b0; end /**/
assign MSTATUS={19'b0,2'b11,3'b0,mpie,3'b0,mie,3'b0};
always@(negedge clk)
begin
    if(mie_set)
        begin
            mie<=mpie;
            mpie<=1'b1;
        end
    else if(mie_clear)
        begin
            mpie<=mie; 
            mie<=1'b0; 
        end
     else if(CSR_ADDR==`MSTATUS && wr_enable)
        begin
            mpie<=write_value_final[7]; 
            mie<=write_value_final[3];
        end
end

//MISA
assign mxl = 2'b01;
assign mextensions = 26'b00000000000000000100000000;
assign MISA = {mxl, 4'b0, mextensions};

//MCAUSE(Machine Trap Cause)
assign MCAUSE={I_or_E,cause_ext,cause};
always@(negedge clk) /**/
begin
    if(cause_set)//cause set has a higher priority over cause write
    begin
        I_or_E=I_or_E_in;
        cause_ext=27'b0;
        cause=cause_in;
    end
    else if(CSR_ADDR==`MCAUSE && wr_enable)
    begin
        I_or_E<=write_value_final[31];
        cause_ext<=write_value_final[30:4];
        cause<=write_value_final[3:0];
    end
end


//MTVEC(Machine Trap Vector Address)
assign MTVEC={trap_addr,2'b0}; //Only Base mode implemented
always@(negedge clk) /**/
begin
    if(CSR_ADDR==`MTVEC && wr_enable)
    begin
        trap_addr<=write_value_final[31:2];
    end
end


//MTVAL(Machine Trap Value)
initial MTVAL=32'b0;//Currently not storing info specific to any particular kind of exception! Maybe used in future to display the kind of exception /**/
always@(negedge clk) /**/
begin
    if(CSR_ADDR==`MTVAL && wr_enable)
    begin
        MTVAL<=write_value_final;
    end
    /*
    if(MISALLIGNED_EXCEPTION)
       MTVAL=MISALLIGNED_ADDRESS;  
    */
end

//MEPC(Machine exception Program Counter)
assign EPC_OUT = MEPC;
assign Take_trap = mepc_set;
assign Trap_Return = is_mret;
assign  MEPC={exception_intr_address,2'b0};
always@(negedge clk) /**/
begin
    if(mepc_set)
        exception_intr_address=exception_intr_address_in;   
    else if(CSR_ADDR==`MEPC && wr_enable)
    begin
        exception_intr_address=write_value_final[31:2];
    end    
end

endmodule


