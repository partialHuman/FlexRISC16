`timescale 1ns / 1ps
`default_nettype none

//============================================================
// Project : FlexRISC16
// Module  : Pipeline Processor Top
//============================================================
//
// NOTE: the original file instantiated `performance_counter`
// wired to signals like mem_wb_reg_write / stall_pc / id_ex_branch
// / forward_a / forward_b - none of which existed in this module's
// scope (they're internal to pipeline_datapath, and were never
// exposed as ports), and `performance_counter` itself wasn't
// included in the file set. Fixed by moving the performance
// counter instantiation inside pipeline_datapath (where those
// signals are actually available) and exposing just its six
// counter outputs here.

module pipeline_processor_top
(
    input wire clk,
    input wire rst,

    //------------------------------------------------------------
    // Debug Signals
    //------------------------------------------------------------

    output wire [15:0] debug_pc,
    output wire [15:0] debug_instruction,

    output wire [15:0] debug_alu_result,
    output wire [15:0] debug_memory_data,
    output wire [15:0] debug_writeback,
    output wire debug_reg_write,
    output wire [3:0] debug_rd,

    //------------------------------------------------------------
    // Performance Counter Signals
    //------------------------------------------------------------

    output wire [31:0] cycle_count,
    output wire [31:0] instruction_count,
    output wire [31:0] stall_count,
    output wire [31:0] branch_count,
    output wire [31:0] branch_taken_count,
    output wire [31:0] forwarding_count
);

//------------------------------------------------------------
// Pipeline Datapath
//------------------------------------------------------------

pipeline_datapath PIPELINE
(
    .clk(clk),
    .rst(rst),

    .debug_pc(debug_pc),
    .debug_instruction(debug_instruction),
    .debug_alu_result(debug_alu_result),
    .debug_memory_data(debug_memory_data),
    .debug_writeback(debug_writeback),
    .debug_reg_write(debug_reg_write),
    .debug_rd(debug_rd),

    .cycle_count(cycle_count),
    .instruction_count(instruction_count),
    .stall_count(stall_count),
    .branch_count(branch_count),
    .branch_taken_count(branch_taken_count),
    .forwarding_count(forwarding_count)
);

endmodule
`default_nettype wire