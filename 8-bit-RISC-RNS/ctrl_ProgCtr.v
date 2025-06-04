// Description: Program counter for 8-Bit processor, modified from NayanaBannur/8-bit-RISC-Processor to support parameterized width

module ctrl_ProgCtr #(parameter PROG_CTR_WID) (
    input clk,
    input reset,
    input branch_taken_EX,
    input [PROG_CTR_WID-1:0] nxt_prog_ctr_EX,

    output reg [PROG_CTR_WID-1:0] prog_ctr
);
    always @(posedge clk)
	    if (reset == 1'b1)
	        prog_ctr <= #1 10'b1;
	    else begin
		if (branch_taken_reg == 1) //update in store res stage
			begin                             
			prog_ctr <= #1 nxt_prog_ctr_EX;
			end
		else
			begin
			prog_ctr <= #1 prog_ctr + 1'b1;
			end
	end
endmodule