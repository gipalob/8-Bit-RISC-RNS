//Description: ALU For EX Stage, with accompanying sub-modules.
//             This ALU handles RNS-Domain operations, and thus has no shift or logical operations



module RNS_complement (
    input RNS_ALU_EN, // Enable for RNS ALU operations
    input [8:0] modulus, //9-bit modulus for RNS operations
    input [7:0] op1_in, op2_in,
    input en_complement,    //whether to complement op2
    input add_op, 
    input mul_op,
    output reg [7:0] op1, op2
);
    always @(op1_in or op2_in or en_complement or add_op or mul_op) 
    begin
        if (RNS_ALU_EN == 1'b1) 
        begin
            op1 <= op1_in; //always passed as-is
            if (store_true) begin //if store operation
                op2 <= 8'b0;
            end 
            else if (en_complement) begin //if complement operation
                op2 <= ~op2_in;
            end
            else begin
                op2 <= op2_in;
            end
        end
    end
endmodule



module RNS_adder (
    input [7:0] op1, op2,
    output reg [15:0] result,
);
    always @(op1 or op2) begin
        result <= op1 + op2; // 8-bit addition with carry
    end
endmodule



module RNS_multiplier (
    input [7:0] op1, op2,
    output reg [15:0] result
);

endmodule


//These two modules are hard-defined for optimization
module RNS_fit_129 (
    input [15:0] op_in,
    output [7:0] op_out
);
    assign op_out = (op_in[7] == 1'b1) ? (op_in[6:0] + 1) : {1'b0, op_in[6:0]}; // Fit into 129
endmodule

module RNS_fit_256 (
    input [15:0] op_in,
    output [7:0] op_out
);
    // This module fits the 16-bit result into the 8-bit domain using the modulus
    assign op_out = op_in[7:0]; // Fit into 256
endmodule



module PL_RNS_ALU (
    input [8:0] modulus,
    input [7:0] op1_in,
    input [7:0] op2_in,
    input [0:15] ALU_ctrl, // Control signals for ALU operations - IFID_reg[2:15]
    input RNS_ALU_EN, // Enable for RNS ALU operations
    output [7:0] dout,
);
    wire [7:0] op1, op2;
    wire [15:0] adder_result, mul_result, final_result;

    wire add_op, en_complement, mul_op_true;
    assign add_op        = ALU_ctrl[0];
    assign en_complement = ALU_ctrl[8];
    assign mul_op        = ALU_ctrl[14];

    // Instantiate sub-modules
    RNS_complement comp_inst (
        .RNS_ALU_EN(RNS_ALU_EN),
        .modulus(modulus),
        .op1_in(op1_in),
        .op2_in(op2_in),
        .en_complement(en_complement),
        .add_op(add_op),
        .mul_op(mul_op),
        .op1(op1),
        .op2(op2)
    );

    RNS_adder add_inst (
        .modulus(modulus)
        .op1(op1),
        .op2(op2),
        .carry_in(carry_in),
        .result(adder_result),
        .carry_out(adder_cout)
    );

    RNS_multiplier mul_inst (
        .op1(op1),
        .op2(op2),
        .result(mul_result)
    );

    assign final_result = (mul_op) ? mul_result : adder_result;

    if (modulus == 9'd129) 
    begin
        RNS_fit_129 fit_inst (
            .op_in(final_result),
            .op_out(dout)
        );
    end else if (modulus == 9'd256) 
    begin
        RNS_fit_256 fit_inst (
            .op_in(final_result),
            .op_out(dout)
        );
    end
endmodule