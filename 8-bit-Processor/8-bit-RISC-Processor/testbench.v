module testbench;
reg clk, reset;
wire [7:0] op1_data, op2_data, dmemout, dmemrdaddr, reg_wr_data, operation_result_out, op1_ex, op2_ex;

wire [2:0] op1_add, op2_add, destreg;
wire reg_wr_enab;
wire took_branch, memwb_inv_instr;

wire [9:0] prog_ctr;

integer i, j;

processor_top proc_top1(clk, reset, prog_ctr, op1_data, op1_add, op2_data, op2_add, destreg, dmemrdaddr, dmemout, reg_wr_data, reg_wr_enab, operation_result_out, took_branch, memwb_inv_instr, op1_ex, op2_ex);


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
		$display("reg_file [%0d] = %0d", i, proc_top1.regfile1.reg_file[i]);
	end
	$display("--------------------");
	$display("Printing Data Memory Contents: ");
	for(j = 0; j < 256; j = j + 1) begin
		$display("data_mem [%0d] = %0d", j, proc_top1.mem1.data_mem[j]);
	end
	$display("--------------------");
	
	$stop;   // stop simulation
end

always clk = #5 ~clk;

endmodule