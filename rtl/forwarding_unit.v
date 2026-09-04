`timescale 1ns / 1ps

//============================================================
// Project : FlexRISC16 Pipeline
// Module  : Forwarding Unit
//============================================================

module forwarding_unit
(
    //--------------------------------------------------------
    // ID/EX Source Registers
    //--------------------------------------------------------

    input wire [3:0] id_ex_rs1,
    input wire [3:0] id_ex_rs2,

    //--------------------------------------------------------
    // EX/MEM Stage
    //--------------------------------------------------------

    input wire ex_mem_reg_write,
    input wire [3:0] ex_mem_rd,

    //--------------------------------------------------------
    // MEM/WB Stage
    //--------------------------------------------------------

    input wire mem_wb_reg_write,
    input wire [3:0] mem_wb_rd,

    //--------------------------------------------------------
    // Outputs
    //--------------------------------------------------------

    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);

//============================================================
// Forwarding Logic
//============================================================

always @(*)
begin

    //--------------------------------------------------------
    // Defaults
    //--------------------------------------------------------

    forward_a = 2'b00;
    forward_b = 2'b00;

    //--------------------------------------------------------
    // EX Hazard
    //--------------------------------------------------------

    if(ex_mem_reg_write &&
       (ex_mem_rd != 4'd0) &&
       (ex_mem_rd == id_ex_rs1))
    begin
        forward_a = 2'b10;
    end

    if(ex_mem_reg_write &&
       (ex_mem_rd != 4'd0) &&
       (ex_mem_rd == id_ex_rs2))
    begin
        forward_b = 2'b10;
    end

    //--------------------------------------------------------
    // MEM Hazard
    //--------------------------------------------------------

    if(mem_wb_reg_write &&
       (mem_wb_rd != 4'd0) &&
       !(ex_mem_reg_write &&
         (ex_mem_rd != 4'd0) &&
         (ex_mem_rd == id_ex_rs1)) &&
       (mem_wb_rd == id_ex_rs1))
    begin
        forward_a = 2'b01;
    end

    if(mem_wb_reg_write &&
       (mem_wb_rd != 4'd0) &&
       !(ex_mem_reg_write &&
         (ex_mem_rd != 4'd0) &&
         (ex_mem_rd == id_ex_rs2)) &&
       (mem_wb_rd == id_ex_rs2))
    begin
        forward_b = 2'b01;
    end

end

endmodule