// Description: Pipeline stage: IF/ID
//              Modified from nayanaBannur/8-bit-RISC-Processor
//              every stage after ID has all signals packaged into a single register

module PL_IFID #(parameter PROG_CTR_WID=10, NUM_DOMAINS=1) (
    input clk,
    input rst,
    //IO signals for IF
    input [15:0] 					instr_mem_out,    	//from intr_mem
    input 								branch_taken_EX,    //branch taken signal from EX stage
    input [NUM_DOMAINS*8 - 1:0] 		op1_data,           //data for op1 from ctrl_Forward 
    input [NUM_DOMAINS*8 - 1:0]			op2_data,           //data for op2 from ctrl_Forward
	input [7:0]							op3_data,           //data for op3 from ctrl_Forward

	output reg 							reg_rd_en,      //Read enable signal for regfile
    output reg [3:0] 					op1_addr_IFID,  //ID: op1_addr to ctrl_Forward  - {RNS_file, [2:0] addr}
    output reg [3:0] 					op2_addr_IFID,  //ID: op2_addr to ctrl_Forward  - {RNS_file, [2:0] addr}
	output reg [2:0]                    op3_addr_IFID,  //ID: op3_addr to ctrl_Forward  - always from int regfile, so no RNS flag needed
    output reg 							load_true_IFID,     //ID: load instruction flag to ctrl_Forward

    //pipeline register out to next stage
    output reg [0:41] 					IFID_reg,    		//IFID pipeline register out
    output reg [PROG_CTR_WID-1:0] 		pred_nxt_prog_ctr, 	//inst address to jump to on successful branch evaluation - pulled from inst in ID
	output reg [NUM_DOMAINS*8 - 1:0] 	op1_dout_IFID, 		//op1 data out for IFID pipeline register - easier to keep this seperate as it's dynamic size
	output reg [NUM_DOMAINS*8 - 1:0] 	op2_dout_IFID,		//op2 data out for IFID pipeline register - easier to keep this seperate as it's dynamic size
	output reg [7:0] 					op3_dout_IFID,		//op3 data out for IFID pipeline register
    output reg [3:0]                    op1_addr_out_IFID,
    output reg [3:0]                    op2_addr_out_IFID,
	output reg [2:0]                    op3_addr_out_IFID, //op3 is rs for RSTORE
    output reg [2:0]                    res_addr_out_IFID
);

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // Instruction Fetch
    reg [15:0] instruction; //instruction fetched from memory
    reg invalidate_fetch_instr; //flag to invalidate fetch instruction if branch is taken
	
    always @(instr_mem_out or rst or branch_taken_EX) 
    begin
        if (rst) begin
            instruction <= 16'b0;
            invalidate_fetch_instr <= 1'b0;
        end else begin
            instruction <= instr_mem_out;

            if (branch_taken_EX)
                invalidate_fetch_instr <= 1'b1; //invalidate fetch instruction if branch is taken
            else
                invalidate_fetch_instr <= 1'b0; //otherwise, continue fetching instructions
        end
    end  
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // Instruction Decode
    reg [4:0] opcode; //opcode of the instruction
    reg [2:0] res_addr; //destination register address
    reg [3:0] op2_addr, op1_addr;
    reg [9:0] branch_addr; //branch address

	//For custom instructions:
	reg [7:0] imm; //8-bit immediate for LDI
	/*
		There were some issues with the regfile having read triggered on address- 
		So, the addresses initially obtained from the instruction are NOT sent out of IF/ID until the opcode is decoded. 
		This also allowed for creation of a new signal, RD_EN, triggered based on opcode.		
	*/

    always @(instruction) 
    begin
		opcode	        	<= instruction[15:11];
		res_addr	    	<= instruction[10:8];
		imm			    	<= instruction[7:0]; //imm is used for LDI as well as INPUT and OUTPUT- acts as the port for INPUT and OUTPUT
		op2_addr		   	<= instruction[7:4]; //bit 7 is rs2 domain flag; 1 == RNS, 0 == normal int
		op1_addr			<= instruction[3:0]; //bit 4 is rs1 domain flag; 1 == RNS, 0 == normal int
		branch_addr     	<= instruction[9:0];
	end
	/*
		Will need to modify to throw an error if:
			(inst[7] == 1 || inst[3] == 1) && (RNS_ALU_op == 0), pipeline error
	*/

    reg add_op_true, and_op_true, or_op_true, not_op_true;      //operation flags
    reg and_bitwise_true, or_bitwise_true, not_bitwise_true;    //bitwise operation flags
    reg carry_in, en_op2_complement;                            //flags for carry and complement operations
    reg jump_true, compare_true, shift_left_true;               //flags for jump and comparison operations
    reg lgcl_or_bitwse_T;                                       //flag for logical or bitwise operations
    reg store_true;                                             //flags for store operations - load flag is output reg for ctrl_Forward
    reg write_to_regfile;                                       //flag to write to register file
    reg unconditional_jump;                                     //flag for unconditional jump
    reg jump_gt, jump_lt, jump_eq, jump_carry;                  //flags for conditional jumps

	//custom flags:
	reg outp_op, inp_op; 
	reg ld_imm, mul_op_true, RNS_ALU_op, RNS_dest_reg, UNRL_op_true, UNRL_lower, RLLM_op_true;

    always@ (opcode or branch_addr or op1_addr or op2_addr or res_addr)        
	begin
		add_op_true <= 1'b0;
		and_op_true <= 1'b0;
		or_op_true  <= 1'b0;
		not_op_true <= 1'b0; 
		and_bitwise_true <= 1'b0;
		or_bitwise_true <= 1'b0;
		not_bitwise_true <= 1'b0;
		carry_in	<= 1'b0;
		en_op2_complement  <= 1'b0;
		jump_true	<= 1'b0;
		compare_true <= 1'b0;
		shift_left_true <= 1'b0;
		lgcl_or_bitwse_T <= 1'b0;
		load_true_IFID <= 1'b0;
		store_true <= 1'b0;
		write_to_regfile <= 1'b0;
		unconditional_jump <= 1'b0;
		jump_gt <= 1'b0;
		jump_lt <= 1'b0;
		jump_eq <= 1'b0;
		jump_carry <= 1'b0;
		outp_op <= 1'b0;
		inp_op <= 1'b0;
		RNS_ALU_op <= 1'b0;
		mul_op_true <= 1'b0;
		UNRL_op_true <= 1'b0;
		UNRL_lower <= 1'b0;
		RLLM_op_true <= 1'b0;
		RNS_dest_reg <= 1'b0;

		ld_imm <= 1'b0;
		reg_rd_en <= 1'b0; //reg_rd_en is used to read from regfile in ID stage, so it is set to 1 for all instructions that read from regfile
		op1_addr_IFID <= 4'b0; //reset op1_addr_IFID
		op2_addr_IFID <= 4'b0; //reset op2_addr_IFID
		op3_addr_IFID <= 3'b0; //reset op3_addr_IFID

		case (opcode)
		//	OP_NOP:  
		//	5'h00:   	;		
		
		//	OP_ADD:	begin
			5'b00001: 
            begin
					write_to_regfile <= 1'b1;
					add_op_true <= 1'b1;

					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					reg_rd_en <= 1'b1;
			end
	
		//	OP_SUB:	begin
			5'b00010: 
            begin
					add_op_true <= 1'b1;	
					carry_in	<= 1'b1;
					en_op2_complement <= 1'b1;
					write_to_regfile <= 1'b1;

					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					reg_rd_en <= 1'b1;
			end

		//	OP_AND:	begin
			5'b00011: 
            begin
					and_op_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1;     

					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					reg_rd_en <= 1'b1;
			end

		//	OP_OR:	begin
			5'b00100: 
            begin
					or_op_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1;

					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					reg_rd_en <= 1'b1;
			end

		//	OP_NOT:	begin
			5'b00101: 
            begin
					not_op_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1;

					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					reg_rd_en <= 1'b1;
			end

		//	OP_SHL	begin                  
			5'b00110: 
            begin
					shift_left_true <= 1'b1;
					write_to_regfile <= 1'b1;

					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					reg_rd_en <= 1'b1;
			end

		//	OP_JMP:	begin
			5'b00111: 
            begin
					//nxt_prog_ctr <= branch_addr;
					jump_true	<= 1'b1;
					unconditional_jump <= 1'b1;
		    end
	//	OP_RLOAD:	begin 
			5'b01000: //'RLOAD': Load from mem to reg 'rd'; LOADR rd, rs1=addr[8:15], rs2=addr[0:7] where rs1 and rs2 are registers that hold the lower and upper 8b of the 16b address
            begin
					load_true_IFID <= 1'b1;
					write_to_regfile <= 1'b1;

					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					reg_rd_en <= 1'b1;
			end                      
                                                      
		//	OP_RSTORE:	begin
			5'b01001: //'RSTORE': Store to mem from reg 'rs'; RSTORE rs, rd1=addr[15:8], rd2=addr[7:0] where rd1 and rd2 are registers that hold the lower and upper 8b of the 16b address
            begin
                    store_true <= 1'b1;
					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					op3_addr_IFID <= res_addr; //op3 is rs for RSTORE
					reg_rd_en <= 1'b1;
            end
    /*
        FOR RLOAD AND RSTORE:
            RLOAD:  res_addr is DESTINATION reg addr
                    register at op1_addr_IFID contains lower 8b of address
                    register at op2_addr_IFID contains upper 8b of address
            RSTORE: res_addr is SOURCE reg addr - aka, op3
                    register at op1_addr_IFID contains lower 8b of address
                    register at op2_addr_IFID contains upper 8b of address
    */

		//	OP_ANDBIT:	begin
			5'b01010:	
            begin
					and_bitwise_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1; 

					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					reg_rd_en <= 1'b1;
			end

		//	OP_ORBIT:	begin
			5'b01011:	
            begin
					or_bitwise_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1;

					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					reg_rd_en <= 1'b1;
			end

		//	OP_NOTBIT:	begin
			5'b01100:	
            begin
					not_bitwise_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1;

					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					reg_rd_en <= 1'b1;
			end
 
		//	OP_COMPARE: begin
			5'b01101:	
            begin
					add_op_true <= 1'b1;
					compare_true <= 1'b1;	
					carry_in	<= 1'b1;   //subtract
					en_op2_complement <= 1'b1;

					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					reg_rd_en <= 1'b1;
			end

		//	OP_JMPGT:	begin
			5'b01110:	
            begin
					//nxt_prog_ctr <= branch_addr;
					jump_true	<= 1'b1;
					jump_gt <= 1'b1;
			end

		//	OP_JMPLT:	begin
			5'b01111:	
            begin
					//nxt_prog_ctr <= branch_addr;
					jump_true	<= 1'b1;
					jump_lt <= 1'b1;
					end
		//	OP_JMPEQ:	begin
			5'b10000:	
            begin
					//nxt_prog_ctr <= branch_addr;
					jump_true	<= 1'b1;
					jump_eq <= 1'b1;
			end

		//	OP_JMPC:	begin
			5'b10001: 
            begin
					//nxt_prog_ctr <= branch_addr;
					jump_true	<= 1'b1;
					jump_carry <= 1'b1;
			end
