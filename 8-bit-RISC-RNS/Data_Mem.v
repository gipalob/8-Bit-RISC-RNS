//Description: Data memory with 16-bit address space, byte addressable. 

module Data_Mem (
    input clk, reset,
	input [15:0] data_rd_addr, data_wr_addr,
    input [7:0] datamem_wr_data, // { [7:0] Domain1, [7:0] Domain2, ... }
	input store_to_mem,
                                    
	output reg [7:0] dmem_dout   // { [7:0] Domain1, [7:0] Domain2 }
);
    reg [7:0] memory_file[65535:0]; //i.e., 64Kbyte

    // get data during LOAD instruction                 
	always @(data_rd_addr)
	begin
		dmem_dout <= memory_file[data_rd_addr];
	end
                                                      
    // Stores synced to clock edge
	always @(posedge clk)
	begin
	    if (store_to_mem == 1'b1) 
		begin
			memory_file[data_wr_addr] <= datamem_wr_data;
		end
	end

endmodule