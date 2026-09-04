`timescale 1ns / 1ps
`default_nettype none

//============================================================
// Project : FlexRISC16
// Module  : Register File
//============================================================

module register_file
#(
    parameter DATA_WIDTH = 16,
    parameter REG_COUNT  = 16,
    parameter ADDR_WIDTH = 4,

    // Set to 1 to make R0 constant zero
    parameter HARDWIRE_R0 = 1
)
(
    input  wire                     clk,
    input  wire                     rst,

    //--------------------------------------------------------
    // Write Port
    //--------------------------------------------------------

    input  wire                     we,
    input  wire [ADDR_WIDTH-1:0]    wr_addr,
    input  wire [DATA_WIDTH-1:0]    wr_data,

    //--------------------------------------------------------
    // Read Port 1
    //--------------------------------------------------------

    input  wire [ADDR_WIDTH-1:0]    rd_addr1,
    output wire [DATA_WIDTH-1:0]    rd_data1,

    //--------------------------------------------------------
    // Read Port 2
    //--------------------------------------------------------

    input  wire [ADDR_WIDTH-1:0]    rd_addr2,
    output wire [DATA_WIDTH-1:0]    rd_data2
);

//============================================================
// Register Array
//============================================================

reg [DATA_WIDTH-1:0] regfile [0:REG_COUNT-1];

integer i;

//============================================================
// Reset / Write Logic
//============================================================

always @(posedge clk)
begin

    if(rst)
    begin
        for(i=0;i<REG_COUNT;i=i+1)
            regfile[i] <= {DATA_WIDTH{1'b0}};
    end

    else if(we)
    begin
        //--------------------------------------------
        // Optional R0 Protection
        //--------------------------------------------
        if(HARDWIRE_R0 && (wr_addr == 0))
        begin
            // Ignore writes to R0
        end
        else
        begin
            regfile[wr_addr] <= wr_data;
        end

    end

end

//============================================================
// Read Port 1 (with same-cycle write-through)
//============================================================
// Without this, a register written back on cycle N (synchronous
// write) is invisible to a decode reading it combinationally on
// that same cycle N - the read would see the pre-write value one
// cycle too late. This never mattered for the single-cycle FSM
// design (its DECODE and WRITEBACK stages belong to different
// instructions that never overlap on the same cycle), but a
// pipelined datapath routinely has one instruction's WB land on
// the same cycle as a later instruction's ID.

assign rd_data1 =
        (HARDWIRE_R0 && (rd_addr1 == 0)) ?
        {DATA_WIDTH{1'b0}} :
        (we && (wr_addr == rd_addr1) && !(HARDWIRE_R0 && (wr_addr == 0))) ?
        wr_data :
        regfile[rd_addr1];

//============================================================
// Read Port 2 (with same-cycle write-through)
//============================================================

assign rd_data2 =
        (HARDWIRE_R0 && (rd_addr2 == 0)) ?
        {DATA_WIDTH{1'b0}} :
        (we && (wr_addr == rd_addr2) && !(HARDWIRE_R0 && (wr_addr == 0))) ?
        wr_data :
        regfile[rd_addr2];

//============================================================
// Simulation Tasks
//============================================================

`ifndef SYNTHESIS

task dump_registers;

integer j;

begin

    $display("");
    $display("========================================");
    $display("Register File");
    $display("========================================");

    for(j=0;j<REG_COUNT;j=j+1)
        $display("R%0d = %h", j, regfile[j]);

    $display("========================================");

end

endtask

`endif

endmodule
`default_nettype wire
