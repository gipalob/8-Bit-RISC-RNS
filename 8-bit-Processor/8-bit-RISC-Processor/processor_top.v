
module processor_top (clk, reset, prog_ctr, op1_data, op1_add, op2_data, op2_add, destreg, dmemrdaddr, dmemout, reg_wr_data, reg_wr_enab, operation_result_out, took_branch, memwb_inv_instr, op1_ex, op2_ex);
    // right now functional for outputting op1_rd and op2_rd data- will need to modify to take in data? should that be done through instr_mem? 
	input clk, reset;
	output [7:0] op1_data, op2_data, dmemrdaddr, dmemout, reg_wr_data, operation_result_out, op1_ex, op2_ex;
	output [2:0] op1_add, op2_add, destreg;
 	output reg_wr_enab;
	output took_branch, memwb_inv_instr;

	wire 	 clk, store_to_mem,reg_wr_en;
	output [9:0]  prog_ctr;
	wire	[15:0] instr_mem_out;
	wire	[2:0]  op1_addr, op2_addr,destination_reg_addr;
	wire [7:0]  op1_rd_data, op2_rd_data, mem_data;
	wire [7:0]  data_rd_addr, data_wr_addr;
 	wire [7:0]  datamem_rd_data, datamem_wr_data;
	wire [7:0] operation_result;

	assign op1_data = op1_rd_data;
	assign op2_data = op2_rd_data;
	assign op1_add = op1_addr;
	assign op2_add = op2_addr;
	assign destreg = destination_reg_addr;
	assign dmemrdaddr = data_rd_addr;
	assign dmemout = datamem_rd_data;
	assign reg_wr_data = datamem_wr_data;
	assign reg_wr_enab = reg_wr_en;
	assign operation_result_out = operation_result;

	instr_and_data_mem  mem1(
		clk, 
		prog_ctr, instr_mem_out, data_rd_addr, data_wr_addr, 
		datamem_rd_data, datamem_wr_data, 
		store_to_mem
	);

	processor_core proc1(
		clk, reset,
		op1_rd_data, op2_rd_data, 
		instr_mem_out,
		op1_addr, op2_addr,
		prog_ctr, 
		store_to_mem, reg_wr_en, 
		data_rd_addr, data_wr_addr, 
		datamem_rd_data, datamem_wr_data, 
		operation_result, destination_reg_addr, took_branch, memwb_inv_instr,
		op1_ex, op2_ex
	);

	register_file regfile1(
		clk, reset, 
		datamem_wr_data, 
		op1_rd_data, op2_rd_data, 
		op1_addr, op2_addr, 
		destination_reg_addr, 
		reg_wr_en
	);

endmodule