import gb_cpu_common_pkg::*;
/* Instruction Decoder for the gameboy CPU

Reads in CISC Instructions and sets control signals accordingly

Inputs:
    opcode      - 8-bit instruction from IR
    cb_prefix   - If instruction is 0xCB prefixed
    isr_cmd     - If the instruction will be the ISR

Outputs:
    schedule    - Cycle-by-Cycle control signals for the decoded instruction
*/
module gb_cpu_decoder (
    input  logic      [7:0] opcode,
    input  logic            cb_prefix,
    input  logic            isr_cmd,
    output schedule_t       schedule
);

    import gb_cpu_decoder_pkg::*;

    always_comb begin : decoderCombinationalLogic

        /* verilog_format: off */
        if (isr_cmd) begin

            schedule = interruptServiceRoutine();

        end else if (cb_prefix) begin
            case (opcode) inside

                // Rotate and Shift
                8'b00_000_???: schedule = rotateShiftBit(.opcode(RLC),  .r8(opcode_r8_t'(opcode[2:0])), .indirectHL((opcode[2:0] == 3'd6) ? 1'b1 : 1'b0)); // rlc  r8
                8'b00_001_???: schedule = rotateShiftBit(.opcode(RRC),  .r8(opcode_r8_t'(opcode[2:0])), .indirectHL((opcode[2:0] == 3'd6) ? 1'b1 : 1'b0)); // rrc  r8
                8'b00_010_???: schedule = rotateShiftBit(.opcode(RL),   .r8(opcode_r8_t'(opcode[2:0])), .indirectHL((opcode[2:0] == 3'd6) ? 1'b1 : 1'b0)); // rl   r8
                8'b00_011_???: schedule = rotateShiftBit(.opcode(RR),   .r8(opcode_r8_t'(opcode[2:0])), .indirectHL((opcode[2:0] == 3'd6) ? 1'b1 : 1'b0)); // rr   r8
                8'b00_100_???: schedule = rotateShiftBit(.opcode(SLA),  .r8(opcode_r8_t'(opcode[2:0])), .indirectHL((opcode[2:0] == 3'd6) ? 1'b1 : 1'b0)); // sla  r8
                8'b00_101_???: schedule = rotateShiftBit(.opcode(SRA),  .r8(opcode_r8_t'(opcode[2:0])), .indirectHL((opcode[2:0] == 3'd6) ? 1'b1 : 1'b0)); // sra  r8
                8'b00_110_???: schedule = rotateShiftBit(.opcode(SWAP), .r8(opcode_r8_t'(opcode[2:0])), .indirectHL((opcode[2:0] == 3'd6) ? 1'b1 : 1'b0)); // swap r8
                8'b00_111_???: schedule = rotateShiftBit(.opcode(SRL),  .r8(opcode_r8_t'(opcode[2:0])), .indirectHL((opcode[2:0] == 3'd6) ? 1'b1 : 1'b0)); // srl  r8

                // Bit, Set, and Reset
                8'b01_???_???: schedule = rotateShiftBit(.opcode(BIT), .r8(opcode_r8_t'(opcode[2:0])), .indirectHL((opcode[2:0] == 3'd6) ? 1'b1 : 1'b0), .bitSetRes(1'b1)); // bit b3, r8
                8'b10_???_???: schedule = rotateShiftBit(.opcode(RES), .r8(opcode_r8_t'(opcode[2:0])), .indirectHL((opcode[2:0] == 3'd6) ? 1'b1 : 1'b0), .bitSetRes(1'b1)); // res b3, r8
                8'b11_???_???: schedule = rotateShiftBit(.opcode(SET), .r8(opcode_r8_t'(opcode[2:0])), .indirectHL((opcode[2:0] == 3'd6) ? 1'b1 : 1'b0), .bitSetRes(1'b1)); // set b3, r8

                default: schedule = emptySchedule();

            endcase
        end else begin
            case (opcode) inside

                ////////////////
                // 8 Bit LOAD //
                ////////////////
                8'b00_??_1010: begin
                    if (opcode[5:4] == 2'd2)
                        schedule = load8Bit(.sourceReg(opcode_r8_t'(3'o7)), .addrReg(opcode_r16mem_t'(opcode[5:4])), .indirectInc(1'b1)); // ld a, [hli]
                    else if (opcode[5:4] == 2'd3)
                        schedule = load8Bit(.sourceReg(opcode_r8_t'(3'o7)), .addrReg(opcode_r16mem_t'(opcode[5:4])), .indirectDec(1'b1)); // ld a, [hld]
                    else
                        schedule = load8Bit(.sourceReg(opcode_r8_t'(3'o7)), .addrReg(opcode_r16mem_t'(opcode[5:4]))); // ld a, [r16mem]
                end
                8'b00_???_110: begin
                    if (opcode[5:3] == 3'd6)
                        schedule = load8Bit(.immediate(1'b1), .writeToMem(1'b1)); // ld [hl] imm8
                    else
                        schedule = load8Bit(.sourceReg(opcode_r8_t'(opcode[5:3])), .immediate(1'b1)); // ld  r8 imm8
                end
                8'b01_???_???: begin
                    if (opcode == 8'b01_110_110)
                        schedule = miscOp(); // halt
                    else begin
                        // first reg is [HL]
                        if (opcode[5:3] == 3'd6)
                            schedule = load8Bit(.sourceReg(opcode_r8_t'(opcode[2:0])), .addrReg(opcode_r16mem_t'(2'b10)), .writeToMem(1'b1)); // ld [hl], r8
                        // second reg is [HL]
                        else if (opcode[2:0] == 3'd6)
                            schedule = load8Bit(.sourceReg(opcode_r8_t'(opcode[5:3])), .addrReg(opcode_r16mem_t'(2'b10))); // ld r8, [hl]
                        // other cases
                        else
                            schedule = load8Bit(.sourceReg(opcode_r8_t'(opcode[5:3])), .otherReg(opcode_r8_t'(opcode[2:0])), .regToReg(1'b1)); // ld r8, r8
                    end
                end
                8'b00_??_0010: begin
                    if (opcode[5:4] == 2'd2)
                        schedule = load8Bit(.sourceReg(opcode_r8_t'(3'o7)), .addrReg(opcode_r16mem_t'(opcode[5:4])), .indirectInc(1'b1), .writeToMem(1'b1)); // ld  [hli], a
                    else if (opcode[5:4] == 2'd3)
                        schedule = load8Bit(.sourceReg(opcode_r8_t'(3'o7)), .addrReg(opcode_r16mem_t'(opcode[5:4])), .indirectDec(1'b1), .writeToMem(1'b1)); // ld  [hld], a
                    else
                        schedule = load8Bit(.sourceReg(opcode_r8_t'(3'o7)), .addrReg(opcode_r16mem_t'(opcode[5:4])), .writeToMem(1'b1)); // ld  [r16mem], a
                end
                8'b111_0001_0: schedule = load8Bit(.sourceReg(opcode_r8_t'(3'o7)), .writeToMem(1'b1), .offsetAddr(1'b1)); // ldh [c], a
                8'b111_0000_0: schedule = load8Bit(.direct(1'b1), .writeToMem(1'b1), .offsetAddr(1'b1)); // ldh [imm8], a
                8'b111_0101_0: schedule = load8Bit(.direct(1'b1), .writeToMem(1'b1)); // ld  [imm16], a
                8'b111_1001_0: schedule = load8Bit(.sourceReg(opcode_r8_t'(3'o7)), .offsetAddr(1'b1)); // ldh a, [c]
                8'b111_1000_0: schedule = load8Bit(.direct(1'b1), .offsetAddr(1'b1)); // ldh a, [imm8]
                8'b111_1101_0: schedule = load8Bit(.direct(1'b1)); // ld  a, [imm16]

                /////////////////
                // 16 Bit LOAD //
                /////////////////
                8'b00_??_0001: schedule = load16Bit(.sourceReg(opcode_r16_t'(opcode[5:4])), .load16Reg(1'b1)); // ld  r16, imm16
                8'b00_001000:  schedule = load16Bit(.loadStackDirect(1'b1)); // ld  [imm16], sp
                8'b11_111001:  schedule = load16Bit(.loadStackHL(1'b1)); // ld  sp, hl
                8'b11_??_0001: schedule = load16Bit(.stackOpReg(opcode_r16stk_t'(opcode[5:4])), .popOp(1'b1)); // pop r16stk
                8'b11_??_0101: schedule = load16Bit(.stackOpReg(opcode_r16stk_t'(opcode[5:4])), .pushOp(1'b1)); // push r16stk
                8'b11_111000:  schedule = load16Bit(.loadAdjusted(1'b1)); // ld  hl, sp + imm8

                //////////////////////
                // 8 Bit ARITHMETIC //
                //////////////////////
                8'b10_000_???: schedule = arithmetic8Bit(.alu_opcode(ADD), .r8(opcode_r8_t'(opcode[2:0])));  // add a, r8
                8'b10_001_???: schedule = arithmetic8Bit(.alu_opcode(ADC), .r8(opcode_r8_t'(opcode[2:0])));  // adc a, r8
                8'b10_010_???: schedule = arithmetic8Bit(.alu_opcode(SUB), .r8(opcode_r8_t'(opcode[2:0])));  // sub a, r8
                8'b10_011_???: schedule = arithmetic8Bit(.alu_opcode(SBC), .r8(opcode_r8_t'(opcode[2:0])));  // sbc a, r8
                8'b10_100_???: schedule = arithmetic8Bit(.alu_opcode(AND), .r8(opcode_r8_t'(opcode[2:0])));  // and a, r8
                8'b10_101_???: schedule = arithmetic8Bit(.alu_opcode(XOR), .r8(opcode_r8_t'(opcode[2:0])));  // xor a, r8
                8'b10_110_???: schedule = arithmetic8Bit(.alu_opcode(OR),  .r8(opcode_r8_t'(opcode[2:0])));  // or  a, r8
                8'b10_111_???: schedule = arithmetic8Bit(.alu_opcode(CP),  .r8(opcode_r8_t'(opcode[2:0])));  // cp  a, r8

                8'b11_000_110: schedule = arithmetic8Bit(.alu_opcode(ADD), .immediate_op(1'b1));  // add a, imm8
                8'b11_001_110: schedule = arithmetic8Bit(.alu_opcode(ADC), .immediate_op(1'b1));  // adc a, imm8
                8'b11_010_110: schedule = arithmetic8Bit(.alu_opcode(SUB), .immediate_op(1'b1));  // sub a, imm8
                8'b11_011_110: schedule = arithmetic8Bit(.alu_opcode(SBC), .immediate_op(1'b1));  // sbc a, imm8
                8'b11_100_110: schedule = arithmetic8Bit(.alu_opcode(AND), .immediate_op(1'b1));  // and a, imm8
                8'b11_101_110: schedule = arithmetic8Bit(.alu_opcode(XOR), .immediate_op(1'b1));  // xor a, imm8
                8'b11_110_110: schedule = arithmetic8Bit(.alu_opcode(OR),  .immediate_op(1'b1));  // or  a, imm8
                8'b11_111_110: schedule = arithmetic8Bit(.alu_opcode(CP),  .immediate_op(1'b1));  // cp  a, imm8

                8'b00_???_100: schedule = arithmetic8Bit(.alu_opcode(INC), .r8(opcode_r8_t'(opcode[5:3])), .incDec(1'b1));  // inc r8
                8'b00_???_101: schedule = arithmetic8Bit(.alu_opcode(DEC), .r8(opcode_r8_t'(opcode[5:3])), .incDec(1'b1));  // dec r8

                8'b00_100111:  schedule = arithmetic8Bit(.alu_opcode(DAA));  // daa
                8'b00_101111:  schedule = arithmetic8Bit(.alu_opcode(CPL));  // cpl
                8'b00_110111:  schedule = arithmetic8Bit(.alu_opcode(SCF), .writeResult(1'b0));  // scf
                8'b00_111111:  schedule = arithmetic8Bit(.alu_opcode(CCF), .writeResult(1'b0));  // ccf

                ///////////////////////
                // 16 Bit ARITHMETIC //
                ///////////////////////
                8'b00_??_0011: schedule = arithmetic16Bit(.incDec(1'b1), .r16(opcode_r16_t'(opcode[5:4])));  // inc r16
                8'b00_??_1011: schedule = arithmetic16Bit(.incDec(1'b0), .r16(opcode_r16_t'(opcode[5:4])));  // dec r16
                8'b00_??_1001: schedule = arithmetic16Bit(.addHL(1'b1),  .r16(opcode_r16_t'(opcode[5:4])));  // add hl, r16
                8'b11_101000:  schedule = arithmetic16Bit(.addSP(1'b1));  // add sp, imm8

                ////////////
                // ROTATE //
                ////////////
                8'b00_000111:  schedule = rotateShiftBit(.opcode(RLCA), .r8(opcode_r8_t'(3'd7))); // rlca
                8'b00_001111:  schedule = rotateShiftBit(.opcode(RRCA), .r8(opcode_r8_t'(3'd7))); // rrca
                8'b00_010111:  schedule = rotateShiftBit(.opcode(RLA),  .r8(opcode_r8_t'(3'd7))); // rla
                8'b00_011111:  schedule = rotateShiftBit(.opcode(RRA),  .r8(opcode_r8_t'(3'd7))); // rra

                //////////////////
                // CONTROL FLOW //
                //////////////////
                8'b11_000011: schedule = controlFlow(.jump(1'b1)); // jp  imm16
                8'b11_101001: schedule = controlFlow(.jumpHL(1'b1)); // jp  hl
                8'b11_0??010: schedule = controlFlow(.jump(1'b1), .conditional(1'b1)); // jp  cond, imm16
                8'b00_011000: schedule = controlFlow(.jumpRelative(1'b1)); // jr  imm8
                8'b00_1??000: schedule = controlFlow(.jumpRelative(1'b1), .conditional(1'b1)); // jr  cond, imm8
                8'b11_001101: schedule = controlFlow(.call(1'b1)); // call imm16
                8'b11_0??100: schedule = controlFlow(.call(1'b1), .conditional(1'b1)); // call cond, imm16
                8'b11_001001: schedule = controlFlow(.ret(1'b1)); // ret
                8'b11_0??000: schedule = controlFlow(.ret(1'b1), .conditional(1'b1)); // ret cond
                8'b11_011001: schedule = controlFlow(.reti(1'b1)); // reti
                8'b11_???111: schedule = controlFlow(.restart(1'b1)); // rst tgt3

                ///////////////////
                // MISCELLANEOUS //
                ///////////////////
                8'h00:         schedule = miscOp(); // No Op
                8'hCB:         schedule = miscOp(.cbNext(1'b1)); // schedule a 0xCB prefixed instruction next
                8'b11_110011:  schedule = miscOp(.di(1'b1)); // di
                8'b11_111011:  schedule = miscOp(.ei(1'b1)); // ei

                8'h10:         schedule = miscOp(.stop(1'b1)); // stop TODO
                8'hD3, 8'hDB, 8'hDD, 8'hE3, 8'hE4, 8'hEB, 8'hEC, 8'hED, 8'hF4, 8'hFC, 8'hFD: schedule = miscOp(.stop(1'b1)); // Illegal Opcodes TODO

                default: schedule = emptySchedule();

            endcase
        end
        /* verilog_format: on */

    end : decoderCombinationalLogic

endmodule : gb_cpu_decoder
