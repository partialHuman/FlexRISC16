`default_nettype none
module alu_operand_mux
#(
    parameter WIDTH = 16
)
(
    input  wire             sel,
    input  wire [WIDTH-1:0] reg_data,
    input  wire [WIDTH-1:0] immediate,
    output wire [WIDTH-1:0] operand_b
);

assign operand_b = sel ? immediate : reg_data;

endmodule
`default_nettype wire
