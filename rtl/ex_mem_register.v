`timescale 1ns / 1ps

//============================================================
// Project : FlexRISC16 Pipeline
// Module  : EX/MEM Pipeline Register
//============================================================

module ex_mem_register
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
    // Datapath Inputs
    //--------------------------------------------------------

    input wire [ADDR_WIDTH-1:0] pc_in,

    input wire [DATA_WIDTH-1:0] alu_result_in,

    input wire [DATA_WIDTH-1:0] store_data_in,

    input wire [3:0] rd_in,

    //--------------------------------------------------------
    // Flags
    //--------------------------------------------------------

    input wire carry_in,
    input wire zero_in,
    input wire negative_in,
    input wire overflow_in,

    //--------------------------------------------------------
    // Control Inputs
    //--------------------------------------------------------

    input wire reg_write_in,
    input wire mem_read_in,
    input wire mem_write_in,
    input wire branch_in,
    input wire flag_write_in,

    input wire [2:0] wb_sel_in,

    input wire valid_in,

    //--------------------------------------------------------
    // Datapath Outputs
    //--------------------------------------------------------

    output reg [ADDR_WIDTH-1:0] pc_out,

    output reg [DATA_WIDTH-1:0] alu_result_out,

    output reg [DATA_WIDTH-1:0] store_data_out,

    output reg [3:0] rd_out,

    //--------------------------------------------------------
    // Flag Outputs
    //--------------------------------------------------------

    output reg carry_out,
    output reg zero_out,
    output reg negative_out,
    output reg overflow_out,

    //--------------------------------------------------------
    // Control Outputs
    //--------------------------------------------------------

    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg branch_out,
    output reg flag_write_out,

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

        pc_out          <= 16'd0;

        alu_result_out  <= 16'd0;
        store_data_out  <= 16'd0;

        rd_out          <= 4'd0;

        carry_out       <= 1'b0;
        zero_out        <= 1'b0;
        negative_out    <= 1'b0;
        overflow_out    <= 1'b0;

        reg_write_out   <= 1'b0;
        mem_read_out    <= 1'b0;
        mem_write_out   <= 1'b0;
        branch_out      <= 1'b0;
        flag_write_out  <= 1'b0;

        wb_sel_out      <= 3'd0;

        valid_out       <= 1'b0;

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

        pc_out          <= pc_in;

        alu_result_out  <= alu_result_in;
        store_data_out  <= store_data_in;

        rd_out          <= rd_in;

        carry_out       <= carry_in;
        zero_out        <= zero_in;
        negative_out    <= negative_in;
        overflow_out    <= overflow_in;

        reg_write_out   <= reg_write_in;
        mem_read_out    <= mem_read_in;
        mem_write_out   <= mem_write_in;
        branch_out      <= branch_in;
        flag_write_out  <= flag_write_in;

        wb_sel_out      <= wb_sel_in;

        valid_out       <= valid_in;

    end

end

endmodule