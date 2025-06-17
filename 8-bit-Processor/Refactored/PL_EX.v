//Description: EX Stage of pipeline. Modified from NayanaBannur/8-bit-RISC-Processor to support parameterized values / RNS domains
//             Instantiates ALU for each domain.

module PL_EX #(parameter NUM_DOMAINS = 1, PROG_CTR_WID = 10) (
    input clk, reset,
    //Pipeline registers from IFID
    input [NUM_DOMAINS*8 - 1:0]     op1, op2,               // { [7:0] Domain1, [7:0] Domain2, ... }
    input [2:0]                     res_addr,              // result address for regfile write
    input [PROG_CTR_WID-1:0]        pred_nxt_prog_ctr,      // next program counter value from IFID
    input [0:38]                    IFID_reg,               // IFID pipeline register out
    input                           branch_taken,

    output reg [0:4]                branch_conds_EX,
    output reg                      branch_taken_EX, //indicate branch was taken in EX stage- reg out needed for timing in Program Counter & IFID I believe
    output reg [7:0]                data_wr_addr, data_rd_addr, //data memory write/read address
    output reg [0:6]                EX_reg,
    output reg [2:0]                destination_reg_addr,
    output reg [NUM_DOMAINS*8 - 1:0] operation_result,      // { [7:0] Domain1, [7:0] Domain2, ... }
    output reg [PROG_CTR_WID-1:0]   pred_nxt_prog_ctr_EX,
    output cout, 
    output [7:0] dout
);
    /*
        Map of IFID_reg input:
        IFID_reg <= #1 {          //og arr | len | IFID_reg idx 
            invalidate_fetch_instr, //      (1)    [0]
            branch_taken_EX,        //      (1)    [1]     invalidate_decode_instr = branch_taken_EX. so we can just pass that
            add_op_true,            //      (1)    [2]
            or_op_true,             //      (1)    [3]
            not_op_true,            //      (1)    [4]
            and_bitwise_true,       //      (1)    [5]
            or_bitwise_true,        //      (1)    [6]
            not_bitwise_true,       //      (1)    [7]
            and_op_true,            //      (1)    [8]
            carry_in,               //      (1)    [9]
            en_op2_complement,      //      (1)    [10]
            jump_true,              //      (1)    [11]
            compare_true,           //      (1)    [12]
            shift_left_true,        //      (1)    [13]
            lgcl_or_bitwse_T,       //      (1)    [14]
            store_true,             //      (1)    [15]
            load_true_IFID,         //      (1)    [16]
            write_to_regfile,       //      (1)    [17]
            jump_gt,                //      (1)    [18]
            jump_lt,                //      (1)    [19]
            jump_eq,                //      (1)    [20]
            jump_carry,             //      (1)    [21]
            unconditional_jump,     //      (1)    [22]
            ld_mem_addr,            //[7:0] (8)    [23:30]
            st_mem_addr             //[7:0] (8)    [31:38] 
        };                       //total len: 39 bits
    */
    reg [NUM_DOMAINS*8 - 1:0] din_1, din_2; //ALU op1/op2
    reg [NUM_DOMAINS*8 - 1:0] ALU_dout, Shift_dout, LGCL_dout;
    wire [NUM_DOMAINS*8 - 1:0] cmb_dout; //final output of ALU/Shift/LGCL
    reg ALU_cout, Shift_cout; 
    wire cmb_cout, save_cout;

    wire COMP_gt_flag, COMP_lt_flag, COMP_eq_flag;

    //trigger at op1, op2, en_op2_comp,    store_true,     add_op_true, lgcl_or_btwse_T, shift_left_true   
    always @(op1 or op2 or IFID_reg[10] or IFID_reg[15] or IFID_reg[2] or IFID_reg[14] or IFID_reg[13])
    begin
        din_1 <= op1; //always passed as-is
        if (IFID_reg[15] == 1'b1) begin //if store_true
            din_2 <= 8'b0;
        end 
        else if (IFID_reg[10] == 1'b1) begin //if en_op2_complement
            din_2 <= ~op2;
        end
        else begin
            din_2 <= op2;
        end
    end

    //**// ADDER //**//
    //trigger at din_1, din_2, carry_in
    always @(din_1 or din_2 or IFID_reg[9]) //AS IS, THIS WILL NOT WORK FOR >1 DOMAIN.
    begin
        {ALU_cout, ALU_dout} <= din_1 + din_2 + IFID_reg[9];
    end
    //**//       //**//

    //**// COMPARE //**//
    assign COMP_gt_flag = (ALU_cout == 1'b1) && (ALU_dout != 8'b0) && (IFID_reg[12] == 1'b1);
    assign COMP_lt_flag = (ALU_cout == 1'b0) && (ALU_dout != 8'b0) && (IFID_reg[12] == 1'b1);
    assign COMP_eq_flag = (ALU_dout == 8'b0)            &&            (IFID_reg[12] == 1'b1);
    //**//         //**//

    //**// Shift Left //**//
    always @(din_1)
    begin
        Shift_cout <= din_1[7];
        Shift_dout <= {din_1[6:0], 1'b0}; //shift left by 1
    end 
    //**//            //**//

    //**// Logical & Bitwise //**//
    always @(IFID_reg[8] or IFID_reg[3] or IFID_reg[4] or IFID_reg[5] or IFID_reg[6] or IFID_reg[7] or din_1 or din_2)
    begin
        if (IFID_reg[8] == 1'b1)        // and_op_true
            LGCL_dout <= din_1 && din_2;
        else if (IFID_reg[5] == 1'b1)   // and_bitwise_true
            LGCL_dout <= din_1 & din_2;
        else if (IFID_reg[3] == 1'b1)   // or_op_true
            LGCL_dout <= din_1 || din_2;
        else if (IFID_reg[6] == 1'b1)   // or_bitwise_true
            LGCL_dout <= din_1 | din_2;
        else if (IFID_reg[4] == 1'b1)   // not_op_true
            LGCL_dout <= !din_1;
        else
            LGCL_dout <= !din_1; //default is NOT (bitwise) - Does this have a point? Does this mean we have a free opcode?
    end
    //**//                   //**//

    //**// Get final outputs //**//
    assign cmb_dout = (IFID_reg[2] || IFID_reg[15]) ? ALU_dout : 
                      (IFID_reg[14]? LGCL_dout : Shift_dout); 

    assign cmb_cout = IFID_reg[2] ? ALU_cout : Shift_cout; //if add_op_true, cmb_cout = ALU_cout, else cmb_cout = Shift_cout

    assign save_cout = (IFID_reg[2] && !IFID_reg[12]) || IFID_reg[13]; //save cout if we're adding and not comparing, or if we're shifting left
    //**//                   //**//

    assign cout = ALU_cout; //output carry out
    assign dout = ALU_dout; //output data

    //**// EX Stage Pipeline Register Out //**//
    wire [7:0] ld_mem_addr, st_mem_addr; //load/store memory address
    assign ld_mem_addr = IFID_reg[23:30];
    assign st_mem_addr = IFID_reg[31:38];
    always @(posedge clk)
	begin
        //Combined pipeline register elements
        data_wr_addr <= #1 IFID_reg[15] ? st_mem_addr : ld_mem_addr; //if store_true, write to st_mem_addr_reg, else write to ld_mem_addr_reg
        data_rd_addr <= #1 ld_mem_addr; 

        EX_reg[4:6] <= #1 {
            IFID_reg[16],   //load_true_IFID
            IFID_reg[0],    //invalidate_fetch_instr
            IFID_reg[1]     //invalidate_decode_instr
        };

        //Distinct pipeline register elements
        operation_result <= #1 cmb_dout;

        branch_conds_EX <= #1 {
            COMP_gt_flag,
            COMP_lt_flag,
            COMP_eq_flag,
            save_cout && cmb_cout,
            IFID_reg[12] //compare_true_EX
        };   

        pred_nxt_prog_ctr_EX <= #1 pred_nxt_prog_ctr;
	end

    //Seperate, to disable register / memory writes during reset
    always @(posedge clk)
    begin
        if (reset == 1'b1)
        begin
            EX_reg[0:3] <= #1 4'b0;
            /*
                store_to_mem_ex <= #1 1'b0;
                reg_wr_en_ex <= #1 1'b0;
                invalidate_execute_instr <= 1'b0;
                save_cout <= 1'b0;
            */
           // branch_taken_EX <= #1 1'b0;
            destination_reg_addr <= 3'b0;
        end
        else begin
            branch_taken_EX <= #1 branch_taken;
            EX_reg[0:3] <= #1 {
                IFID_reg[15],   //store_true
                IFID_reg[17],   //write_to_regfile
                save_cout,
                branch_taken_EX //invalidate_execute_instr
            };
            destination_reg_addr <= #1 res_addr;
        end
    end

    /*
        EX_reg signals:                 Len. | Index
        {
            store_to_mem,               (1)    [0]
            reg_wr_en,                  (1)    [1]
            save_cout,                  (1)    [2]
            invalidate_execute_instr,   (1)    [3]
            load_true,                  (1)    [4]
            invalidate_fetch_instr,     (1)    [5]
            invalidate_decode_instr     (1)    [6]
        }
    */
endmodule