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
	input [NUM_DOMAINS*8 - 1:0]			op3_data,           //data for op2 from ctrl_Forward

    output reg [3:0] 					op1_addr_IFID,  //ID: op1_addr to ctrl_Forward
    output reg [3:0] 					op2_addr_IFID,  //ID: op2_addr to ctrl_Forward
	output reg [2:0]                    op3_addr_IFID,  //ID: op3_addr to ctrl_Forward
    output reg 							load_true_IFID,     //ID: load instruction flag to ctrl_Forward

    //pipeline register out to next stage
    output reg [0:33] 					IFID_reg,    		//IFID pipeline register out
    output reg [PROG_CTR_WID-1:0] 		pred_nxt_prog_ctr, 	//inst address to jump to on successful branch evaluation - pulled from inst in ID
	output reg [NUM_DOMAINS*8 - 1:0] 	op1_dout_IFID, 		//op1 data out for IFID pipeline register - easier to keep this seperate as it's dynamic size
	output reg [NUM_DOMAINS*8 - 1:0] 	op2_dout_IFID,		//op2 data out for IFID pipeline register - easier to keep this seperate as it's dynamic size
	output reg [NUM_DOMAINS*8 - 1:0] 	op3_dout_IFID,		//op3 data out for IFID pipeline register - easier to keep this seperate as it's dynamic size
    output reg [3:0]                    op1_addr_out_IFID,
    output reg [3:0]                    op2_addr_out_IFID,
	output reg [2:0]                    op3_addr_out_IFID, //op3 is rs for RSTORE
    output reg [3:0]                    res_addr_out_IFID,
	output reg [4:0] debug_opcode_IFID //debug: opcode of instruction in IFID stage
);

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // Instruction Fetch
    reg [15:0] instruction; //instruction fetched from memory
    reg invalidate_fetch_instr; //flag to invalidate fetch instruction if branch is taken

	always @(rst)
	begin
		if (rst == 1'b1)                          
		begin
			instruction <= 16'b0;
		end
	end
	
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
    //reg [7:0] ld_mem_addr; //load memory address
    reg [9:0] branch_addr; //branch address
    reg [PROG_CTR_WID-1:0] nxt_prog_ctr; //next program counter value

	//For custom instructions:
	reg [7:0] imm; //8-bit immediate for LDI

    always @(instruction) 
    begin
		opcode	        	<= instruction[15:11];
		res_addr	    	<= instruction[10:8];
		imm			    	<= instruction[7:0];
		op2_addr_IFID	   	<= instruction[7:4]; //bit 7 is rs2 domain flag; 1 == RNS, 0 == normal int
		op1_addr_IFID		<= instruction[3:0]; //bit 4 is rs1 domain flag; 1 == RNS, 0 == normal int
		branch_addr     	<= instruction[9:0];
	end
	/*
		Will need to modify to throw an error if:
			(inst[7] == 1 || inst[3] == 1) && (RNS_op_true == 0), pipeline error
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
	reg ld_imm, mul_op_true, RNS_op_true;

    always@ (opcode or branch_addr)        
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
		RNS_op_true <= 1'b0;
		mul_op_true <= 1'b0;
		
		ld_imm <= 1'b0;
		op3_addr_IFID <= 3'b0; //reset op3_addr_IFID

		case (opcode)
		//	OP_NOP:  
		//	5'h00:   	;		
		
		//	OP_ADD:	begin
			5'b00001: 
            begin
					write_to_regfile <= 1'b1;
					add_op_true <= 1'b1;
			end
	
		//	OP_SUB:	begin
			5'b00010: 
            begin
					add_op_true <= 1'b1;	
					carry_in	<= 1'b1;
					en_op2_complement <= 1'b1;
					write_to_regfile <= 1'b1;
			end

		//	OP_AND:	begin
			5'b00011: 
            begin
					and_op_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1;     
			end

		//	OP_OR:	begin
			5'b00100: 
            begin
					or_op_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1;
			end

		//	OP_NOT:	begin
			5'b00101: 
            begin
					not_op_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1;
			end

		//	OP_SHL	begin                  
			5'b00110: 
            begin
					shift_left_true <= 1'b1;
					write_to_regfile <= 1'b1;
			end

		//	OP_JMP:	begin
			5'b00111: 
            begin
					nxt_prog_ctr <= branch_addr;
					jump_true	<= 1'b1;
					unconditional_jump <= 1'b1;
		    end
	//Original load / store instructions
	// 	//	OP_LOAD:	begin 
	// 		5'b01000:
    //         begin
	// 				load_true_IFID <= 1'b1;
	// 				write_to_regfile <= 1'b1;
	// 		end                      
                                                      
	// 	//	OP_RSTORE:	begin
	// 		5'b01001:
    //         begin
    //                 store_true <= 1'b1;
    //         end
	//	OP_RLOAD:	begin 
			5'b01000: //'RLOAD': Load from mem to reg 'rd'; LOADR rd, rs1=addr[0:7], rs2=addr[8:15] where rs1 and rs2 are registers that hold the lower and upper 8b of the 16b address
            begin
					load_true_IFID <= 1'b1;
					write_to_regfile <= 1'b1;
			end                      
                                                      
		//	OP_RSTORE:	begin
			5'b01001: //'RSTORE': Store to mem from reg 'rs'; STORER rs, rd1=addr[0:7], rd2=addr[8:15] where rd1 and rd2 are registers that hold the lower and upper 8b of the 16b address
            begin
                    store_true <= 1'b1;
					op3_addr_IFID <= res_addr; //op3 is rs for RSTORE
            end
    /*
     /*
        FOR RLOAD AND RSTORE:
            RLOAD:  res_addr is DESTINATION reg addr
                    register at op1_addr_IFID contains lower 8b of address
                    register at op2_addr_IFID contains upper 8b of address
            RSTORE: res_addr is SOURCE reg addr
                    register at op1_addr_IFID contains lower 8b of address
                    register at op2_addr_IFID contains upper 8b of address
            
            That's the plan- keep them as they were in original implementation until refactoring done

    */

		//	OP_ANDBIT:	begin
			5'b01010:	
            begin
					and_bitwise_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1; 
			end

		//	OP_ORBIT:	begin
			5'b01011:	
            begin
					or_bitwise_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1;
			end

		//	OP_NOTBIT:	begin
			5'b01100:	
            begin
					not_bitwise_true <= 1'b1;
					lgcl_or_bitwse_T <= 1'b1;
					write_to_regfile <= 1'b1;
			end
 
		//	OP_COMPARE: begin
			5'b01101:	
            begin
					add_op_true <= 1'b1;
					compare_true <= 1'b1;	
					carry_in	<= 1'b1;   //subtract
					en_op2_complement <= 1'b1;
			end

		//	OP_JMPGT:	begin
			5'b01110:	
            begin
					nxt_prog_ctr <= branch_addr;
					jump_true	<= 1'b1;
					jump_gt <= 1'b1;
			end

		//	OP_JMPLT:	begin
			5'b01111:	
            begin
					nxt_prog_ctr <= branch_addr;
					jump_true	<= 1'b1;
					jump_lt <= 1'b1;
					end
		//	OP_JMPEQ:	begin
			5'b10000:	
            begin
					nxt_prog_ctr <= branch_addr;
					jump_true	<= 1'b1;
					jump_eq <= 1'b1;
			end

		//	OP_JMPC:	begin
			5'b10001: 
            begin
					nxt_prog_ctr <= branch_addr;
					jump_true	<= 1'b1;
					jump_carry <= 1'b1;
			end
////////////////////////////////////////////////////////////
//NEW CUSTOM INSTRUCTIONS (ignoring RLOAD and RSTORE above):
////////////////////////////////////////////////////////////
		//	OP_LDI:	begin 
			5'b10010: //'LDI': Load 8-bit immediate; immediate held in same bit indices as ld_mem_addr, res_addr is dest reg addr. EX stage will set operation_result to imm on ld_imm flag, effectively storing as if the immediate was an arithmetic result
            begin
					ld_imm <= 1'b1;
					write_to_regfile <= 1'b1;
			end           

//RNS Instructions
		//	OP_ADDMD:	begin 
			5'b10011: 
			begin
					RNS_op_true <= 1'b1;
					write_to_regfile <= 1'b1;
					add_op_true <= 1'b1;
			end
		//	OP_SUBMD:	begin 
			5'b10100: 
			begin
					RNS_op_true <= 1'b1;
					write_to_regfile <= 1'b1;
					en_op2_complement <= 1'b1; //subtract
					add_op_true <= 1'b1;
					//No two's compl;ement needed for RNS subtraction, as it is done in the RNS domain
			end
		//	OP_MULMD:	begin 		
			5'b10101: 
			begin
					RNS_op_true <= 1'b1;
					write_to_regfile <= 1'b1;
					mul_op_true <= 1'b1;
			end
		//	OP_RECNST:	begin 		
			5'b10110: 
			begin
					RNS_op_true <= 1'b1;
					write_to_regfile <= 1'b1;
					//need to write the logic for this
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
			op1_addr_out_IFID <= #1 op1_addr_IFID; //op1 address out for IFID pipeline register
   			op2_addr_out_IFID <= #1 op2_addr_IFID; //op2 address out for IFID pipeline register
			op3_addr_out_IFID <= #1 op3_addr_IFID; //op2 address out for IFID pipeline register
   			res_addr_out_IFID <= #1 store_true ? 3'b0 : res_addr; //destination register address out for IFID pipeline register
   			IFID_reg[1]       <= #1 branch_taken_EX; //invalidate fetch instruction if branch is taken
		end
	end

	always @(posedge clk)
	begin
        if (rst == 1'b1) begin
            IFID_reg <= 64'b0;
        end else begin
			debug_opcode_IFID <= #1 opcode; //debug: opcode of instruction in IFID stage
            pred_nxt_prog_ctr   <= #1 nxt_prog_ctr; //next program counter value
			op1_dout_IFID 	    <= #1 op1_data; //op1 data out for IFID pipeline register
			op2_dout_IFID 	    <= #1 op2_data; //op2 data out for IFID pipeline register
			op3_dout_IFID 	    <= #1 op3_data; //op2 data out for IFID pipeline register
			IFID_reg[0] 	    <= #1 invalidate_fetch_instr; //invalidate fetch instruction if branch is taken
			if (branch_taken_EX == 1'b1) begin //even though this just means invalidate_decode_instruction == branch_taken_EX, the original has it this way so we'll keep it
				//if branch is taken, invalidate decode instruction
				IFID_reg[1] <= #1 1'b1; //invalidate decode instruction
			end else begin
				IFID_reg[1] <= #1 1'b0; //otherwise, do not invalidate decode instruction
			end
            IFID_reg[2:32] <= #1 {   //og arr | len | IFID_reg idx 
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
				RNS_op_true				//      (1)    [33] - RNS operation flag, set to 1 for RNS instructions
            };                       //total len: 33 bits
        end
	end
endmodule