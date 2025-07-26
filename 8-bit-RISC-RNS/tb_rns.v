module testbench;
reg clk100, reset;
wire [7:0] IO_write_data, IO_port_ID;;
reg [7:0] IO_read_data;
wire IO_write_strobe, IO_read_strobe;


integer i, j, k;

processor_top proc_top1(
	clk100, reset, IO_read_data, IO_port_ID, IO_write_data, IO_write_strobe, IO_read_strobe
);
 wire [9:0] prog_ctr;
 wire [3:0] IF_addr1, IF_addr2, EX_addr1, EX_addr2, dest_reg_addr_EX;
 wire [2:0] dest_reg_addr_ID;
 wire [15:0] IF_op1, IF_op2, EX_op1, EX_op2, reg_d1, reg_d2;
 wire [7:0] reg_d3, imm;
 wire [4:0] IF_opcode;
 wire reg_wr_en, invalidate_instr, invalidate_instr_IFID, unconditional_jmp, branch_taken_EX;
 wire [15:0] reg_wr_data, operation_result, RNS_dout;
 wire [0:41] IFID_reg;
 wire [7:0] op1_mod129, op2_mod129, op1_mod256, op2_mod256;
 wire [7:0] m129_out, m256_out;
 wire destination_rns;

 // wire [6:0] m129_low, m129_mid;
 // wire [1:0] m129_high;
 // wire [8:0] m129_step_one, m129_step_two;
 // assign m256_dout = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[1].RNS_ALU.genblk1.fit_inst.op_out;
 // assign m129_low = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[0].RNS_ALU.genblk1.fit_inst.low;
 // assign m129_mid = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[0].RNS_ALU.genblk1.fit_inst.mid;
 // assign m129_high = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[0].RNS_ALU.genblk1.fit_inst.high;
 // assign m129_step_one = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[0].RNS_ALU.genblk1.fit_inst.step_one;
 // assign m129_step_two = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[0].RNS_ALU.genblk1.fit_inst.step_two;
wire [15:0] instruction;
assign instruction = proc_top1.instr_mem_out;


// wire [15:0] m129_subout, m256_subout;
// assign m129_subout = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[0].RNS_ALU.sub_inst.result;
// assign m256_subout = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[1].RNS_ALU.sub_inst.result;

// wire [7:0] m129_dout, m256_dout;
// assign m129_dout = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[0].RNS_ALU.genblk1.fit_inst.op_out;
// assign m256_dout = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[1].RNS_ALU.genblk1.fit_inst.op_out;

 wire op1_data_FWD_EX;
 wire [15:0] op1_data_IDtoEX;
 assign op1_data_FWD_EX = proc_top1.fwd.bypass_op1_ex_stage;
 assign op1_data_IDtoEX = proc_top1.op1_dout_IFID;

assign RNS_dout = proc_top1.stage_EX.RNS_dout;
assign destination_rns = proc_top1.destination_RNS;
assign op1_mod129 = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[0].RNS_ALU.op1_in;
assign op2_mod129 = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[0].RNS_ALU.op2_in;
assign op1_mod256 = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[1].RNS_ALU.op1_in;
assign op2_mod256 = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[1].RNS_ALU.op2_in;
// assign m129_out = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[0].RNS_ALU.dout;
// assign m256_out = proc_top1.stage_EX.genblk1.ALU_RNS_GENBLK[1].RNS_ALU.dout;

 assign imm = proc_top1.stage_IFID.imm;
 assign dest_reg_addr_ID = proc_top1.res_addr_out_IFID;
 assign dest_reg_addr_EX = proc_top1.destination_reg_addr;
 assign operation_result = proc_top1.stage_EX.operation_result;
 assign reg_d1 = proc_top1.rd_data1;
 assign reg_d2 = proc_top1.rd_data2;
 assign reg_d3= proc_top1.rd_data3;
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
 assign reg_wr_data = proc_top1.wr_data;
 assign IFID_reg = proc_top1.IFID_reg;
initial
begin
    IO_read_data = 8'b0;
	clk100 = 1'b0;
	reset = 1'b1;
	reset = #50 1'b0;

	// Assuming that the registers have been modified via simulation code above
	// Add your test cases here.
	
	// Simulation End
	#25000; 
	
	// print the register contents
	$display("--------------------");
	$display("Printing Integer Register Contents: ");
	for(i = 0; i < 8; i = i + 1) begin
		$display("reg_file [%0d] = %0d", i, proc_top1.reg_file.reg_file[i]);
	end
	$display("--------------------");
	$display("Printing RNS Domain Register Contents: ");
	$display("Index | D256 Bin | D129 Bin");
	for(j = 0; j < 8; j = j + 1) begin
		$display("%0d\t| %08b | %08b", j, proc_top1.reg_file.RNS_reg_file[j][15:8], proc_top1.reg_file.RNS_reg_file[j][7:0]);
	end
	// $display("--------------------");
	// $display("Printing Data Memory Contents: ");
	// for(k = 0; k < 65535; k = k + 1) begin
	//    if (proc_top1.data_mem.memory_file[j] > 0) begin
	// 	  $display("data_mem [%0d] = %0d", k, proc_top1.data_mem.memory_file[k]);
	// 	end
	// end
	// $display("--------------------");
	
	$stop;   // stop simulation
end

always clk100 = #5 ~clk100;

always @(*) begin
    if (IO_read_strobe == 1'b1) begin
        case (IO_port_ID) 
            8'h01: IO_read_data <= 8'h04;
            8'h02: IO_read_data <= 8'hFF; //RX data present always yes during sim
            8'h03: IO_read_data <= 8'h00; //TX buff full always no during sim
            default: IO_read_data <= 8'hFF;
        endcase
    end
end 

always @(IO_write_strobe) begin
	if (IO_write_strobe == 1'b1) begin
		case (IO_port_ID)
			8'h01: $display("UART TX Data: %8b", IO_write_data); // Print the data being sent to UART
			default: $display("Unknown IO Write Strobe on Port ID: %0h", IO_port_ID);
		endcase
	end
end

endmodule