//Description: ALU For EX Stage.
//             This ALU operates in the %129 domain, with the algorithmic customizations required
module PL_ALU (
    input [7:0] op1,
    input [7:0] op2,
    input carry_in,
    input [2:0] opcode, // 3-bit operation code
    output reg [7:0] result
);
    always @(*) begin
        case (opcode)
            3'b000: result <= (op1 + op2); // ADD
            3'b001: result <= (op1 - op2); // SUB
            3'b010: result <= (op1 & op2); // AND
            3'b011: result <= (op1 | op2); // OR
            3'b100: result <= (op1 ^ op2); // XOR
            3'b101: result <= ~op1;                  // NOT
            default: result = 0;                        // Default case
        endcase
    end

endmodule