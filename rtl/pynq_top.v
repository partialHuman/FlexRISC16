`timescale 1ns / 1ps
`default_nettype none

//============================================================
// Project : FlexRISC16 Pipeline
// Module  : PYNQ Top (with clock divider)
//============================================================
//
// This is now the actual Vivado synth top for the hardware build
// - set it as top the same way fpga_top was set as top before.
// fpga_top.v itself is unchanged; it still just takes whatever
// clock it's given.
//
// Why this exists: at the full 125 MHz board clock, the design's
// tightest path (forwarding -> ALU -> flag detect -> flag latch,
// all in one cycle) has repeatedly come in right at the edge of
// meeting timing, and finally failed outright (-0.584ns) once a
// fuller test program left more of that logic live for synthesis
// to actually time. Running the CPU core at 62.5 MHz instead
// doubles the available time per path, which comfortably absorbs
// this class of violation regardless of which program is loaded -
// a permanent fix rather than another specific-net trim.
//
// The XDC does NOT need to change: the physical 125 MHz input
// clock constraint on the `clk` pin still applies to this
// module's `clk` port exactly as before. The Clocking Wizard IP
// carries its own internal timing relationship between clk_in1
// and clk_out1 automatically - no hand-written create_clock is
// needed for the derived 62.5 MHz domain.
//
// NOTE: clk_wiz_0 is a Xilinx-generated IP (MMCM underneath) and
// can't be simulated with Icarus Verilog - it has no open-source
// model. Everything downstream of clk_out1 (fpga_top and
// everything inside it) has already been verified in simulation;
// only this wrapper's connectivity has been sanity-checked here
// (structural elaboration against a behavioral stand-in), not the
// MMCM's actual timing behavior - that only Vivado can confirm.

module pynq_top
(
    input  wire        clk,      // 125 MHz board clock (H16)
    input  wire        rst,      // btn[0], active-high
    input  wire [1:0]  sw,
    output wire [3:0]  led
);

wire clk_cpu;
wire locked;

//------------------------------------------------------------
// Clocking Wizard IP (clk_in1=125MHz -> clk_out1=62.5MHz)
//------------------------------------------------------------
// Standard Clocking Wizard 6.0 instantiation template with
// default port renaming (reset in, locked+clk_out1 out). If your
// generated clk_wiz_0.veo shows different port names (only
// happens if the Port Renaming tab was touched), match those
// instead - the .veo file in
// <project>.srcs/sources_1/ip/clk_wiz_0/ has the exact template
// Vivado generated for your IP instance.

clk_wiz_0 CLK_GEN
(
    .clk_in1(clk),
    .reset(rst),
    .clk_out1(clk_cpu),
    .locked(locked)
);

//------------------------------------------------------------
// Hold the CPU in reset until the MMCM has locked, in addition
// to the board's own reset button - standard practice so the
// core never sees a not-yet-stable clock.
//------------------------------------------------------------

wire cpu_rst = rst | ~locked;

//------------------------------------------------------------
// CPU + board I/O (unchanged from before)
//------------------------------------------------------------

fpga_top CPU_TOP
(
    .clk(clk_cpu),
    .rst(cpu_rst),
    .sw(sw),
    .led(led)
);

endmodule
`default_nettype wire