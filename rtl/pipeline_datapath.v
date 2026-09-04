`timescale 1ns / 1ps
`include "cpu_constants.vh"
`default_nettype none

//============================================================
// Project : FlexRISC16
// Module  : Pipeline Datapath
//============================================================

module pipeline_datapath
(
    input  wire clk,
    input  wire rst,

    //--------------------------------------------------------
    // Debug Outputs
    //--------------------------------------------------------

    output wire [`ADDR_WIDTH-1:0] debug_pc,
    output wire [`DATA_WIDTH-1:0] debug_instruction,
    output wire [`DATA_WIDTH-1:0] debug_alu_result,
    output wire [`DATA_WIDTH-1:0] debug_memory_data,
    output wire [`DATA_WIDTH-1:0] debug_writeback,
    output wire debug_reg_write,
    output wire [3:0] debug_rd,

    //--------------------------------------------------------
    // Performance Counters
    //--------------------------------------------------------

    output wire [31:0] cycle_count,
    output wire [31:0] instruction_count,
    output wire [31:0] stall_count,
    output wire [31:0] branch_count,
    output wire [31:0] branch_taken_count,
    output wire [31:0] forwarding_count
);


//============================================================
// IF STAGE SIGNALS
//============================================================

wire [`ADDR_WIDTH-1:0] pc;
wire [`ADDR_WIDTH-1:0] pc_plus_one;

wire [`DATA_WIDTH-1:0] instruction;
wire instruction_valid;


//============================================================
// IF/ID PIPELINE SIGNALS
//============================================================

wire [`ADDR_WIDTH-1:0] if_id_pc;
wire [`ADDR_WIDTH-1:0] if_id_pc_plus_one;

wire [`DATA_WIDTH-1:0] if_id_instruction;
wire if_id_valid;


//============================================================
// Branch Signals
//============================================================

wire branch_taken;
wire [`ADDR_WIDTH-1:0] branch_target;


//============================================================
// Hazard Signals
//============================================================

wire stall_pc;
wire stall_if_id;
wire flush_id_ex;

wire pc_enable;
wire if_id_enable;
wire if_id_flush;

wire id_ex_enable;
wire id_ex_flush;


//============================================================
// Program Counter
//============================================================

program_counter PC
(
    .clk(clk),
    .rst(rst),
    .pc_enable(pc_enable),
    .stall(1'b0),
    .pc_load(branch_taken),
    .pc_next(branch_target),
    .pc(pc)
);


//============================================================
// PC + 1
//============================================================

assign pc_plus_one = pc + 16'd1;


//============================================================
// Instruction Memory
//============================================================

instruction_memory IMEM
(
    .address(pc),
    .instruction(instruction),
    .instruction_valid(instruction_valid)
);


//============================================================
// IF / ID Register
//============================================================

if_id_register IF_ID
(
    .clk(clk),
    .rst(rst),
    .enable(if_id_enable),
    .stall(stall_if_id),
    .flush(if_id_flush),
    .pc_in(pc),
    .pc_plus_one_in(pc_plus_one),
    .instruction_in(instruction),
    .valid_in(instruction_valid),
    .pc_out(if_id_pc),
    .pc_plus_one_out(if_id_pc_plus_one),
    .instruction_out(if_id_instruction),
    .valid_out(if_id_valid)
);

//============================================================
// ID STAGE SIGNALS
//============================================================

//------------------------------------------------------------
// Decoder Outputs
//------------------------------------------------------------

wire [3:0] opcode;

wire [3:0] rd;
wire [3:0] rs1;
wire [3:0] rs2;

wire [1:0] instr_class;

wire [3:0] alu_func;

wire is_load;
wire is_store;
wire is_branch;
wire is_immediate;

wire alu_src;

//------------------------------------------------------------
// STORE data-register fix
//------------------------------------------------------------
// rs2 (instruction[3:0]) doubles as the 4-bit address offset for
// LOAD/STORE, which collides with the store-data register select.
// STORE reads its data register out of the rd field instead (rd
// is otherwise unused on STORE, since reg_write is de-asserted).
wire [3:0] reg_rd_addr2;
assign reg_rd_addr2 = is_store ? rd : rs2;

//------------------------------------------------------------
// Flag write: only ALU-class instructions update the status
// register (matches the original single-cycle CTRL_FLAG_WR).
// NOP falls into the decoder's default case as CLASS_ALU (there's
// no dedicated NOP class), so without excluding ALU_NOP here, a
// NOP sitting between a CMP and a dependent branch would silently
// overwrite the flags with whatever ALU_NOP's default (result=0,
// zero=1) produces.
//------------------------------------------------------------
wire flag_write_id;
assign flag_write_id = (instr_class == `CLASS_ALU) && (alu_func != `ALU_NOP);

//------------------------------------------------------------
// Immediate Generator
//------------------------------------------------------------

wire [`DATA_WIDTH-1:0] immediate;

