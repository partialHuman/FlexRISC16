`timescale 1ns / 1ps
`include "cpu_constants.vh"

//============================================================
// Project : FlexRISC16
// Module  : Processor Top
//============================================================

module processor_top
(
    input wire clk,
    input wire rst,

    // Debug Outputs
    output wire [`ADDR_WIDTH-1:0] debug_pc,
    output wire [`DATA_WIDTH-1:0] debug_instruction,
    output wire [`DATA_WIDTH-1:0] debug_alu_result,
    output wire [`DATA_WIDTH-1:0] debug_writeback,
    
    // Debug FSM State
    output wire [2:0] debug_state,
    
    output wire zero_flag,
    output wire carry_flag
);

//============================================================
// Internal Signals
//============================================================

//------------------------------------------------------------
// Control Word
//------------------------------------------------------------

wire [15:0] control_word;

//------------------------------------------------------------
// Decoder Outputs
//------------------------------------------------------------

wire [3:0] opcode;
wire [1:0] instr_class;
wire is_load;
wire is_store;
wire is_branch;
wire is_immediate;

//============================================================
// Control Unit
//============================================================

control_unit CONTROL
(
    .clk(clk),
    .rst(rst),
    .instr_class(instr_class),
    .is_load(is_load),
    .is_store(is_store),
    .is_branch(is_branch),
    .is_immediate(is_immediate),
    .control_word(control_word),
    .debug_state(debug_state)
);

//============================================================
// Datapath
//============================================================

datapath DATAPATH
(
    .clk(clk),
    .rst(rst),
    .control_word(control_word),
    .opcode(opcode),
    .instr_class(instr_class),
    .is_load(is_load),
    .is_store(is_store),
    .is_branch(is_branch),
    .is_immediate(is_immediate),
    .zero_flag(zero_flag),
    .carry_flag(carry_flag),
    .debug_pc(debug_pc),
    .debug_instruction(debug_instruction),
    .debug_alu_result(debug_alu_result),
    .debug_writeback(debug_writeback)
);

endmodule