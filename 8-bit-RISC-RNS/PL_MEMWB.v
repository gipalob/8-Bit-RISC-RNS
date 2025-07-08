// Description: Memory / Write Back (to reg) Pipeline stage - modified from NayanaBannur/8-bit-RISC-Processor

module PL_MEMWB #(parameter NUM_DOMAINS = 1, PROG_CTR_WID = 10) (
    input clk, reset,
    //Pipeline registers from EX
    input [NUM_DOMAINS*8 - 1:0] operation_result, // { [7:0] Domain1, [7:0] Domain2, ... }
    input [0:7] EX_reg,
    input [0:4] branch_conds_EX,

    //Other
    input [7:0] dmem_dout, //data read from data memory

    //Outputs
    output reg [0:3] branch_conds_MEMWB,
    output invalidate_instr,              //invalidate instruction in IFID pipeline register
    output mem_wr_en,                     
    output reg_wr_en,
    output destination_RNS,
    output [NUM_DOMAINS*8 - 1:0] wr_data // { [7:0] Domain1, [7:0] Domain2, ... }
);
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
        destination_RNS             (1)    [7]
    }
*/
    assign wr_data =            EX_reg[4] ? {8'b0, dmem_dout} : operation_result;
    assign invalidate_instr =   (EX_reg[3] || EX_reg[5] || EX_reg[6]);
    assign mem_wr_en =          (EX_reg[0] && !invalidate_instr);
    assign reg_wr_en =          (EX_reg[1] && !invalidate_instr);
    assign destination_RNS =    EX_reg[7]; //if 1, write to RNS reg file, else write to normal reg file


    //Pipeline registers
    always @(posedge clk)
	begin                                
        if (reset == 1'b1)                     
        begin
            branch_conds_MEMWB <= #1 4'b0;
        end
        else begin
            branch_conds_MEMWB <= #1 4'b0; //reset branch conditions
            if ((EX_reg[2] && !invalidate_instr) == 1'b1)
                branch_conds_MEMWB[3] <= #1 branch_conds_EX[3]; //does this always get reset to X or 0? 

            if ((branch_conds_EX[4] && !invalidate_instr) == 1'b1) //if compare_true && not invalidate_instr
            begin
                branch_conds_MEMWB[0] <= #1 branch_conds_EX[0];
                branch_conds_MEMWB[1] <= #1 branch_conds_EX[1];
                branch_conds_MEMWB[2] <= #1 branch_conds_EX[2];
            end
        end
	end
endmodule