//------------------------------------------------------------
// Register File
//------------------------------------------------------------

wire [`DATA_WIDTH-1:0] rs1_data;
wire [`DATA_WIDTH-1:0] rs2_data;

//------------------------------------------------------------
// ALU Control
//------------------------------------------------------------

wire [3:0] alu_operation;


//============================================================
// Instruction Decoder
//============================================================

instruction_decoder DECODER
(
    .instruction(if_id_instruction),
    .opcode(opcode),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .instr_class(instr_class),
    .alu_func(alu_func),
    .is_load(is_load),
    .is_store(is_store),
    .is_branch(is_branch),
    .is_immediate(is_immediate),
    .alu_src(alu_src)
);


//============================================================
// Immediate Generator
//============================================================

immediate_generator IMM_GEN
(
    .instruction(if_id_instruction),
    .instr_class(instr_class),
    .immediate(immediate)
);


//============================================================
// Register File
//============================================================

wire reg_write_wb;
wire [3:0] rd_wb;
wire [`DATA_WIDTH-1:0] writeback_data;

register_file REGFILE
(
    .clk(clk),
    .rst(rst),
    .we(reg_write_wb),
    .wr_addr(rd_wb),
    .wr_data(writeback_data),
    .rd_addr1(rs1),
    .rd_data1(rs1_data),
    .rd_addr2(reg_rd_addr2),
    .rd_data2(rs2_data)
);


//============================================================
// ALU Control
//============================================================

alu_control ALU_CTRL
(
    .alu_enable(1'b1),
    .instr_class(instr_class),
    .alu_func(alu_func),
    .alu_operation(alu_operation)
);

//============================================================
// Hazard Detection
//============================================================

hazard_detection_unit HAZARD
(
    .if_id_rs1(rs1),
    .if_id_rs2(reg_rd_addr2),

    .id_ex_mem_read(id_ex_mem_read),
    .id_ex_rd(id_ex_rd),

    .stall_pc(stall_pc),
    .stall_if_id(stall_if_id),
    .flush_id_ex(flush_id_ex)
);


//============================================================
// Pipeline Control
//============================================================

pipeline_control PIPE_CTRL
(
    .branch_taken(branch_taken),

    .stall_pc(stall_pc),
    .stall_if_id(stall_if_id),
    .flush_id_ex(flush_id_ex),

    .pc_enable(pc_enable),

    .if_id_enable(if_id_enable),
    .if_id_flush(if_id_flush),

    .id_ex_enable(id_ex_enable),
    .id_ex_flush(id_ex_flush)
);


//============================================================
// ID/EX Signals
//============================================================

wire [`ADDR_WIDTH-1:0] id_ex_pc;
wire [`ADDR_WIDTH-1:0] id_ex_pc_plus_one;

wire [`DATA_WIDTH-1:0] id_ex_instruction;

wire [`DATA_WIDTH-1:0] id_ex_rs1_data;
wire [`DATA_WIDTH-1:0] id_ex_rs2_data;

