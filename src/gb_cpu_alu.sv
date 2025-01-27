import gb_cpu_common_pkg::*;
/* ALU module for the gameboy CPU

Handles 8-bit operations and sets flags
    Z = Zero Flag
    N = Subtract Flag
    H = Half-Carry Flag
    C = Carry Flag

Inputs:
    instruction - contains operands and opcode
    flags_i     - flags from previous operation

Outputs:
    out         - 8-bit result
    flags_o     - flag results from operation
*/
module gb_cpu_alu (
    alu_instruction_t instruction,
    input alu_flags_t flags_i,
    output logic [7:0] out,
    output alu_flags_t flags_o
);
    always_comb begin
        case (instruction.opcode)
            ALU_NOP: begin
                out = instruction.operand_a;
                flags_o.C = flags_i.C;
                flags_o.N = flags_i.N;
                flags_o.H = flags_i.H;
            end
            ADD: begin
                {flags_o.C, out} = {1'b0, instruction.operand_a} + {1'b0, instruction.operand_b};
                flags_o.N = 1'b0;
                flags_o.H = ({1'b0, instruction.operand_a[3:0]} + {1'b0, instruction.operand_b[3:0]}) > 5'h0F;
            end
            ADC: begin
                {flags_o.C, out} = {1'b0, instruction.operand_a} + {1'b0, instruction.operand_b} + {8'h00, flags_i.C};
                flags_o.N = 1'b0;
                flags_o.H   = ({1'b0, instruction.operand_a[3:0]} + {1'b0, instruction.operand_b[3:0]} + {4'h0, flags_i.C}) > 5'h0F;
            end
            SUB: begin
                {flags_o.C, out} = {instruction.operand_a[7], instruction.operand_a} - {instruction.operand_b[7], instruction.operand_b};
                flags_o.N = 1'b1;
                flags_o.H = ({1'b0, instruction.operand_a[3:0]} + {1'b0, instruction.operand_b[3:0]}) > 5'h0F;
            end
            SBC: begin
                {flags_o.C, out} = {instruction.operand_a[7], instruction.operand_a} - {instruction.operand_b[7], instruction.operand_b} - {8'h00, flags_i.C};
                flags_o.N = 1'b1;
                flags_o.H   = ({1'b0, instruction.operand_a[3:0]} + {1'b0, instruction.operand_b[3:0]} + {4'h0, flags_i.C}) > 5'h0F;
            end
            CP: begin
                out = instruction.operand_a;
                {flags_o.C, 8'hxx} = {instruction.operand_a[7], instruction.operand_a} - {instruction.operand_b[7], instruction.operand_b};
                flags_o.N = 1'b1;
                flags_o.H = ({1'b0, instruction.operand_a[3:0]} + {1'b0, instruction.operand_b[3:0]}) > 5'h0F;
            end
            INC: begin
                {flags_o.C, out} = {1'b0, instruction.operand_a} + 9'd1;
                flags_o.N = 1'b0;
                flags_o.H = ({1'b0, instruction.operand_a[3:0]} + 5'd1) > 5'h0F;
                flags_o.C = flags_i.C;
            end
            DEC: begin
                {flags_o.C, out} = {1'b0, instruction.operand_a} - 9'd1;
                flags_o.N = 1'b1;
                flags_o.H = ({1'b0, instruction.operand_a[3:0]} - 5'd1) > 5'h0F;
                flags_o.C = flags_i.C;
            end
            AND: begin
                out = instruction.operand_a & instruction.operand_b;
                flags_o.N = 1'b0;
                flags_o.H = 1'b1;
                flags_o.C = 1'b0;
            end
            OR: begin
                out = instruction.operand_a | instruction.operand_b;
                flags_o.N = 1'b0;
                flags_o.H = 1'b0;
                flags_o.C = 1'b0;
            end
            XOR: begin
                out = instruction.operand_a ^ instruction.operand_b;
                flags_o.N = 1'b0;
                flags_o.H = 1'b0;
                flags_o.C = 1'b0;
            end
            CCF: begin
                out = 8'bxxxx_xxxx;
                flags_o.N = 1'b0;
                flags_o.H = 1'b0;
                flags_o.C = ~flags_i.C;
            end
            SCF: begin
                out = 8'bxxxx_xxxx;
                flags_o.N = 1'b0;
                flags_o.H = 1'b0;
                flags_o.C = 1'b1;
            end
            DAA: begin
                flags_o.N = flags_i.N;
                flags_o.H = 1'b0;
                if (flags_i.N) begin
                    case ({
                        flags_i.C, flags_i.H
                    })
                        00: begin
                            out = instruction.operand_a;
                            flags_o.C = 1'b0;
                        end
                        01: begin
                            out = instruction.operand_a - 8'h06;
                            flags_o.C = (8'h06 > instruction.operand_a);
                        end
                        10: begin
                            out = instruction.operand_a - 8'h60;
                            flags_o.C = (8'h60 > instruction.operand_a);
                        end
                        11: begin
                            out = instruction.operand_a - 8'h66;
                            flags_o.C = (8'h66 > instruction.operand_a);
                        end
                        default: begin
                            out = 8'bxxxx_xxxx;
                            flags_o.C = 1'bx;
                        end
                    endcase
                end else begin
                    case ({
                        (flags_i.C || (instruction.operand_a[7:4] > 4'h9)),
                        (flags_i.H || (instruction.operand_a[3:0] > 4'h9))
                    })
                        00: begin
                            out = instruction.operand_a;
                            flags_o.C = 1'b0;
                        end
                        01: {flags_o.C, out} = {1'b0, instruction.operand_a} + 9'h006;
                        10: {flags_o.C, out} = {1'b0, instruction.operand_a} + 9'h060;
                        11: {flags_o.C, out} = {1'b0, instruction.operand_a} + 9'h066;
                        default: begin
                            out = 8'bxxxx_xxxx;
                            flags_o.C = 1'bx;
                        end
                    endcase
                end
            end
            CPL: begin
                out = ~instruction.operand_a;
                flags_o.N = 1'b1;
                flags_o.H = 1'b1;
                flags_o.C = flags_i.C;
            end
            SLA: begin
                out = {instruction.operand_a[6:0], 1'b0};
                flags_o.N = 1'b0;
                flags_o.H = 1'b0;
                flags_o.C = instruction.operand_a[7];
            end
            SRA: begin
                out = {instruction.operand_a[7], instruction.operand_a[7:1]};
                flags_o.N = 1'b0;
                flags_o.H = 1'b0;
                flags_o.C = instruction.operand_a[0];  // Carry is low-bit
            end
            SRL: begin
                out = {1'b0, instruction.operand_a[7:1]};
                flags_o.N = 1'b0;
                flags_o.H = 1'b0;
                flags_o.C = instruction.operand_a[0];  // Carry is low-bit
            end
            RL, RLA: begin
                out = {instruction.operand_a[6:0], instruction.operand_a[7]};
                flags_o.N = 1'b0;
                flags_o.H = 1'b0;
                flags_o.C = instruction.operand_a[7];
            end
            RLC, RLCA: begin
                out = {instruction.operand_a[6:0], flags_i.C};
                flags_o.N = 1'b0;
                flags_o.H = 1'b0;
                flags_o.C = instruction.operand_a[7];
            end
            RR, RRA: begin
                out = {1'b0, instruction.operand_a[7:1]};
                flags_o.N = 1'b0;
                flags_o.H = 1'b0;
                flags_o.C = instruction.operand_a[0];  // Carry is low-bit
            end
            RRC, RRCA: begin
                out = {flags_i.C, instruction.operand_a[7:1]};
                flags_o.N = 1'b0;
                flags_o.H = 1'b0;
                flags_o.C = instruction.operand_a[0];  // Carry is low-bit
            end
            BIT: begin
                out = 8'bxxxx_xxxx;
                flags_o.N = 1'b0;
                flags_o.H = 1'b1;
                flags_o.C = flags_i.C;
            end
            SET: begin
                out = instruction.operand_a;
                out[instruction.operand_b[2:0]] = 1'b1;
                flags_o.N = flags_i.N;
                flags_o.H = flags_i.H;
                flags_o.C = flags_i.C;
            end
            RES: begin
                out = instruction.operand_a;
                out[instruction.operand_b[2:0]] = 1'b0;
                flags_o.N = flags_i.N;
                flags_o.H = flags_i.H;
                flags_o.C = flags_i.C;
            end
            SWAP: begin
                out = {instruction.operand_a[3:0], instruction.operand_a[7:4]};
                flags_o.C = 1'b0;
                flags_o.H = 1'b0;
                flags_o.N = 1'b0;
            end
            default: begin
                out       = 8'bxxxx_xxxx;
                flags_o.C = 1'bx;
                flags_o.H = 1'bx;
                flags_o.N = 1'bx;
            end
        endcase
    end

    always_comb begin : setZeroFlag
        if (instruction.opcode == BIT) flags_o.Z = ~instruction.operand_a[instruction.operand_b[2:0]];
        else if (instruction.opcode == ALU_NOP || instruction.opcode == SET || instruction.opcode == RES)
            flags_o.Z = flags_i.Z;
        else if (instruction.opcode == RRCA || instruction.opcode == RLCA || instruction.opcode == RRA || instruction.opcode == RLA)
            flags_o.Z = 1'b0;
        else flags_o.Z = (out == 8'h00);
    end : setZeroFlag

endmodule : gb_cpu_alu
