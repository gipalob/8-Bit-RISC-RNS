module testbench;
reg clk, reset;

initial
	begin
	clk = 1'b0;
	reset = 1'b1;
	reset = #161 1'b0;
	end

always clk = #5 ~clk;

processor_top proc_top1(clk, reset);

endmodule