wire [`DATA_WIDTH-1:0] id_ex_immediate;

wire [3:0] id_ex_rd;
wire [3:0] id_ex_rs2_num;

wire [3:0] id_ex_alu_func;

wire id_ex_alu_src;

wire id_ex_reg_write;
wire id_ex_mem_read;
wire id_ex_mem_write;
wire id_ex_branch;
wire id_ex_flag_write;
wire id_ex_valid;

wire [2:0] id_ex_wb_sel;


//============================================================
// ID/EX Pipeline Register
//============================================================

id_ex_register ID_EX
(
    .clk(clk),
    .rst(rst),

    .enable(id_ex_enable),
    .stall(1'b0),
    .flush(id_ex_flush),
    .pc_in(if_id_pc),
    .pc_plus_one_in(if_id_pc_plus_one),
    .instruction_in(if_id_instruction),
    .rs1_data_in(rs1_data),
    .rs2_data_in(rs2_data),
    .immediate_in(immediate),
    .rd_in(rd),
    .rs2_num_in(reg_rd_addr2),
    .alu_func_in(alu_operation),
    .alu_src_in(alu_src),
    .reg_write_in((~is_store & ~is_branch) & if_id_valid),
    .mem_read_in(is_load & if_id_valid),
    .mem_write_in(is_store & if_id_valid),
    .branch_in(is_branch),
    .flag_write_in(flag_write_id),
    .wb_sel_in
    (
        is_load ?
        `WB_MEMORY :
        `WB_ALU
    ),
    .valid_in(if_id_valid),

    //--------------------------------------------------------
    // Outputs
    //--------------------------------------------------------

    .pc_out(id_ex_pc),
    .pc_plus_one_out(id_ex_pc_plus_one),
    .instruction_out(id_ex_instruction),
    .rs1_data_out(id_ex_rs1_data),
    .rs2_data_out(id_ex_rs2_data),
    .immediate_out(id_ex_immediate),
    .rd_out(id_ex_rd),
    .rs2_num_out(id_ex_rs2_num),
    .alu_func_out(id_ex_alu_func),
    .alu_src_out(id_ex_alu_src),
    .reg_write_out(id_ex_reg_write),
    .mem_read_out(id_ex_mem_read),
    .mem_write_out(id_ex_mem_write),
    .branch_out(id_ex_branch),
    .flag_write_out(id_ex_flag_write),
    .wb_sel_out(id_ex_wb_sel),
    .valid_out(id_ex_valid)
);

//============================================================
// EX STAGE SIGNALS
//============================================================

//------------------------------------------------------------
// Forwarding
//------------------------------------------------------------

wire [1:0] forward_a;
wire [1:0] forward_b;

wire [`DATA_WIDTH-1:0] forwarded_rs1;
wire [`DATA_WIDTH-1:0] forwarded_rs2;

//------------------------------------------------------------
// ALU Operand
//------------------------------------------------------------

wire [`DATA_WIDTH-1:0] alu_operand_b;

//------------------------------------------------------------
// ALU Outputs
//------------------------------------------------------------

wire [`DATA_WIDTH-1:0] alu_result;

wire carry_flag;
wire zero_flag;
wire negative_flag;
wire overflow_flag;


//============================================================
// Forwarding Unit
//============================================================

forwarding_unit FORWARD
(
    .id_ex_rs1(id_ex_instruction[7:4]),
    // Registered in ID (see reg_rd_addr2 above) instead of being
    // re-derived combinationally here from id_ex_mem_write - that
    // mux sat at the front of the forward -> ALU -> flags ->
    // status-register path and was the cause of a -0.081ns setup
    // violation at 125MHz (Vivado: CPU/PIPELINE/ID_EX/mem_write_
    // out_reg/C -> CPU/PIPELINE/STATUS/zero_out_reg/D, 11 logic
    // levels). Same value, computed one cycle earlier instead.
    .id_ex_rs2(id_ex_rs2_num),

    .ex_mem_reg_write(ex_mem_reg_write),
    .ex_mem_rd(ex_mem_rd),

    .mem_wb_reg_write(mem_wb_reg_write),
    .mem_wb_rd(mem_wb_rd),

    .forward_a(forward_a),
    .forward_b(forward_b)
);


//============================================================
// Forwarding MUX A
//============================================================

forwarding_mux
#(
    .WIDTH(`DATA_WIDTH)
)
FWD_A
(
    .sel(forward_a),
    .reg_data(id_ex_rs1_data),
    .ex_mem_data(ex_mem_alu_result),
    .mem_wb_data(writeback_data),
    .data_out(forwarded_rs1)
);


