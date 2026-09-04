`timescale 1ns / 1ps
`default_nettype none

//============================================================
// Project : FlexRISC16
// Module  : Program Counter
//============================================================

module program_counter
#(
    parameter ADDR_WIDTH = 16
)
(
    input  wire                     clk,
    input  wire                     rst,

    // Global Enable
    input  wire                     pc_enable,

    // Pipeline Stall
    input  wire                     stall,

    // Branch / Jump Load
    input  wire                     pc_load,

    // Next PC
    input  wire [ADDR_WIDTH-1:0]    pc_next,

    // Current PC
    output reg  [ADDR_WIDTH-1:0]    pc
);

always @(posedge clk)
begin

    //----------------------------------------
    // Reset
    //----------------------------------------

    if(rst)
    begin
        pc <= {ADDR_WIDTH{1'b0}};
    end

    //----------------------------------------
    // Pipeline Stall
    //----------------------------------------

    else if(stall)
    begin
        pc <= pc;
    end

    //----------------------------------------
    // PC Enabled
    //----------------------------------------

    else if(pc_enable)
    begin

        //------------------------------------
        // Branch / Jump
        //------------------------------------

        if(pc_load)
            pc <= pc_next;

        //------------------------------------
        // Sequential
        //------------------------------------

        else
            pc <= pc + 1'b1;

    end

end

endmodule
`default_nettype wire
