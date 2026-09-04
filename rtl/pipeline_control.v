`timescale 1ns / 1ps

//============================================================
// Project : FlexRISC16 Pipeline
// Module  : Pipeline Control
//============================================================

module pipeline_control
(
    //--------------------------------------------------------
    // Inputs
    //--------------------------------------------------------

    input wire branch_taken,

    input wire stall_pc,
    input wire stall_if_id,
    input wire flush_id_ex,

    //--------------------------------------------------------
    // Outputs
    //--------------------------------------------------------

    output wire pc_enable,

    output wire if_id_enable,
    output wire if_id_flush,

    output wire id_ex_enable,
    output wire id_ex_flush

);

//------------------------------------------------------------
// PC
//------------------------------------------------------------

assign pc_enable = ~stall_pc;

//------------------------------------------------------------
// IF/ID
//------------------------------------------------------------

assign if_id_enable = ~stall_if_id;

assign if_id_flush = branch_taken;

//------------------------------------------------------------
// ID/EX
//------------------------------------------------------------

assign id_ex_enable = 1'b1;

assign id_ex_flush = flush_id_ex | branch_taken;

endmodule