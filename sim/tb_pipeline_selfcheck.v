`timescale 1ns / 1ps
`include "cpu_constants.vh"

//============================================================
// Self-checking testbench for pipeline_processor_top
//
// Preloads a program directly into instruction memory (no
// external .mem file needed), runs it, and checks register
// file / data memory / branch outcomes against expected
// values computed by hand. Prints PASS/FAIL per check and a
// summary at the end.
//============================================================

module tb_pipeline_selfcheck;

reg clk = 0;
reg rst = 1;

wire [15:0] debug_pc, debug_instruction;
wire [15:0] debug_alu_result, debug_memory_data, debug_writeback;
wire [31:0] cycle_count, instruction_count, stall_count;
wire [31:0] branch_count, branch_taken_count, forwarding_count;

pipeline_processor_top DUT
(
    .clk(clk),
    .rst(rst),
    .debug_pc(debug_pc),
    .debug_instruction(debug_instruction),
    .debug_alu_result(debug_alu_result),
    .debug_memory_data(debug_memory_data),
    .debug_writeback(debug_writeback),
    .cycle_count(cycle_count),
    .instruction_count(instruction_count),
    .stall_count(stall_count),
    .branch_count(branch_count),
    .branch_taken_count(branch_taken_count),
    .forwarding_count(forwarding_count)
);

always #5 clk = ~clk;

//------------------------------------------------------------
// Instruction encoders
//------------------------------------------------------------

function [15:0] R_TYPE;
    input [3:0] op, rd, rs1, rs2;
    R_TYPE = {op, rd, rs1, rs2};
endfunction

function [15:0] I_TYPE;
    input [3:0] op;
    input [3:0] rd;
    input [7:0] imm8;
    I_TYPE = {op, rd, imm8};
endfunction

function [15:0] MEM_TYPE;
    input [3:0] op, rd_or_data, rs1, imm4;
    MEM_TYPE = {op, rd_or_data, rs1, imm4};
endfunction

