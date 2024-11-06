# RV32I_Verilog
The repository is an implementation of a RV32I processor using Verilog HDL.
It is a 5 stage pipelined processor with the following stages(IF, ID, EX, MEM, WB) with a maximum clock frequency of 160MHz.
The Control mechanism is implemented using a hierarchical approach i.e. first we generate something called as global control signals(scope is the entire processor) and then we generate local control signals(scope limited to a particular stage only).
There are two memory modules a data memory and an instruction memory. The former is modelled as a ROM and the latter as RAM.
A UART is also integrated in the SOC to view the outputs on a console.
The implementation also supports hazard detection and stalling to remove data hazards and to deal with data dependencies. The design is capable of detecting a few exceptions like address-misalign and illegal-instruction. If any exception is detected, it performs relevant jumps to certain routines and returns back.
A custom instruction "MRSWP" is also implemented in the design to accelerate memory swap instructions in sorting algorithms.
The SOC consisting of a core, data memory, instruction memory, bus arbiter and a uart is synthesised succefully without any errors. 

To Run Compliance Tests:
You can replace the file <debugger.txt> in Instruction_mem.v for different tests. A few sample files for the same are available in the folder: Instruction_sets_for_functional_checks 
The compliance tests in the folder, Instruction_sets_for_functional_checks were initially taken from [riscv-software-src repository](https://github.com/riscv-software-src/riscv-tests/tree/master/isa/rv32ui) and then passed through an [assembler](https://github.com/metastableB/RISCV-RV32I-Assembler/blob/master/).
The folder UnitTest-files has all formats of instructions for the compliance tests.
