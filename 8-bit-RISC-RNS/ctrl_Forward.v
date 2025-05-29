// Description: Forwarding unit for pipeline control
// Modified from Pipelined implementation from GH repo hushon/Tiny-RISCV-CPU/
module Forwarding(
    input wire [2:0] rd_ex,         //dest reg for inst in EX stage    
    input wire [2:0] rd_mem,        //dest reg for inst in MEM stage
    input wire [2:0] rd_wb,         //dest reg for inst in WB stage
    input wire RegWrite_wb,         //whether inst in WB stage is writing to regfile
    input wire RegWrite_mem,        //whether data from MEM is being written to regfile
    input wire [2:0] rs1_id,        //source regs for inst in ID stage
    input wire [2:0] rs2_id,
    input wire [2:0] rs1_ex,        //source regs for inst in EX stage
    input wire [2:0] rs2_ex,
    input wire rs1_used_ex,         //whether rs1 / rs2 is actively being used in EX stage
    input wire rs2_used_ex,
    input wire [4:0] opcode_id,     //opcode for inst in ID stage
    input wire [4:0] opcode_ex,     //opcode for inst in EX stage
    input wire [4:0] opcode_mem,    //opcode for inst in MEM stage
    input wire [4:0] opcode_wb,     //opcode for inst in WB stage
    
    output reg [1:0] forwardA,      //Where to forward data for ALU operand A from
    output reg [1:0] forwardB,      //Where to forward data for ALU operand B from
    output reg [1:0] writedatasel,  //Where to forward data for MEM write from
    output reg [1:0] jump_forwardA, //Where to forward data for JMP operand A from
    output reg [1:0] jump_forwardB  //Where to forward data for JMP operand B from
    );

    //initial defs for outputs
    initial begin
        forwardA = 2'bxx;
        forwardB = 2'bxx;
        writedatasel = 2'bxx;
        jump_forwardA = 2'bxx;
        jump_forwardB = 2'bxx;
    end

    //need to define constants for opcode compares

    //logic for output signals 

endmodule