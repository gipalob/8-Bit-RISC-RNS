// Description: Pipeline stage: IF/ID
//              Modified from nayanaBannur/8-bit-RISC-Processor
//              every stage after ID has all signals packaged into a single register

module PL_IFID #(parameter PROG_CTR_WID) (
    input wire clk,
    input wire rst,
    //IO signals for IF
    input wire [15:0] instr_mem_out,    //from intr_mem
    input branch_taken_reg,
    input [7:0] op1_data,               //data for op1 from ctrl_Forward 
    input [7:0] op2_data,               //data for op2 from ctrl_Forward

    output reg [2:0] op1_addr_IFID,              //op1_addr to ctrl_Forward
    output reg [2:0] op2_addr_IFID,              //op2_addr to ctrl_Forward
    output reg load_true_IFID,                   //load instruction flag to ctrl_Forward
    output reg [63:0] IFID_reg    //IFID pipeline register out
    output reg [PROG_CTR_WID-1:0] nxt_prog_ctr_reg //easier to keep this seperate as it's dynamic size
);

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // Instruction Fetch
    reg [15:0] instruction; //instruction fetched from memory
    reg invalidate_fetch_instr; //flag to invalidate fetch instruction if branch is taken

    always @(posedge clk) 
    begin
        if (rst) begin
            instruction <= 16'b0;
            invalidate_fetch_instr <= 1'b0;
        end else begin
            instruction <= instr_mem_out;

            if (branch_taken_reg)
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
    reg [7:0] ld_mem_addr; //load memory address
    reg [7:0] st_mem_addr; //store memory address
    reg [9:0] branch_addr; //branch address
    reg [PROG_CTR_WID-1:0] nxt_prog_ctr; //next program counter value

    always @(instruction) 
    begin
		opcode	        <= instruction[15:11];
		op1_addr_IFID	<= instruction[2:0];
		op2_addr_IFID   <= instruction[6:4];
		res_addr	    <= instruction[10:8];
		ld_mem_addr     <= instruction[7:0];
		st_mem_addr     <= instruction[10:3];
		branch_addr     <= instruction[9:0];
	end

    reg add_op_true, and_op_true, or_op_true, not_op_true;      //operation flags
    reg and_bitwise_true, or_bitwise_true, not_bitwise_true;    //bitwise operation flags
    reg carry_in, en_op2_complement;                            //flags for carry and complement operations
    reg jump_true, compare_true, shift_left_true;               //flags for jump and comparison operations
    reg lgcl_or_bitwse_T;                                       //flag for logical or bitwise operations
    reg store_true;                                             //flags for store operations - load flag is output reg for ctrl_Forward
    reg write_to_regfile;                                       //flag to write to register file
    reg unconditional_jump;                                     //flag for unconditional jump
    reg jump_gt, jump_lt, jump_eq, jump_carry;                  //flags for conditional jumps

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
		load_true_IFID <= 1'b0;
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

		//	OP_LOAD:	begin
			5'h01000: 
            begin
					load_true_IFID <= 1'b1;
					write_to_regfile <= 1'b1;
			end                      
                                                      
		//	OP_STORE:	store_true <= 1'b1;
			5'b01001:	store_true <= 1'b1;

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

			default: 	;			//= NOP
			endcase
	end


    //ID Pipeline Registers
	always @(posedge clk)
	begin
        if (rst == 1'b1) begin
            IFID_reg <= 64'b0;
        end else begin
            IFID_reg <= #1 {          //og arr | len | IFID_reg idx
                op1_data,               //[7:0] (8)    [0:7]
                op2_data,               //[7:0] (8)    [8:15]
                ld_mem_addr,            //[7:0] (8)    [16:23]
                st_mem_addr,            //[7:0] (8)    [24:31]  
                op1_addr,               //[2:0] (3)    [32:34]  
                op2_addr,               //[2:0] (3)    [35:37]
                res_addr,               //[2:0] (3)    [38:40] 
                invalidate_fetch_instr, //      (1)    [41]
                branch_taken_reg,       //      (1)    [42]     invalidate_decode_instr = branch_taken_reg. so we can just pass that
                add_op_true,            //      (1)    [43]
                or_op_true,             //      (1)    [44]
                not_op_true,            //      (1)    [45]
                and_bitwise_true,       //      (1)    [46]
                or_bitwise_true,        //      (1)    [47]
                not_bitwise_true,       //      (1)    [48]
                and_op_true,            //      (1)    [49]
                carry_in,               //      (1)    [50]
                en_op2_complement,      //      (1)    [51]
                jump_true,              //      (1)    [52]
                compare_true,           //      (1)    [53]
                shift_left_true,        //      (1)    [54]
                lgcl_or_bitwse_T,       //      (1)    [55]
                store_true,             //      (1)    [56]
                load_true_IFID,         //      (1)    [57]
                write_to_regfile,       //      (1)    [58]
                jump_gt,                //      (1)    [59]
                jump_lt,                //      (1)    [60]
                jump_eq,                //      (1)    [61]
                jump_carry,             //      (1)    [62]
                unconditional_jump,     //      (1)    [63]
            }                       //total len: 64 bits
        end
	end
endmodule