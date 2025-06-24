//Description: EX Stage of pipeline. Modified from NayanaBannur/8-bit-RISC-Processor to support parameterized values / RNS domains
//             Instantiates ALU for each domain.

module PL_EX #(parameter NUM_DOMAINS = 1, PROG_CTR_WID = 10) (
    input clk, reset,
    //Pipeline registers from IFID
    input [NUM_DOMAINS*8 - 1:0]     op1, op2, op3,          // { [7:0] Domain1, [7:0] Domain2, ... }
    input [2:0]                     res_addr,               // result address for regfile write
    input [PROG_CTR_WID-1:0]        pred_nxt_prog_ctr,      // next program counter value from IFID
    input [0:31]                    IFID_reg,               // IFID pipeline register out
    input                           branch_taken,

    output reg [0:4]                 branch_conds_EX,
    output reg                       branch_taken_EX, //indicate branch was taken in EX stage- reg out needed for timing in Program Counter & IFID I believe
    output reg [15:0]                data_wr_addr, data_rd_addr, //data memory write/read address
    output reg [0:6]                 EX_reg,
    output reg [2:0]                 destination_reg_addr,
    output reg [NUM_DOMAINS*8 - 1:0] operation_result,      // { [7:0] Domain1, [7:0] Domain2, ... }
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
            ld_imm,                 //      (1)    [23]
            imm                     //[7:0] (8)    [24:31]
        };                       //total len: 24 bits
    */
    
    //**// ALU Instantiation //**//
    wire [NUM_DOMAINS*8 - 1:0] cmb_dout; //final output of ALU/Shift/LGCL
    wire cmb_cout, save_cout;

    wire COMP_gt_flag, COMP_lt_flag, COMP_eq_flag;

    PL_ALU ALU (
        .op1_in(op1),
        .op2_in(op2),
        .ALU_ctrl(IFID_reg[2:15]), //IFID_reg[2:15] contains ALU control signals
        .dout(cmb_dout),
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
        //Combined pipeline register elements
        EX_reg[4:6] <= #1 {
            IFID_reg[16],   //load_true_IFID
            IFID_reg[0],    //invalidate_fetch_instr
            IFID_reg[1]     //invalidate_decode_instr
        };
        /////////////////////////////////////
        //Distinct pipeline register elements
        /////////////////////////////////////
        //operation result == 
        //                      IF store_true, op3 ELSE
        //                      IF ld_imm: [7:0] imm 
        //                      ELSE cmb_dout
        //where ld_mem_addr contains the immediate value, cmb_dout is ALU output
        operation_result <= #1 IFID_reg[15] ? op3 : (IFID_reg[23] ? imm : cmb_dout);

        data_wr_addr <= #1 IFID_reg[15] ? {op2, op1} : 16'b0; //if store_true, write to st_mem_addr_reg, else write to ld_mem_addr_reg
        data_rd_addr <= #1 IFID_reg[16] ? {op2, op1} : 16'b0; //if load_true_IFID, write to ld_mem_addr_reg, else write to st_mem_addr_reg

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
            /*
                store_to_mem_ex <= #1 1'b0;
                reg_wr_en_ex <= #1 1'b0;
                invalidate_execute_instr <= 1'b0;
                save_cout <= 1'b0;
            */
           // branch_taken_EX <= #1 1'b0;
            destination_reg_addr <= 3'b0;
        end
        else begin
            branch_taken_EX <= #1 branch_taken && !branch_taken_EX && !IFID_reg[0]; 
            //'!branch_taken_EX` (the last state of the reg) prevents JMP execution if JMP instr comes directly after a conditional JMP
            //'!IFID_reg[0]` also checks invalidate_fetch_instr, just to be safe.
            EX_reg[0:3] <= #1 {
                IFID_reg[15],   //store_true
                IFID_reg[17],   //write_to_regfile
                save_cout,
                branch_taken_EX //invalidate_execute_instr
            };
            destination_reg_addr <= #1 res_addr;
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
            invalidate_decode_instr     (1)    [6]
        }
    */
endmodule