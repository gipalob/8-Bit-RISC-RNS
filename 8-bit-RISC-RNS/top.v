// Description: Top module for 8-bit RISC RNS processor. 
//              Defines parameters for dynamic var widths, instantiates all submodules / pipeline stages

parameter PROG_CTR_WID = 10, NUM_DOMAINS = 1;

module processor_top (clk, reset);
    wire clk, reset;
    wire [PROG_CTR_WID-1:0]     prog_ctr;           //next program counter value
    wire                        branch_taken_EX;    //indicate branch was taken in EX stage
    wire [15:0]                 instr_mem_out;      //instruction fetched from memory
    
    wire [2:0]                  rd_addr1;
    wire [2:0]                  rd_addr2;
    wire [2:0]                  wr_addr;

    wire [NUM_DOMAINS*8 - 1:0]  rd_data1;           //data for op1 from ctrl_Forward
    wire [NUM_DOMAINS*8 - 1:0]  rd_data2;           //data for op2 from ctrl_Forward
    wire [NUM_DOMAINS*8 - 1:0]  wr_data;            //data to be written to reg || datamem 
    wire                        wr_en;

    //**// IF/ID Pipeline Register Signals //**//
    wire                        load_true_IFID;     //load instruction flag to ctrl_Forward
    wire [2:0]                  op1_addr_IFID_fwd;  //op1 address to ctrl_Forward
    wire [2:0]                  op2_addr_IFID_fwd;  //op2 address to ctrl_Forward
    wire [NUM_DOMAINS*8 - 1:0]  op1_data_IFID;      //op1 data out for IFID pipeline register
    wire [NUM_DOMAINS*8 - 1:0]  op2_data_IFID;      //op2 data out for IFID pipeline register
    wire [PROG_CTR_WID-1:0]     pred_nxt_prog_ctr;  //predicted next program counter value obtained from addr in branch instruction currently in IFID
    wire [47:0]                 IFID_reg;           //IFID pipeline register out
    //**/////////////////////////////////////**//

    //**// EX Pipeline Register Signals //**//
    wire                        destination_reg_addr; //destination register address, triggered on Register write enable

    ctrl_ProgCtr #(PROG_CTR_WID) programcounter(
        .clk(clk), .reset(reset),
        .branch_taken_EX(branch_taken_EX),
        .nxt_prog_ctr_EX(),                 //next program counter, to be pulled from EX pipeline reg ************************************
        .prog_ctr(prog_ctr)                 //current program counter value
    );

    Instr_Mem #(PROG_CTR_WID) instr_mem (
        .clk(clk),
        .prog_ctr(prog_ctr),
        .instr_mem_out(instr_mem_out)
    );

    Reg_File #(NUM_DOMAINS) reg_file (
        .clk(clk),
        .reset(reset),
        .wr_data(wr_data),              //data to be written to reg on wr_addr && wr_en, to be pulled from EX pipeline reg
        .rd_addr1(rd_addr1),            //op1 address, to be pulled from ID pipeline reg
        .rd_addr2(rd_addr2),            //op2 address, to be pulled from ID pipeline reg
        .wr_addr(wr_addr),              //destination register address, to be pulled from EX pipeline reg
        .wr_en(wr_en),                  //write enable signal, to be pulled from EX pipeline reg
        .rd_data1(rd_data1),            //op1 read data, to be pulled from ID pipeline reg
        .rd_data2(rd_data1)             //op2 read data, to be pulled from ID pipeline reg
    );

    PL_IFID #(PROG_CTR_WID, NUM_DOMAINS) stage_IFID (
        .clk(clk),
        .rst(reset),
        .instr_mem_out(instr_mem_out),          //instruction fetched from memory
        .branch_taken_EX(branch_taken_EX),      //indicate branch was taken in EX stage
        .op1_data(),             //data for op1 from ctrl_Forward - assignment messed up somewhere? not an OP on FWD
        .op2_data(),             //data for op2 from ctrl_Forward - assignment messed up somewhere? not an OP on FWD
        .op1_addr_IFID_fwd(op1_addr_IFID_fwd),  //IF-OUT: op1 address to ctrl_Forward
        .op2_addr_IFID_fwd(op2_addr_IFID_fwd),  //IF-OUT: op2 address to ctrl_Forward
        .load_true_IFID(load_true_IFID),        //load instruction flag to ctrl_Forward
        .IFID_reg(IFID_reg),                    //IFID pipeline register out
        .pred_nxt_prog_ctr(pred_nxt_prog_ctr),  //predicted next program counter value obtained from addr in branch instruction currently in IFID
        .op1_data_IFID(op1_data_IFID),          //op1 data out for IFID pipeline register
        .op2_data_IFID(op2_data_IFID)           //op2 data out for IFID pipeline register
    );

    //need to think about where each of these inputs are coming from / going to, make sure timing mirrors original design
    Forwarding #(NUM_DOMAINS) fwd (
        .op1_addr_IFID(op1_addr_IFID_fwd),              //op1 address to ctrl_Forward
        .op2_addr_IFID(op2_addr_IFID_fwd),              //op2 address to ctrl_Forward
        .destination_reg_addr(destination_reg_addr),    //destination register address, to be pulled from EX pipeline reg
        .reg_wr_en(),                              //register write enable signal
        .load_true_IFID(load_true_IFID),                //from IFID
        .datamem_wr_data(),                             //data memory write data (from store instruction, for load instruction)
        .rd_data1(rd_data1),                            //data read from register file
        .rd_data2(rd_data2),                            //data read from register file
        .op1_addr_IDtoEX(),                             //source register 1 address in EX stage (pulled from IFID pipeline register)
        .op2_addr_IDtoEX(),                             //source register 2 address in EX stage (pulled from IFID pipeline register)
        .op1_data_IDtoEX(),               //data read from register file for op1 in EX stage (pulled from IFID pipeline register)
        .op2_data_IDtoEX(),               //data read from register file for op2 in EX stage (pulled from IFID pipeline register)
        .reg_wr_en_reg(),                               //register write enable signal in EX stage
        .load_true_EX(),                                //load instruction flag in EX stage

        .bypass_op1_dcd_stage(),                        //bypass signal for op1 in decode stage
        .bypass_op2_dcd_stage(),                        //bypass signal for op2 in decode stage
        .op1_data_FWD_ID(),               //data for op1 after bypassing if needed
        .op2_data_FWD_ID(),               //data for op2 after bypassing if needed
        .op1_data_FWD_EX(),                             //operand 1 for EX stage after bypassing if needed
        .op2_data_FWD_EX()                              //operand 2 for EX stage after bypassing if needed

    );


endmodule