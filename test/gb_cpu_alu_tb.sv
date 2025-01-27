module gb_cpu_alu_tb ();
    /* verilator lint_off WIDTHEXPAND */
    /* verilator lint_off WIDTHTRUNC */
    import gb_cpu_common_pkg::*;

    // Replicate IO
    alu_instruction_t instruction;
    logic [7:0] out;
    alu_flags_t flags_i, flags_o;

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

    function automatic logic [7:0] getRandBCD();
        logic [31:0] randVal;
        logic [ 7:0] bcdVal;
        randVal = $urandom();
        bcdVal  = randVal[7:0];
        if (bcdVal[3:0] > 4'h9) bcdVal[3:0] = bcdVal[3:0] - 4'h6;
        if (bcdVal[7:4] > 4'h9) bcdVal[7:4] = bcdVal[7:4] - 4'h6;
        return bcdVal;
    endfunction : getRandBCD

    initial begin
        // Dump Simulation Data
        $dumpfile("gb_cpu_alu_tb.fst");
        $dumpvars();

        //        for (int i = 0; i < 10; i++) begin : testADD
        //            instruction.operand_a = getRandOperand();
        //            instruction.operand_b = getRandOperand();
        //            instruction.opcode    = ADD;
        //            getALUInfo();
        //            #1;
        //            if (out != instruction.operand_a + instruction.operand_b)
        //                $display("FAILED ADD OPERATION");
        //            $display("Result: %d", out);
        //        end : testADD
        //
        //        for (int i = 0; i < 10; i++) begin : testSUB
        //            instruction.operand_a = getRandOperand();
        //            instruction.operand_b = getRandOperand();
        //            instruction.opcode    = SUB;
        //            getALUInfo();
        //            #1;
        //            if (out != instruction.operand_a - instruction.operand_b)
        //                $display("FAILED SUB OPERATION");
        //            $display("Result: %d", out);
        //        end : testSUB
        //
        //        for (int i = 0; i < 10; i++) begin : testAND
        //            instruction.operand_a = getRandOperand();
        //            instruction.operand_b = getRandOperand();
        //            instruction.opcode    = AND;
        //            getALUInfo();
        //            #1;
        //            if (out != instruction.operand_a & instruction.operand_b)
        //                $display("FAILED AND OPERATION");
        //            $display("Result: %d", out);
        //        end : testAND
        //
        //        for (int i = 0; i < 10; i++) begin : testOR
        //            instruction.operand_a = getRandOperand();
        //            instruction.operand_b = getRandOperand();
        //            instruction.opcode    = OR;
        //            getALUInfo();
        //            #1;
        //            if (out != instruction.operand_a | instruction.operand_b)
        //                $display("FAILED OR OPERATION");
        //            $display("Result: %d", out);
        //        end : testOR
        //
        //        for (int i = 0; i < 10; i++) begin : testXOR
        //            instruction.operand_a = getRandOperand();
        //            instruction.operand_b = getRandOperand();
        //            instruction.opcode    = XOR;
        //            getALUInfo();
        //            #1;
        //            if (out != instruction.operand_a ^ instruction.operand_b)
        //                $display("FAILED XOR OPERATION");
        //            $display("Result: %d", out);
        //        end : testXOR

        for (int i = 0; i < 10; i++) begin : testDAA
            // ADD
            instruction.operand_a = getRandBCD();
            instruction.operand_b = getRandBCD();
            instruction.operand_a = instruction.operand_a & 8'h0F;
            $display("BCD ADD:\n  %2h\n+ %2h", instruction.operand_a, instruction.operand_b);
            instruction.opcode = ADD;
            #1;
            instruction.operand_a = out;
            flags_i = flags_o;
            instruction.opcode    = DAA;
            #1;
            $display("= %2h", out);
            $display("where C=%d H=%d CASE=%d%d IN=%2h\n", flags_i.C, flags_i.H,
                     (flags_i.C || (instruction.operand_a > 8'h9F)),
                     (flags_i.H || (instruction.operand_a[3:0] > 4'h9)), instruction.operand_a);

            // SUB
            instruction.operand_a = getRandBCD();
            instruction.operand_b = getRandBCD();
            instruction.operand_b = instruction.operand_b & 8'h0F;
            $display("BCD SUB:\n  %2h\n- %2h", instruction.operand_a, instruction.operand_b);
            instruction.opcode = SUB;
            #1;
            instruction.operand_a = out;
            flags_i = flags_o;
            instruction.opcode    = DAA;
            #1;
            $display("= %2h", out);
            $display("where C=%d H=%d CASE=%d%d IN=%2h\n", flags_i.C, flags_i.H, flags_i.C, flags_i.H,
                     instruction.operand_a);
        end : testDAA

        $finish();
    end
    /* verilator lint_on WIDTHEXPAND */
    /* verilator lint_on WIDTHTRUNC */

endmodule : gb_cpu_alu_tb
