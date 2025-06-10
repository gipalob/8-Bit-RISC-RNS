//Description: EX Stage of pipeline. Modified from NayanaBannur/8-bit-RISC-Processor to support parameterized values / RNS domains
//             Instantiates ALU for each domain.

module PL_EX #(parameter NUM_DOMAINS = 1, PROG_CTR_WID = 10) (
    input clk, reset,
    //Pipeline registers from IFID
    input [NUM_DOMAINS*8 - 1:0]     op1, op2,               // { [7:0] Domain1, [7:0] Domain2, ... }
    input [PROG_CTR_WID-1:0]        pred_nxt_prog_ctr,      // next program counter value from IFID
    input [38:0]                    IFID_reg,               // IFID pipeline register out
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
            ld_mem_addr,            //[7:0] (8)    [23:30]
            st_mem_addr             //[7:0] (8)    [31:38] 
        };                       //total len: 39 bits
    */
    reg [NUM_DOMAINS*8 - 1:0] din_1, din_2; //ALU op1/op2

    //trigger at op1, op2, en_op2_comp,    store_true,     add_op_true, lgcl_or_btwse_T, shift_left_true   
    always @(op1 or op2 or IFID_reg[10] or IFID_reg[15] or IFID_reg[2] or IFID_reg[14] or IFID_reg[13])
    begin
        din_1 <= op1; //always passed as-is
        if (IFID_reg[15] == 1'b1) begin //if store_true
            din_2 <= 8'b0;
        end 
        else if (IFID_reg[10] == 1'b1) begin //if en_op2_complement
            din_2 <= ~op2;
        end
        else begin
            din_2 <= op2;
        end
    end


endmodule