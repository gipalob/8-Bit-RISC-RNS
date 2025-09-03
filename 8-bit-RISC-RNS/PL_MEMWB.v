// Description: Memory / Write Back (to reg) Pipeline stage - modified from NayanaBannur/8-bit-RISC-Processor

module PL_MEMWB #(parameter NUM_DOMAINS = 1, PROG_CTR_WID = 10) (
    input clk, reset,
    //Pipeline registers from EX
    input [NUM_DOMAINS*8 - 1:0] operation_result, // { [7:0] Domain1, [7:0] Domain2, ... }
    input [7:0] IO_read_data,
    input [0:9] EX_reg,
    input [0:4] branch_conds_EX,

    input [7:0] dmem_dout, //data read from data memory

    //Outputs
    output reg [0:3] branch_conds_MEMWB,
    output invalidate_instr,              //invalidate instruction currently in IFID
    output mem_wr_en,             
    output mem_rd_en,        
    output reg_wr_en,
    output [NUM_DOMAINS*8 - 1:0] wr_data, // { [7:0] Domain1, [7:0] Domain2, ... }
    //For INPUT / OUTPUT instructions
    output [7:0] IO_write_data,
    output IO_write_strobe,
    output IO_read_strobe
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
        destination_RNS,            (1)    [7]
        outp_op,                    (1)    [8]
        inp_op                      (1)    [9]
    }
*/
    assign wr_data =            (EX_reg[9] == 1'b1) ? {8'b0, IO_read_data} : ((EX_reg[4]==1'b1) ? {8'b0, dmem_dout} : operation_result);
    assign invalidate_instr =   (EX_reg[3] || EX_reg[5] || EX_reg[6]);
    assign mem_wr_en =          (EX_reg[0] && !invalidate_instr);
    assign mem_rd_en =          (EX_reg[4] && !invalidate_instr);
    assign reg_wr_en =          (EX_reg[1] && !invalidate_instr);

    assign IO_write_data =      (EX_reg[8] == 1'b1) ? operation_result[7:0] : 8'b0; //output data is always the lowest 8 bits of the operation result
    assign IO_write_strobe =    (EX_reg[8] && !invalidate_instr); //PL_EX sets IO_port_ID to val from imm and operation_result to op3. MEMWB raises strobe as soon as EX PL reg populated 
    assign IO_read_strobe =     (EX_reg[9] && !invalidate_instr); //PL_EX sets IO_port_ID to val from imm and operation_result to data held on input port. MEMWB raises strobe as soon as EX PL reg populated

    always @(posedge clk)
	begin                                
        if (reset == 1'b1)                     
        begin
            branch_conds_MEMWB <=  4'b0;
        end
        else begin
            branch_conds_MEMWB <=  4'b0; //reset branch conditions
            if ((EX_reg[2] && !invalidate_instr) == 1'b1)
                branch_conds_MEMWB[3] <=  branch_conds_EX[3];

            if ((branch_conds_EX[4] && !invalidate_instr) == 1'b1) //if compare_true && not invalidate_instr
            begin
                branch_conds_MEMWB[0] <=  branch_conds_EX[0];
                branch_conds_MEMWB[1] <=  branch_conds_EX[1];
                branch_conds_MEMWB[2] <=  branch_conds_EX[2];
            end
        end
	end
endmodule