// Description: 8-bit RISC Register File, from NayanaBannur/8-bit-RISC-Processor
//              Simultaneous reading of two registers at rd_addr1/2, and (not at the same time as read), writing to a register on active CLK edge && wr_en

module Reg_File #(parameter NUM_DOMAINS=1) (
        input clk, 
        input reset, 
        input [NUM_DOMAINS*8 - 1:0] wr_data,    //data to be written to reg on wr_addr && wr_en
        input rd_en,
        input [3:0] rd_addr1, //4 bits to distinguish reg files
        input [3:0] rd_addr2, //4 bits to distinguish reg files
        input [2:0] rd_addr3, //used exclusively for RSTORE / OUTPUT
        input [3:0] wr_addr,  //4 bits to distinguish reg files
        input wr_en,          

        output reg [NUM_DOMAINS*8 - 1:0] rd_data1,
        output reg [NUM_DOMAINS*8 - 1:0] rd_data2, 
        output reg [7:0] rd_data3   //data read from reg at rd_addr3 - always 8-bit int domain 
    );
    reg [7:0] reg_file [7:0];
    reg [NUM_DOMAINS*8 - 1:0] RNS_reg_file [7:0];

    integer i;
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            reg_file[i] = 8'b0;
            RNS_reg_file[i] = 16'b0;
        end
    end

                                            
    //below assumes two RNS domains
    always @(rd_addr1 or rd_addr2 or rd_addr3 or reset or rd_en) 
    begin
        if (rd_en == 1'b1) begin
            //MSB of addr indicates RNS reg file, populate with 16b RNS data, else bit fill MSB with 0 and use 8b reg file data
            //rd_addr3 used exclusively for RSTORE + OUTPUT and will always be int domain, thus doesn't need RNS domain handling
            rd_data1 <= (rd_addr1[3] == 1'b1) ? RNS_reg_file[rd_addr1[2:0]] : {8'b0, reg_file[rd_addr1[2:0]]};
            rd_data2 <= (rd_addr2[3] == 1'b1) ? RNS_reg_file[rd_addr2[2:0]] : {8'b0, reg_file[rd_addr2[2:0]]};
            rd_data3 <= reg_file[rd_addr3]; 
        end else begin
            rd_data1 <= 0; //reset to 0 if not reading
            rd_data2 <= 0;
            rd_data3 <= 0;
        end
    end

    always @(posedge clk) 
    begin
        if (wr_en == 1)
        begin
            if (wr_addr[3] == 1'b1) //if writing to RNS reg file
                RNS_reg_file[wr_addr[2:0]] <= wr_data;
            else //if writing to normal reg file
                reg_file[wr_addr[2:0]] <= wr_data[7:0];
        end
    end

endmodule