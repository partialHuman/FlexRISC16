`timescale 1ns / 1ps

//============================================================
// Project : FlexRISC16 Pipeline
// Module  : IF/ID Pipeline Register
//============================================================

module if_id_register
#(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16
)
(
    //--------------------------------------------------------
    // Clock & Reset
    //--------------------------------------------------------

    input wire clk,
    input wire rst,

    //--------------------------------------------------------
    // Pipeline Control
    //--------------------------------------------------------

    input wire enable,
    input wire stall,
    input wire flush,

    //--------------------------------------------------------
    // IF Stage Inputs
    //--------------------------------------------------------

    input wire [ADDR_WIDTH-1:0] pc_in,
    input wire [ADDR_WIDTH-1:0] pc_plus_one_in,
    input wire [DATA_WIDTH-1:0] instruction_in,
    input wire                  valid_in,

    //--------------------------------------------------------
    // ID Stage Outputs
    //--------------------------------------------------------

    output reg [ADDR_WIDTH-1:0] pc_out,
    output reg [ADDR_WIDTH-1:0] pc_plus_one_out,
    output reg [DATA_WIDTH-1:0] instruction_out,
    output reg                  valid_out
);

//============================================================
// Pipeline Register
//============================================================

always @(posedge clk)
begin

    //--------------------------------------------------------
    // Reset
    //--------------------------------------------------------

    if(rst)
    begin

        pc_out           <= {ADDR_WIDTH{1'b0}};
        pc_plus_one_out  <= {ADDR_WIDTH{1'b0}};
        instruction_out  <= {DATA_WIDTH{1'b0}};
        valid_out        <= 1'b0;

    end

    //--------------------------------------------------------
    // Flush Pipeline
    //--------------------------------------------------------

    else if(flush)
    begin

        pc_out           <= {ADDR_WIDTH{1'b0}};
        pc_plus_one_out  <= {ADDR_WIDTH{1'b0}};
        instruction_out  <= {DATA_WIDTH{1'b0}};
        valid_out        <= 1'b0;

    end

    //--------------------------------------------------------
    // Stall Pipeline
    //--------------------------------------------------------

    else if(stall)
    begin

        // Hold Current Values

        pc_out          <= pc_out;
        pc_plus_one_out <= pc_plus_one_out;
        instruction_out <= instruction_out;
        valid_out       <= valid_out;

    end

    //--------------------------------------------------------
    // Normal Operation
    //--------------------------------------------------------

    else if(enable)
    begin

        pc_out          <= pc_in;
        pc_plus_one_out <= pc_plus_one_in;
        instruction_out <= instruction_in;
        valid_out       <= valid_in;

    end

end

endmodule