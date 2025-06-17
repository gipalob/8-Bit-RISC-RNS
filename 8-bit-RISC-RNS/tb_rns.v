module testbench;
reg clk, reset;
wire [7:0] op1_data, op2_data, operation_result_out;
wire [7:0] dmemout;
wire [7:0] dmemrdaddr;
wire [2:0] op1_addr, op2_addr, destination_reg_addr;
wire [9:0] prog_ctr_out;
wire [7:0] reg_wr_data;
wire reg_wr_enab;
wire [15:0] instr;
wire took_branch, memwb_inv_instr;
wire [0:38] plreg_ifid;
wire [0:6] plreg_ex;
wire [0:4] branch_conds_IFID, branch_conds_EX;
wire [0:3] branch_conds_MEMWB;
wire cout;
wire [7:0] dout, op1_ex, op2_ex;


integer i, j;

processor_top proc_top1(
	clk, reset, 
	prog_ctr_out, 
	instr, 
	op1_data, op1_addr, 
	op2_data, op2_addr,
	destination_reg_addr,
	dmemrdaddr, dmemout,
	reg_wr_data, reg_wr_enab,
	operation_result_out, took_branch, memwb_inv_instr, plreg_ifid, plreg_ex,
	branch_conds_IFID, branch_conds_EX, branch_conds_MEMWB, cout, dout,
	op1_ex, op2_ex
	);


initial
begin
	clk = 1'b0;
	reset = 1'b1;
	reset = #161 1'b0;

	// Assuming that the registers have been modified via simulation code above
	// Add your test cases here.
	
	// Simulation End
	#400; 
	
	// print the register contents
	$display("--------------------");
	$display("Printing Register Contents: ");
	for(i = 0; i < 8; i = i + 1) begin
		$display("reg_file [%0d] = %0d", i, proc_top1.reg_file.reg_file[i]);
	end
	$display("--------------------");
	$display("Printing Data Memory Contents: ");
	for(j = 0; j < 256; j = j + 1) begin
		$display("data_mem [%0d] = %0d", j, proc_top1.data_mem.data_mem[j]);
	end
	$display("--------------------");
	
	$stop;   // stop simulation
end

always clk = #5 ~clk;

endmodule