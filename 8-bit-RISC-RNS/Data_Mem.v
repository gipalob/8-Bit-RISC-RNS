//Description: Data memory module for 8-bit RNS-domain RISC processor, modified from NayanaBannur/8-bit-RISC-Processor to support dual-domain RNS
//             Currently implementation is 256-element, 2-byte memory.
//              This is to store data from both RNS domains- each domain is parallel / synchronous, and we don't want to
//              deconstruct / reconstruct on every load / store. Thus, we want as many elements allowable by an 8-bit address,
//              but store both domains' operand in the same element.

module Data_Mem (
    input clk;
	input [7:0] data_rd_addr, data_wr_addr;
    input [15:0] datamem_wr_data; // { [7:0] Domain1, [7:0] Domain2 }
	input store_to_mem;  
                                    
	output reg [7:0] dmem_dout;   // { [7:0] Domain1, [7:0] Domain2 }
);
    reg [15:0] data_mem[255:0];

    initial begin
	    $readmemh("/home/user/CIS4900/8-bit-RISC-Processor/data2.txt",data_mem);
	end

    // get data during LOAD instruction                 
	always @(data_rd_addr)
		datamem_rd_data <= data_mem[data_rd_addr]; 
                                                      
    // write to data memory in STORE instruction
	always @(posedge clk)
		if (store_to_mem == 1'b1)
			data_mem[data_wr_addr] <= datamem_wr_data;

endmodule