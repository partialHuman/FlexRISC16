`timescale 1ns / 1ps
`default_nettype none

//============================================================
// Project : FlexRISC16
// Module  : Instruction Memory
//============================================================

module instruction_memory
#(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16,
    parameter MEM_DEPTH  = 256,
    parameter MEM_FILE = "program.mem"
)
(
    input  wire [ADDR_WIDTH-1:0] address,
    output reg instruction_valid,
    output reg  [DATA_WIDTH-1:0] instruction
);

//------------------------------------------------------------
// Memory Array
//------------------------------------------------------------

reg [DATA_WIDTH-1:0] memory [0:MEM_DEPTH-1];

//------------------------------------------------------------
// Memory Initialization
//------------------------------------------------------------

initial
begin
    if(MEM_FILE != "")
        $readmemh(MEM_FILE, memory);

end

//------------------------------------------------------------
// Asynchronous Read
//------------------------------------------------------------

always @(*) begin

    if(address < MEM_DEPTH)
    begin
        instruction = memory[address];
        instruction_valid = 1'b1;
    end
    else
    begin
        instruction = {DATA_WIDTH{1'b0}};
        instruction_valid = 1'b0;
    end

end

endmodule
`default_nettype wire
