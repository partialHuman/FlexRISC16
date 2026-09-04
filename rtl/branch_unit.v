`timescale 1ns / 1ps
`default_nettype none
`include "cpu_constants.vh"

//============================================================
// Project : FlexRISC16
// Module  : Branch Unit
//============================================================

module branch_unit
(
    //--------------------------------------------------------
    // Inputs
    //--------------------------------------------------------

    input wire [3:0] opcode,

    input wire carry_flag,
    input wire zero_flag,
    input wire negative_flag,
    input wire overflow_flag,

    //--------------------------------------------------------
    // Output
    //--------------------------------------------------------

    output reg branch_taken
);

//============================================================
// Branch Decision Logic
//============================================================

always @(*)
begin

    //----------------------------------------
    // Default
    //----------------------------------------

    branch_taken = 1'b0;

    //----------------------------------------
    // Branch Decode
    //----------------------------------------

    case(opcode)

        //------------------------------------
        // JMP
        //------------------------------------

        `OP_JMP:
            branch_taken = 1'b1;

        //------------------------------------
        // BEQ
        //------------------------------------

        `OP_BEQ:
            branch_taken = zero_flag;

        //------------------------------------
        // BNE
        //------------------------------------

        `OP_BNE:
            branch_taken = ~zero_flag;

        //------------------------------------
        // Reserved for future ISA expansion
        //------------------------------------

        //`OP_BLT:
            //branch_taken = negative_flag;

        //`OP_BGE:
          //  branch_taken = ~negative_flag;

        //`OP_BVS:
          //  branch_taken = overflow_flag;

        //`OP_BVC:
          //  branch_taken = ~overflow_flag;

       // `OP_BCS:
       // branch_taken = carry_flag;

       // `OP_BCC:
         //   branch_taken = ~carry_flag;

        default:
            branch_taken = 1'b0;

    endcase

end

endmodule
`default_nettype wire
