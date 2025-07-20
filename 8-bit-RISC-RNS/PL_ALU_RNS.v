//Description: ALU For EX Stage, with accompanying sub-modules.
//             This ALU handles RNS-Domain operations, and thus has no shift or logical operations

module RNS_complement (
    input RNS_ALU_EN, // Enable for RNS ALU operations
    input [7:0] op1_in, op2_in,
    input en_complement,    //whether to complement op2
    input add_op, 
    input mul_op,
    output reg [7:0] op1, op2
);
    always @(op1_in or op2_in or en_complement or add_op or mul_op or RNS_ALU_EN) 
    begin
        if (RNS_ALU_EN == 1'b1) 
        begin
            //For RNS-domain operations, we always pass both operands as they are.
            //Two's complement subtraction doesn't work in RNS 
            op1 <= op1_in;
            op2 <= op2_in;
        end
    end
endmodule



module RNS_adder (
    input [7:0] op1, op2,
    output reg [15:0] result
);
    always @(op1 or op2) begin
        result <= {8'b0, op1 + op2}; // 8-bit addition with carry
    end
endmodule



module RNS_sub #(parameter [8:0] modulus = 9'd129) (
    input [7:0] op1, op2,
    output reg [15:0] result
);
    /*
        RNS-specific subtraction module.
        Given 2's comp subtraction doesn't work in RNS, we need a custom module taking the modulo as input as well
        After fit_inst, the formula for for RNS subtraction is:
            result = (op1 - op2 + modulus) % modulus
    */
    always @(op1 or op2) begin
        result <= {6'b0, op1 - op2 + modulus}; 
    end
endmodule



module RNS_multiplier (
    input [7:0] op1, op2,
    output reg [15:0] result
);
    always @ (op1 or op2) 
    begin
        result <= op1 * op2;
    end
endmodule


/*
    These two modules are hard-defined for optimization
    16-bit input as a the result of 8-bit multiplication operations maxes out at 16-bits. 
*/ 
module RNS_fit_129 (
    input [15:0] op_in,
    output [7:0] op_out
);
    wire [6:0] low = op_in[6:0];
    wire [6:0] mid = op_in[13:7];
    wire [1:0] high = op_in[15:14];

    wire [8:0] step_one = low + mid + high; //fold bits together - this step has a max value of 384

    wire [8:0] step_two = step_one[6:0] + step_one[8:7]; //fold again - this step has a max value of 130

    assign op_out = (step_two >= 129) ? (step_two - 129) : step_two[7:0]; // Fit into 129
endmodule

module RNS_fit_256 (
    input [15:0] op_in,
    output [7:0] op_out
);
    assign op_out = op_in[7:0]; // Fit into 256
endmodule



module PL_ALU_RNS #(parameter [8:0] modulus = 9'd129) ( //need to define a std value for parameter even if it'll always be provded by above module in hierarchy
    input [7:0] op1_in,
    input [7:0] op2_in,
    input [0:14] ALU_ctrl, // Control signals for ALU operations - IFID_reg[2:15], IFID_reg[32]
    input RNS_ALU_EN, // Enable for RNS ALU operations
    output [7:0] dout
);
    wire [7:0] op1, op2;
    wire [15:0] adder_result, sub_result, mul_result, final_result;

    wire add_op, en_complement, mul_op_true;
    assign add_op        = ALU_ctrl[0];
    assign en_complement = ALU_ctrl[8];
    assign mul_op        = ALU_ctrl[14];

    // Instantiate sub-modules
    RNS_complement comp_inst (
        .RNS_ALU_EN(RNS_ALU_EN),
        .op1_in(op1_in),
        .op2_in(op2_in),
        .en_complement(en_complement),
        .add_op(add_op),
        .mul_op(mul_op),
        .op1(op1),
        .op2(op2)
    );

    /*
        The adder and multiplier both have 16-bit outputs:
            reasoning is obvious for the multiplier,
            but for the adder it was just more convenient to fill the upper 8 bits with 0s
            due to the multiplier REQUIRING 16-bit outputs. 
            Means that the % modules (fit_xxx) do less work.
    */
    RNS_adder add_inst (
        .op1(op1),
        .op2(op2),
        .result(adder_result)
    );

    RNS_sub #(modulus) sub_inst (
        .op1(op1),
        .op2(op2),
        .result(sub_result)
    );

    RNS_multiplier mul_inst (
        .op1(op1),
        .op2(op2),
        .result(mul_result)
    );

    //if en_complement is HIGH, that means we're intended to perform a subtraction operation.
    //only reason it's still named 'en_complement' here instead of 'sub_op' or something is to retain original naming for consistency
    assign final_result = (mul_op == 1'b1) ? mul_result : (en_complement == 1'b1) ? sub_result : adder_result;

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