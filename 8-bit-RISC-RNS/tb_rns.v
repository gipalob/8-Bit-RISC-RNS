module testbench;
reg clk, reset;

integer i, j;

processor_top proc_top1(
	clk, reset 
);
wire [9:0] prog_ctr;
wire [2:0] IF_addr1, IF_addr2, EX_addr1, EX_addr2;
wire [7:0] IF_op1, IF_op2, EX_op1, EX_op2;
wire [4:0] IF_opcode;
wire reg_wr_en, invalidate_instr, invalidate_instr_IFID, unconditional_jmp, branch_taken_EX;
wire [7:0] reg_wr_data;
wire [0:31] IFID_reg;

assign prog_ctr = proc_top1.prog_ctr;
assign IF_opcode = proc_top1.stage_IFID.opcode;
assign IF_addr1 = proc_top1.op1_addr_IFID;
assign IF_addr2 = proc_top1.op2_addr_IFID;
assign IF_op1 = proc_top1.op1_din_IFID;
assign IF_op2 = proc_top1.op2_din_IFID;
assign EX_addr1 = proc_top1.op1_addr_out_IFID;
assign EX_addr2 = proc_top1.op2_addr_out_IFID;
assign EX_op1 = proc_top1.op1_din_EX;
assign EX_op2 = proc_top1.op2_din_EX;
assign invalidate_instr = proc_top1.invalidate_instr;
assign invalidate_instr_IFID = proc_top1.IFID_reg[1];
assign unconditional_jmp = proc_top1.IFID_reg[22];
assign branch_taken_EX = proc_top1.branch_taken_EX;
assign reg_wr_en = proc_top1.reg_wr_en;
assign reg_wr_data = proc_top1.wr_data;
assign IFID_reg = proc_top1.IFID_reg;
initial
begin
	clk = 1'b0;
	reset = 1'b1;
	reset = #50 1'b0;

	// Assuming that the registers have been modified via simulation code above
	// Add your test cases here.
	
	// Simulation End
	#950; 
	
	// print the register contents
	$display("--------------------");
	$display("Printing Register Contents: ");
	for(i = 0; i < 8; i = i + 1) begin
		$display("reg_file [%0d] = %0d", i, proc_top1.reg_file.reg_file[i]);
	end
	$display("--------------------");
	$display("Printing Data Memory Contents: ");
	for(j = 0; j < 65535; j = j + 1) begin
	   if (proc_top1.data_mem.data_mem[j]) begin
		  $display("data_mem [%0d] = %0d", j, proc_top1.data_mem.data_mem[j]);
		end
	end
	$display("--------------------");
	
	$stop;   // stop simulation
end

always clk = #5 ~clk;

endmodule