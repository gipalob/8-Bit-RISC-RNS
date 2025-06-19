//Description: Data memory with 16-bit address space, byte addressable. 

module Data_Mem (
    input clk, reset,
	input [15:0] data_rd_addr, data_wr_addr,
    input [7:0] datamem_wr_data, // { [7:0] Domain1, [7:0] Domain2, ... }
	input store_to_mem,
                                    
	output reg [7:0] dmem_dout   // { [7:0] Domain1, [7:0] Domain2 }
);
    reg [7:0] data_mem[65535:0]; //i.e., 64Kbyte

    //for loading initial data memory contents
    //initial begin
	//    $readmemh("",data_mem);
	//end

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