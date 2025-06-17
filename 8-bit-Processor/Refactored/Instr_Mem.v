// Description: Instr mem for 8-bit RISC processor, modified from NayanaBannur/8-bit-RISC-Processor to support parameterized program counter width.

module Instr_Mem #(parameter PROG_CTR_WID=10) (
    input clk,
    input [PROG_CTR_WID-1:0] prog_ctr,
    output reg [15:0] instr_mem_out
);
    reg [15:0] instr_mem[0:1023]; //define instr mem as 2^PROG_CTR_WID = {1, shifted left PROG_CTR_WID times} - 1 elements

    initial begin
	    $readmemh("/home/user/CIS4900/8-bit-RISC-Processor/program3.txt",instr_mem);
	end

    always @(posedge clk)
		instr_mem_out <=  #1 instr_mem[prog_ctr];
        
endmodule