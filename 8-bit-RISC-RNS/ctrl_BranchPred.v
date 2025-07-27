//Description: Very simple Branch Prediction Unit for 8-bit RISC-RNS processor, modified from NayanaBannur/8-bit-RISC-Processor to support dual-domain RNS

module ctrl_BranchPred (
    input [0:4] conds_IFID, //{jump_gt, jump_lt, jump_eq, jump_carry, unconditional_jump} from IFID pipeline register
    input [0:4] conds_EX,       // {COND_gt_flag, COND_lt_flag, COND_eq_flag, carry_flag, compare_true_EX} that are currently WITHIN EX stage
    input [0:3] conds_MEMWB,   // {COND_gt_flag, COND_lt_flag, COND_eq_flag, carry_flag} that have most recently EXITED EX stage
    input invalidate_instr,

    output branch_taken
);
    wire gt_flag_true, lt_flag_true, eq_flag_true, carry_flag_true;

    assign gt_flag_true =       (((conds_EX[4] && !invalidate_instr) == 1'b1) && conds_EX[0]) || conds_MEMWB[0];
    assign lt_flag_true =       (((conds_EX[4] && !invalidate_instr) == 1'b1) && conds_EX[1]) || conds_MEMWB[1];
    assign eq_flag_true =       (((conds_EX[4] && !invalidate_instr) == 1'b1) && conds_EX[2]) || conds_MEMWB[2];
    assign carry_flag_true =    (((conds_EX[4] && !invalidate_instr) == 1'b1) && conds_EX[3]) || conds_MEMWB[3];


    //Determine whether branch is taken based on what JMP inst is currently in IFID and what the result of the compare op currently in EX is
    assign branch_taken = 
        (conds_IFID[0] && gt_flag_true) || 
        (conds_IFID[1] && lt_flag_true) || 
        (conds_IFID[2] && eq_flag_true) || 
        (conds_IFID[3] && carry_flag_true) || 
        conds_IFID[4];

endmodule