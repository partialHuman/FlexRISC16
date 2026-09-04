`timescale 1ns / 1ps
`default_nettype none
`include "cpu_constants.vh"

//============================================================
// Project : FlexRISC16
// Module  : Write Back Multiplexer
//============================================================

module write_back_mux
#(
    parameter DATA_WIDTH = 16
)
(
    //--------------------------------------------------------
    // Select
    //--------------------------------------------------------

    input wire [2:0] wb_sel,

    //--------------------------------------------------------
    // Sources
    //--------------------------------------------------------

    input wire [DATA_WIDTH-1:0] alu_data,
    input wire [DATA_WIDTH-1:0] mem_data,
    input wire [DATA_WIDTH-1:0] pc_data,
    input wire [DATA_WIDTH-1:0] imm_data,

    //--------------------------------------------------------
    // Output
    //--------------------------------------------------------

    output reg [DATA_WIDTH-1:0] wb_data

);

//============================================================
// Write Back Selection
//============================================================

always @(*)
begin

    case(wb_sel)

        //------------------------------------
        // ALU Result
        //------------------------------------

        `WB_ALU:
            wb_data = alu_data;

        //------------------------------------
        // Memory
        //------------------------------------

        `WB_MEMORY:
            wb_data = mem_data;

        //------------------------------------
        // PC + 1
        //------------------------------------

        `WB_PC:
            wb_data = pc_data;

        //------------------------------------
        // Immediate
        //------------------------------------

        `WB_IMM:
            wb_data = imm_data;

        //------------------------------------
        // Reserved
        //------------------------------------

        `WB_MUL:
            wb_data = {DATA_WIDTH{1'b0}};

        `WB_DIV:
            wb_data = {DATA_WIDTH{1'b0}};

        `WB_CSR:
            wb_data = {DATA_WIDTH{1'b0}};

        //------------------------------------
        // Default
        //------------------------------------

        default:
            wb_data = {DATA_WIDTH{1'b0}};

    endcase

end

endmodule
`default_nettype wire
