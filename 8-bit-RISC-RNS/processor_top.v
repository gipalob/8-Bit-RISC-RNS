// Description: Top module for 8-bit RISC RNS processor. 
//              Defines parameters for dynamic var widths, instantiates all submodules / pipeline stages

module processor_top #(parameter NUM_DOMAINS = 2, parameter [9 * NUM_DOMAINS - 1 : 0] MODULI = {9'd129, 9'd256}) (
    input wire      clk100, 
    input wire      reset,
    input  [7:0]    IO_read_data,
    output [7:0]    IO_port_ID,
    output [7:0]    IO_write_data,
    output          IO_write_strobe,
    output          IO_read_strobe
); 
    parameter PROG_CTR_WID = 10;

    wire [PROG_CTR_WID-1:0]     prog_ctr;           //next program counter value
    wire                        branch_taken_EX;    //indicate branch was taken in EX stage
    wire [15:0]                 instr_mem_out;      //instruction fetched from memory
    
    wire [2:0]                  rd_addr1;
    wire [2:0]                  rd_addr2;
    wire [2:0]                  rd_addr3;           //for RSTORE

    wire [NUM_DOMAINS*8 - 1:0]  rd_data1;           //data for op1 from regfile
    wire [NUM_DOMAINS*8 - 1:0]  rd_data2;           //data for op2 from regfile
    wire [7:0]                  rd_data3;           //data for op3 from regfile
    wire [7:0]  dmem_dout;          //data read from data memory
    wire [NUM_DOMAINS*8 - 1:0]  wr_data;            //data to be written to reg || datamem 
    wire [15:0]                 data_wr_addr, data_rd_addr;
    wire                        mem_wr_en, reg_wr_en;

    //**// IF/ID Pipeline Register Signals //**//
    wire                        load_true_IFID;     //load instruction flag to ctrl_Forward
    wire [3:0]                  op1_addr_IFID;      //op1 address to ctrl_Forward
    wire [3:0]                  op2_addr_IFID;      //op2 address to ctrl_Forward
    wire                        RNS_inst_IFID_fwd;
    wire [2:0]                  op3_addr_IFID;      //op2 address to ctrl_Forward
    wire [NUM_DOMAINS*8 - 1:0]  op1_din_IFID;       //op1 data IN to IFID from ctrl_Forward
    wire [NUM_DOMAINS*8 - 1:0]  op2_din_IFID;       //op1 data IN to IFID from ctrl_Forward
    wire [7:0]                  op3_din_IFID;       //op1 data IN to IFID from ctrl_Forward
    wire [NUM_DOMAINS*8 - 1:0]  op1_dout_IFID;      //op1 data out for IFID pipeline register
    wire [NUM_DOMAINS*8 - 1:0]  op2_dout_IFID;      //op2 data out for IFID pipeline register
    wire [7:0]                  op3_dout_IFID;      //op2 data out for IFID pipeline register
    wire [3:0]                  op1_addr_out_IFID;  //op1 address out for IFID pipeline register
    wire [3:0]                  op2_addr_out_IFID;  //op2 address out for IFID pipeline register
    wire [2:0]                  op3_addr_out_IFID;  //op3 address out for IFID pipeline register
    wire [2:0]                  res_addr_out_IFID;  //result address out for IFID pipeline register
    wire [PROG_CTR_WID-1:0]     pred_nxt_prog_ctr;  //predicted next program counter value obtained from addr in branch instruction currently in IFID
    wire [0:41] IFID_reg; //IFID pipeline register output
    
    wire [0:4] brnch_conds_IFID;
    //**/////////////////////////////////////**//

    //**// EX Inputs //**//
    wire [NUM_DOMAINS*8 - 1:0]  op1_din_EX; //from ctrl_Forward
    wire [NUM_DOMAINS*8 - 1:0]  op2_din_EX; //from ctrl_Forward
    wire [7:0]                  op3_din_EX; //from ctrl_Forward
    wire branch_taken_in_EX;
    //**// EX Pipeline Register Signals //**//
    wire [0:9] EX_reg; //EX pipeline register output
    wire [0:4] brnch_conds_EX;
    wire [0:4]                  branch_conds_EX;        //branch conditions in EX stage to ctrl_Fwd
    wire [3:0]                  destination_reg_addr;   //destination register address, triggered on Register write enable
    wire destination_RNS;                               //whether rd is in RNS domain, used to determine which reg file is written to
    wire [NUM_DOMAINS*8 - 1:0]  operation_result;       //result of ALU/Shift/LGCL operation
    wire [PROG_CTR_WID-1:0]     pred_nxt_prog_ctr_EX;   //predicted next program counter value to be pulled from EX pipeline reg
    //**/////////////////////////////////////**//

    //**// MEM/WB Pipeline Register Signals //**//
    wire [0:3]                  branch_conds_MEMWB;  
    wire invalidate_instr;
    //**//                                  //**//

    //**// I/O Signals (i.e., for UART) //**//
    /*
        Although IO_port_ID comes from PL_EX, IO_write_data, IO_write_strobe, and IO_read_strobe are all by PL_MEMWB at effectively the same time, in assign statements from EX PL reg.
    */

    ctrl_ProgCtr #(PROG_CTR_WID) programcounter(
        .clk(clk100), .reset(reset),
        .branch_taken_EX(branch_taken_EX),
        .nxt_prog_ctr_EX(pred_nxt_prog_ctr_EX),     //next program counter, to be pulled from EX pipeline reg ************************************
        .prog_ctr(prog_ctr)                         //current program counter value
    );

    Instr_Mem #(PROG_CTR_WID) instr_mem (
        .clk(clk100),
        .prog_ctr(prog_ctr),
        .instr_mem_out(instr_mem_out)
    );

    /*
        Data mem is byte-addressable with 16b addr
        but what data is written to it?
            (given we have multiple bytes of data [one per domain] in register file)
    */
    Data_Mem data_mem(
        .clk(clk100), .reset(reset),
        //INPUTS
        .data_rd_addr(data_rd_addr), .data_wr_addr(data_wr_addr), //even though both will be {op1, op2} need to keep separate for timing - read triggers dout <= {mem @ addr}
        .datamem_wr_data(wr_data[7:0]), .store_to_mem(mem_wr_en),
        //OUTPUTS
        .dmem_dout(dmem_dout)
    );


    Reg_File #(NUM_DOMAINS) reg_file (
        .clk(clk100),
        .reset(reset),
        .wr_data(wr_data),              //data to be written to reg on wr_addr && wr_en, to be pulled from EX pipeline reg
        .rd_addr1(op1_addr_IFID),       //op1 address, to be pulled from ID pipeline reg
        .rd_addr2(op2_addr_IFID),       //op2 address, to be pulled from ID pipeline reg
        .rd_addr3(op3_addr_IFID),       //op2 address, to be pulled from ID pipeline reg
        .wr_addr(destination_reg_addr), //destination register address, to be pulled from EX pipeline reg
        .wr_RNS(destination_RNS),       //whether rd is in RNS domain, used to determine which reg file is written to
        .wr_en(reg_wr_en),              //write enable signal, to be pulled from EX pipeline reg
        .rd_data1(rd_data1),            //op1 read data, to be pulled from ID pipeline reg
        .rd_data2(rd_data2),            //op2 read data, to be pulled from ID pipeline reg
        .rd_data3(rd_data3)             //op3 read data, to be pulled from ID pipeline reg
    );


    PL_IFID #(PROG_CTR_WID, NUM_DOMAINS) stage_IFID (
        .clk(clk100),
        .rst(reset),
        .instr_mem_out(instr_mem_out),          //instruction fetched from memory
        .branch_taken_EX(branch_taken_EX),      //indicate branch was taken in EX stage
        .op1_data(op1_din_IFID),                //data for op1 from ctrl_Forward - assignment messed up somewhere? not an OP on FWD
        .op2_data(op2_din_IFID),                //data for op2 from ctrl_Forward - assignment messed up somewhere? not an OP on FWD
        .op3_data(op3_din_IFID),                //data for op3 from ctrl_Forward - assignment messed up somewhere? not an OP on FWD
        .op1_addr_IFID(op1_addr_IFID),  //IF-OUT: op1 address to ctrl_Forward
        .op2_addr_IFID(op2_addr_IFID),  //IF-OUT: op2 address to ctrl_Forward
        .op3_addr_IFID(op3_addr_IFID),  //IF-OUT: op2 address to ctrl_Forward
        .load_true_IFID(load_true_IFID),        //load instruction flag to ctrl_Forward
        //Pipeline register out to next stage
        .IFID_reg(IFID_reg),                    //IFID pipeline register out
        .pred_nxt_prog_ctr(pred_nxt_prog_ctr),  //predicted next program counter value obtained from addr in branch instruction currently in IFID
        .op1_dout_IFID(op1_dout_IFID),          //op1 data out for IFID pipeline register
        .op2_dout_IFID(op2_dout_IFID),          //op2 data out for IFID pipeline register
        .op3_dout_IFID(op3_dout_IFID),          //op2 data out for IFID pipeline register
        .op1_addr_out_IFID(op1_addr_out_IFID),
        .op2_addr_out_IFID(op2_addr_out_IFID),
        .op3_addr_out_IFID(op3_addr_out_IFID),
        .res_addr_out_IFID(res_addr_out_IFID)
    );

    PL_EX #(NUM_DOMAINS, PROG_CTR_WID) stage_EX (
        .clk(clk100), .reset(reset),
        //Pipeline registers from IFID
        .op1(op1_din_EX),                                           //op1 din after ctrl_Forward makes decision
        .op2(op2_din_EX),                                           //op2 din after ctrl_Forward makes decision
        .op3(op3_din_EX),                                           //op2 din after ctrl_Forward makes decision
        .res_addr(res_addr_out_IFID),                               //result address for regfile write, pulled from IFID pipeline registe
        .pred_nxt_prog_ctr(pred_nxt_prog_ctr),                      //predicted next program counter value from IFID
        .IFID_reg(IFID_reg),                                        //IFID pipeline register out
        .branch_taken(branch_taken_in_EX),
        //Outputs to next stage
        .branch_conds_EX(branch_conds_EX),
        .branch_taken_EX(branch_taken_EX),
        .data_wr_addr(data_wr_addr), .data_rd_addr(data_rd_addr),   //data memory write/read address
        .EX_reg(EX_reg),                                            //mixed EX pipeline register signals
        .destination_reg_addr(destination_reg_addr),                //destination register address, to be pulled from EX pipeline reg)
        .operation_result(operation_result),
        .IO_port_ID(IO_port_ID),                    
        .pred_nxt_prog_ctr_EX(pred_nxt_prog_ctr_EX)                //predicted next program counter value to be pulled from EX pipeline reg
    );

    PL_MEMWB #(NUM_DOMAINS, PROG_CTR_WID) stage_MEMWB (
        .clk(clk100), .reset(reset),
        //Pipeline registers from EX
        .operation_result(operation_result),        //result of ALU/Shift/LGCL operation
        .EX_reg(EX_reg),                            //mixed EX pipeline register signals
        .branch_conds_EX(branch_conds_EX),          //branch conditions in EX stage to ctrl_Fwd
        //Other
        .dmem_dout(dmem_dout),                      //data read from data memory
        //Outputs
        .branch_conds_MEMWB(branch_conds_MEMWB),    //branch conditions in MEM/WB stage to ctrl_Fwd
        .invalidate_instr(invalidate_instr),        //invalidate instruction in IFID pipeline register
        .mem_wr_en(mem_wr_en),                      //memory write enable signal
        .reg_wr_en(reg_wr_en),                      //register write enable signal
        .destination_RNS(destination_RNS),          //whether rd is in RNS domain, used to determine which reg file is written to
        .wr_data(wr_data),                          //data to be written to reg || datamem 
        .IO_read_data(IO_read_data),          //data read from input port
        .IO_write_data(IO_write_data),         
        .IO_write_strobe(IO_write_strobe),         
        .IO_read_strobe(IO_read_strobe)            
    );

    Forwarding #(NUM_DOMAINS) fwd (
        //General I/O
        .wr_data(wr_data),                             //data memory write data (from store instruction, for load instruction)
        .rd_data1(rd_data1),                            //data read from register file
        .rd_data2(rd_data2),                            //data read from register file
        .rd_data3(rd_data3),                            //data read from register file
        //Inputs from ID
        .op1_addr_IFID(op1_addr_IFID),              //op1 address IFID -> ctrl_Forward
        .op2_addr_IFID(op2_addr_IFID),              //op2 address IFID -> ctrl_Forward
        .op3_addr_IFID(op3_addr_IFID),              //op2 address IFID -> ctrl_Forward
        .load_true_IFID(load_true_IFID),                //load from reg IFID -> ctrl_Forward
        //Outputs to IFID
        .op1_data_FWD_ID(op1_din_IFID),               //Operand 1 Data for IFID pipeline register after bypassing (if required)
        .op2_data_FWD_ID(op2_din_IFID),               //Operand 2 Data for IFID pipeline register after bypassing (if required)
        .op3_data_FWD_ID(op3_din_IFID),               //Operand 2 Data for IFID pipeline register after bypassing (if required)
        ///////////////////////////////

        .destination_reg_addr(destination_reg_addr),    //destination register address, to be pulled from EX pipeline reg
        .reg_wr_en(reg_wr_en),                          //register write enable signal
        .op1_addr_IDtoEX(op1_addr_out_IFID),            //source register 1 address in EX stage (pulled from IFID pipeline register)
        .op2_addr_IDtoEX(op2_addr_out_IFID),            //source register 2 address in EX stage (pulled from IFID pipeline register)
        .op3_addr_IDtoEX(op3_addr_out_IFID),            //source register 2 address in EX stage (pulled from IFID pipeline register)
        .op1_data_IDtoEX(op1_dout_IFID),                //data read from register file for op1 in EX stage (pulled from IFID pipeline register)
        .op2_data_IDtoEX(op2_dout_IFID),                //data read from register file for op2 in EX stage (pulled from IFID pipeline register)
        .op3_data_IDtoEX(op3_dout_IFID),                //data read from register file for op2 in EX stage (pulled from IFID pipeline register)
        .load_true_EX(IFID_reg[16]),                    //load instruction flag in EX stage
        .op1_data_FWD_EX(op1_din_EX),                   //operand 1 for EX stage after bypassing if needed
        .op2_data_FWD_EX(op2_din_EX),                   //operand 2 for EX stage after bypassing if needed
        .op3_data_FWD_EX(op3_din_EX)                    //operand 2 for EX stage after bypassing if needed
    );

    ctrl_BranchPred branch_prediction (
        .conds_IFID(IFID_reg[18:22]),
        .conds_EX(branch_conds_EX),
        .conds_MEMWB(branch_conds_MEMWB),
        .invalidate_instr(invalidate_instr),
        .branch_taken(branch_taken_in_EX)
    );


endmodule