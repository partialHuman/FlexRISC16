`timescale 1ns / 1ps
`default_nettype none

//============================================================
// Project : FlexRISC16 Pipeline
// Module  : Performance Counter
//============================================================
//
// Referenced by pipeline_processor_top.v but not included in the
// original upload - implemented here to match that instantiation.

module performance_counter
(
    input wire clk,
    input wire rst,

    input wire instruction_retired,
    input wire stall,
    input wire branch,
    input wire branch_taken,
    input wire forwarding,

    output reg [31:0] cycle_count,
    output reg [31:0] instruction_count,
    output reg [31:0] stall_count,
    output reg [31:0] branch_count,
    output reg [31:0] branch_taken_count,
    output reg [31:0] forwarding_count
);

always @(posedge clk)
begin
    if(rst)
    begin
        cycle_count         <= 32'd0;
        instruction_count   <= 32'd0;
        stall_count         <= 32'd0;
        branch_count        <= 32'd0;
        branch_taken_count  <= 32'd0;
        forwarding_count    <= 32'd0;
    end
    else
    begin
        cycle_count <= cycle_count + 32'd1;

        if(instruction_retired)
            instruction_count <= instruction_count + 32'd1;

        if(stall)
            stall_count <= stall_count + 32'd1;

        if(branch)
            branch_count <= branch_count + 32'd1;

        if(branch_taken)
            branch_taken_count <= branch_taken_count + 32'd1;

        if(forwarding)
            forwarding_count <= forwarding_count + 32'd1;
    end
end

endmodule
`default_nettype wire