//============================================================
// Forwarding MUX B
//============================================================

forwarding_mux
#(
    .WIDTH(`DATA_WIDTH)
)
FWD_B
(
    .sel(forward_b),
    .reg_data(id_ex_rs2_data),
    .ex_mem_data(ex_mem_alu_result),
    .mem_wb_data(writeback_data),
    .data_out(forwarded_rs2)
);


//============================================================
// ALU Operand MUX
//============================================================

alu_operand_mux
#(
    .WIDTH(`DATA_WIDTH)
)
OPERAND_MUX
(
    .sel(id_ex_alu_src),
    .reg_data(forwarded_rs2),
    .immediate(id_ex_immediate),
    .operand_b(alu_operand_b)
);


//============================================================
// ALU
//============================================================

alu ALU
(
    .operand_a(forwarded_rs1),
    .operand_b(alu_operand_b),
    .alu_operation(id_ex_alu_func),
    .result(alu_result),
    .carry(carry_flag),
    .zero(zero_flag),
    .negative(negative_flag),
    .overflow(overflow_flag)
);


//============================================================
// Status Register
//============================================================
//
// CRITICAL FIX: the status register's *outputs* were previously
// left unconnected (.carry_out(), .zero_out(), ...), and the
// branch unit below was reading the ALU's *live, current-cycle*
// carry_flag/zero_flag/etc. wires directly instead. In a pipeline,
// a CMP and the branch that depends on it are normally different
// instructions in different cycles, so a conditional branch would
// have been testing whatever the ALU happened to be doing on its
// own EX cycle - not CMP's latched result. Also, enable was tied
// to id_ex_reg_write, which is asserted for LOAD/MOV too (neither
// of which should update the flags). Fixed to gate on flag_write
// (ALU-class instructions only, mirroring the original single-cycle
// CTRL_FLAG_WR) and to route the *_out signals to the branch unit.

wire sr_carry_flag;
wire sr_zero_flag;
wire sr_negative_flag;
wire sr_overflow_flag;

// STATUS register itself is instantiated later, in the MEM-stage
// section below - it's driven by EX_MEM's registered flag outputs,
// not the live EX-stage ones (see the note down there).

//------------------------------------------------------------
// Flag forwarding
//------------------------------------------------------------
// STATUS now only reflects flags through the end of the MEM stage,
// one cycle later than before. For a CMP immediately followed by a
// branch (0 instructions between them), the branch resolves in EX
// on the very same cycle CMP sits in EX/MEM - STATUS hasn't caught
// up yet. Forward EX/MEM's already-registered flags directly for
// that case; anything older than that has already made it into
// STATUS by the time the branch needs it, so no other forwarding
// path is needed (same reasoning as an ordinary 1-source forward,
// just for condition codes instead of register data).

wire flag_forward;
assign flag_forward = ex_mem_flag_write & ex_mem_valid;

wire forwarded_carry_flag;
wire forwarded_zero_flag;
wire forwarded_negative_flag;
wire forwarded_overflow_flag;

assign forwarded_carry_flag    = flag_forward ? ex_mem_carry    : sr_carry_flag;
assign forwarded_zero_flag     = flag_forward ? ex_mem_zero     : sr_zero_flag;
assign forwarded_negative_flag = flag_forward ? ex_mem_negative : sr_negative_flag;
assign forwarded_overflow_flag = flag_forward ? ex_mem_overflow : sr_overflow_flag;


//============================================================
// Branch Unit
//============================================================

