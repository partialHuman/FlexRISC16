`timescale 1ns / 1ps

//============================================================
// Project : FlexRISC16 Pipeline
// Module  : MEM/WB Pipeline Register
//============================================================

module mem_wb_register
#(
    parameter DATA_WIDTH = 16
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
    // Datapath Inputs
    //--------------------------------------------------------

    input wire [DATA_WIDTH-1:0] alu_result_in,
    input wire [DATA_WIDTH-1:0] memory_data_in,

    input wire [3:0] rd_in,

    //--------------------------------------------------------
    // Control Inputs
    //--------------------------------------------------------

    input wire reg_write_in,

    input wire [2:0] wb_sel_in,

    input wire valid_in,

    //--------------------------------------------------------
    // Datapath Outputs
    //--------------------------------------------------------

    output reg [DATA_WIDTH-1:0] alu_result_out,
    output reg [DATA_WIDTH-1:0] memory_data_out,

    output reg [3:0] rd_out,

    //--------------------------------------------------------
    // Control Outputs
    //--------------------------------------------------------

    output reg reg_write_out,

    output reg [2:0] wb_sel_out,

    output reg valid_out

);

//============================================================
// Pipeline Register
//============================================================

always @(posedge clk)
begin

    //--------------------------------------------------------
    // Reset / Flush
    //--------------------------------------------------------

    if(rst || flush)
    begin

        alu_result_out <= 16'd0;
        memory_data_out <= 16'd0;

        rd_out <= 4'd0;

        reg_write_out <= 1'b0;

        wb_sel_out <= 3'd0;

        valid_out <= 1'b0;

    end

    //--------------------------------------------------------
    // Stall
    //--------------------------------------------------------

    else if(stall)
    begin
        // Hold Current Values
    end

    //--------------------------------------------------------
    // Normal Operation
    //--------------------------------------------------------

    else if(enable)
    begin

        alu_result_out <= alu_result_in;
        memory_data_out <= memory_data_in;

        rd_out <= rd_in;

        reg_write_out <= reg_write_in;

        wb_sel_out <= wb_sel_in;

        valid_out <= valid_in;

    end

end

endmodule