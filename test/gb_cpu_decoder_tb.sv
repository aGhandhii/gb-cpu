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

        // ld hl, sp+e
        opcode = 8'b11_111000;
        #1;

        // ld sp, hl
        opcode = 8'b11_111001;
        #1;

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

        $finish();
    end

endmodule : gb_cpu_decoder_tb