branch_unit BRANCH
(
    .opcode(id_ex_instruction[15:12]),
    .carry_flag(forwarded_carry_flag),
    .zero_flag(forwarded_zero_flag),
    .negative_flag(forwarded_negative_flag),
    .overflow_flag(forwarded_overflow_flag),
    .branch_taken(branch_taken)
);


//============================================================
// Branch Target
//============================================================

assign branch_target =
        id_ex_pc_plus_one +
        id_ex_immediate;


//============================================================
// EX/MEM SIGNALS
//============================================================

wire [`ADDR_WIDTH-1:0] ex_mem_pc;
wire [`DATA_WIDTH-1:0] ex_mem_alu_result;
wire [`DATA_WIDTH-1:0] ex_mem_store_data;
wire [3:0]             ex_mem_rd;

wire ex_mem_carry;
wire ex_mem_zero;
wire ex_mem_negative;
wire ex_mem_overflow;

wire ex_mem_reg_write;
wire ex_mem_mem_read;
wire ex_mem_mem_write;
wire ex_mem_branch;
wire ex_mem_flag_write;

wire [2:0] ex_mem_wb_sel;
wire       ex_mem_valid;


//============================================================
// EX/MEM Pipeline Register
//============================================================

ex_mem_register EX_MEM
(
    .clk(clk),
    .rst(rst),

    .enable(1'b1),
    .stall(1'b0),
    .flush(1'b0),

    .pc_in(id_ex_pc),
    .alu_result_in(alu_result),
    // Store data is the (possibly forwarded) rs2 value - the
    // ALU's operand_b carries the immediate for STORE's address
    // calc instead, so the value to write to memory has to travel
    // down its own path rather than through the ALU result.
    .store_data_in(forwarded_rs2),
    .rd_in(id_ex_rd),

    .carry_in(carry_flag),
    .zero_in(zero_flag),
    .negative_in(negative_flag),
    .overflow_in(overflow_flag),

    // Gated by id_ex_valid so a bubble or an out-of-range fetch
    // can never write a register or memory.
    .reg_write_in(id_ex_reg_write & id_ex_valid),
    .mem_read_in(id_ex_mem_read & id_ex_valid),
    .mem_write_in(id_ex_mem_write & id_ex_valid),
    .branch_in(id_ex_branch),
    .flag_write_in(id_ex_flag_write & id_ex_valid),

    .wb_sel_in(id_ex_wb_sel),
    .valid_in(id_ex_valid),

    .pc_out(ex_mem_pc),
    .alu_result_out(ex_mem_alu_result),
    .store_data_out(ex_mem_store_data),
    .rd_out(ex_mem_rd),

    .carry_out(ex_mem_carry),
    .zero_out(ex_mem_zero),
    .negative_out(ex_mem_negative),
    .overflow_out(ex_mem_overflow),

    .reg_write_out(ex_mem_reg_write),
    .mem_read_out(ex_mem_mem_read),
    .mem_write_out(ex_mem_mem_write),
    .branch_out(ex_mem_branch),
    .flag_write_out(ex_mem_flag_write),

    .wb_sel_out(ex_mem_wb_sel),
    .valid_out(ex_mem_valid)
);


//============================================================
// MEM STAGE
//============================================================

wire [`DATA_WIDTH-1:0] memory_data;

