`ifndef CPU_CONSTANTS_VH
`define CPU_CONSTANTS_VH

//============================================================
// FlexRISC16 CPU Constants
//============================================================

//------------------------------------------------------------
// Processor Parameters
//------------------------------------------------------------

`define DATA_WIDTH     16
`define ADDR_WIDTH     16
`define REG_COUNT      16
`define REG_ADDR_WIDTH 4

//------------------------------------------------------------
// Instruction Opcodes
//------------------------------------------------------------

`define OP_ADD    4'b0000
`define OP_SUB    4'b0001
`define OP_AND    4'b0010
`define OP_OR     4'b0011
`define OP_XOR    4'b0100
`define OP_NOT    4'b0101
`define OP_CMP    4'b0110
`define OP_MOV    4'b0111

`define OP_LOAD   4'b1000
`define OP_STORE  4'b1001
`define OP_JMP    4'b1010
`define OP_BEQ    4'b1011
`define OP_BNE    4'b1100
`define OP_SHL    4'b1101
`define OP_SHR    4'b1110
`define OP_NOP    4'b1111

//------------------------------------------------------------
// FSM States
//------------------------------------------------------------

`define ST_RESET      3'd0
`define ST_FETCH      3'd1
`define ST_DECODE     3'd2
`define ST_EXECUTE    3'd3
`define ST_MEMORY     3'd4
`define ST_WRITEBACK  3'd5

//------------------------------------------------------------
// Write Back Select
//------------------------------------------------------------

`define WB_ALU        3'b000
`define WB_MEMORY     3'b001
`define WB_PC         3'b010
`define WB_IMM  3'b011

`define WB_MUL      3'b100
`define WB_DIV      3'b101
`define WB_CSR      3'b110

`define WB_NONE     3'b111

//------------------------------------------------------------
// ALU Operations
//------------------------------------------------------------

`define ALU_ADD     4'd0
`define ALU_SUB     4'd1
`define ALU_AND     4'd2
`define ALU_OR      4'd3
`define ALU_XOR     4'd4
`define ALU_NOT     4'd5
`define ALU_CMP     4'd6
`define ALU_MOV     4'd7
`define ALU_SHL     4'd8
`define ALU_SHR     4'd9

// Reserved expansion

`define ALU_MUL     4'd10
`define ALU_DIV     4'd11
`define ALU_MOD     4'd12
`define ALU_ROL     4'd13
`define ALU_ROR     4'd14
`define ALU_NOP     4'd15

//------------------------------------------------------------
// Control Word Bit Positions
//------------------------------------------------------------

// Single-bit Control Signals

`define CTRL_PC_EN        15
`define CTRL_IR_LOAD      14
`define CTRL_ALU_EN       13
`define CTRL_MEM_RD       12
`define CTRL_MEM_WR       11
`define CTRL_REG_WR       10
`define CTRL_FLAG_WR       9

//------------------------------------------------------------
// Multi-bit Fields
//------------------------------------------------------------

// Write Back Select

`define CTRL_WB_SEL_MSB    8
`define CTRL_WB_SEL_LSB    6

//------------------------------------------------------------
// Reserved Bits
//------------------------------------------------------------

`define CTRL_RESERVED_MSB  5
`define CTRL_RESERVED_LSB  0

//------------------------------------------------------------
// Instruction Classes
//------------------------------------------------------------

`define CLASS_ALU        2'b00
`define CLASS_IMMEDIATE  2'b01
`define CLASS_MEMORY     2'b10
`define CLASS_BRANCH     2'b11

//------------------------------------------------------------
// Special Instructions
//------------------------------------------------------------

`define NOP_INSTRUCTION 16'h0000

//------------------------------------------------------------
// Processor States
//------------------------------------------------------------

`define S_FETCH      3'd0
`define S_DECODE     3'd1
`define S_EXECUTE    3'd2
`define S_MEMORY     3'd3
`define S_WRITEBACK  3'd4

`endif