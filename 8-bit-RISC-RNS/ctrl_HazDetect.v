// Description: Hazard Detection Unit for pipeline control
// Modified from Pipelined implementation from GH repo hushon/Tiny-RISCV-CPU/

module HazDetect (
    input [2:0] rd_ex,      //reg being written in EX stage
    input MemRead_ex,       //whether rd_ex is being read in EX stage
    input [2:0] rs1_id,     //regs being read in ID stage
    input [2:0] rs2_id,
    input rs1_used_id,         //whether rs1 / rs2 is actively being used in ID stage
    input rs2_used_id,

    output reg stall_id,    //output to control whether ID stage should stall
    output reg inc_ProgCtr  //output to control whether program counter should increment
    output reg write_IFID   //output to control whether IF/ID register should write
);
    initial begin
        stall_id = 0;
        inc_ProgCtr = 1;
        write_IFID = 1;
    end

    always @(*) begin
        if ((((rs1_id == rd_ex) && (rs1_used)) || ((rs2_id == rd_ex) && (rs2_used))) && MemRead_ex) begin
            stall_id    <= 1;
            inc_ProgCtr <= 0;
            write_IFID  <= 0;
        end else begin
            stall_id    <= 0;
            inc_ProgCtr <= 1;
            write_IFID  <= 1;
        end
    end
endmodule