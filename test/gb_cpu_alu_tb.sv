module gb_cpu_alu_tb ();

    import gb_cpu_common_pkg::*;

    // Replicate IO
    alu_instruction_t instruction;
    logic carry_in;
    logic [7:0] out;
    logic Z, N, H, C;

    // Help with waveforms
    logic [7:0] op_a, op_b;
    assign op_a = instruction.operand_a;
    assign op_b = instruction.operand_b;

    // Instance
    gb_cpu_alu dut (.*);

    function automatic void getALUInfo();
        $display("Testing operation %s\nInputs: %d and %d", instruction.opcode.name(), instruction.operand_a,
                 instruction.operand_b);
    endfunction : getALUInfo

    function automatic logic [7:0] getRandOperand();
        logic [31:0] randVal;
        randVal = $urandom();
        return randVal[7:0];
    endfunction : getRandOperand

    initial begin
        // Dump Simulation Data
        $dumpfile("gb_cpu_alu_tb.fst");
        $dumpvars();

        carry_in = 0;

        instruction.operand_a = getRandOperand();
        instruction.operand_b = getRandOperand();
        instruction.opcode    = ADD;
        getALUInfo();
        #1;
        $display("Result: %d", out);

        instruction.operand_a = getRandOperand();
        instruction.operand_b = getRandOperand();
        instruction.opcode    = SUB;
        getALUInfo();
        #1;
        $display("Result: %d", out);

        instruction.operand_a = getRandOperand();
        instruction.operand_b = getRandOperand();
        instruction.opcode    = XOR;
        getALUInfo();
        #1;
        $display("Result: %d", out);

        $finish();
    end

endmodule : gb_cpu_alu_tb
