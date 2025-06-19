module testbench;
reg clk, reset;

integer i, j;

processor_top proc_top1(
	clk, reset 
);


initial
begin
	clk = 1'b0;
	reset = 1'b1;
	reset = #50 1'b0;

	// Assuming that the registers have been modified via simulation code above
	// Add your test cases here.
	
	// Simulation End
	#90000; 
	
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