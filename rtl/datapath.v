`timescale 1ns / 1ps
`include "cpu_constants.vh"

//============================================================
// Project : FlexRISC16
// Module  : Datapath
// Description : Processor Datapath
//============================================================

module datapath(

    input wire clk,
    input wire rst,

    //--------------------------------------------------------
    // Control Word
    //--------------------------------------------------------

    input wire [15:0] control_word,

    //--------------------------------------------------------
    // Outputs to Control Unit
    //--------------------------------------------------------

    output wire [3:0] opcode,
    output wire [1:0] instr_class,
    output wire is_load,
    output wire is_store,
    output wire is_branch,
    output wire is_immediate,

    output wire zero_flag,
    output wire carry_flag,
    
    //----------------------------------------------------
    // Debug Signals
    //----------------------------------------------------
    
    output wire [`ADDR_WIDTH-1:0] debug_pc,
    output wire [`DATA_WIDTH-1:0] debug_instruction,
    output wire [`DATA_WIDTH-1:0] debug_alu_result,
    output wire [`DATA_WIDTH-1:0] debug_writeback

);

//============================================================
// Internal Signals
//============================================================

//------------------------------------------------------------
// Program Counter
//------------------------------------------------------------

wire [`ADDR_WIDTH-1:0] pc;
wire [`ADDR_WIDTH-1:0] next_pc;
wire branch_taken;

//------------------------------------------------------------
// Instruction Memory
//------------------------------------------------------------

wire [`DATA_WIDTH-1:0] instruction;

//------------------------------------------------------------
// Instruction Register         
//------------------------------------------------------------

wire [`DATA_WIDTH-1:0] ir_instruction;
    
//============================================================
// DECODE STAGE SIGNALS
//============================================================

// Instruction Fields

wire [3:0] rd;
wire [3:0] rs1;
wire [3:0] rs2;
wire [3:0] write_reg_addr;

// Decoded Information

//wire [1:0] instr_class;
wire [3:0] alu_func;

//wire is_load;
//wire is_store;
//wire is_branch;
//wire is_immediate;
wire alu_src;

// Immediate

wire [`DATA_WIDTH-1:0] immediate;

// Register File

wire [`DATA_WIDTH-1:0] reg_data1;
wire [`DATA_WIDTH-1:0] reg_data2;

// Write Back

wire [`DATA_WIDTH-1:0] wb_data;

// ALU Control

wire [3:0] alu_operation;
wire [`DATA_WIDTH-1:0] alu_operand_b;

//============================================================
// Execute Stage Signals
//============================================================

// ALU Outputs

wire [`DATA_WIDTH-1:0] alu_result;

wire carry;
wire zero;
wire negative;
wire overflow;

// STATUS REGISTER

wire sr_zero_flag;
wire sr_carry_flag;
wire sr_negative_flag;
wire sr_overflow_flag;


// Branch

wire [`ADDR_WIDTH-1:0] branch_target;

//============================================================
// Memory Stage Signals
//============================================================

wire [`DATA_WIDTH-1:0] memory_data;

//------------------------------------------------------------
// Control Signals
//------------------------------------------------------------

wire pc_enable;
wire ir_load;

wire alu_enable;

wire mem_read;
wire mem_write;

wire reg_write;
wire flag_write;

wire [2:0] wb_sel;

//------------------------------------------------------------
// PC + 1
//------------------------------------------------------------

wire [`ADDR_WIDTH-1:0] pc_plus_one;


//============================================================
// Decode Control Word
//============================================================

assign pc_enable = control_word[`CTRL_PC_EN];
assign ir_load   = control_word[`CTRL_IR_LOAD];
assign alu_enable = control_word[`CTRL_ALU_EN];
assign mem_read  = control_word[`CTRL_MEM_RD];
assign mem_write = control_word[`CTRL_MEM_WR];
assign reg_write = control_word[`CTRL_REG_WR];
assign flag_write = control_word[`CTRL_FLAG_WR];
assign wb_sel = control_word[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB];
assign write_reg_addr = rd;

//============================================================
// FETCH STAGE
//============================================================

//------------------------------------------------------------
// Program Counter
//------------------------------------------------------------