////////////////////////////////////////////////////////////
//NEW CUSTOM INSTRUCTIONS (ignoring RLOAD and RSTORE above):
////////////////////////////////////////////////////////////
		//	OP_LDI:	begin 
			5'b10010: //'LDI': Load 8-bit immediate; res_addr is dest reg addr. EX stage will set operation_result to imm on ld_imm flag, effectively storing as if the immediate was an arithmetic result
            begin
					ld_imm <= 1'b1;
					write_to_regfile <= 1'b1;
			end          
		//  OP_OUTPUT: begin
			5'b11010: //OP_OUTPUT: Output the value of the register to output port
			begin
					write_to_regfile <= 1'b0; 
					outp_op <= 1'b1;
					op3_addr_IFID <= res_addr; //op3 is the register to output
					reg_rd_en <= 1'b1; //read only op3 
			end 
		//  OP_INPUT: begin
			5'b11011: //OP_INPUT: Take a value from the input port to the register
			begin
					write_to_regfile <= 1'b1; 
					inp_op <= 1'b1;
			end 

//RNS Instructions
		//	OP_ADDM:	begin 
			5'b10011: 
			begin
					RNS_ALU_op 			<= 1'b1;
					RNS_dest_reg 		<= 1'b1;
					write_to_regfile 	<= 1'b1;
					add_op_true 		<= 1'b1;

					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					reg_rd_en <= 1'b1;
			end
		//	OP_SUBM:	begin 
			5'b10100: 
			begin
					RNS_ALU_op 			<= 1'b1;
					RNS_dest_reg 		<= 1'b1;
					write_to_regfile 	<= 1'b1;
					en_op2_complement 	<= 1'b1; //indicate subtract- for the RNS ALU, this just indicates the operation is subtraction. No complement is performed
					add_op_true 		<= 1'b1;
					//No two's complement needed for RNS subtraction, as it is done in the RNS domain

					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					reg_rd_en <= 1'b1;
			end
		//	OP_MULM:	begin 		
			5'b10101: 
			begin
					RNS_ALU_op 			<= 1'b1;
					RNS_dest_reg 		<= 1'b1;
					write_to_regfile 	<= 1'b1;
					mul_op_true 		<= 1'b1;

					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					reg_rd_en <= 1'b1;
			end
		
			// 5'b10110: 
			// begin
					
			// end
			/*
				The 'UNRLx' instructions unroll an RNS register into two integer domain registers; i.e., for outputting or storing to data memory.
				To maintain consistency / lessen complexity, unrolling is done with two instructions:
					UNRLL, Unroll-Lower. This will take rsM[7:0] and store to rd.
					UNRLU, Unroll-Upper. This will take rsM[15:8] and store to rd.

				Complementary, there's the RLLM instruction to roll two integer source registers into an RNS register. 

				Note that 'write_to_regfile' in UNRLx isn't simply raised to 1-
				It's set to the MSB of the source address- which is 1 if the source is RNS
				In theory, it's possible to receive an mod-domain instruction that doesn't have mod-domain rs's...
				This isn't a problem for RLLM, or for mod-arithmetic operations, but if UNRLx receives a non-mod domain rs
				it may store 8'bX to the regfile.
			*/

		//	OP_UNRLL:	begin
			5'b10111: 
			begin
					UNRL_op_true 		<= 1'b1;
					write_to_regfile 	<= op1_addr[3];
					UNRL_lower 			<= 1'b1;

					op1_addr_IFID <= op1_addr; //only read op1
					reg_rd_en <= 1'b1;
			end
		//	OP_UNRLU:	begin
			5'b11000: 
			begin
					UNRL_op_true 		<= 1'b1;
					write_to_regfile 	<= op1_addr[3];
					UNRL_lower 			<= 1'b0;

					op1_addr_IFID <= op1_addr;
					reg_rd_en <= 1'b1;
			end
		// OP_RLLM: 	begin      // Roll two integer domain registers into an RNS register; for example, reading two bytes from data mem (across two LOAD instructions) and rolling them into an RNS register.
			5'b11001: 
			begin
					RLLM_op_true 		<= 1'b1;
					RNS_dest_reg 		<= 1'b1;
					write_to_regfile 	<= 1'b1;

					op1_addr_IFID <= op1_addr;
					op2_addr_IFID <= op2_addr;
					reg_rd_en <= 1'b1;
			end

			default: 	;			//= NOP
			endcase
	end


    //ID Pipeline Registers
	always @(posedge clk)
	begin
		if (rst == 1'b1) 
		begin
			op1_addr_out_IFID <= 3'b0;
			op2_addr_out_IFID <= 3'b0;
			op3_addr_out_IFID <= 3'b0;
			res_addr_out_IFID <= 3'b0;
			IFID_reg[1] 	  <= 1'b0; //invalidate_decode_instr
		end else
		begin
			op1_addr_out_IFID <=  op1_addr_IFID; //op1 address out for IFID pipeline register
   			op2_addr_out_IFID <=  op2_addr_IFID; //op2 address out for IFID pipeline register
			op3_addr_out_IFID <=  op3_addr_IFID; //op2 address out for IFID pipeline register
   			res_addr_out_IFID <=  store_true ? 3'b0 : res_addr; //destination register address out for IFID pipeline register
   			IFID_reg[1]       <=  branch_taken_EX; //invalidate fetch instruction if branch is taken
		end
	end

	always @(posedge clk)
	begin
        if (rst == 1'b1) begin
            IFID_reg <= 64'b0;
        end else begin
            pred_nxt_prog_ctr   <=  branch_addr; //next program counter value
			op1_dout_IFID 	    <=  op1_data; //op1 data out for IFID pipeline register
			op2_dout_IFID 	    <=  op2_data; //op2 data out for IFID pipeline register
			op3_dout_IFID 	    <=  op3_data; //op2 data out for IFID pipeline register
			IFID_reg[0] 	    <=  invalidate_fetch_instr; //invalidate fetch instruction if branch is taken
			if (branch_taken_EX == 1'b1) begin //even though this just means invalidate_decode_instruction == branch_taken_EX, the original has it this way so we'll keep it
				//if branch is taken, invalidate decode instruction
				IFID_reg[1] <=  1'b1; //invalidate decode instruction
			end else begin
				IFID_reg[1] <=  1'b0; //otherwise, do not invalidate decode instruction
			end
            IFID_reg[2:41] <=  {   //og arr | len | IFID_reg idx 
                add_op_true,            //      (1)    [2]
                or_op_true,             //      (1)    [3]
                not_op_true,            //      (1)    [4]
                and_bitwise_true,       //      (1)    [5]
                or_bitwise_true,        //      (1)    [6]
                not_bitwise_true,       //      (1)    [7]
                and_op_true,            //      (1)    [8]
                carry_in,               //      (1)    [9]
                en_op2_complement,      //      (1)    [10]
                jump_true,              //      (1)    [11]
                compare_true,           //      (1)    [12]
                shift_left_true,        //      (1)    [13]
                lgcl_or_bitwse_T,       //      (1)    [14]
                store_true,             //      (1)    [15]
                load_true_IFID,         //      (1)    [16]
                write_to_regfile,       //      (1)    [17]
                jump_gt,                //      (1)    [18]
                jump_lt,                //      (1)    [19]
                jump_eq,                //      (1)    [20]
                jump_carry,             //      (1)    [21]
                unconditional_jump,     //      (1)    [22]
				ld_imm,					//      (1)    [23] (imm val held in ld_mem_addr)
				imm,					//[7:0] (8)    [24:31] immediate value for LDI instruction
				mul_op_true,			//      (1)    [32]
				RNS_ALU_op,				//      (1)    [33] - RNS ALU operation flag
				UNRL_op_true,			//      (1)    [34] - UNROLL operation flag
				RLLM_op_true,			//      (1)    [35] - ROLL-MODULAR operation flag
				RNS_dest_reg, 		 	//      (1)    [36] - RNS destination register flag
				op1_addr_IFID[3],		//	  	(1)    [37] - op1 file flag, 0 for integer, 1 for RNS
				op2_addr_IFID[3],		//	  	(1)    [38] - op2 file flag, 0 for integer, 1 for RNS
				UNRL_lower,				//      (1)    [39] - Indicate whether an UNRL instruction is storing the lower or upper 8b of RNS reg
				outp_op,				//      (1)    [40] - output operation flag
				inp_op					//      (1)    [41] - input operation
            };                       //total len: 41 bits
        end
	end
endmodule