// Description: Forwarding unit for pipeline control
// Modified from Pipelined implementation from GH repo hushon/Tiny-RISCV-CPU/
module Forwarding(
    input [2:0] op1_addr_IFID,               //source register 1 address from IF/ID
    input [2:0] op2_addr_IFID,               //source register 2 address from IF/ID
    input [2:0] destination_reg_addr,   //destination register address from
    input reg_wr_en,                    //register write enable signal
    input load_true,                    //load instruction flag
    input [7:0] datamem_wr_data,        //data memory write data (for load instruction)
    input [7:0] op1_rd_data,            //data read from register file for op1
    input [7:0] op2_rd_data,            //data read from register file for op2

    //Inputs specific for fwd logic for EX stage
    input [2:0] op1_addr_reg,           //source register 1 address in EX stage (pulled from IFID pipeline register)
    input [2:0] op2_addr_reg,           //source register 2 address in EX stage (pulled from IFID pipeline register)
    input [7:0] op1_data_reg,           //data read from register file for op1 in EX stage (pulled from IFID pipeline register)
    input [7:0] op2_data_reg,           //data read from register file for op2 in EX stage (pulled from IFID pipeline register)
    input reg_wr_en_reg,                //register write enable signal in EX stage
    input load_true_reg,                //load instruction flag in EX stage

    output reg bypass_op1_dcd_stage,    //bypass signal for op1 in decode stage
    output reg bypass_op2_dcd_stage,    //bypass signal for op2 in decode stage
    output [7:0] op1_data,              //data for op1 after bypassing if needed
    output [7:0] op2_data               //data for op2 after bypassing if needed
    output [7:0] operand1,              //operand 1 for EX stage after bypassing if needed
    output [7:0] operand2               //operand 2 for EX stage after bypassing if needed
    );
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //Forwarding logic for IF/ID
    always @(op1_addr or destination_reg_addr or reg_wr_en or load_true)

        begin
        if ((op1_addr == destination_reg_addr) && (reg_wr_en == 1'b1) && (load_true == 1'b0))
            bypass_op1_dcd_stage <= 1'b1;
        else
            bypass_op1_dcd_stage <= 1'b0;
        end

    always @(op2_addr or destination_reg_addr or reg_wr_en or load_true)

        begin
        if ((op2_addr == destination_reg_addr) && (reg_wr_en == 1'b1) && (load_true == 1'b0))
            bypass_op2_dcd_stage <= 1'b1;
        else
            bypass_op2_dcd_stage <= 1'b0;
        end

    assign op1_data = bypass_op1_dcd_stage  ? datamem_wr_data : op1_rd_data;
    assign op2_data = bypass_op2_dcd_stage  ? datamem_wr_data : op2_rd_data;
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //Forwarding logic for EX
    always @(op1_addr_reg or destination_reg_addr or reg_wr_en or op2_addr_reg or load_true_reg)

        begin
        if ((op1_addr_reg == destination_reg_addr) && (reg_wr_en == 1'b1) && (load_true_reg == 1'b0))
            bypass_op1_ex_stage <= 1'b1;
        else
            bypass_op1_ex_stage <= 1'b0;

        if ((op2_addr_reg == destination_reg_addr) && (reg_wr_en == 1'b1) && (load_true_reg == 1'b0))
            bypass_op2_ex_stage <= 1'b1;
        else
            bypass_op2_ex_stage <= 1'b0;
        end

    assign operand1 = bypass_op1_ex_stage  ? datamem_wr_data : op1_data_reg;
    assign operand2 = bypass_op2_ex_stage  ? datamem_wr_data : op2_data_reg;
    //////////////////////////////////////////////////////////////////////////////////////////////////////
endmodule