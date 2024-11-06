`ifndef CSR_ADDR
`define CSR_ADDR

// Machine Trap Setup
`define MSTATUS         12'h300
`define MISA            12'h301
`define MIE             12'h304
`define MTVEC           12'h305

// Machine Trap Handling
`define MSCRATCH        12'h340
`define MEPC            12'h341
`define MCAUSE          12'h342
`define MTVAL           12'h343
`define MIP             12'h344

//CSR funct3
`define CSRRW           2'b01
`define CSRRS           2'b10 
`define CSRRC           2'b11

//Trap Address
`define TRAP_ADDR       30'b00000000000000000000000000001 

`endif