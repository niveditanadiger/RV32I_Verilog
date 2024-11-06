`timescale 1ns / 1ns
`include "CSR_ADDR.vh"

module compliance_tb();

    reg clk;
    reg rst;              
    reg [31:0] instr;
    reg [31:0] data_in;   

    //assuming o/ps of processor should be wires
    wire [10:0] address_out;
    wire [31:0] data_out;
    wire [1:0]addr_allign;
    wire B;
    wire H;
    wire [10:0]instr_addr;
    wire mem_read_ctrl;
    wire mem_write_ctrl;


reg [8*50:0] tests[0:41]={

    "add-01.elf.mem",
    "addi-01.elf.mem",
    "and-01.elf.mem",
    "andi-01.elf.mem",
    "auipc-01.elf.mem",
    "beq-01.elf.mem",
    "bge-01.elf.mem",
    "bgeu-01.elf.mem",
    "blt-01.elf.mem",
    "bltu-01.elf.mem",
    "bne-01.elf.mem",
    "jal-01.elf.mem",
    "jalr-01.elf.mem",
    "lb-align-01.elf.mem",
    "lbu-align-01.elf.mem",
    "lh-align-01.elf.mem",
    "lhu-align-01.elf.mem",
    "lui-01.elf.mem",
    "lw-align-01.elf.mem",
    "or-01.elf.mem",
    "ori-01.elf.mem",
    "sb-align-01.elf.mem",
    "sh-align-01.elf.mem",
    "sll-01.elf.mem",
    "slli-01.elf.mem",
    "slt-01.elf.mem",
    "slti-01.elf.mem",
    "sltiu-01.elf.mem",
    "sltu-01.elf.mem",
    "sra-01.elf.mem",
    "srai-01.elf.mem",
    "srl-01.elf.mem",
    "srli-01.elf.mem",
    "sub-01.elf.mem",
    "sw-align-01.elf.mem",
    "xor-01.elf.mem",
    "xori-01.elf.mem",

    "misalign-lh-01.elf.mem",
    "misalign-lhu-01.elf.mem",
    "misalign-lw-01.elf.mem",
    "misalign-sh-01.elf.mem",
    "misalign-sw-01.elf.mem"

    /*
    "I-RF_x0-01.elf.mem",
    "I-RF_width-01.elf.mem",
    "I-RF_size-01.elf.mem",
    "I-ENDIANESS-01.elf.mem",

    "I-CSRRC-01.elf.mem",
    "I-CSRRCI-01.elf.mem",
    "I-CSRRS-01.elf.mem",
    "I-CSRRSI-01.elf.mem",
    "I-CSRRW-01.elf.mem",
    "I-CSRRWI-01.elf.mem"
    */

};

reg [8*256:0] signatures [0:41] = {
    "compliance/add-01.signature.output",
    "compliance/addi-01.signature.output",
    "compliance/and-01.signature.output",
    "compliance/andi-01.signature.output",
    "compliance/auipc-01.signature.output",
    "compliance/beq-01.signature.output",
    "compliance/bge-01.signature.output",
    "compliance/bgeu-01.signature.output",
    "compliance/blt-01.signature.output",
    "compliance/bltu-01.signature.output",
    "compliance/bne-01.signature.output",
    "compliance/jal-01.signature.output",
    "compliance/jalr-01.signature.output",
    "compliance/lb-align-01.signature.output",
    "compliance/lbu-align-01.signature.output",
    "compliance/lh-align-01.signature.output",
    "compliance/lhu-align-01.signature.output",
    "compliance/lui-01.signature.output",
    "compliance/lw-align-01.signature.output",
    "compliance/or-01.signature.output",
    "compliance/ori-01.signature.output",
    "compliance/sb-align-01.signature.output",
    "compliance/sh-align-01.signature.output",
    "compliance/sll-01.signature.output",
    "compliance/slli-01.signature.output",
    "compliance/slt-01.signature.output",
    "compliance/slti-01.signature.output",
    "compliance/sltiu-01.signature.output",
    "compliance/sltu-01.signature.output",
    "compliance/sra-01.signature.output",
    "compliance/srai-01.signature.output",
    "compliance/srl-01.signature.output",
    "compliance/srli-01.signature.output",
    "compliance/sub-01.signature.output",
    "compliance/sw-align-01.signature.output",
    "compliance/xor-01.signature.output",
    "compliance/xori-01.signature.output",


    "compliance/misalign-lh-01.signature.output",
    "compliance/misalign-lhu-01.signature.output",
    "compliance/misalign-lw-01.signature.output",
    "compliance/misalign-sh-01.signature.output",
    "compliance/misalign-sw-01.signature.output"

};

    



processor #(.BOOT_ADDRESS(32'h00000000)) 
    processor(
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .instr_in(instr),
        .mem_read_ctrl(mem_read_ctrl),
        .mem_write_ctrl(mem_write_ctrl),
        .address_out(address_out),
        .data_out(data_out),
        .addr_allign(addr_allign),
        .B(B),
        .H(H),
        .instr_addr(instr_addr)
        );


    reg [31:0] dmem_ram [0:2047];   //8KB RAM   [8192/4=2048]
    reg [31:0] imem_ram [0:511];    //2KB ROM   [2048/4=512]  /**/
    integer f;
    integer i;
    integer j;
    integer k;
    integer m;
            
    always
        begin
            #10 clk = ~clk;/**/
        end

    initial 
        begin
            for( k=0 ; k<42 ; k=k+1 )
                begin
                    //LOADS PROGRAM INTO INSTRUCTION MEMORY
                    for(i = 0; i < 512; i=i+1) 
                        imem_ram[i] = 32'b0;                //Clear imem_ram before next test enters it
                    $display("Running %s...", tests[k]);
                    
                    f = $fopen(signatures[k], "w");
                    $readmemh(tests[k],imem_ram);         //42 instructions are stored in imem_ram from tests(.elf.mem files) one after the other


                    //INITIAL VALUES
                    rst=1'b0;/**/
                    clk=1'b0;

                    //RESET
                    #5  rst=1'b1;
                    #15 rst=1'b0;

                    // one second loop
                    for(j = 0; j < 50000000; j = j + 1)
                    begin
                        #20;
                        /*repair
                        if(mem_write_ctrl == 1'b1)
                        begin           
                            m = 0;
                            for(m = 0; m < 2048; m=m+1)
                            begin
                                $fwrite(f, "%h\n", dmem_ram[m]);
                                $display("%h\n", dmem_ram[m]); 
                            end
                            #20;
                            j = 50000000;
                        end
                        */
                    end
                                
                    $fclose(f);
                end
                $display("All signatures generated. Run the verify.sh script located inside the compliance folder.");
        end

/*Repair
    always @(posedge clk or posedge rst)
    begin
        if(rst)
            begin
                instr = imem_ram[instr_addr];
                data_in = dmem_ram[address_out];
            end
        else
            begin            
                instr = imem_ram[instr_addr];
                data_in = dmem_ram[address_out];            
            end
    end
*/
endmodule

