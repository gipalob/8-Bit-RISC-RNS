// Description: Instr mem for 8-bit RISC processor, modified from NayanaBannur/8-bit-RISC-Processor to support parameterized program counter width.

module Instr_Mem_Sim #(parameter PROG_CTR_WID=10) (
    input clk,
    input [PROG_CTR_WID-1:0] prog_ctr,
    output reg [15:0] instr_mem_out
);
    reg [15:0] instr_mem[0:1023]; //define instr mem as 2^PROG_CTR_WID = {1, shifted left PROG_CTR_WID times} - 1 elements
    
    // Windows Path: "C:\code-projs\CIS4900\8-bit-RISC-RNS\test_progs\"
    initial begin
	    $readmemh("C:/code-projs/CIS4900/8-bit-RISC-RNS/test_progs/big_mem_test/big_mem_test.txt",instr_mem);
	end

    always @(prog_ctr) //is this an okay trigger? seems to mitigate some of the branching issues
		instr_mem_out <=  #1 instr_mem[prog_ctr];
        
endmodule