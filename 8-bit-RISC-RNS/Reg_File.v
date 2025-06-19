// Description: 8-bit RISC Register File, from NayanaBannur/8-bit-RISC-Processor
//              Simultaneous reading of two registers at rd_addr1/2, and (not at the same time as read), writing to a register on active CLK edge && wr_en

module Reg_File #(parameter NUM_DOMAINS=1) (
        input clk, 
        input reset, 
        input [NUM_DOMAINS*8 - 1:0] wr_data,    //data to be written to reg on wr_addr && wr_en
        input [2:0] rd_addr1, 
        input [2:0] rd_addr2, 
        input [2:0] rd_addr3, //used for RLOAD, RSTORE
        input [2:0] wr_addr, 
        input wr_en,             //write enable control signal

        output reg [NUM_DOMAINS*8 - 1:0] rd_data1,  //data read from reg at rd_addr1
        output reg [NUM_DOMAINS*8 - 1:0] rd_data2,  //data read from reg at rd_addr2
        output reg [NUM_DOMAINS*8 - 1:0] rd_data3   //data read from reg at rd_addr3
    );
    //	register file
    reg [NUM_DOMAINS*8 - 1:0] reg_file [7:0]; //might be able to increase number of registers? prob shouldn't, bc of depth == NUM_DOMAINS*8...
                                            
    always @(rd_addr1 or rd_addr2 or reset or wr_en or wr_data) begin
        rd_data1 <= reg_file[rd_addr1];
        rd_data2 <= reg_file[rd_addr2];
    end

    always @(rd_addr3) begin //for RSTORE
        rd_data3 <= reg_file[rd_addr3];
    end

    always @(posedge clk) begin
        if (wr_en == 1)
            reg_file[wr_addr] <= #1 wr_data;
    end

endmodule