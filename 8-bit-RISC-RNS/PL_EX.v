//Description: EX Stage of pipeline. Modified from NayanaBannur/8-bit-RISC-Processor to support parameterized values / RNS domains
//             Instantiates ALU for each domain.
                                                            // 9-bit moduli max to fit 256.
module PL_EX #(parameter NUM_DOMAINS = 1, PROG_CTR_WID = 10, [9 * NUM_DOMAINS-1:0] MODULI = {9'd256, 9'd129}) (
    input clk, reset,
    //Pipeline registers from IFID
    input [NUM_DOMAINS*8 - 1:0]     op1, op2,               // { [7:0] Domain1, [7:0] Domain2, ... }
    input [7:0]                     op3,
    input [2:0]                     res_addr,               // result address for regfile write
    input [PROG_CTR_WID-1:0]        pred_nxt_prog_ctr,      // next program counter value from IFID
    input [0:41]                    IFID_reg,               // IFID pipeline register out
    input                           branch_taken,

    output reg [0:4]                 branch_conds_EX,
    output reg                       branch_taken_EX, //indicate branch was taken in EX stage- reg out needed for timing in Program Counter & IFID I believe
    output reg [15:0]                data_wr_addr, data_rd_addr, //data memory write/read address
    output reg [0:9]                 EX_reg,
    output reg [3:0]                 destination_reg_addr, // {RNS_file, [2:0] addr}
    output reg [NUM_DOMAINS*8 - 1:0] operation_result,      // { [7:0] Domain1, [7:0] Domain2, ... }
    output reg [7:0]                 IO_port_ID,            // ID of the port for INPUT / OUTPUT instructions
    output reg [PROG_CTR_WID-1:0]    pred_nxt_prog_ctr_EX
);
    /*
        Map of IFID_reg input:
        IFID_reg <= #1 {          //og arr | len | IFID_reg idx 
            invalidate_fetch_instr, //      (1)    [0]
            branch_taken_EX,        //      (1)    [1]     invalidate_decode_instr = branch_taken_EX. so we can just pass that
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
            op1_file,				//	  	(1)    [37] - op1 file flag, 0 for integer, 1 for RNS
            op2_file,				//	  	(1)    [38] - op2 file flag, 0 for integer, 1 for RNS
            UNRL_lower,				//      (1)    [39] - Indicate whether an UNRL instruction is storing the lower or upper 8b of RNS reg
            outp_op,				//      (1)    [40] - output operation flag
            inp_op                  //      (1)    [41] - input operation flag
        };                       //total len: 41 bits
    */
    
    //**// ALU Instantiation //**//
    wire [NUM_DOMAINS*8 - 1:0] RNS_dout; //final output of ALU
    wire [7:0] ALU_dout; //final output of ALU, for integer domain
    wire cmb_cout, save_cout;

    wire COMP_gt_flag, COMP_lt_flag, COMP_eq_flag;

    if (NUM_DOMAINS > 1)
    begin
        genvar i;
        for (i = 0; i < NUM_DOMAINS; i = i + 1) 
        begin: ALU_RNS_GENBLK
            /*
                Below input logic for op1 and op2 allows support for int-domain rs; if src regfile is RNS, then use the value held in reg for that domain, else use the 8-bit int domain src.
            */
            PL_ALU_RNS #(MODULI[i*9 +: 9]) RNS_ALU(
                .op1_in((IFID_reg[37] == 1'b1) ? op1[i*8 +: 8] : op1[7:0]),
                .op2_in((IFID_reg[38] == 1'b1) ? op2[i*8 +: 8] : op2[7:0]),
                .ALU_ctrl({IFID_reg[2:15], IFID_reg[32]}), //IFID_reg[2:15] contains ALU control signals, IFID_reg[32] is mul_op_true
                .RNS_ALU_EN(IFID_reg[33]), //RNS operation flag
                .dout(RNS_dout[i*8 +: 8])
            );
        end
    end
    
    //Generate integer domain ALU regardless of whether RNS is enabled
    PL_ALU ALU (
        .ALU_EN(!IFID_reg[33]), //if RNS_ALU_EN is 0, use normal ALU
        .op1_in(op1[7:0]),
        .op2_in(op2[7:0]),
        .ALU_ctrl(IFID_reg[2:15]), //IFID_reg[2:15] contains ALU control signals
        .dout(ALU_dout),
        .cout(cmb_cout),
        .COMP_gt(COMP_gt_flag),
        .COMP_lt(COMP_lt_flag),
        .COMP_eq(COMP_eq_flag)
    );

    assign save_cout = (IFID_reg[2] && !IFID_reg[12]) || IFID_reg[13]; //save cout if we're adding and not comparing, or if we're shifting left
    //**//                   //**//

    //**// EX Stage Pipeline Register Out //**//
    wire [7:0] imm;
    assign imm = IFID_reg[24:31]; //immediate value from IFID pipeline register

    always @(posedge clk)
	begin
        IO_port_ID <= #1 8'b0; //reset IO port ID
        
        //Combined pipeline register elements
        EX_reg[4:9] <= #1 {
            IFID_reg[16],   //load_true_IFID
            IFID_reg[0],    //invalidate_fetch_instr
            IFID_reg[1],     //invalidate_decode_instr
            IFID_reg[36],
            IFID_reg[40], //outp_op
            IFID_reg[41]  //inp_op
        };
        /////////////////////////////////////
        //Distinct pipeline register elements
        /////////////////////////////////////
        if (IFID_reg[33]) begin
            operation_result <= #1 RNS_dout;                // if RNS operation, use RNS output
        end else if (IFID_reg[35]) begin
            operation_result <= #1 {op1[7:0], op2[7:0]};    // For RLLM-Values that go into domain2, domain1 for mod-domain rd
        end else if (IFID_reg[15]) begin
            operation_result <= #1 {8'b0, op3};             // if store_true, use op3
        end else if (IFID_reg[23]) begin
            operation_result <= #1 {8'b0, imm};             // if ld_imm, use immediate value
        end else if (IFID_reg[34]) begin                        
            operation_result <= #1 {8'b0, (IFID_reg[39] == 1'b1) ? op1[7:0] : op1[15:8]}; //UNRL- If UNRLL, use lower 8b, else upper 8b
        end else if (IFID_reg[40]) begin
            operation_result <= #1 {8'b0, op3};             //OUTPUT will hold data to be placed on output port in op3
            IO_port_ID <= #1 imm;
        end else if (IFID_reg[41]) begin                    //INPUT data is read in MEMWB, as that's where the read strobe is raised
            IO_port_ID <= #1 imm;
        end else begin
            operation_result <= #1 {8'b0, ALU_dout};            // else use ALU output
        end

        data_wr_addr <= #1 IFID_reg[15] ? {op1[7:0], op2[7:0]} : 16'b0; //if store_true, write to st_mem_addr_reg, else write to ld_mem_addr_reg
        data_rd_addr <= #1 IFID_reg[16] ? {op1[7:0], op2[7:0]} : 16'b0; //if load_true_IFID, write to ld_mem_addr_reg, else write to st_mem_addr_reg

        branch_conds_EX <= #1 {
            COMP_gt_flag,
            COMP_lt_flag,
            COMP_eq_flag,
            save_cout && cmb_cout,
            IFID_reg[12] //compare_true_EX
        };   

        pred_nxt_prog_ctr_EX <= #1 pred_nxt_prog_ctr;
	end

    //Seperate, to disable register / memory writes during reset
    always @(posedge clk)
    begin
        if (reset == 1'b1)
        begin
            EX_reg[0:3] <= #1 4'b0;
            destination_reg_addr <= 4'b0;
        end
        else begin
            branch_taken_EX <= #1 branch_taken && !branch_taken_EX && !IFID_reg[0]; 
            //'!branch_taken_EX` (the last state of the reg) prevents JMP execution if JMP instr comes directly after a conditional JMP
            //'!IFID_reg[0]` also checks invalidate_fetch_instr, just to be safe to check against other currently-in-pipeline instructions
            
            EX_reg[0:3] <= #1 {
                IFID_reg[15],   //store_true
                IFID_reg[17],   //write_to_regfile
                save_cout,
                branch_taken_EX //invalidate_execute_instr
            };
        //  destination_reg_addr <=   {RNS_operation, [2:0] destination_reg_addr}
            destination_reg_addr <= #1 {IFID_reg[36], res_addr};
            // will need to modify condition for reconstruct operation
        end
    end

    /*
        EX_reg signals:                 Len. | Index
        {
            store_to_mem,               (1)    [0]
            reg_wr_en,                  (1)    [1]
            save_cout,                  (1)    [2]
            invalidate_execute_instr,   (1)    [3]
            load_true,                  (1)    [4]
            invalidate_fetch_instr,     (1)    [5]
            invalidate_decode_instr,    (1)    [6]
            destination_RNS,            (1)    [7]
            outp_op,                    (1)    [8]
            inp_op                      (1)    [9]
        }
    */
endmodule