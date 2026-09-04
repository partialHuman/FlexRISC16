`timescale 1ns / 1ps
`default_nettype none
`include "cpu_constants.vh"

//============================================================
// Project : FlexRISC16
// Module  : ALU Control
//============================================================

module alu_control(
    input wire alu_enable,
    input wire [1:0] instr_class,
    input wire [3:0] alu_func,
    output reg [3:0] alu_operation
);

always @(*) begin

    //----------------------------------------
    // Default
    //----------------------------------------

    alu_operation = `ALU_NOP;

    //----------------------------------------
    // Only ALU and MEMORY instructions
    // require ALU operations
    //----------------------------------------

    if(alu_enable)
    begin

        case(instr_class)

            //--------------------------------
            // Arithmetic / Logic
            //--------------------------------

            `CLASS_ALU:
                alu_operation = alu_func;
            
            //--------------------------------
            // Immediate Instructions
            //--------------------------------
                
            `CLASS_IMMEDIATE:
               alu_operation = alu_func;

            //--------------------------------
            // Memory Address Calculation
            //--------------------------------

            `CLASS_MEMORY:
                alu_operation = alu_func;

            //--------------------------------
            // Branch
            //--------------------------------

            `CLASS_BRANCH:
                alu_operation = `ALU_NOP;

            //--------------------------------
            // System
            //--------------------------------

            default:
                alu_operation = `ALU_NOP;

        endcase

    end

end

endmodule
`default_nettype wire
