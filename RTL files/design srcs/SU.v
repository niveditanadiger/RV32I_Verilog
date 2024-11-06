//Store Unit: Contains a 'Local Control Unit'. Generates the required word to be stored based on the type of store instruction.

`timescale 1ns/1ns

module SU(funct,mem_address_1_0,addr_allign,B,H);

input [2:0]funct;
input [1:0]mem_address_1_0;
output reg [1:0]addr_allign;
output reg B,H;


always@*
begin
    case(funct)
        3'b000: //store byte
                begin
                case(mem_address_1_0[1:0])
                    2'b00: addr_allign=2'b00;
                    2'b01: addr_allign=2'b01;
                    2'b10: addr_allign=2'b10;
                    2'b11: addr_allign=2'b11;
                endcase
                B=1'b1;
                H=1'b0;
                end
        3'b001: //store halfword
                begin
                case(mem_address_1_0[1])
                    1'b0: addr_allign=2'b00;
                    1'b1: addr_allign=2'b10;
                endcase
                B=1'b0;
                H=1'b1;
                end
        3'b010: //store word
                begin
                addr_allign=2'b00;
                B=1'b0;
                H=1'b0;
                end
        default:
            begin
            addr_allign=2'b00;/**/
            B=1'b0;/**/
            H=1'b0;/**/
            end
    endcase    
end


endmodule