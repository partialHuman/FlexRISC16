`timescale 1ns / 1ps
`default_nettype none

//============================================================
// Project : FlexRISC16
// Module  : Status Register
//============================================================

module status_register
#(
    parameter FLAG_WIDTH = 4
)
(
    input  wire clk,
    input  wire rst,

    //--------------------------------------------------------
    // Control
    //--------------------------------------------------------

    input  wire enable,

    //--------------------------------------------------------
    // ALU Flags
    //--------------------------------------------------------

    input  wire carry_in,
    input  wire zero_in,
    input  wire negative_in,
    input  wire overflow_in,

    //--------------------------------------------------------
    // Stored Flags
    //--------------------------------------------------------

    output reg carry_out,
    output reg zero_out,
    output reg negative_out,
    output reg overflow_out
);

//============================================================
// Status Register
//============================================================

always @(posedge clk)
begin

    //----------------------------------------
    // Reset
    //----------------------------------------

    if(rst)
    begin

        carry_out     <= 1'b0;
        zero_out      <= 1'b0;
        negative_out  <= 1'b0;
        overflow_out  <= 1'b0;

    end

    //----------------------------------------
    // Update Flags
    //----------------------------------------

    else if(enable)
    begin

        carry_out     <= carry_in;
        zero_out      <= zero_in;
        negative_out  <= negative_in;
        overflow_out  <= overflow_in;

    end

end

endmodule
`default_nettype wire
