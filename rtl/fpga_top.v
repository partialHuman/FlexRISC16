`timescale 1ns / 1ps
`default_nettype none

//============================================================
// Project : FlexRISC16 Pipeline
// Module  : FPGA Top (PYNQ-Z2)
//============================================================
//
// pipeline_processor_top exposes ~274 bits of debug/performance-
// counter outputs, which is fine for simulation but is 274 pins
// against a package that only has 125 available (see the
// utilization report: Bonded IOB 274/125, 219% - implementation
// would fail to place this many pins). This wrapper is the actual
// synthesis top for a real board build: it instantiates the CPU
// internally and exposes only a handful of real pins.
//
// Use this as the Vivado synth `-top` for a hardware build; keep
// pipeline_processor_top as the top for simulation/tb_pipeline_
// selfcheck.v - the two are not the same target.
//
// Interface (PYNQ-Z2 base board has only 2 switches, 4 LEDs on
// its own header - see the XDC):
//   clk   - 125 MHz board clock (H16)
//   rst   - btn[0], active-high reset
//   sw[1:0] - selects which 4-bit nibble of the *last real
//             register write* is shown on led[3:0]
//             (0=bits[3:0] ... 3=bits[15:12])
//   led[3:0] - the selected nibble. Updates the instant any
//              instruction writes a register other than R0, and
//              holds that value once the program finishes and
//              falls into NOP padding (see the note below the
//              CPU instance for why NOP itself doesn't disturb
//              the display).

module fpga_top
(
    input  wire        clk,
    input  wire        rst,
    input  wire [1:0]  sw,
    output wire [3:0]  led
);

//------------------------------------------------------------
// CPU core
//------------------------------------------------------------

wire [15:0] debug_pc;
wire [15:0] debug_instruction;
wire [15:0] debug_alu_result;
wire [15:0] debug_memory_data;
wire [15:0] debug_writeback;
wire        debug_reg_write;
wire [3:0]  debug_rd;

wire [31:0] cycle_count;
wire [31:0] instruction_count;
wire [31:0] stall_count;
wire [31:0] branch_count;
wire [31:0] branch_taken_count;
wire [31:0] forwarding_count;

pipeline_processor_top CPU
(
    .clk(clk),
    .rst(rst),

    .debug_pc(debug_pc),
    .debug_instruction(debug_instruction),
    .debug_alu_result(debug_alu_result),
    .debug_memory_data(debug_memory_data),
    .debug_writeback(debug_writeback),
    .debug_reg_write(debug_reg_write),
    .debug_rd(debug_rd),

    .cycle_count(cycle_count),
    .instruction_count(instruction_count),
    .stall_count(stall_count),
    .branch_count(branch_count),
    .branch_taken_count(branch_taken_count),
    .forwarding_count(forwarding_count)
);

//------------------------------------------------------------
// Result latch
//------------------------------------------------------------
// The CPU free-runs continuously with no halt - once your
// program finishes, it keeps fetching NOP padding (or, past the
// end of instruction memory, undefined content), and NOP retires
// with reg_write=1 targeting R0 every single cycle (harmless
// architecturally - R0 is hardwired zero and the write is
// ignored - but debug_writeback itself doesn't know that). A
// periodic sampler would almost certainly land on one of those
// R0-targeted NOP cycles rather than your actual result, since
// the real result only exists for a few nanoseconds before NOPs
// take over. Latching only on a real write to a register other
// than R0 fixes this: the display updates the instant something
// meaningful happens, then holds that value forever once the
// program falls into NOP padding, since NOP's writes all target
// R0 and are excluded here.

reg [15:0] latched_writeback;

always @(posedge clk)
begin
    if (rst)
        latched_writeback <= 16'd0;
    else if (debug_reg_write && (debug_rd != 4'd0))
        latched_writeback <= debug_writeback;
end

//------------------------------------------------------------
// Nibble select
//------------------------------------------------------------

assign led = latched_writeback[sw*4 +: 4];

endmodule
`default_nettype wire