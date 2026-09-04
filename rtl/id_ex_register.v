`timescale 1ns / 1ps

//============================================================
// Project : FlexRISC16 Pipeline
// Module  : ID/EX Pipeline Register
//============================================================

module id_ex_register
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
    input wire [ADDR_WIDTH-1:0] pc_plus_one_in,

    input wire [DATA_WIDTH-1:0] instruction_in,

    input wire [DATA_WIDTH-1:0] rs1_data_in,
    input wire [DATA_WIDTH-1:0] rs2_data_in,

    input wire [DATA_WIDTH-1:0] immediate_in,

    input wire [3:0] rd_in,
    input wire [3:0] rs2_num_in,

    //--------------------------------------------------------
    // Control Inputs
    //--------------------------------------------------------

    input wire [3:0] alu_func_in,

    input wire alu_src_in,

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
    output reg [ADDR_WIDTH-1:0] pc_plus_one_out,

    output reg [DATA_WIDTH-1:0] instruction_out,

    output reg [DATA_WIDTH-1:0] rs1_data_out,
    output reg [DATA_WIDTH-1:0] rs2_data_out,

    output reg [DATA_WIDTH-1:0] immediate_out,

    output reg [3:0] rd_out,
    output reg [3:0] rs2_num_out,

    //--------------------------------------------------------
    // Control Outputs
    //--------------------------------------------------------

    output reg [3:0] alu_func_out,

    output reg alu_src_out,

    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg branch_out,
    output reg flag_write_out,

    output reg [2:0] wb_sel_out,

    output reg valid_out
);

always @(posedge clk)
begin

    //--------------------------------------------------------
    // Reset / Flush
    //--------------------------------------------------------

    if(rst || flush)
    begin

        pc_out           <= 16'd0;
        pc_plus_one_out  <= 16'd0;
        instruction_out  <= 16'd0;

        rs1_data_out     <= 16'd0;
        rs2_data_out     <= 16'd0;
        immediate_out    <= 16'd0;

        rd_out           <= 4'd0;
        rs2_num_out      <= 4'd0;

        alu_func_out     <= 4'd0;

        alu_src_out      <= 1'b0;

        reg_write_out    <= 1'b0;
        mem_read_out     <= 1'b0;
        mem_write_out    <= 1'b0;
        branch_out       <= 1'b0;
        flag_write_out   <= 1'b0;

        wb_sel_out       <= 3'd0;

        valid_out        <= 1'b0;

    end

    //--------------------------------------------------------
    // Stall
    //--------------------------------------------------------

    else if(stall)
    begin
        // Hold current values
    end

    //--------------------------------------------------------
    // Normal Operation
    //--------------------------------------------------------

    else if(enable)
    begin

        pc_out          <= pc_in;
        pc_plus_one_out <= pc_plus_one_in;

        instruction_out <= instruction_in;

        rs1_data_out    <= rs1_data_in;
        rs2_data_out    <= rs2_data_in;

        immediate_out   <= immediate_in;

        rd_out          <= rd_in;
        rs2_num_out     <= rs2_num_in;

        alu_func_out    <= alu_func_in;

        alu_src_out     <= alu_src_in;

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