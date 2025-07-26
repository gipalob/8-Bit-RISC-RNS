//Description: ALU For EX Stage, with accompanying sub-modules.



module complement (
    input       ALU_EN, // Enable for ALU operations
    input [7:0] op1_in, op2_in,
    input       en_complement,    //whether to complement op2
    input       store_true,       //if store operation, keep op2 @ 0
    output reg [7:0] op1, op2
);
    always @(op1_in or op2_in or en_complement or store_true or ALU_EN) 
    begin
        op1 = 8'b0;
        op2 = 8'b0;
        if (ALU_EN == 1'b1)
        begin
            op1 = op1_in; //always passed as-is
            if (store_true) begin //if store operation
                op2 = 8'b0;
            end 
            else if (en_complement) begin //if complement operation
                op2 = ~op2_in;
            end
            else begin
                op2 = op2_in;
            end
        end
    end
endmodule



module adder (
    input [7:0] op1, op2,
    input       carry_in,
    output reg [7:0] result,
    output reg carry_out
);
    always @(op1 or op2 or carry_in) begin
        {carry_out, result} = op1 + op2 + carry_in; // 8-bit addition with carry
    end
endmodule



module shift (
    input [7:0] op1, 
    input       shift_en, //enable shift operation
    output reg [7:0] result,
    output reg       carry_out
);
    always @(op1 or shift_en)
    begin
        carry_out = 1'b0;
        result = 8'b0;
        if (shift_en == 1'b1) begin
            carry_out = op1[7]; // Capture the MSB before shifting
            result = {op1[6:0], 1'b0}; // Shift left
        end
    end 
endmodule



module logical (
    input [7:0] op1, op2,
    input and_op, and_bitwise, or_op, or_bitwise, not_op,
    output reg [7:0] result
);
    always @(op1 or op2 or and_op or and_bitwise or or_op or or_bitwise or not_op) begin
        if (and_op == 1'b1) 
        begin
            result = op1 && op2; // Logical AND
        end else if (and_bitwise == 1'b1) 
        begin
            result = op1 & op2; // Bitwise AND
        end else if (or_op == 1'b1) 
        begin
            result = op1 || op2; // Logical OR
        end else if (or_bitwise == 1'b1) 
        begin
            result = op1 | op2; // Bitwise OR
        end else if (not_op == 1'b1) 
        begin
            result = !op1; // NOT operation
        end else 
        begin
            result = 8'b0; // Default case
        end
    end
endmodule 



module PL_ALU (
    input           ALU_EN,
    input [7:0]     op1_in,
    input [7:0]     op2_in,
    input [0:13]    ALU_ctrl, // Control signals for ALU operations - IFID_reg[2:15]
    output [7:0]    dout,
    output cout,
    output COMP_gt, COMP_lt, COMP_eq // Compare outputs
);
    wire [7:0] op1, op2;
    wire [7:0] adder_result, shift_result, lgcl_result;
    wire adder_cout, shift_cout;

    wire add_op, carry_in, en_complement, jump_true, compare_true, lgcl_en, store_true;
    wire or_op, not_op, and_bitwise, or_bitwise, not_bitwise, and_op; //logical ops
    assign add_op        = ALU_ctrl[0];
    assign or_op         = ALU_ctrl[1];
    assign not_op        = ALU_ctrl[2];
    assign and_bitwise   = ALU_ctrl[3];
    assign or_bitwise    = ALU_ctrl[4];
    assign not_bitwise   = ALU_ctrl[5];
    assign and_op        = ALU_ctrl[6];
    assign carry_in      = ALU_ctrl[7];
    assign en_complement = ALU_ctrl[8];
    assign jump_true     = ALU_ctrl[9];
    assign compare_true  = ALU_ctrl[10];
    assign shift_left    = ALU_ctrl[11];
    assign lgcl_en       = ALU_ctrl[12];
    assign store_true    = ALU_ctrl[13];

    // Instantiate sub-modules
    /*
        The outputs of complement, even if op1 and op2 aren't being complemented, are always passed to adder, shift, and logical modules.
        Thus, we can disable this ALU by stopping complement if RNS ALU is enabled
    */

    complement comp_inst (
        .ALU_EN(ALU_EN),
        .op1_in(op1_in),
        .op2_in(op2_in),
        .en_complement(en_complement),
        .store_true(store_true),
        .op1(op1),
        .op2(op2)
    );

    adder add_inst (
        .op1(op1),
        .op2(op2),
        .carry_in(carry_in),
        .result(adder_result),
        .carry_out(adder_cout)
    );

    shift shift_inst (
        .op1(op1),
        .shift_en(shift_left),
        .result(shift_result),
        .carry_out(shift_cout)
    );

    logical lgcl_inst (
        .op1(op1),
        .op2(op2),
        .and_op(and_op),
        .and_bitwise(and_bitwise),
        .or_op(or_op),
        .or_bitwise(or_bitwise),
        .not_op(not_op),
        .result(lgcl_result)
    );

    // Combine results based on control signals
    // Original dout assignment was (add_op || store_true) ? adder_result. with 16b-addressable data mem this is now irrelevant.
    assign dout = (add_op) ? adder_result :
                  (lgcl_en ? lgcl_result : shift_result);
    assign cout = (add_op) ? adder_cout : shift_cout;

    assign COMP_gt = (adder_cout == 1'b1) && (adder_result != 8'b0) && compare_true;
    assign COMP_lt = (adder_cout == 1'b0) && (adder_result != 8'b0) && compare_true;
    assign COMP_eq = (adder_result == 8'b0) && compare_true;
endmodule