//Description: Data memory with 16-bit address space, byte addressable. 

module Data_Mem (
    input clk, reset,
	input [15:0] data_op_addr,
    input [7:0] datamem_wr_data, // { [7:0] Domain1, [7:0] Domain2, ... }
	input read_from_mem,
	input store_to_mem,
                                    
	output [7:0] dmem_dout   // { [7:0] Domain1, [7:0] Domain2 }
);
	// IP Gen blockmem for data_mem has _marginally_ better delay (~0.2ns, depending on synth / imp methodologies) versus 'manual' definition.
	// I figure it's the more 'correct' method to implement the data memory, and I might just not have a great understanding of the IP gen params to optimize it further.
	blk_mem_gen_0 memory_file (
		.clka(clk),    // input wire clka
		.ena(read_from_mem),      // input wire ena
		.wea(store_to_mem),      // input wire [0 : 0] wea
		.addra(data_op_addr),  // input wire [15 : 0] addra
		.dina(datamem_wr_data),    // input wire [7 : 0] dina
		.douta(dmem_dout)  // output wire [7 : 0] douta
	);
    //reg [7:0] memory_file[0:65535]; //i.e., 64Kbyte

    // // get data during LOAD instruction                 
	// always @(data_rd_addr)
	// begin
	// 	dmem_dout <= memory_file[data_rd_addr];
	// end
                                                      
    // // Stores synced to clock edge
	// always @(posedge clk)
	// begin
	//     if (store_to_mem == 1'b1) 
	// 	begin
	// 		memory_file[data_wr_addr] <= datamem_wr_data;
	// 	end
	// end

endmodule