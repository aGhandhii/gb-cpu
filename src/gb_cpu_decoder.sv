import gb_cpu_common_pkg::*;
/* Instruction Decoder for the gameboy CPU

Reads in CISC Instructions and sets control signals accordingly

Based on the Pan Docs 'CPU Instruction Set' page
https://gbdev.io/pandocs/CPU_Instruction_Set.html

Inputs:
    opcode      - 8-bit instruction from IR
    cb_prefix   - If instruction is 0xCB prefixed

Outputs:
    schedule    - M-cycle schedule for decoded instruction
*/
module gb_cpu_decoder (
    input  logic      [7:0] opcode,
    input  logic            cb_prefix,
    output schedule_t       schedule
);

    import gb_cpu_decoder_pkg::*;

    always_comb begin : decoderCombinationalLogic

        if (cb_prefix == 1'b0) begin
            case (opcode) inside

                //8'b00_000000: // No Op
                //8'b00_??_0001: // ld  r16, imm16
                //8'b00_??_0010: // ld  [r16mem], a
                //8'b00_??_1010: // ld  a, [r16mem]
                //8'b00_001000: // ld  [imm16], sp
                8'b00_??_0011: schedule = arithmetic16Bit(.incDec(1'b1), .r16(opcode_r16_t'(opcode[5:4])));  // inc r16
                8'b00_??_1011: schedule = arithmetic16Bit(.incDec(1'b0), .r16(opcode_r16_t'(opcode[5:4])));  // dec r16
                8'b00_??_1001:
                schedule = arithmetic16Bit(.addHL(1'b1), .r16(opcode_r16_t'(opcode[5:4])));  // add hl, r16
                8'b00_???_100:
                schedule = arithmetic8Bit(.alu_opcode(INC), .r8(opcode_r8_t'(opcode[5:3])), .incDec(1'b1));  // inc r8
                8'b00_???_101:
                schedule = arithmetic8Bit(.alu_opcode(DEC), .r8(opcode_r8_t'(opcode[5:3])), .incDec(1'b1));  // dec r8
                //8'b00_???110: // ld  r8 imm8
                //8'b00_000111: // rlca
                //8'b00_001111: // rrca
                //8'b00_010111: // rla
                //8'b00_011111: // rra
                8'b00_100111: schedule = arithmetic8Bit(.alu_opcode(DAA), .writeResult(1'b0));  // daa
                8'b00_101111: schedule = arithmetic8Bit(.alu_opcode(CPL), .writeResult(1'b0));  // cpl
                8'b00_110111: schedule = arithmetic8Bit(.alu_opcode(SCF), .writeResult(1'b0));  // scf
                8'b00_111111: schedule = arithmetic8Bit(.alu_opcode(CCF), .writeResult(1'b0));  // ccf
                //8'b00_011000: // jr  imm8
                //8'b00_1??000: // jr  cond, imm8
                //8'b00_010000: // stop

                //8'b01_??????: begin
                //    if (opcode == 8'b01_110110) // halt
                //    else // ld r8, r8
                //end

                8'b10_000_???:
                schedule = arithmetic8Bit(.alu_opcode(ADD), .r8(opcode_r8_t'(opcode[2:0])));  // add a, r8
                8'b10_001_???:
                schedule = arithmetic8Bit(.alu_opcode(ADC), .r8(opcode_r8_t'(opcode[2:0])));  // adc a, r8
                8'b10_010_???:
                schedule = arithmetic8Bit(.alu_opcode(SUB), .r8(opcode_r8_t'(opcode[2:0])));  // sub a, r8
                8'b10_011_???:
                schedule = arithmetic8Bit(.alu_opcode(SBC), .r8(opcode_r8_t'(opcode[2:0])));  // sbc a, r8
                8'b10_100_???:
                schedule = arithmetic8Bit(.alu_opcode(AND), .r8(opcode_r8_t'(opcode[2:0])));  // and a, r8
                8'b10_101_???:
                schedule = arithmetic8Bit(.alu_opcode(XOR), .r8(opcode_r8_t'(opcode[2:0])));  // xor a, r8
                8'b10_110_???: schedule = arithmetic8Bit(.alu_opcode(OR), .r8(opcode_r8_t'(opcode[2:0])));  // or  a, r8
                8'b10_111_???: schedule = arithmetic8Bit(.alu_opcode(CP), .r8(opcode_r8_t'(opcode[2:0])));  // cp  a, r8

                8'b11_000_110: schedule = arithmetic8Bit(.alu_opcode(ADD), .immediate_op(1'b1));  // add a, imm8
                8'b11_001_110: schedule = arithmetic8Bit(.alu_opcode(ADC), .immediate_op(1'b1));  // adc a, imm8
                8'b11_010_110: schedule = arithmetic8Bit(.alu_opcode(SUB), .immediate_op(1'b1));  // sub a, imm8
                8'b11_011_110: schedule = arithmetic8Bit(.alu_opcode(SBC), .immediate_op(1'b1));  // sbc a, imm8
                8'b11_100_110: schedule = arithmetic8Bit(.alu_opcode(AND), .immediate_op(1'b1));  // and a, imm8
                8'b11_101_110: schedule = arithmetic8Bit(.alu_opcode(XOR), .immediate_op(1'b1));  // xor a, imm8
                8'b11_110_110: schedule = arithmetic8Bit(.alu_opcode(OR), .immediate_op(1'b1));  // or  a, imm8
                8'b11_111_110: schedule = arithmetic8Bit(.alu_opcode(CP), .immediate_op(1'b1));  // cp  a, imm8

                //8'b11_0??000: // ret cond
                //8'b11_001001: // ret
                //8'b11_011001: // reti
                //8'b11_0??010: // jp  cond, imm16
                //8'b11_000011: // jp  imm16
                //8'b11_101001: // jp  hl
                //8'b11_0??100: // call cond, imm16
                //8'b11_001101: // call imm16
                //8'b11_???111: // rst tgt3

                //8'b11_??0001: // pop r16stk
                //8'b11_??0101: // push r16stk

                //8'b111_0001_0: // ldh [c], a
                //8'b111_0000_0: // ldh [imm8], a
                //8'b111_0101_0: // ld  [imm16], a
                //8'b111_1001_0: // ldh a, [c]
                //8'b111_1000_0: // ldh a, [imm8]
                //8'b111_1101_0: // ld  a, [imm16]

                8'b11_101000: schedule = arithmetic16Bit(.addSP(1'b1));  // add sp, imm8
                //8'b11_111000: // ld  hl, sp + imm8
                //8'b11_111001: // ld  sp, hl

                //8'b11_110011: // di
                //8'b11_111011: // ei

                //8'hD3: // Hard Lock
                //8'hDB: // Hard Lock
                //8'hDD: // Hard Lock
                //8'hE3: // Hard Lock
                //8'hE4: // Hard Lock
                //8'hEB: // Hard Lock
                //8'hEC: // Hard Lock
                //8'hED: // Hard Lock
                //8'hF4: // Hard Lock
                //8'hFC: // Hard Lock
                //8'hFD: // Hard Lock

                default: schedule = emptySchedule();

            endcase

        end else begin
            // 0xCB prefixed operations
            case (opcode) inside

                //8'b00_000_???: // rlc r8
                //8'b00_001_???: // rrc r8
                //8'b00_010_???: // rl  r8
                //8'b00_011_???: // rr  r8
                //8'b00_100_???: // sla r8
                //8'b00_101_???: // sra r8
                //8'b00_110_???: // swap r8
                //8'b00_111_???: // srl r8

                //8'b01_???_???: // bit b3, r8
                //8'b10_???_???: // res b3, r8
                //8'b11_???_???: // set b3, r8

                default: schedule = emptySchedule();

            endcase
        end

    end : decoderCombinationalLogic

endmodule : gb_cpu_decoder
