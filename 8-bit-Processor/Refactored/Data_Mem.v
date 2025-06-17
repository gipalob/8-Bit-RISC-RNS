//Description: Data memory module for 8-bit RNS-domain RISC processor, modified from NayanaBannur/8-bit-RISC-Processor to support dual-domain RNS
//             Currently implementation is 256-elements, with each element being NUM_DOMAINS byte(s)
//			   Remember, we're completing the same operation for each domain in parallel- so we don't want to have to deconstruct / reconstruct for every operation.
//             Better to just store each domain's operand. 

module Data_Mem #(parameter NUM_DOMAINS = 1) (
    input clk, reset,
	input [7:0] data_rd_addr, data_wr_addr,
    input [NUM_DOMAINS*8 - 1:0] datamem_wr_data, // { [7:0] Domain1, [7:0] Domain2, ... }
	input store_to_mem,
                                    
	output reg [NUM_DOMAINS*8 - 1:0] dmem_dout   // { [7:0] Domain1, [7:0] Domain2 }
);
    reg [NUM_DOMAINS*8 - 1:0] data_mem[255:0];

    initial begin
	    $readmemh("/home/user/CIS4900/8-bit-RISC-Processor/data3.txt",data_mem);
	end

    // get data during LOAD instruction                 
	always @(data_rd_addr)
	begin
		dmem_dout <= data_mem[data_rd_addr];
		/*
			A possible concern with this is which domain we're going to use for the address...
			Part of a standard assembly flow is performing arithmetic operations on the address...
			What happens if we do, say, addr = 256 + 1? Theoretically, the assembler should never do this-
			but overflowing the address is a possibility.
		*/
	end
                                                      
    // write to data memory in STORE instruction
	always @(posedge clk)
	begin
	    if (store_to_mem == 1'b1) 
		begin
			data_mem[data_wr_addr] <= datamem_wr_data;
		end
	end

endmodule