data_memory DMEM
(
    .clk(clk),
    .read_enable(ex_mem_mem_read),
    .write_enable(ex_mem_mem_write),
    .address(ex_mem_alu_result[`ADDR_WIDTH-1:0]),
    .write_data(ex_mem_store_data),
    .read_data(memory_data)
);

//------------------------------------------------------------
// Status Register (MEM stage)
//------------------------------------------------------------
// Moved here from EX. Previously STATUS was written directly from
// the live, same-cycle ALU flags (forward -> ALU -> flags ->
// STATUS, all in one EX cycle) - Vivado's post-route timing report
// showed this as the design's tightest path, and it stayed the
// tightest path (WNS +0.019ns, essentially zero margin) even after
// trimming logic levels out of the forwarding decision. Since
// ex_mem_carry/zero/negative/overflow are already registered
// outputs of EX_MEM (one full cycle old, latched for free), driving
// STATUS from those instead makes its D input a plain register-to-
// register copy - trivial timing, comfortable margin. The price is
// that STATUS itself now reflects a flag-writer one cycle later
// than before; branch_unit compensates via flag forwarding from
// EX_MEM above (same idea as ordinary register forwarding).

status_register STATUS
(
    .clk(clk),
    .rst(rst),

    .enable(ex_mem_flag_write & ex_mem_valid),

    .carry_in(ex_mem_carry),
    .zero_in(ex_mem_zero),
    .negative_in(ex_mem_negative),
    .overflow_in(ex_mem_overflow),

    .carry_out(sr_carry_flag),
    .zero_out(sr_zero_flag),
    .negative_out(sr_negative_flag),
    .overflow_out(sr_overflow_flag)
);


//============================================================
// MEM/WB SIGNALS
//============================================================

wire [`DATA_WIDTH-1:0] mem_wb_alu_result;
wire [`DATA_WIDTH-1:0] mem_wb_memory_data;
wire [3:0]             mem_wb_rd;
wire                   mem_wb_reg_write;
wire [2:0]             mem_wb_wb_sel;
wire                   mem_wb_valid;


//============================================================
// MEM/WB Pipeline Register
//============================================================

mem_wb_register MEM_WB
(
    .clk(clk),
    .rst(rst),

    .enable(1'b1),
    .stall(1'b0),
    .flush(1'b0),

    .alu_result_in(ex_mem_alu_result),
    .memory_data_in(memory_data),
    .rd_in(ex_mem_rd),

    .reg_write_in(ex_mem_reg_write),
    .wb_sel_in(ex_mem_wb_sel),
    .valid_in(ex_mem_valid),

    .alu_result_out(mem_wb_alu_result),
    .memory_data_out(mem_wb_memory_data),
    .rd_out(mem_wb_rd),

    .reg_write_out(mem_wb_reg_write),
    .wb_sel_out(mem_wb_wb_sel),
    .valid_out(mem_wb_valid)
);


//============================================================
// WB STAGE
//============================================================

write_back_mux WBMUX
(
    .wb_sel(mem_wb_wb_sel),
    .alu_data(mem_wb_alu_result),
    .mem_data(mem_wb_memory_data),
    // WB_PC/WB_IMM are not exercised by any current opcode in
    // this pipeline (MOV routes its immediate through the ALU -
    // see the instruction_decoder fix - and no CALL/JAL opcode
    // exists yet to use WB_PC), so these inputs are tied off.
    .pc_data({`DATA_WIDTH{1'b0}}),
    .imm_data({`DATA_WIDTH{1'b0}}),
    .wb_data(writeback_data)
);

assign reg_write_wb = mem_wb_reg_write;
assign rd_wb         = mem_wb_rd;


//============================================================
// Debug Outputs
//============================================================

assign debug_pc            = pc;
assign debug_instruction   = instruction;
assign debug_alu_result    = alu_result;
assign debug_memory_data   = memory_data;
assign debug_writeback     = writeback_data;
assign debug_reg_write     = mem_wb_reg_write;
assign debug_rd            = mem_wb_rd;


//============================================================
// Performance Counter
//============================================================

performance_counter PERF
(
    .clk(clk),
    .rst(rst),

    .instruction_retired(mem_wb_valid),
    .stall(stall_pc),
    .branch(id_ex_branch & id_ex_valid),
    .branch_taken(branch_taken),
    .forwarding(forward_a != 2'b00 || forward_b != 2'b00),

    .cycle_count(cycle_count),
    .instruction_count(instruction_count),
    .stall_count(stall_count),
    .branch_count(branch_count),
    .branch_taken_count(branch_taken_count),
    .forwarding_count(forwarding_count)
);

endmodule
`default_nettype wire