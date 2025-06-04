// Description: Forwarding unit for pipeline control
// Modified from Pipelined implementation from GH repo hushon/Tiny-RISCV-CPU/
module Forwarding #(parameter NUM_DOMAINS) (
    input [2:0]                 op1_addr_IFID,              //source register 1 address from IF/ID
    input [2:0]                 op2_addr_IFID,              //source register 2 address from IF/ID
    input [2:0]                 destination_reg_addr,       //destination register address from WB
    input                       reg_wr_en,                  //register write enable signal
    input                       load_true_IFID,             //load instruction flag from IFID
    input [NUM_DOMAINS*8 - 1:0] datamem_wr_data,            //data memory write data (for load instruction)
    input [NUM_DOMAINS*8 - 1:0] rd_data1,                   //data read from register file for op1
    input [NUM_DOMAINS*8 - 1:0] rd_data2,                   //data read from register file for op2

    //Inputs specific for fwd logic for EX stage
    input [2:0]                 op1_addr_IDtoEX,            //source register 1 address in EX stage (pulled from IFID pipeline register)
    input [2:0]                 op2_addr_IDtoEX,            //source register 2 address in EX stage (pulled from IFID pipeline register)
    input [NUM_DOMAINS*8 - 1:0] op1_data_IDtoEX,            //data read from register file for op1 in EX stage (pulled from IFID pipeline register)
    input [NUM_DOMAINS*8 - 1:0] op2_data_IDtoEX,            //data read from register file for op2 in EX stage (pulled from IFID pipeline register)
    input                       reg_wr_en_reg,              //register write enable signal in EX stage
    input                       load_true_EX,              //load instruction flag in EX stage

    output reg                  bypass_op1_dcd_stage,       //bypass signal for op1 in decode stage
    output reg                  bypass_op2_dcd_stage,       //bypass signal for op2 in decode stage
    output [NUM_DOMAINS*8 - 1:0] op1_data_FWD_ID,           //data for op1 after bypassing if needed
    output [NUM_DOMAINS*8 - 1:0] op2_data_FWD_ID,           //data for op2 after bypassing if needed
    output [NUM_DOMAINS*8 - 1:0] op1_data_FWD_EX,           //operand 1 for EX stage after bypassing if needed
    output [NUM_DOMAINS*8 - 1:0] op2_data_FWD_EX            //operand 2 for EX stage after bypassing if needed
    );
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //Forwarding logic for IF/ID
    always @(op1_addr_IFID or destination_reg_addr or reg_wr_en or load_true_IFID)
    begin
        if ((op1_addr_IFID == destination_reg_addr) && (reg_wr_en == 1'b1) && (load_true_IFID == 1'b0))
            bypass_op1_dcd_stage <= 1'b1;
        else
            bypass_op1_dcd_stage <= 1'b0;
    end

    always @(op2_addr_IFID or destination_reg_addr or reg_wr_en or load_true_IFID)
    begin
        if ((op2_addr_IFID == destination_reg_addr) && (reg_wr_en == 1'b1) && (load_true_IFID == 1'b0))
            bypass_op2_dcd_stage <= 1'b1;
        else
            bypass_op2_dcd_stage <= 1'b0;
    end

    assign op1_data_FWD_ID = bypass_op1_dcd_stage  ? datamem_wr_data : rd_data1;
    assign op2_data_FWD_ID = bypass_op2_dcd_stage  ? datamem_wr_data : rd_data2;
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //Forwarding logic for EX
    always @(op1_addr_IDtoEX or destination_reg_addr or reg_wr_en or op2_addr_IDtoEX or load_true_EX)
    begin
        if ((op1_addr_IDtoEX == destination_reg_addr) && (reg_wr_en == 1'b1) && (load_true_EX == 1'b0))
            bypass_op1_ex_stage <= 1'b1;
        else
            bypass_op1_ex_stage <= 1'b0;

        if ((op2_addr_IDtoEX == destination_reg_addr) && (reg_wr_en == 1'b1) && (load_true_EX == 1'b0))
            bypass_op2_ex_stage <= 1'b1;
        else
            bypass_op2_ex_stage <= 1'b0;
    end

    assign op1_data_FWD_EX = bypass_op1_ex_stage  ? datamem_wr_data : op1_data_IDtoEX;
    assign op2_data_FWD_EX = bypass_op2_ex_stage  ? datamem_wr_data : op2_data_IDtoEX;
    //////////////////////////////////////////////////////////////////////////////////////////////////////
endmodule