
module processor_top (clk, reset, prog_ctr, op1_rd, op2_rd);
    // right now functional for outputting op1_rd and op2_rd data- will need to modify to take in data? should that be done through instr_mem? 
	input clk, reset;

	wire 	 clk, store_to_mem,reg_wr_en;
	output [9:0]  prog_ctr;
	wire	[15:0] instr_mem_out;
	wire	[2:0]  op1_addr, op2_addr,destination_reg_addr;
	wire [7:0]  op1_rd_data, op2_rd_data, mem_data;
	wire [7:0]  data_rd_addr, data_wr_addr;
 	wire [7:0]  datamem_rd_data, datamem_wr_data;
	wire [7:0] operation_result;

    output reg [7:0] op1_rd, op2_rd;

    always @(posedge clk) begin
        op1_rd = op1_rd_data;
        op2_rd = op2_rd_data;
    end

	instr_and_data_mem  mem1(clk, prog_ctr, instr_mem_out, data_rd_addr, data_wr_addr, datamem_rd_data, datamem_wr_data, store_to_mem);

	processor_core proc1(clk,reset,op1_rd_data,op2_rd_data, instr_mem_out,op1_addr, op2_addr,prog_ctr, store_to_mem, reg_wr_en, data_rd_addr, data_wr_addr, datamem_rd_data, datamem_wr_data, operation_result, destination_reg_addr );

	register_file regfile1(clk, reset, datamem_wr_data, op1_rd_data, op2_rd_data, op1_addr, op2_addr, destination_reg_addr, reg_wr_en);

endmodule