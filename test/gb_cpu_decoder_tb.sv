module gb_cpu_decoder_tb ();

    import gb_cpu_common_pkg::*;

    logic      [7:0] opcode;
    logic            cb_prefix;
    logic            isr_cmd;
    schedule_t       schedule;

    // Instance
    gb_cpu_decoder dut (.*);

    // Testbench
    initial begin
        $dumpfile("gb_cpu_decoder_tb.fst");
        $dumpvars();

        cb_prefix = 1'b0;
        isr_cmd = 1'b0;

        // CONTROL FLOW
        opcode = 8'b11_101001;  // jp hl
        #1;
        opcode = 8'b11_000011;  // jp imm16
        #1;
        opcode = 8'b11_0_00_010;  // jp cond imm16
        #1;
        opcode = 8'b00_011000;  // jr imm8
        #1;
        opcode = 8'b00_1_00_000;  // jr cond imm8
        #1;
        opcode = 8'b11_001101;  // call imm16
        #1;
        opcode = 8'b11_0_00_100;  // call cond imm16
        #1;
        opcode = 8'b11_001001;  // ret
        #1;
        opcode = 8'b11_0_00_000;  // ret cond
        #1;
        opcode = 8'b11_011001;  // reti
        #1;
        opcode = 8'b11_000_111;  // rst
        #1;


        //// misc operations
        //opcode = 8'h00;  // no op
        //#1;
        //opcode = 8'hCB;  // 0xCB next
        //#1;
        //opcode = 8'b01110110;  // halt
        //#1;
        //opcode = 8'b11_110011;  // di
        //#1;
        //opcode = 8'b11_111011;  // ei
        //#1;

        //// accumulator shift operations
        //opcode = 8'b00_000111;
        //#1;
        //opcode = 8'b00_001111;
        //#1;
        //opcode = 8'b00_010111;
        //#1;
        //opcode = 8'b00_011111;
        //#1;

        //// ld b imm8
        //opcode = 8'b00_000_110;
        //#1;

        //// ld [hl] imm8
        //opcode = 8'b00_110_110;
        //#1;

        //// ld [imm8] a
        //opcode = 8'b111_0101_0;
        //#1;

        //// ld a [imm8]
        //opcode = 8'b111_1101_0;
        //#1;

        //// ldh [imm8] a
        //opcode = 8'b111_0000_0;
        //#1;

        //// ldh a [imm8]
        //opcode = 8'b111_1000_0;
        //#1;

        //// ldh a [c]
        //opcode = 8'b111_0001_0;
        //#1;

        //// ldh [c] a
        //opcode = 8'b111_1001_0;
        //#1;

        //// ld [hli] a
        //opcode = 8'b00_10_0010;
        //#1;

        //// ld [hld] a
        //opcode = 8'b00_11_0010;
        //#1;

        //// ld [bc] a
        //opcode = 8'b00_00_0010;
        //#1;

        //// ld a [hli]
        //opcode = 8'b00_10_1010;
        //#1;

        //// ld a [hld]
        //opcode = 8'b00_11_1010;
        //#1;

        //// ld a [bc]
        //opcode = 8'b00_00_1010;
        //#1;

        //// ld [hl] d
        //opcode = 8'b01_110_010;
        //#1;

        //// ld c [hl]
        //opcode = 8'b01_001_110;
        //#1;

        //// ld c h
        //opcode = 8'b01_001_100;
        //#1;

        //// ld de imm16
        //opcode = 8'b00_01_0001;
        //#1;

        //// ld [imm16] sp
        //opcode = 8'b00_001000;
        //#1;

        //// pop de
        //opcode = 8'b11_01_0001;
        //#1;

        //// push bc
        //opcode = 8'b11_00_0101;
        //#1;

        //// ld hl, sp+e
        //opcode = 8'b11_111000;
        //#1;

        //// ld sp, hl
        //opcode = 8'b11_111001;
        //#1;

        //// xor a e
        //opcode    = 8'b10_101_011;
        //#1;
        //// dec d
        //opcode = 8'b00_010_101;
        //#1;
        //// inc [HL]
        //opcode = 8'b00_110_100;
        //#1;

        //// inc SP
        //opcode = 8'b00_11_0011;
        //#1;
        //// dec BC
        //opcode = 8'b00_00_1011;
        //#1;

        //// add HL, BC
        //opcode = 8'b00_00_1001;
        //#1;
        //// add HL, DE
        //opcode = 8'b00_01_1001;
        //#1;

        //// add sp, imm8
        //opcode = 8'b11_101000;
        //#1;

        //isr_cmd   = 1'b1;
        //#1;

        //// Test the 0xCB prefixed operations
        //cb_prefix = 1'b1;
        //opcode = 8'b00_000_000; // rlc  b
        //#1;
        //opcode = 8'b00_001_001; // rrc  c
        //#1;
        //opcode = 8'b00_010_010; // rl   d
        //#1;
        //opcode = 8'b00_011_011; // rr   e
        //#1;
        //opcode = 8'b00_100_100; // sla  h
        //#1;
        //opcode = 8'b00_101_101; // sra  l
        //#1;
        //opcode = 8'b00_110_111; // swap a
        //#1;
        //opcode = 8'b00_111_000; // srl  b
        //#1;
        //opcode = 8'b00_000_110; // rlc  [hl]
        //#1;
        //opcode = 8'b00_001_110; // rrc  [hl]
        //#1;
        //opcode = 8'b00_010_110; // rl   [hl]
        //#1;
        //opcode = 8'b00_011_110; // rr   [hl]
        //#1;
        //opcode = 8'b00_100_110; // sla  [hl]
        //#1;
        //opcode = 8'b00_101_110; // sra  [hl]
        //#1;
        //opcode = 8'b00_110_110; // swap [hl]
        //#1;
        //opcode = 8'b00_111_110; // srl  [hl]
        //#1;
        //opcode = 8'b01_000_000; // bit b
        //#1;
        //opcode = 8'b10_000_001; // res c
        //#1;
        //opcode = 8'b11_000_010; // set d
        //#1;
        //opcode = 8'b01_000_110; // bit [hl]
        //#1;
        //opcode = 8'b10_000_110; // res [hl]
        //#1;
        //opcode = 8'b11_000_110; // set [hl]
        //#1;

        $finish();
    end

endmodule : gb_cpu_decoder_tb
