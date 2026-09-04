`timescale 1ns / 1ps

//============================================================
// Project : FlexRISC16 Pipeline
// Module  : Forwarding Multiplexer
//============================================================

module forwarding_mux
#(
    parameter WIDTH = 16
)
(
    input wire [1:0] sel,

    input wire [WIDTH-1:0] reg_data,
    input wire [WIDTH-1:0] ex_mem_data,
    input wire [WIDTH-1:0] mem_wb_data,

    output reg [WIDTH-1:0] data_out
);

always @(*)
begin

    case(sel)

        2'b00:
            data_out = reg_data;

        2'b01:
            data_out = mem_wb_data;

        2'b10:
            data_out = ex_mem_data;

        default:
            data_out = reg_data;

    endcase

end

endmodule