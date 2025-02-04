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

Notes:
    - longest possible instruction takes 6 M-cycles
    - we need to schedule 6 M-cycles worth of controls for each instruction
    - use macros?
    - for conditional operations, assume condition is true
        - have external handling for false condition case

*/
module gb_cpu_decoder (
    input logic [7:0]   opcode,
    input logic         cb_prefix,
    output schedule_t   schedule
);

    always_comb begin : decoderCombinationalLogic

        case (cb_prefix)

            1'b0: begin
                case (opcode) inside

                    8'b00_000000: $display("No Op");
                    8'b00_??0001: $display("ld  r16, imm16");
                    8'b00_??0010: $display("ld  [r16mem], a");
                    8'b00_??1010: $display("ld  a, [r16mem]");
                    8'b00_001000: $display("ld  [imm16], sp");
                    8'b00_??0011: $display("inc r16");
                    8'b00_??1011: $display("dec r16");
                    8'b00_??1001: $display("add hl, r16");
                    8'b00_???100: $display("inc r8");
                    8'b00_???101: $display("dec r8");
                    8'b00_???110: $display("ld  r8 imm8");
                    8'b00_000111: $display("rlca");
                    8'b00_001111: $display("rrca");
                    8'b00_010111: $display("rla");
                    8'b00_011111: $display("rra");
                    8'b00_100111: $display("daa");
                    8'b00_101111: $display("cpl");
                    8'b00_110111: $display("scf");
                    8'b00_111111: $display("ccf");
                    8'b00_011000: $display("jr  imm8");
                    8'b00_1??000: $display("jr  cond, imm8");
                    8'b00_010000: $display("stop");  // has a special condition

                    8'b01_??????: begin
                        if (opcode == 8'b01_110110) $display("halt");
                        else $display("ld r8, r8");
                    end

                    8'b10_000_???: $display("add a, r8");
                    8'b10_001_???: $display("adc a, r8");
                    8'b10_010_???: $display("sub a, r8");
                    8'b10_011_???: $display("sbc a, r8");
                    8'b10_100_???: $display("and a, r8");
                    8'b10_101_???: $display("xor a, r8");
                    8'b10_110_???: $display("or  a, r8");
                    8'b10_111_???: $display("cp  a, r8");

                    8'b11_000_110: $display("add a, imm8");
                    8'b11_001_110: $display("adc a, imm8");
                    8'b11_010_110: $display("sub a, imm8");
                    8'b11_011_110: $display("sbc a, imm8");
                    8'b11_100_110: $display("and a, imm8");
                    8'b11_101_110: $display("xor a, imm8");
                    8'b11_110_110: $display("or  a, imm8");
                    8'b11_111_110: $display("cp  a, imm8");

                    8'b11_0??000: $display("ret cond");
                    8'b11_001001: $display("ret");
                    8'b11_011001: $display("reti");
                    8'b11_0??010: $display("jp  cond, imm16");
                    8'b11_000011: $display("jp  imm16");
                    8'b11_101001: $display("jp  hl");
                    8'b11_0??100: $display("call cond, imm16");
                    8'b11_001101: $display("call imm16");
                    8'b11_???111: $display("rst tgt3");

                    8'b11_??0001: $display("pop r16stk");
                    8'b11_??0101: $display("push r16stk");

                    8'b111_0001_0: $display("ldh [c], a");
                    8'b111_0000_0: $display("ldh [imm8], a");
                    8'b111_0101_0: $display("ld  [imm16], a");
                    8'b111_1001_0: $display("ldh a, [c]");
                    8'b111_1000_0: $display("ldh a, [imm8]");
                    8'b111_1101_0: $display("ld  a, [imm16]");

                    8'b11_101000: $display("add sp, imm8");
                    8'b11_111000: $display("ld  hl, sp + imm8");
                    8'b11_111001: $display("ld  sp, hl");

                    8'b11_110011: $display("di");
                    8'b11_111011: $display("ei");

                    8'hD3: $display("Hard Lock");
                    8'hDB: $display("Hard Lock");
                    8'hDD: $display("Hard Lock");
                    8'hE3: $display("Hard Lock");
                    8'hE4: $display("Hard Lock");
                    8'hEB: $display("Hard Lock");
                    8'hEC: $display("Hard Lock");
                    8'hED: $display("Hard Lock");
                    8'hF4: $display("Hard Lock");
                    8'hFC: $display("Hard Lock");
                    8'hFD: $display("Hard Lock");

                    default: $display("Bad Opcode");

                endcase
            end

            1'b1: begin
                case (opcode) inside

                    8'b00_000_???: $display("rlc r8");
                    8'b00_001_???: $display("rrc r8");
                    8'b00_010_???: $display("rl  r8");
                    8'b00_011_???: $display("rr  r8");
                    8'b00_100_???: $display("sla r8");
                    8'b00_101_???: $display("sra r8");
                    8'b00_110_???: $display("swap r8");
                    8'b00_111_???: $display("srl r8");

                    8'b01_???_???: $display("bit b3, r8");
                    8'b10_???_???: $display("res b3, r8");
                    8'b11_???_???: $display("set b3, r8");

                    default: $display("Bad Opcode");

                endcase
            end

            default: $display("unknown decoder state!");

        endcase

    end : decoderCombinationalLogic

endmodule : gb_cpu_decoder
