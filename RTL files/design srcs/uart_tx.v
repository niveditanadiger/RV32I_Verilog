module uart_tx 
  #(parameter CLKS_PER_BIT =10415)         /* (core speed)100MHz / (baud rate) 9600 */
(
input clk,
input rst,
input data_valid,
input [7:0] data,//byte data
output tx, //transmitting
output reg serial,
output tx_complete
);

/*
States:
	IDLE=3'b000
	TX_START_BIT = 3'b001
	TX_DATA_BITS = 3'b010
	TX_STOP_BIT  = 3'b011
	CLEANUP      = 3'b100
*/

  reg [2:0]    state;    
  reg [7:0]    clk_cntr;  
  reg [2:0]    bit_index;   
  reg [7:0]    reg_Data;     
  reg          Done;     
  reg          Active;  
     
  always @(posedge clk)
    begin

	if(rst)
		begin
		state     <= 0;
		clk_cntr  <= 0;
		bit_index <= 0;
		reg_Data  <= 0;
		Done      <= 0;
		Active    <= 0;
		end
    else 
      case (state)
        3'b000 :
          begin
            serial   <= 1'b1;         // Idle
            Done     <= 1'b0;
            clk_cntr <= 0;
            bit_index<= 0;
             
            if (data_valid == 1'b1)
              begin
                Active   <= 1'b1;
                reg_Data <= data; 
                state    <= 3'b001;
              end
            else
              state <= 3'b000;
          end 
         
         
        // Start bit = 0
        3'b001 :
          begin
            serial <= 1'b0;
             
            // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
            if (clk_cntr < CLKS_PER_BIT-1)
              begin
                clk_cntr <= clk_cntr + 1;
                state     <= 3'b001;
              end
            else
              begin
                clk_cntr <= 0;
                state     <= 3'b010;
              end
          end 
         
         
        // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish         
        3'b010 :
          begin
            serial <= reg_Data[bit_index];
             
            if (clk_cntr < CLKS_PER_BIT-1)
              begin
                clk_cntr <= clk_cntr + 1;
                state     <= 3'b010;
              end
            else
              begin
                clk_cntr <= 0;
                 
                // Check if all bits were sent
                if (bit_index < 8)
                  begin
                    bit_index <= bit_index + 1;
                    state   <= 3'b010;
                  end
                else
                  begin
                    bit_index <= 0;
                    state   <= 3'b011;
                  end
              end
          end 
         
         
        // Stop bit = 1
        3'b011 :
          begin
            serial <= 1'b1;
             
            // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            if (clk_cntr < CLKS_PER_BIT-1)
              begin
                clk_cntr <= clk_cntr + 1;
                state     <= 3'b011;
              end
            else
              begin
                Done     <= 1'b1;
                clk_cntr <= 0;
                state     <= 3'b100;
                Active   <= 1'b0;
              end
          end 
         
         
        // Stay here 1 clock
        3'b100 :
          begin
            Done <= 1'b1;
            state <= 3'b000;
          end
         
         
        default :
          state <= 3'b000;
         
      endcase
    end
 
  assign tx = Active;
  assign tx_complete   = Done;
   
endmodule
