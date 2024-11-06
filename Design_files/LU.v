`timescale 1ns/1ns

module LU(funct,mem_address,mem_out,mem_in);
input [31:0] mem_in;
input[2:0] funct;
input[1:0] mem_address;
output reg [31:0] mem_out;


always@(*)
case(funct)
    3'b000:         //load byte
        begin 
            case(mem_address[1:0])
                2'b00 : 
                    begin
                        //mem_out=mem_in & 32'h000000ff;
                        if(mem_in[7]==1)
                            //mem_out=mem_out + 32'hffffff00;
                            mem_out={24'hffffff,mem_in[7:0]};
                        else
                            //mem_out=mem_out;
                            mem_out={24'h0,mem_in[7:0]};
                    end

                2'b01 : 
                    begin 
                        //mem_out=mem_in & 32'h0000ff00;
                        if(mem_in[15]==1)
                            //mem_out=mem_out + 32'hffff0000;
                            mem_out={24'hffffff,mem_in[15:8]};
                        else
                            //mem_out=mem_out;
                            mem_out={24'h0,mem_in[15:8]};
                    end

                2'b10 : 
                    begin 
                        //mem_out=mem_in & 32'h00ff0000;
                        if(mem_in[23]==1)
                            //mem_out=mem_out + 32'hff000000;
                            mem_out={24'hffffff,mem_in[23:16]};
                        else
                            mem_out={24'h0,mem_in[23:16]};
                    end

                2'b11 : 
                    begin
                        //mem_out=mem_in & 32'hff000000;
                        if(mem_in[31]==1)
                            //mem_out=mem_out + 32'h00000000;
                            mem_out={24'hffffff,mem_in[31:24]};
                        else
                            //mem_out=mem_out;
                            mem_out={24'h0,mem_in[31:24]};
                    end
            endcase 
        end

    3'b001:         //load halfword
        begin
            case(mem_address[1])
                1'b0: 
                    begin
                        //mem_out=mem_in & 32'h0000ffff;
                        if(mem_in[15]==1)begin
                            //mem_out=mem_out + 32'hffff0000;
                            mem_out={16'hffff,mem_in[15:0]};
                            end
                        else
                            //mem_out=mem_out;
                            mem_out={16'h0,mem_in[15:0]};
                    end

                1'b1: 
                    begin
                        //mem_out=mem_in & 32'hffff0000;
                        if(mem_in[31]==1)
                            //mem_out=mem_out + 32'h00000000;
                            mem_out={16'hffff,mem_in[31:16]};
                        else
                            //mem_out=mem_out;
                            mem_out={16'h0,mem_in[31:16]};
                    end        
            endcase 
        end

    3'b100:     //load unsigned byte
        begin
//            case(mem_address[1:0])
//                2'b00 : mem_out=mem_in & 32'h000000ff;
//                2'b01 : mem_out=mem_in & 32'h0000ff00;
//                2'b10 : mem_out=mem_in & 32'h00ff0000;
//                2'b11 : mem_out=mem_in & 32'hff000000;
//            endcase
            case(mem_address[1:0])
                2'b00 : mem_out={24'h0,mem_in[7:0]};
                2'b01 : mem_out={24'h0,mem_in[15:8]};
                2'b10 : mem_out={24'h0,mem_in[23:16]};
                2'b11 : mem_out={24'h0,mem_in[31:24]};
            endcase
        end

    3'b101:         //load unsigned halfword
        begin
//            case(mem_address[1])
//                1'b0: mem_out=mem_in & 32'h0000ffff;
//                1'b1: mem_out=mem_in & 32'hffff0000;
//            endcase
            case(mem_address[1])
                1'b0: mem_out={16'h0,mem_in[15:0]};
                1'b1: mem_out={16'h0,mem_in[31:16]};
            endcase
        end
        
    3'b010:        //load word   
        mem_out=mem_in;
    default:
        mem_out=32'b0;/**/
    endcase


endmodule