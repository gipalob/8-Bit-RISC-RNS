module testbench;
reg clk, reset;
wire [7:0] op1_rd, op2_rd;
wire [9:0] prog_ctr;
initial
	begin
	clk = 1'b0;
	reset = 1'b1;
	reset = #161 1'b0;
	end

always clk = #5 ~clk;

processor_top proc_top1(clk, reset, prog_ctr, op1_rd, op2_rd);

endmodule