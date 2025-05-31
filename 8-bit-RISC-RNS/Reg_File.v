// Description: 8-bit RISC Register File, from NayanaBannur/8-bit-RISC-Processor
//              Simultaneous reading of two registers at rd_addr1/2, and (not at the same time as read), writing to a register on active CLK edge && wr_en

module register_file (
        input clk, 
        input reset, 
        input [7:0] wr_data,    //data to be written to reg on wr_addr && wr_en
        input [2:0] rd_addr1, 
        input [2:0] rd_addr2, 
        input [2:0] wr_addr, 
        input wr_en             //write enable control signal

        output reg [7:0] rd_data1,  //data read from reg at rd_addr1
        output reg [7:0] rd_data2,  //data read from reg at rd_addr2
    );
    //	register file
    reg [7:0] reg_file [7:0];
                                            
    always @(rd_addr1 or rd_addr2 or reset or wr_en or wr_data) begin
        rd_data1 <= reg_file[rd_addr1];
        rd_data2 <= reg_file[rd_addr2];
    end

    always @(posedge clk) begin
        if (wr_en == 1)
            reg_file[wr_addr] <= #1 wr_data;
    end

endmodule