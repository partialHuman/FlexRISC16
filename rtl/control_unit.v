`timescale 1ns / 1ps
`include "cpu_constants.vh"

//============================================================
// Project : FlexRISC16
// Module  : Control Unit
//============================================================

module control_unit
(
    input wire clk,
    input wire rst,

    //--------------------------------------------------------
    // Decoded Instruction Information
    //--------------------------------------------------------

    input wire [1:0] instr_class,

    input wire is_load,
    input wire is_store,
    input wire is_branch,
    input wire is_immediate,

    //--------------------------------------------------------
    // Output
    //--------------------------------------------------------

    output reg [15:0] control_word,
    output wire [2:0] debug_state

);

//============================================================
// FSM
//============================================================

reg [2:0] state;
reg [2:0] next_state;

// Debug Output
assign debug_state = state;

//============================================================
// State Register
//============================================================

always @(posedge clk)
begin

    if(rst)
        state <= `ST_RESET;
    else
        state <= next_state;

end

//============================================================
// Next State Logic
//============================================================

always @(*)
begin

    next_state = state;

    case(state)

        //------------------------------------
        // RESET
        //------------------------------------

        `ST_RESET:
            next_state = `ST_FETCH;

        //------------------------------------
        // FETCH
        //------------------------------------

        `ST_FETCH:
            next_state = `ST_DECODE;

        //------------------------------------
        // DECODE
        //------------------------------------

        `ST_DECODE:
            next_state = `ST_EXECUTE;

        //------------------------------------
        // EXECUTE
        //------------------------------------

        `ST_EXECUTE:
        begin

            if(is_load || is_store)
                next_state = `ST_MEMORY;

            else if(is_branch)
                next_state = `ST_FETCH;

            else
                next_state = `ST_WRITEBACK;

        end

        //------------------------------------
        // MEMORY
        //------------------------------------

        `ST_MEMORY:
        begin

            if(is_load)
                next_state = `ST_WRITEBACK;
            else
                next_state = `ST_FETCH;

        end

        //------------------------------------
        // WRITEBACK
        //------------------------------------

        `ST_WRITEBACK:
            next_state = `ST_FETCH;

        //------------------------------------

        default:
            next_state = `ST_RESET;

    endcase

end

//============================================================
// Control Word Generator
//============================================================

always @(*)
begin

    //----------------------------------------
    // Default
    //----------------------------------------

    control_word = 16'h0000;

    case(state)

    //--------------------------------------------------------
    // FETCH
    //--------------------------------------------------------

    `ST_FETCH:
    begin

        control_word[`CTRL_PC_EN]   = 1'b1;
        control_word[`CTRL_IR_LOAD] = 1'b1;

    end

    //--------------------------------------------------------
    // DECODE
    //--------------------------------------------------------

    `ST_DECODE:
    begin
        // No control signals required
    end

    //--------------------------------------------------------
    // EXECUTE
    //--------------------------------------------------------

    `ST_EXECUTE:
    begin

        //------------------------------------
        // ALU Enable
        //------------------------------------

        if(!is_branch)
            control_word[`CTRL_ALU_EN] = 1'b1;

        //------------------------------------
        // Update Flags only for ALU operations
        //------------------------------------

        if(instr_class == `CLASS_ALU)
            control_word[`CTRL_FLAG_WR] = 1'b1;

    end

    //--------------------------------------------------------
    // MEMORY
    //--------------------------------------------------------

    `ST_MEMORY:
    begin

        control_word[`CTRL_ALU_EN] = 1'b1;

        if(is_load)
            control_word[`CTRL_MEM_RD] = 1'b1;

        if(is_store)
            control_word[`CTRL_MEM_WR] = 1'b1;

    end

    //--------------------------------------------------------
    // WRITEBACK
    //--------------------------------------------------------

    `ST_WRITEBACK:
    begin

        //------------------------------------
        // LOAD
        //------------------------------------

        if(is_load)
        begin

            control_word[`CTRL_REG_WR] = 1'b1;

            control_word[`CTRL_WB_SEL_MSB:
                         `CTRL_WB_SEL_LSB]
                         = `WB_MEMORY;

        end

        //------------------------------------
        // ALU / Immediate Instructions
        //------------------------------------

        else if(!is_branch && !is_store)
        begin

            control_word[`CTRL_REG_WR] = 1'b1;

            if(is_immediate)
            begin

                control_word[`CTRL_WB_SEL_MSB:
                             `CTRL_WB_SEL_LSB]
                             = `WB_IMM;

            end

            else
            begin

                control_word[`CTRL_WB_SEL_MSB:
                             `CTRL_WB_SEL_LSB]
                             = `WB_ALU;

            end

        end

    end

    endcase

end

endmodule