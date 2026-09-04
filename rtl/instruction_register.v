`timescale 1ns / 1ps
`include "cpu_constants.vh"

//============================================================
// Project : FlexRISC16
// Module  : Instruction Register
//============================================================

module instruction_register
#(
    parameter DATA_WIDTH = 16,
    parameter NOP_INSTRUCTION = `NOP_INSTRUCTION
)
(
    input  wire                    clk,
    input  wire                    rst,

    // Enable instruction update
    input  wire                    enable,

    // Hold current instruction
    input  wire                    stall,

    // Flush pipeline
    input  wire                    flush,

    // Instruction from Instruction Memory
    input  wire [DATA_WIDTH-1:0]   instruction_in,

    // Current Instruction
    output reg [DATA_WIDTH-1:0]    instruction_out
);

//------------------------------------------------------------
// Instruction Register
//------------------------------------------------------------

always @(posedge clk)
begin

    //----------------------------------------
    // Reset
    //----------------------------------------

    if(rst)
    begin
        instruction_out <= NOP_INSTRUCTION;
    end

    //----------------------------------------
    // Flush
    //----------------------------------------

    else if(flush)
    begin
        instruction_out <= NOP_INSTRUCTION;
    end

    //----------------------------------------
    // Stall
    //----------------------------------------

    else if(stall)
    begin
        // Hold current instruction
    end

    //----------------------------------------
    // Normal Operation
    //----------------------------------------

    else if(enable)
    begin
        instruction_out <= instruction_in;
    end

end

endmodule