function [15:0] BR_TYPE;
    input [3:0] op;
    input [7:0] imm8;
    BR_TYPE = {op, 4'b0000, imm8};
endfunction

//------------------------------------------------------------
// Retirement tracking (counts real instructions reaching
// MEM/WB, ignoring bubbles from stalls/flushes)
//------------------------------------------------------------

integer retire_count;
always @(posedge clk) begin
    if (rst)
        retire_count <= 0;
    else if (DUT.PIPELINE.mem_wb_valid)
        retire_count <= retire_count + 1;
end

integer target;
task wait_retire(input integer n);
begin
    target = retire_count + n;
    while (retire_count < target) begin
        @(posedge clk);
        #1; // let retire_count's nonblocking update settle before reading it
    end
end
endtask

//------------------------------------------------------------
// Test Result Counters
//------------------------------------------------------------

integer pass_count = 0;
integer fail_count = 0;
integer test_count = 0;

//------------------------------------------------------------
// Files
//------------------------------------------------------------

integer log_file;
integer csv_file;

localparam LOG_PATH = "../../../../simulation_results.log";
localparam CSV_PATH = "../../../../simulation_results.csv";

//------------------------------------------------------------
// Print Header
//------------------------------------------------------------

task print_header;
begin

    $display("");
    $display("================================================================================");
    $display("                        FlexRISC16 PIPELINE SELF-CHECK");
    $display("================================================================================");
    $display("| %-3s | %-34s | %-8s | %-10s | %-10s |",
             "No.", "Test", "Status", "Actual", "Expected");
    $display("--------------------------------------------------------------------------------");

    $fwrite(log_file, "\n");
    $fwrite(log_file, "================================================================================\n");
    $fwrite(log_file, "                        FlexRISC16 PIPELINE SELF-CHECK\n");
    $fwrite(log_file, "================================================================================\n");
    $fwrite(log_file, "| %-3s | %-34s | %-8s | %-10s | %-10s |\n",
            "No.", "Test", "Status", "Actual", "Expected");
    $fwrite(log_file, "--------------------------------------------------------------------------------\n");

end
endtask

//------------------------------------------------------------
// Register Check
//------------------------------------------------------------

task check_reg(
    input integer regnum,
    input [15:0] expected,
    input [127:0] name
);

    reg [15:0] actual;

begin

    actual = DUT.PIPELINE.REGFILE.regfile[regnum];

    test_count = test_count + 1;

    if (actual === expected)
    begin

        pass_count = pass_count + 1;

        $display(
            "| %-3d | %-34s | %-8s | 0x%04h     | 0x%04h     |",
            test_count,
            name,
            "PASS",
            actual,
            expected
        );

        $fwrite(
            log_file,
            "| %-3d | %-34s | %-8s | 0x%04h     | 0x%04h     |\n",
            test_count,
            name,
            "PASS",
            actual,
            expected
        );
        
        $fwrite(
            csv_file,
            "%0d,%s,PASS,%04h,%04h\n",
            test_count,
            name,
            actual,
            expected
        );

    end
    else
    begin

        fail_count = fail_count + 1;

        $display(
            "| %-3d | %-34s | %-8s | 0x%04h     | 0x%04h     |",
            test_count,
            name,
            "FAIL",
            actual,
            expected
        );

        $fwrite(
            log_file,
            "| %-3d | %-34s | %-8s | 0x%04h     | 0x%04h     |\n",
            test_count,
            name,
            "FAIL",
            actual,
            expected
        );
        
        $fwrite(
            csv_file,
            "%0d,%s,FAIL,%04h,%04h\n",
            test_count,
            name,
            actual,
            expected
        );
    end

end

endtask

//------------------------------------------------------------
// Memory Check
//------------------------------------------------------------

task check_mem(
    input integer addr,
    input [15:0] expected,
    input [127:0] name
);

    reg [15:0] actual;

begin

    actual = DUT.PIPELINE.DMEM.memory[addr];

    test_count = test_count + 1;

    if (actual === expected)
    begin

        pass_count = pass_count + 1;

        $display(
            "| %-3d | %-34s | %-8s | 0x%04h     | 0x%04h     |",
            test_count,
            name,
            "PASS",
            actual,
            expected
        );

        $fwrite(
            log_file,
            "| %-3d | %-34s | %-8s | 0x%04h     | 0x%04h     |\n",
            test_count,
            name,
            "PASS",
            actual,
            expected
        );
        
        $fwrite(
            csv_file,
            "%0d,%s,PASS,%04h,%04h\n",
            test_count,
            name,
            actual,
            expected
        );
    end
    else
    begin

        fail_count = fail_count + 1;

        $display(
            "| %-3d | %-34s | %-8s | 0x%04h     | 0x%04h     |",
            test_count,
            name,
            "FAIL",
            actual,
            expected
        );

        $fwrite(
            log_file,
            "| %-3d | %-34s | %-8s | 0x%04h     | 0x%04h     |\n",
            test_count,
            name,
            "FAIL",
            actual,
            expected
        );
        
        $fwrite(
            csv_file,
            "%0d,%s,FAIL,%04h,%04h\n",
            test_count,
            name,
            actual,
            expected
        );

    end

end

endtask

//------------------------------------------------------------
// Watchdog
//------------------------------------------------------------

integer watchdog;
initial begin
    watchdog = 0;
    forever begin
        @(posedge clk);
        watchdog = watchdog + 1;
        if (watchdog > 2000) begin
        
            $display("[FAIL] Watchdog timeout - simulation appears hung");
        
            $fwrite(
                log_file,
                "[FAIL] Watchdog timeout - simulation appears hung\n"
            );
        
            fail_count = fail_count + 1;
        
            $fclose(log_file);
            $fclose(csv_file);
            $finish;
        
        end
    end
end

//------------------------------------------------------------
// Program
//------------------------------------------------------------
// Register plan: R1=10, R2=3 kept live throughout as ALU
// operands (each dependent ADD/SUB/... below sits directly
// after a MOV/prior op, so this also exercises EX/MEM
// forwarding on every step).

integer i;

initial begin

    //--------------------------------------------------------
    // Open simulation output files
    //--------------------------------------------------------

    log_file = $fopen(LOG_PATH, "w");
    csv_file = $fopen(CSV_PATH, "w");

    if (log_file == 0)
    begin
        $display("[ERROR] Could not open:");
        $display("        %s", LOG_PATH);
        $finish;
    end

    if (csv_file == 0)
    begin
        $display("[ERROR] Could not open:");
        $display("        %s", CSV_PATH);

        $fclose(log_file);
        $finish;
    end

    $display("");
    $display("[INFO] Simulation output files:");
    $display("       LOG : %s", LOG_PATH);
    $display("       CSV : %s", CSV_PATH);

    //--------------------------------------------------------
    // CSV header
    //--------------------------------------------------------

    $fwrite(csv_file,
            "No.,Test,Status,Actual,Expected\n");

    #1; // let DUT initialization finish

    // Fill instruction memory with NOP so anything past our
    // program is inert.
    for (i = 0; i < 256; i = i + 1)
        DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_NOP, 4'd0, 4'd0, 4'd0);

    // Seed a known value for the LOAD-USE hazard test.
    DUT.PIPELINE.DMEM.memory[10] = 16'h1234;

    i = 0;
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd1, 8'd10);            i=i+1; // 0: R1=10
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd2, 8'd3);             i=i+1; // 1: R2=3  (immediately needed next -> EX/MEM fwd)
    DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_ADD, 4'd3, 4'd1, 4'd2);       i=i+1; // 2: R3=13
    DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_SUB, 4'd4, 4'd1, 4'd2);       i=i+1; // 3: R4=7
    DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_AND, 4'd5, 4'd1, 4'd2);       i=i+1; // 4: R5=2
    DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_OR,  4'd6, 4'd1, 4'd2);       i=i+1; // 5: R6=11
    DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_XOR, 4'd7, 4'd1, 4'd2);       i=i+1; // 6: R7=9
    DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_NOT, 4'd8, 4'd1, 4'd0);       i=i+1; // 7: R8=~R1
    DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_SHL, 4'd9, 4'd1, 4'd0);       i=i+1; // 8: R9=R1<<1
    DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_SHR, 4'd10,4'd1, 4'd0);       i=i+1; // 9: R10=R1>>1
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd11,8'hFF);            i=i+1; //10: R11=sign-extend(-1)

    // Load-use hazard: consuming R12 the very next instruction
    // forces a 1-cycle stall + MEM/WB forward.
    DUT.PIPELINE.IMEM.memory[i] = MEM_TYPE(`OP_LOAD, 4'd12, 4'd1, 4'd0);   i=i+1; //11: R12=mem[R1+0]=mem[10]
    DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_ADD, 4'd13, 4'd12, 4'd2);    i=i+1; //12: R13=R12+R2 (load-use)

    // STORE with a data value forwarded from the immediately
    // preceding instruction (tests the STORE data-register fix
    // together with forwarding), then LOAD it back.
    DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_ADD, 4'd14, 4'd1, 4'd2);      i=i+1; //13: R14=13
    DUT.PIPELINE.IMEM.memory[i] = MEM_TYPE(`OP_STORE, 4'd14, 4'd1, 4'd1); i=i+1; //14: mem[R1+1]=R14 (fwd)
    DUT.PIPELINE.IMEM.memory[i] = MEM_TYPE(`OP_LOAD, 4'd15, 4'd1, 4'd1);  i=i+1; //15: R15=mem[R1+1]

    // BEQ taken (R1 == R1)
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd8, 8'd0);             i=i+1; //16
    DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_CMP, 4'd0, 4'd1, 4'd1);       i=i+1; //17
    DUT.PIPELINE.IMEM.memory[i] = BR_TYPE(`OP_BEQ, 8'd1);                  i=i+1; //18
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd8, 8'hAA);            i=i+1; //19 poison

    // BEQ not-taken (R1 != R2)
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd8, 8'd0);             i=i+1; //20
    DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_CMP, 4'd0, 4'd1, 4'd2);       i=i+1; //21
    DUT.PIPELINE.IMEM.memory[i] = BR_TYPE(`OP_BEQ, 8'd1);                  i=i+1; //22
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd8, 8'hAA);            i=i+1; //23 fallthrough

    // BNE taken (R1 != R2)
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd8, 8'd0);             i=i+1; //24
    DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_CMP, 4'd0, 4'd1, 4'd2);       i=i+1; //25
    DUT.PIPELINE.IMEM.memory[i] = BR_TYPE(`OP_BNE, 8'd1);                  i=i+1; //26
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd8, 8'hAA);            i=i+1; //27 poison

    // BNE not-taken (R1 == R1)
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd8, 8'd0);             i=i+1; //28
    DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_CMP, 4'd0, 4'd1, 4'd1);       i=i+1; //29
    DUT.PIPELINE.IMEM.memory[i] = BR_TYPE(`OP_BNE, 8'd1);                  i=i+1; //30
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd8, 8'hAA);            i=i+1; //31 fallthrough

    // BEQ with a 1-instruction gap between CMP and the branch.
    // Every branch test above has CMP immediately adjacent to its
    // branch, which always hits the EX/MEM flag-forward path.
    // Inserting a non-flag-writing instruction (MOV) here forces
    // the branch to read STATUS's own committed value instead -
    // the other half of the flag-forwarding restructuring that
    // isn't otherwise exercised.
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd8, 8'd0);             i=i+1; //32
    DUT.PIPELINE.IMEM.memory[i] = R_TYPE(`OP_CMP, 4'd0, 4'd1, 4'd1);       i=i+1; //33
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd14,8'h11);            i=i+1; //34 gap (non-flag-writing)
    DUT.PIPELINE.IMEM.memory[i] = BR_TYPE(`OP_BEQ, 8'd1);                  i=i+1; //35
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd8, 8'hAA);            i=i+1; //36 poison

    // JMP (always taken)
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd8, 8'd0);             i=i+1; //37
    DUT.PIPELINE.IMEM.memory[i] = BR_TYPE(`OP_JMP, 8'd1);                  i=i+1; //38
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd8, 8'hAA);            i=i+1; //39 poison

    // Final marker: proves execution kept going correctly
    // after every branch/jump test above.
    DUT.PIPELINE.IMEM.memory[i] = I_TYPE(`OP_MOV, 4'd9, 8'h55);            i=i+1; //40

    //--------------------------------------------------------
    // Release reset and run
    //--------------------------------------------------------

    @(posedge clk); 
    @(posedge clk);
    rst = 0;
    print_header();

    wait_retire(3);  check_reg(3,  16'd13,    "ADD (fwd)");
    wait_retire(1);  check_reg(4,  16'd7,     "SUB (fwd)");
    wait_retire(1);  check_reg(5,  16'd2,     "AND (fwd)");
    wait_retire(1);  check_reg(6,  16'd11,    "OR (fwd)");
    wait_retire(1);  check_reg(7,  16'd9,     "XOR (fwd)");
    wait_retire(1);  check_reg(8,  16'hFFF5,  "NOT (fwd)");
    wait_retire(1);  check_reg(9,  16'd20,    "SHL (fwd)");
    wait_retire(1);  check_reg(10, 16'd5,     "SHR (fwd)");
    wait_retire(1);  check_reg(11, 16'hFFFF,  "MOV sign-extend -1");

    wait_retire(1);  check_reg(12, 16'h1234,  "LOAD");
    wait_retire(1);  check_reg(13, 16'h1237,  "ADD after load-use stall");

    wait_retire(1);  check_reg(14, 16'd13,    "ADD (pre-store)");
    wait_retire(1);  check_mem(11, 16'd13,    "STORE (forwarded data)");
    wait_retire(1);  check_reg(15, 16'd13,    "LOAD-back of stored value");

    // NOTE on counts below: when a branch is actually taken, its
    // poison instruction is squashed by the flush and never
    // reaches MEM/WB, so it does not count as a retirement. Taken
    // blocks (MOV, CMP, branch, squashed-poison) are 3 real
    // retirements, not 4; not-taken blocks (MOV, CMP, branch,
    // fallthrough-poison) are a full 4; JMP has no CMP, so its
    // taken block is 2 (MOV, JMP) plus a squashed poison.
    wait_retire(3);  check_reg(8,  16'h0000,  "BEQ taken (skip)");
    wait_retire(4);  check_reg(8,  16'hFFAA,  "BEQ not-taken (fallthrough)");
    wait_retire(3);  check_reg(8,  16'h0000,  "BNE taken (skip)");
    wait_retire(4);  check_reg(8,  16'hFFAA,  "BNE not-taken (fallthrough)");

    // BEQ taken via STATUS's committed value (1-instruction gap
    // between CMP and the branch - not the EX/MEM forward path).
    // 4 real retirements: MOV, CMP, MOV(gap), BEQ; poison squashed.
    wait_retire(4);  check_reg(8,  16'h0000,  "BEQ taken (STATUS, gap)");

    wait_retire(2);  check_reg(8,  16'h0000,  "JMP (skip)");

    wait_retire(1);  check_reg(9,  16'h0055,  "post-branch sequential continuation");

    // R0 must stay hardwired zero despite the CMP instructions
    // above targeting it as their (discarded) destination.
    check_reg(0, 16'h0000, "R0 hardwired zero");

    #20;
$display("--------------------------------------------------------------------------------");
    $display("| TOTAL CHECKS     | %-58d |", test_count);
    $display("| PASSED           | %-58d |", pass_count);
    $display("| FAILED           | %-58d |", fail_count);
    $display("--------------------------------------------------------------------------------");
    
    $fwrite(log_file, "--------------------------------------------------------------------------------\n");
    $fwrite(log_file, "| TOTAL CHECKS     | %-58d |\n", test_count);
    $fwrite(log_file, "| PASSED           | %-58d |\n", pass_count);
    $fwrite(log_file, "| FAILED           | %-58d |\n", fail_count);
    $fwrite(log_file, "--------------------------------------------------------------------------------\n");
    
    
    $display("");
    $display("================================================================================");
    $display("                              PERFORMANCE");
    $display("================================================================================");
    $display("| %-30s | %-10d |", "Cycles", cycle_count);
    $display("| %-30s | %-10d |", "Instructions Retired", instruction_count);
    $display("| %-30s | %-10d |", "Stalls", stall_count);
    $display("| %-30s | %-10d |", "Branches", branch_count);
    $display("| %-30s | %-10d |", "Branches Taken", branch_taken_count);
    $display("| %-30s | %-10d |", "Forwarding Events", forwarding_count);
    $display("--------------------------------------------------------------------------------");
    
    
    $fwrite(log_file, "\n");
    $fwrite(log_file, "================================================================================\n");
    $fwrite(log_file, "                              PERFORMANCE\n");
    $fwrite(log_file, "================================================================================\n");
    $fwrite(log_file, "| %-30s | %-10d |\n", "Cycles", cycle_count);
    $fwrite(log_file, "| %-30s | %-10d |\n", "Instructions Retired", instruction_count);
    $fwrite(log_file, "| %-30s | %-10d |\n", "Stalls", stall_count);
    $fwrite(log_file, "| %-30s | %-10d |\n", "Branches", branch_count);
    $fwrite(log_file, "| %-30s | %-10d |\n", "Branches Taken", branch_taken_count);
    $fwrite(log_file, "| %-30s | %-10d |\n", "Forwarding Events", forwarding_count);
    $fwrite(log_file, "--------------------------------------------------------------------------------\n");
    
    $fwrite(csv_file, "\n");
    $fwrite(csv_file, "Performance,Value\n");
    $fwrite(csv_file, "Cycles,%0d\n", cycle_count);
    $fwrite(csv_file, "Instructions Retired,%0d\n", instruction_count);
    $fwrite(csv_file, "Stalls,%0d\n", stall_count);
    $fwrite(csv_file, "Branches,%0d\n", branch_count);
    $fwrite(csv_file, "Branches Taken,%0d\n", branch_taken_count);
    $fwrite(csv_file, "Forwarding Events,%0d\n", forwarding_count);
    $fwrite(csv_file, "\n");
    $fwrite(csv_file, "Summary,Value\n");
    $fwrite(csv_file, "Total Checks,%0d\n", test_count);
    $fwrite(csv_file, "Passed,%0d\n", pass_count);
    $fwrite(csv_file, "Failed,%0d\n", fail_count);
    
    
    if (fail_count == 0)
    begin
        $display("|                              ALL CHECKS PASSED                              |");
        $fwrite(log_file,
                "|                              ALL CHECKS PASSED                              |\n");
    end
    else
    begin
        $display("|                             SIMULATION FAILED                               |");
        $fwrite(log_file,
                "|                             SIMULATION FAILED                               |\n");
    end
    
    
    $display("================================================================================");
    $fwrite(log_file, "================================================================================\n");
    
    
    //--------------------------------------------------------
    // Close log file
    //--------------------------------------------------------
    $fflush(log_file);
    $fflush(csv_file);
    
    $fclose(log_file);
    $fclose(csv_file);
    
    $finish;
end

endmodule