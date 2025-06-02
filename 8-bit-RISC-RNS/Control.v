//Description: Control unit for 8-bit RISC-RNS processor
//             Modified from NayanaBannur/8-bit-RISC-Processor, using some logic from hushon/Tiny-RISCV-CPU/

module Control (
    input [15:0] instruction,
    input [9:0] branch_addr,

    //decoded instruction
    output [2:0] op1_addr,
    output [2:0] op2_addr,
    output [2:0] res_addr,
    output [7:0] ld_mem_addr,
    output [7:0] st_mem_addr,
    output [9:0] branch_addr,

    //control signals
    output write_to_regfile,
    output add_op_true,
    output carry_in, //no carry in needed for RNS- however, used for subtraction
    output en_op2_complement, //2's complement for subtraction
    output lgcl_or_bitwse_T,
    output or_op_true,
    output not_op_true,
    output shift_left_true,
    output next_prog_ctr,
    output [9:0] next_prog_ctr,
    output jump_true,
    output unconditional_jump,
    output load_true,
    output store_true,
    output and_bitwise_true,
    output or_bitwise_true,
    output not_bitwise_true, 
    output compare_true,
    output jump_lt,
    output jump_gt,
    output jump_eq
);

    always@(instruction) 
    begin
		opcode	<=  instruction[15:11];
		op1_addr	<=  instruction[2:0];
		op2_addr	<= instruction[6:4];
		res_addr	<= instruction[10:8];
		ld_mem_addr <= instruction[7:0];
		st_mem_addr <= instruction [10:3];
		branch_addr <= instruction[9:0];
	end

	always@ (opcode or branch_addr) 
    begin
		add_op_true <= 1'b0;
		and_op_true <= 1'b0;
		or_op_true  <= 1'b0;
		not_op_true <= 1'b0; 
		carry_in	<= 1'b0;
		en_op2_complement  <= 1'b0;
		jump_true	<= 1'b0;
		compare_true <= 1'b0;
		shift_left_true <= 1'b0;
		lgcl_or_bitwse_T <= 1'b0;
		load_true <= 1'b0;
		store_true <= 1'b0;
		write_to_regfile <= 1'b0;
		unconditional_jump <= 1'b0;
		jump_gt <= 1'b0;
		jump_lt <= 1'b0;
		jump_eq <= 1'b0;
		jump_carry <= 1'b0;

		case (opcode)
		//	OP_NOP:  
		//	5'h00:   	;		
		
		//	OP_ADD:	begin
			5'b00001:	begin
					write_to_regfile <= 1'b1;
					add_op_true <= 1'b1;
					end
	
		//	OP_SUB:	begin
			5'b00010:	begin
					add_op_true <= 1'b1;	
					carry_in	<= 1'b1; //not needed for RNS, but used for subtraction
					en_op2_complement <= 1'b1;
					write_to_regfile <= 1'b1;
				   	end

		//	OP_AND:	begin
			5'b00011:	begin
					and_op_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1;     
					end

		//	OP_OR:	begin
			5'b00100:	begin
					or_op_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1;
					end

		//	OP_NOT:	begin
			5'b00101:	begin
					not_op_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1;
					end

		//	OP_SHL	begin                  
			5'b00110:	begin
					shift_left_true <= 1'b1;
					write_to_regfile <= 1'b1;
					end

		//	OP_JMP:	begin
			5'b00111:	begin
					nxt_prog_ctr <= branch_addr;
					jump_true	<= 1'b1;
					unconditional_jump <= 1'b1;
					end

		//	OP_LOAD:	begin
			5'b01000:	begin
					load_true <= 1'b1;
					write_to_regfile <= 1'b1;
					end                      
                                                      
		//	OP_STORE:	store_true <= 1'b1;
			5'b01001:	store_true <= 1'b1;

		//	OP_ANDBIT:	begin
			5'b01010	begin
					and_bitwise_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1; 
			   		end

		//	OP_ORBIT:	begin
			5'b01011:	begin
					or_bitwise_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1;
					end

		//	OP_NOTBIT:	begin
			5'b01100:	begin
					not_bitwise_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1;
					end
 
		//	OP_COMPARE: begin
			5'b01101:	begin
					add_op_true <= 1'b1;
					compare_true <= 1'b1;	
					carry_in	<= 1'b1;   //subtract
					en_op2_complement <= 1'b1;
				   	end

		//	OP_JMPGT:	begin
			5'b01110:	begin
					nxt_prog_ctr <= branch_addr;
					jump_true	<= 1'b1;
					jump_gt <= 1'b1;
					end

		//	OP_JMPLT:	begin
			5'b01111:	begin
					nxt_prog_ctr <= branch_addr;
					jump_true	<= 1'b1;
					jump_lt <= 1'b1;
					end
		//	OP_JMPEQ:	begin
			5'b10000:	begin
					nxt_prog_ctr <= branch_addr;
					jump_true	<= 1'b1;
					jump_eq <= 1'b1;
					end

		//	OP_JMPC:	begin
			5'b10001:	begin
					nxt_prog_ctr <= branch_addr;
					jump_true	<= 1'b1;
					jump_carry <= 1'b1;
					end

			default: 	;			//= NOP
			endcase
	end

endmodule