program_counter PC(
    .clk(clk),
    .rst(rst),
    .pc_enable(pc_enable),
    .stall(1'b0),
    .pc_load(branch_taken),
    .pc_next(next_pc),
    .pc(pc)
);

//------------------------------------------------------------
// PC + 1
//------------------------------------------------------------

assign pc_plus_one = pc + 1'b1;

//------------------------------------------------------------
// Instruction Memory
//------------------------------------------------------------

instruction_memory IMEM(
    .address(pc),
    .instruction(instruction)
);

//------------------------------------------------------------
// Instruction Register
//------------------------------------------------------------

instruction_register IR(
    .clk(clk),
    .rst(rst),
    .enable(ir_load),
    .stall(1'b0),
    .flush(1'b0),
    .instruction_in(instruction),
    .instruction_out(ir_instruction)
);

//============================================================
// DECODE STAGE
//============================================================

//------------------------------------------------------------
// Instruction Decoder
//------------------------------------------------------------

instruction_decoder DECODER(
    .instruction(ir_instruction),
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

//------------------------------------------------------------
// Immediate Generator
//------------------------------------------------------------

immediate_generator IMMGEN(
    .instruction(ir_instruction),
    .instr_class(instr_class),
    .immediate(immediate)
);

//------------------------------------------------------------
// Register File
//------------------------------------------------------------

register_file RF(
    .clk(clk),
    .rst(rst),
    .we(reg_write),
    .wr_addr(write_reg_addr),
    .wr_data(wb_data),
    .rd_addr1(rs1),
    .rd_addr2(rs2),
    .rd_data1(reg_data1),
    .rd_data2(reg_data2)
);

//------------------------------------------------------------
// ALU Control
//------------------------------------------------------------

alu_control ALUCTRL(
    .alu_enable(alu_enable),
    .instr_class(instr_class),
    .alu_func(alu_func),
    .alu_operation(alu_operation)
);

//============================================================
// EXECUTE STAGE
//============================================================

//------------------------------------------------------------
// ALU Operand B Multiplexer
//------------------------------------------------------------

alu_operand_mux ALU_MUX(
    .sel(alu_src),
    .reg_data(reg_data2),
    .immediate(immediate),
    .operand_b(alu_operand_b)
);

//------------------------------------------------------------
// Arithmetic Logic Unit
//------------------------------------------------------------

alu ALU(
    .operand_a(reg_data1),
    .operand_b(alu_operand_b),
    .alu_operation(alu_operation),
    .result(alu_result),
    .carry(carry),
    .zero(zero),
    .negative(negative),
    .overflow(overflow)
);

//------------------------------------------------------------
// Status Register
//------------------------------------------------------------

status_register STATUS(
    .clk(clk),
    .rst(rst),
    .enable(flag_write),
    .carry_in(carry),
    .zero_in(zero),
    .negative_in(negative),
    .overflow_in(overflow),
    .carry_out(sr_carry_flag),
    .zero_out(sr_zero_flag),
    .negative_out(sr_negative_flag),
    .overflow_out(sr_overflow_flag)
);

//------------------------------------------------------------
// Branch Unit
//------------------------------------------------------------

branch_unit BRANCH(
    .opcode(opcode),
    .carry_flag(sr_carry_flag),
    .zero_flag(sr_zero_flag),
    .negative_flag(sr_negative_flag),
    .overflow_flag(sr_overflow_flag),
    .branch_taken(branch_taken)
);

//============================================================
// MEMORY STAGE
//============================================================

//------------------------------------------------------------
// Data Memory
//------------------------------------------------------------

data_memory DMEM (
    .clk(clk),
    .read_enable(mem_read),
    .write_enable(mem_write),
    // Address calculated by the ALU
    .address(alu_result[`ADDR_WIDTH-1:0]),
    // Data to store comes from RS2
    .write_data(reg_data2),
    // Data read from memory
    .read_data(memory_data)
);

//============================================================
// WRITE BACK STAGE
//============================================================

//------------------------------------------------------------
// Write Back Multiplexer
//------------------------------------------------------------

write_back_mux WBMUX(
    .wb_sel(wb_sel),
    .alu_data(alu_result),
    .mem_data(memory_data),
    .pc_data({{(`DATA_WIDTH-`ADDR_WIDTH){1'b0}},pc_plus_one}),
    .imm_data(immediate),
    .wb_data(wb_data)
);

//============================================================
// NEXT PC LOGIC
//============================================================

//------------------------------------------------------------
// Branch Target
//------------------------------------------------------------

//------------------------------------------------------------
// PC Relative Branch Address
//------------------------------------------------------------

assign branch_target = pc_plus_one + immediate[`ADDR_WIDTH-1:0];
//------------------------------------------------------------
// Next PC MUX Selection
//------------------------------------------------------------

next_pc_mux NPCMUX(
    .pc_load(branch_taken),
    .pc_plus_one(pc_plus_one),
    .branch_target(branch_target),
    .next_pc(next_pc)
);               

//------------------------------------------------------------
// Datapath Outputs
//------------------------------------------------------------

// Status flags come from the Status Register
// through the Branch Unit.

assign zero_flag  = sr_zero_flag;
assign carry_flag = sr_carry_flag;

//----------------------------------------------------
// Debug Signals
//----------------------------------------------------

assign debug_pc = pc;
assign debug_instruction = ir_instruction;
assign debug_alu_result = alu_result;
assign debug_writeback = wb_data;

endmodule