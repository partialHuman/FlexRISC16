`timescale 1ns / 1ps
`default_nettype none

//============================================================
// Project : FlexRISC16
// Module  : Data Memory
//============================================================

module data_memory
#(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16,
    parameter MEM_DEPTH  = 256,
    parameter MEM_FILE   = ""
)
(
    //--------------------------------------------------------
    // Inputs
    //--------------------------------------------------------

    input wire clk,

    input wire read_enable,
    input wire write_enable,

    input wire [ADDR_WIDTH-1:0] address,

    input wire [DATA_WIDTH-1:0] write_data,

    //--------------------------------------------------------
    // Output
    //--------------------------------------------------------

    output reg [DATA_WIDTH-1:0] read_data
);

//============================================================
// Memory Array
//============================================================

reg [DATA_WIDTH-1:0] memory [0:MEM_DEPTH-1];

integer i;

//============================================================
// Initialization
//============================================================

initial
begin

    //------------------------------------
    // Clear Memory
    //------------------------------------

    for(i=0;i<MEM_DEPTH;i=i+1)
        memory[i] = {DATA_WIDTH{1'b0}};

    //------------------------------------
    // Optional Memory File
    //------------------------------------

    if(MEM_FILE != "")
        $readmemh(MEM_FILE, memory);

end

//============================================================
// Write Logic
//============================================================

always @(posedge clk)
begin

    if(write_enable)
    begin

        if(address < MEM_DEPTH)
            memory[address] <= write_data;

    end

end

//============================================================
// Read Logic
//============================================================

always @(*)
begin

    if(read_enable)
    begin

        if(address < MEM_DEPTH)
            read_data = memory[address];

        else
            read_data = {DATA_WIDTH{1'b0}};

    end

    else
    begin

        read_data = {DATA_WIDTH{1'b0}};

    end

end

endmodule
`default_nettype wire
