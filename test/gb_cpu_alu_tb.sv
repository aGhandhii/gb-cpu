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

    function automatic void shuffleFlags();
        logic [31:0] randVal;
        randVal   = $urandom();
        flags_i.Z = randVal[0];
        flags_i.N = randVal[1];
        flags_i.H = randVal[2];
        flags_i.C = randVal[3];
    endfunction : shuffleFlags

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

        flags_i.Z = 1'b1;
        flags_i.N = 1'b1;
        flags_i.H = 1'b1;
        flags_i.C = 1'b0;
        instruction.operand_a = 8'd0;
        instruction.opcode = DAA;
        #1;

        //for (int i = 0; i < 10; i++) begin : testNoOp
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    shuffleFlags();
        //    instruction.opcode    = ALU_NOP;
        //    getALUInfo();
        //    $display("Expected Result: %d", instruction.operand_a);
        //    #1;
        //    if (out != instruction.operand_a || flags_i != flags_o)
        //        $display("FAILED %s", instruction.opcode.name());
        //    $display("Result: %d\n", out);
        //end : testNoOp

        //for (int i = 0; i < 10; i++) begin : testADD
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = ADD;
        //    getALUInfo();
        //    $display("Expected Result: %d", instruction.operand_a+instruction.operand_b);
        //    #1;
        //    if (out != instruction.operand_a + instruction.operand_b)
        //        $display("FAILED ADD OPERATION");
        //    $display("Result: %d FLAGS[ZNHC][%b%b%b%b]\n", out, flags_o.Z, flags_o.N, flags_o.H, flags_o.C);
        //end : testADD

        //for (int i = 0; i < 10; i++) begin : testADC
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    shuffleFlags();
        //    instruction.opcode    = ADC;
        //    getALUInfo();
        //    $display("%s", (flags_i.C == 1'b1 ? "Carry-in is present" : "No Carry-in"));
        //    $display("Expected Result: %d", instruction.operand_a+instruction.operand_b+{7'd0, flags_i.C});
        //    #1;
        //    if (out != instruction.operand_a + instruction.operand_b + {7'd0, flags_i.C})
        //        $display("FAILED ADC OPERATION");
        //    $display("Result: %d FLAGS[ZNHC][%b%b%b%b]\n", out, flags_o.Z, flags_o.N, flags_o.H, flags_o.C);
        //end : testADC

        //for (int i = 0; i < 10; i++) begin : testSUB
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = SUB;
        //    shuffleFlags();
        //    getALUInfo();
        //    $display("Expected Result: %d", instruction.operand_a-instruction.operand_b);
        //    #1;
        //    if (out != instruction.operand_a - instruction.operand_b || flags_o.N != 1'b1)
        //        $display("FAILED %s", instruction.opcode.name());
        //    $display("Result: %d FLAGS[ZNHC][%b%b%b%b]\n", out, flags_o.Z, flags_o.N, flags_o.H, flags_o.C);
        //end : testSUB

        //for (int i = 0; i < 10; i++) begin : testSBC
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = SBC;
        //    shuffleFlags();
        //    getALUInfo();
        //    $display("%s", (flags_i.C == 1'b1 ? "Carry-in is present" : "No Carry-in"));
        //    $display("Expected Result: %d", instruction.operand_a-instruction.operand_b-{7'd0,flags_i.C});
        //    #1;
        //    if (out != instruction.operand_a - instruction.operand_b - {7'd0,flags_i.C} || flags_o.N != 1'b1)
        //        $display("FAILED %s", instruction.opcode.name());
        //    $display("Actual Result:   %d\nFLAGS[ZNHC][%b%b%b%b]\n", out, flags_o.Z, flags_o.N, flags_o.H, flags_o.C);
        //end : testSBC

        //for (int i = 0; i < 10; i++) begin : testCP
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = CP;
        //    shuffleFlags();
        //    getALUInfo();
        //    $display("Expected Result: %d", instruction.operand_a);
        //    #1;
        //    if (out != instruction.operand_a || flags_o.N != 1'b1)
        //        $display("FAILED %s", instruction.opcode.name());
        //    $display("Result: %d FLAGS[ZNHC][%b%b%b%b]\n", out, flags_o.Z, flags_o.N, flags_o.H, flags_o.C);
        //end : testCP

        //for (int i = 0; i < 10; i++) begin : testINC
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = INC;
        //    shuffleFlags();
        //    getALUInfo();
        //    $display("Expected Result: %d", instruction.operand_a+8'd1);
        //    #1;
        //    if (out != instruction.operand_a+8'd1 || flags_o.N != 1'b0 || flags_i.C != flags_o.C)
        //        $display("FAILED %s", instruction.opcode.name());
        //    $display("Result: %d FLAGS[ZNHC][%b%b%b%b]\n", out, flags_o.Z, flags_o.N, flags_o.H, flags_o.C);
        //end : testINC

        //for (int i = 0; i < 10; i++) begin : testDEC
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = DEC;
        //    shuffleFlags();
        //    getALUInfo();
        //    $display("Expected Result: %d", instruction.operand_a-8'd1);
        //    #1;
        //    if (out != instruction.operand_a-8'd1 || flags_o.N != 1'b1 || flags_i.C != flags_o.C)
        //        $display("FAILED %s", instruction.opcode.name());
        //    $display("Result: %d FLAGS[ZNHC][%b%b%b%b]\n", out, flags_o.Z, flags_o.N, flags_o.H, flags_o.C);
        //end : testDEC

        //for (int i = 0; i < 10; i++) begin : testAND
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = AND;
        //    shuffleFlags();
        //    getALUInfo();
        //    $display("Expected: %8b", instruction.operand_a&instruction.operand_b);
        //    #1;
        //    $display("Result:   %8b\nFLAGS[ZNHC][%b%b%b%b]\n", out, flags_o.Z, flags_o.N, flags_o.H, flags_o.C);
        //    if (out != instruction.operand_a&instruction.operand_b)
        //        $display("FAILED AND OPERATION\n");
        //    if ({flags_o.N, flags_o.H, flags_o.C} != 3'b010)
        //        $display("Bad Flag Values\n");
        //end : testAND

        //for (int i = 0; i < 10; i++) begin : testOR
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = OR;
        //    shuffleFlags();
        //    getALUInfo();
        //    $display("Expected: %8b", instruction.operand_a | instruction.operand_b);
        //    #1;
        //    $display("Result:   %8b\nFLAGS[ZNHC][%b%b%b%b]\n", out, flags_o.Z, flags_o.N, flags_o.H, flags_o.C);
        //    if ({flags_o.N, flags_o.H, flags_o.C} != 3'b000)
        //        $display("Bad Flag Values\n");
        //end : testOR

        //for (int i = 0; i < 10; i++) begin : testXOR
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = XOR;
        //    shuffleFlags();
        //    getALUInfo();
        //    $display("Expected: %8b", instruction.operand_a ^ instruction.operand_b);
        //    #1;
        //    $display("Result:   %8b\nFLAGS[ZNHC][%b%b%b%b]\n", out, flags_o.Z, flags_o.N, flags_o.H, flags_o.C);
        //    if ({flags_o.N, flags_o.H, flags_o.C} != 3'b000)
        //        $display("Bad Flag Values\n");
        //end : testXOR

        //for (int i = 0; i < 10; i++) begin : testCCF
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = CCF;
        //    shuffleFlags();
        //    getALUInfo();
        //    $display("Expected: %8b", instruction.operand_a);
        //    #1;
        //    $display("Result:   %8b\nFLAGS[ZNHC][%b%b%b%b]\n", out, flags_o.Z, flags_o.N, flags_o.H, flags_o.C);
        //    if ({flags_o.N, flags_o.H} != 2'b00 || flags_o.Z != flags_i.Z)
        //        $display("Flag Mismatch\n");
        //    if (flags_o.C == flags_i.C)
        //        $display("Failed CCF\n");
        //end : testCCF

        //for (int i = 0; i < 10; i++) begin : testSCF
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = SCF;
        //    shuffleFlags();
        //    getALUInfo();
        //    $display("Expected: %8b", instruction.operand_a);
        //    #1;
        //    $display("Result:   %8b\nFLAGS[ZNHC][%b%b%b%b]\n", out, flags_o.Z, flags_o.N, flags_o.H, flags_o.C);
        //    if ({flags_o.N, flags_o.H, flags_o.C} != 3'b001 || flags_o.Z != flags_i.Z)
        //        $display("Flag Mismatch\n");
        //end : testSCF

        //for (int i = 0; i < 10; i++) begin : testDAA
        //    // ADD
        //    instruction.operand_a = getRandBCD();
        //    instruction.operand_b = getRandBCD();
        //    instruction.operand_a = instruction.operand_a & 8'h0F;
        //    $display("BCD ADD:\n  %2h\n+ %2h", instruction.operand_a, instruction.operand_b);
        //    instruction.opcode = ADD;
        //    #1;
        //    instruction.operand_a = out;
        //    flags_i = flags_o;
        //    instruction.opcode    = DAA;
        //    #1;
        //    $display("= %2h", out);
        //    $display("where input (C=%d H=%d) CASE=%d%d IN=%2h\n", flags_i.C, flags_i.H,
        //             (flags_i.C || (instruction.operand_a > 8'h9F)),
        //             (flags_i.H || (instruction.operand_a[3:0] > 4'h9)), instruction.operand_a);
        //    // SUB
        //    instruction.operand_a = getRandBCD();
        //    instruction.operand_b = getRandBCD();
        //    instruction.operand_b = instruction.operand_b & 8'h0F;
        //    $display("BCD SUB:\n  %2h\n- %2h", instruction.operand_a, instruction.operand_b);
        //    instruction.opcode = SUB;
        //    #1;
        //    instruction.operand_a = out;
        //    flags_i = flags_o;
        //    instruction.opcode    = DAA;
        //    #1;
        //    $display("= %2h", out);
        //    $display("where input (C=%d H=%d) CASE=%d%d IN=%2h\n", flags_i.C, flags_i.H, flags_i.C, flags_i.H,
        //             instruction.operand_a);
        //end : testDAA

        //// ADDITIONAL TARGETED DAA TESTS
        //instruction.operand_a = 8'h50;
        //instruction.operand_b = 8'h50;
        //$display("BCD ADD:\n  %2h\n+ %2h", instruction.operand_a, instruction.operand_b);
        //instruction.opcode = ADD;
        //#1;
        //instruction.operand_a = out;
        //flags_i = flags_o;
        //instruction.opcode    = DAA;
        //#1;
        //$display("= %2h", out);
        //$display("FLAGS [ZNHC] [%b%b%b%b]\n", flags_o.Z, flags_o.N, flags_o.H, flags_o.C);
        //$display("where input (C=%d H=%d) CASE=%d%d IN=%2h\n", flags_i.C, flags_i.H,
        //         (flags_i.C || (instruction.operand_a > 8'h9F)),
        //         (flags_i.H || (instruction.operand_a[3:0] > 4'h9)), instruction.operand_a);

        //for (int i = 0; i < 10; i++) begin : testCPL
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = CPL;
        //    shuffleFlags();
        //    getALUInfo();
        //    $display("Expected: %8b", ~instruction.operand_a);
        //    #1;
        //    $display("Result:   %8b\nFLAGS[ZNHC][%b%b%b%b]\n", out, flags_o.Z, flags_o.N, flags_o.H, flags_o.C);
        //    if (out != ~instruction.operand_a)
        //        $display("FAILED AND OPERATION\n");
        //    if ({flags_o.N, flags_o.H} != 2'b11 || flags_o.Z != flags_i.Z || flags_o.C != flags_i.C)
        //        $display("Bad Flag Values\n");
        //end : testCPL

        //for (int i = 0; i < 10; i++) begin : testSLA
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = SLA;
        //    shuffleFlags();
        //    $display("%s with input %8b", instruction.opcode.name(), instruction.operand_a);
        //    #1;
        //    $display("C, Result:   %b %8b\nFLAGS[ZNH][%b%b%b]\n", flags_o.C, out, flags_o.Z, flags_o.N, flags_o.H);
        //    if (out != instruction.operand_a<<1)
        //        $display("FAILED OPERATION\n");
        //    if ({flags_o.N, flags_o.H} != 2'b00 || flags_o.Z != (out == 8'd0) || flags_o.C != instruction.operand_a[7])
        //        $display("Bad Flag Values\n");
        //end : testSLA

        //for (int i = 0; i < 10; i++) begin : testSRA
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = SRA;
        //    shuffleFlags();
        //    $display("%s        %8b", instruction.opcode.name(), instruction.operand_a);
        //    #1;
        //    $display("Result, C: %8b %b\nFLAGS[ZNH][%b%b%b]\n", out, flags_o.C, flags_o.Z, flags_o.N, flags_o.H);
        //    if (out != {instruction.operand_a[7], instruction.operand_a[7:1]})
        //        $display("FAILED OPERATION\n");
        //    if ({flags_o.N, flags_o.H} != 2'b00 || flags_o.Z != (out == 8'd0) || flags_o.C != instruction.operand_a[0])
        //        $display("Bad Flag Values\n");
        //end : testSRA

        //for (int i = 0; i < 10; i++) begin : testSRL
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = SRL;
        //    shuffleFlags();
        //    $display("%s        %8b", instruction.opcode.name(), instruction.operand_a);
        //    #1;
        //    $display("Result, C: %8b %b\nFLAGS[ZNH][%b%b%b]\n", out, flags_o.C, flags_o.Z, flags_o.N, flags_o.H);
        //    if (out != {1'b0, instruction.operand_a[7:1]})
        //        $display("FAILED OPERATION\n");
        //    if ({flags_o.N, flags_o.H} != 2'b00 || flags_o.Z != (out == 8'd0) || flags_o.C != instruction.operand_a[0])
        //        $display("Bad Flag Values\n");
        //end : testSRL

        //for (int i = 0; i < 10; i++) begin : testRL
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = RL;
        //    shuffleFlags();
        //    $display("%s        %b %8b", instruction.opcode.name(), flags_i.C, instruction.operand_a);
        //    #1;
        //    $display("C,Result: %b %8b\nFLAGS[ZNH][%b%b%b]\n", flags_o.C, out, flags_o.Z, flags_o.N, flags_o.H);
        //    if (out != {instruction.operand_a[6:0], flags_i.C})
        //        $display("FAILED OPERATION\n");
        //    if ({flags_o.N, flags_o.H} != 2'b00 || flags_o.Z != (out == 8'd0) || flags_o.C != instruction.operand_a[7])
        //        $display("Bad Flag Values\n");
        //end : testRL

        //for (int i = 0; i < 10; i++) begin : testRLC
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = RLCA;
        //    shuffleFlags();
        //    $display("%s       %b %8b", instruction.opcode.name(), flags_i.C, instruction.operand_a);
        //    #1;
        //    $display("C,Result: %b %8b\nFLAGS[ZNH][%b%b%b]\n", flags_o.C, out, flags_o.Z, flags_o.N, flags_o.H);
        //    if (out != {instruction.operand_a[6:0], instruction.operand_a[7]})
        //        $display("FAILED OPERATION\n");
        //    if ({flags_o.N, flags_o.H} != 2'b00 || flags_o.Z != (out == 8'd0) || flags_o.C != instruction.operand_a[7])
        //        $display("Bad Flag Values\n");
        //end : testRLC

        //for (int i = 0; i < 10; i++) begin : testRR
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = RR;
        //    shuffleFlags();
        //    $display("%s        %b %8b", instruction.opcode.name(), flags_i.C, instruction.operand_a);
        //    #1;
        //    $display("C,Result: %b %8b\nFLAGS[ZNH][%b%b%b]\n", flags_o.C, out, flags_o.Z, flags_o.N, flags_o.H);
        //    if (out != {flags_i.C, instruction.operand_a[7:1]})
        //        $display("FAILED OPERATION\n");
        //    if ({flags_o.N, flags_o.H} != 2'b00 || flags_o.Z != (out == 8'd0) || flags_o.C != instruction.operand_a[0])
        //        $display("Bad Flag Values\n");
        //end : testRR

        //for (int i = 0; i < 10; i++) begin : testRRC
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = RRC;
        //    shuffleFlags();
        //    $display("%s       %b %8b", instruction.opcode.name(), flags_i.C, instruction.operand_a);
        //    #1;
        //    $display("C,Result: %b %8b\nFLAGS[ZNH][%b%b%b]\n", flags_o.C, out, flags_o.Z, flags_o.N, flags_o.H);
        //    if (out != {instruction.operand_a[0], instruction.operand_a[7:1]})
        //        $display("FAILED OPERATION\n");
        //    if ({flags_o.N, flags_o.H} != 2'b00 || flags_o.Z != (out == 8'd0) || flags_o.C != instruction.operand_a[0])
        //        $display("Bad Flag Values\n");
        //end : testRRC

        //for (int i = 0; i < 10; i++) begin : testBIT
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = BIT;
        //    shuffleFlags();
        //    $display("Testing bit %d of %8b", instruction.operand_b[2:0], instruction.operand_a);
        //    #1;
        //    $display("FLAGS[ZNHC][%b%b%b%b]\n", flags_o.Z, flags_o.N, flags_o.H, flags_o.C);
        //    if (out != instruction.operand_a)
        //        $display("FAILED OPERATION\n");
        //    if ({flags_o.N, flags_o.H} != 2'b01 || flags_o.Z != (~instruction.operand_a[instruction.operand_b[2:0]]) || flags_o.C != flags_i.C)
        //        $display("Bad Flag Values\n");
        //end : testBIT

        //for (int i = 0; i < 20; i++) begin : testSET
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_a = 8'd0;
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = SET;
        //    shuffleFlags();
        //    $display("Setting bit %d of %8b", instruction.operand_b[2:0], instruction.operand_a);
        //    #1;
        //    $display("Result:          %8b", out);
        //    if (flags_i != flags_o)
        //        $display("Bad Flag Values\n");
        //end : testSET

        //for (int i = 0; i < 20; i++) begin : testRES
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_a = 8'hFF;
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = RES;
        //    shuffleFlags();
        //    $display("Clearing bit %d of %8b", instruction.operand_b[2:0], instruction.operand_a);
        //    #1;
        //    $display("Result:           %8b", out);
        //    if (flags_i != flags_o)
        //        $display("Bad Flag Values\n");
        //end : testRES

        //for (int i = 0; i < 20; i++) begin : testSWAP
        //    instruction.operand_a = getRandOperand();
        //    instruction.operand_b = getRandOperand();
        //    instruction.opcode    = SWAP;
        //    shuffleFlags();
        //    $display("Swapping nibbles for %4b %4b", instruction.operand_a[7:4], instruction.operand_a[3:0]);
        //    $display("Expected:            %4b %4b", instruction.operand_a[3:0], instruction.operand_a[7:4]);
        //    #1;
        //    $display("Result:              %4b %4b", out[7:4], out[3:0]);
        //    if ({flags_o.N, flags_o.H, flags_o.C} != 3'b000 || flags_o.Z != (out == 8'd0))
        //        $display("Bad Flag Values\n");
        //end : testSWAP

        $finish();
    end
    /* verilator lint_on WIDTHEXPAND */
    /* verilator lint_on WIDTHTRUNC */

endmodule : gb_cpu_alu_tb
