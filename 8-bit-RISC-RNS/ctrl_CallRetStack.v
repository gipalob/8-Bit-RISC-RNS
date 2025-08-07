/*
    Module for managing call / return stack. 
    Up to 8 elements of history.
    Callee address will be added on JMP, JMP{LT,GT,EQ,C}.
    Top address will be popped on JR RA.
*/

module ctrl_CallRetStack (
    input clk,
    input reset,
    input push, // push address on stack
    input pop,  // pop address from stack
    input [9:0] push_addr, // address to push
    output reg [9:0] ret_addr, // address on top of stack
    output reg empty // indicates if stack is empty
);

    reg [9:0] stack [0:7]; // 8 elements stack
    reg [2:0] sp; // stack pointer

    always @(posedge clk) begin
        if (reset == 1'b1) begin
            sp <= 3'b000;
            empty <= 1'b1;
        end else begin
        // When a return address is pushed onto the stack, the program counter has already progressed to the next instruction
            if (push == 1'b1 && sp < 3'b111) begin
                stack[sp] <= push_addr;
                sp <= sp + 1;
                empty <= 1'b0;
            end else if (pop == 1'b1 && sp > 3'b000) begin
                sp <= sp - 1;
                if (sp == 3'b001) empty <= 1'b1; // last element popped
            end
            
            if (sp > 0) begin
                ret_addr <= stack[sp - 1];
            end else begin
                ret_addr <= 8'b0; // no elements in stack - start program from 0
            end
        end
    end
endmodule