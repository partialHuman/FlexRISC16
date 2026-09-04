`timescale 1ns / 1ps
`default_nettype none
`include "cpu_constants.vh"

//============================================================
// Project : FlexRISC16
// Module  : Arithmetic Logic Unit
//============================================================

module alu
#(
    parameter DATA_WIDTH = 16
)
(
    //--------------------------------------------------------
    // Inputs
    //--------------------------------------------------------

    input wire [DATA_WIDTH-1:0] operand_a,
    input wire [DATA_WIDTH-1:0] operand_b,

    input wire [3:0] alu_operation,

    //--------------------------------------------------------
    // Outputs
    //--------------------------------------------------------

    output reg [DATA_WIDTH-1:0] result,

    output reg carry,
    output reg zero,
    output reg negative,
    output reg overflow
);

//------------------------------------------------------------
// Internal
//------------------------------------------------------------

reg [DATA_WIDTH:0] temp;

//------------------------------------------------------------
// ALU
//------------------------------------------------------------

always @(*)
begin

    //----------------------------------------
    // Defaults
    //----------------------------------------

    result     = 0;
    carry      = 0;
    overflow   = 0;

    temp       = 0;

    //----------------------------------------
    // Operation
    //----------------------------------------

    case(alu_operation)

    //----------------------------------------
    // ADD
    //----------------------------------------

    `ALU_ADD:
    begin
        temp   = operand_a + operand_b;
        result = temp[DATA_WIDTH-1:0];
        carry  = temp[DATA_WIDTH];
        
        overflow =
        (~(operand_a[DATA_WIDTH-1]^operand_b[DATA_WIDTH-1])) &
        ( operand_a[DATA_WIDTH-1]^result[DATA_WIDTH-1]);
    end

    //----------------------------------------
    // SUB
    //----------------------------------------

    `ALU_SUB:
    begin
        temp   = operand_a - operand_b;
        result = temp[DATA_WIDTH-1:0];
        carry  = temp[DATA_WIDTH];

        overflow =
        (operand_a[DATA_WIDTH-1]^operand_b[DATA_WIDTH-1]) &
        (operand_a[DATA_WIDTH-1]^result[DATA_WIDTH-1]);
    end

    //----------------------------------------
    // AND
    //----------------------------------------

    `ALU_AND:
        result = operand_a & operand_b;

    //----------------------------------------
    // OR
    //----------------------------------------

    `ALU_OR:
        result = operand_a | operand_b;

    //----------------------------------------
    // XOR
    //----------------------------------------

    `ALU_XOR:
        result = operand_a ^ operand_b;

    //----------------------------------------
    // NOT
    //----------------------------------------

    `ALU_NOT:
        result = ~operand_a;

    //----------------------------------------
    // MOV
    //----------------------------------------

    `ALU_MOV:
        result = operand_b;

    //----------------------------------------
    // SHL
    //----------------------------------------

    `ALU_SHL:
    begin
        result = operand_a << 1;
        carry  = operand_a[DATA_WIDTH-1];
    end

    //----------------------------------------
    // SHR
    //----------------------------------------

    `ALU_SHR:
    begin
        result = operand_a >> 1;
        carry  = operand_a[0];
    end

    //----------------------------------------
    // CMP
    //----------------------------------------

    `ALU_CMP:
    begin
        temp = operand_a - operand_b;
        result = temp[DATA_WIDTH-1:0];
        carry = temp[DATA_WIDTH];
        
        overflow =
        (operand_a[DATA_WIDTH-1]^operand_b[DATA_WIDTH-1]) &
        (operand_a[DATA_WIDTH-1]^result[DATA_WIDTH-1]);
    end

    //----------------------------------------
    // Default
    //----------------------------------------

    default:
        result = 0;

    endcase

    //----------------------------------------
    // Common Flags
    //----------------------------------------

    zero = (result == 0);
    negative = result[DATA_WIDTH-1];

end

endmodule
`default_nettype wire
