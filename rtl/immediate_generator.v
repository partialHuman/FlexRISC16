`timescale 1ns / 1ps
`default_nettype none
`include "cpu_constants.vh"

//============================================================
// Project : FlexRISC16
// Module  : Immediate Generator
// Description:
//   Generates sign/zero extended immediates from instructions
//============================================================

module immediate_generator
(
    input  wire [`DATA_WIDTH-1:0] instruction,
    input  wire [1:0]             instr_class,

    output reg [`DATA_WIDTH-1:0] immediate
);

//------------------------------------------------------------
// Immediate Extraction
//------------------------------------------------------------

always @(*)
begin

    immediate = {`DATA_WIDTH{1'b0}};

    case(instr_class)

    //--------------------------------------------------------
    // ALU Register Instructions
    //--------------------------------------------------------

    `CLASS_ALU:
    begin
        immediate = 16'd0;
    end

    //--------------------------------------------------------
    // Immediate Instructions (MOVI / ADDI ...)
    //--------------------------------------------------------

    `CLASS_IMMEDIATE:
    begin
        immediate = {{8{instruction[7]}},
                      instruction[7:0]};
    end

    //--------------------------------------------------------
    // Memory Instructions
    //--------------------------------------------------------

    `CLASS_MEMORY:
    begin
        immediate = {{12{instruction[3]}},
                      instruction[3:0]};
    end

    //--------------------------------------------------------
    // Branch Instructions
    //--------------------------------------------------------

    `CLASS_BRANCH:
    begin
        immediate = {{8{instruction[7]}},
                      instruction[7:0]};
    end

    //--------------------------------------------------------

    default:
        immediate = 16'd0;

    endcase

end

endmodule
`default_nettype wire
