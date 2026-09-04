`timescale 1ns / 1ps
`default_nettype none
`include "cpu_constants.vh"
//============================================================
// Project : FlexRISC16
// Module  : Instruction Decoder
//============================================================

module instruction_decoder(

    input wire [`DATA_WIDTH-1:0] instruction,

    output wire [3:0] opcode,
    output wire [3:0] rd,
    output wire [3:0] rs1,
    output wire [3:0] rs2,

    // output reg [`DATA_WIDTH-1:0] immediate,

    //------------------------------------------------------------
    // Decoded Information
    //------------------------------------------------------------
    output reg [1:0] instr_class,
    output reg [3:0] alu_func,

    output reg is_load,
    output reg is_store,
    output reg is_branch,
    output reg is_immediate,
    output reg alu_src

);

//------------------------------------------------------------
// Basic Decode
//------------------------------------------------------------

assign opcode = instruction[15:12];
assign rd     = instruction[11:8];
assign rs1    = instruction[7:4];
assign rs2    = instruction[3:0];

//------------------------------------------------------------
// Instruction Decode
//------------------------------------------------------------

always @(*) begin

    //------------------------------------------------------------
    // Default Values
    //------------------------------------------------------------

    instr_class = `CLASS_ALU;
    alu_func    = `ALU_NOP;

    is_load      = 1'b0;
    is_store     = 1'b0;
    is_branch    = 1'b0;
    is_immediate = 1'b0;
    alu_src = 1'b0;

    case(opcode)

    //--------------------------------------------------------
    // R-Type Instructions
    //--------------------------------------------------------

    `OP_ADD:
    begin
        instr_class = `CLASS_ALU;
        alu_func = `ALU_ADD;
        alu_src = 1'b0;
    end

    `OP_SUB:
    begin
        instr_class = `CLASS_ALU;
        alu_func = `ALU_SUB;
        alu_src = 1'b0;
    end

    `OP_AND:
    begin
        instr_class = `CLASS_ALU;
        alu_func = `ALU_AND;
        alu_src = 1'b0;
    end

    `OP_OR:
    begin
        instr_class = `CLASS_ALU;
        alu_func = `ALU_OR;
        alu_src = 1'b0;
    end

    `OP_XOR:
    begin
        instr_class = `CLASS_ALU;
        alu_func = `ALU_XOR;
        alu_src = 1'b0;
    end

    `OP_NOT:
    begin
        instr_class = `CLASS_ALU;
        alu_func = `ALU_NOT;
        alu_src = 1'b0;
    end

    `OP_CMP:
    begin
        instr_class = `CLASS_ALU;
        alu_func = `ALU_CMP;
        alu_src = 1'b0;
    end

    //--------------------------------------------------------
    // MOVI (I-Type)
    //--------------------------------------------------------

    `OP_MOV:
    begin
        instr_class =  `CLASS_IMMEDIATE;
        alu_func    = `ALU_MOV;
        is_immediate     = 1'b1;
        alu_src = 1'b1;
    end

    //--------------------------------------------------------
    // Memory
    //--------------------------------------------------------

    `OP_LOAD:
    begin
        instr_class = `CLASS_MEMORY;
        is_load      = 1'b1;
        is_store     = 1'b0;
        alu_func = `ALU_ADD;
        alu_src = 1'b1;
    end

    `OP_STORE:
    begin
        instr_class = `CLASS_MEMORY;
        is_load      = 1'b0;
        is_store     = 1'b1;
        alu_func = `ALU_ADD;
        alu_src = 1'b1;
    end

    //--------------------------------------------------------
    // Branch
    //--------------------------------------------------------

    `OP_JMP,
    `OP_BEQ,
    `OP_BNE:
    begin
        instr_class = `CLASS_BRANCH;
        is_branch = 1'b1;
        alu_func = `ALU_NOP;
        alu_src = 1'b0;
    end

    //--------------------------------------------------------
    // Shift
    //--------------------------------------------------------

    `OP_SHL:
    begin
        instr_class = `CLASS_ALU;
        alu_func = `ALU_SHL;
        alu_src = 1'b0;
    end

    `OP_SHR:
    begin
        instr_class = `CLASS_ALU;
        alu_func = `ALU_SHR;
        alu_src = 1'b0;
    end

    default:
    begin
        instr_class = `CLASS_ALU;
        alu_func = `ALU_NOP;
    end

    endcase

end

endmodule
`default_nettype wire
