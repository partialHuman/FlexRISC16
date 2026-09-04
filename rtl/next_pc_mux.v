`timescale 1ns / 1ps

module next_pc_mux
#(
    parameter PC_WIDTH = 16
)
(
    input  wire                    pc_load,
    input  wire [PC_WIDTH-1:0]     pc_plus_one,
    input  wire [PC_WIDTH-1:0]     branch_target,
    output wire [PC_WIDTH-1:0]     next_pc
);

assign next_pc =
        pc_load ?
        branch_target :
        pc_plus_one;

endmodule