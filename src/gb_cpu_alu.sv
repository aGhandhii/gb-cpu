import gb_cpu_common_pkg::*;
/* ALU module for the gameboy CPU

Handles 8-bit operations and sets flags

Inputs:
    instruction: contains operand registers and ALU opcode
    carry_in: current carry flag - used for certain rotations

Outputs:
    out  - 8-bit result
    Z    - Zero Flag
    N    - Subtract Flag
    H    - Half-Carry Flag
    C    - Carry Flag
*/
module gb_cpu_alu (
    alu_instruction_t instruction,
    input logic carry_in,
    output logic [7:0] out,
    output logic Z,
    N,
    H,
    C
);
    always_comb begin
        case (instruction.opcode)
            ADD: begin
                out = instruction.operand_a + instruction.operand_b + carry_in;
                N   = 1'b0;
                H   = ({1'b0, instruction.operand_a[3:0]} + {1'b0, instruction.operand_b[3:0]}) > 5'h0F;
                C   = ({1'b0, instruction.operand_a} + {1'b0, instruction.operand_b}) > 9'h0FF;
            end
            SUB: begin
                out = instruction.operand_a - instruction.operand_b;
                N   = 1'b1;
                H   = ({1'b0, instruction.operand_a[3:0]} + {1'b0, instruction.operand_b[3:0]}) > 5'h0F;
                C   = ({1'b0, instruction.operand_a} + {1'b0, instruction.operand_b}) > 9'h0FF;
            end
            AND: begin
                out = instruction.operand_a & instruction.operand_b;
                N   = 1'b0;
                H   = 1'b1;
                C   = 1'b0;
            end
            OR: begin
                out = instruction.operand_a | instruction.operand_b;
                N   = 1'b0;
                H   = 1'b0;
                C   = 1'b0;
            end
            XOR: begin
                out = instruction.operand_a ^ instruction.operand_b;
                N   = 1'b0;
                H   = 1'b0;
                C   = 1'b0;
            end
            SHIFT_L: begin
                out = {instruction.operand_a[6:0], 1'b0};
                N   = 1'b0;
                H   = 1'b0;
                C   = instruction.operand_a[7];
            end
            SHIFT_R_ARITH: begin
                out = {instruction.operand_a[7], instruction.operand_a[7:1]};
                N   = 1'b0;
                H   = 1'b0;
                C   = instruction.operand_a[0];  // Carry is low-bit
            end
            SHIFT_R_LOGIC: begin
                out = {1'b0, instruction.operand_a[7:1]};
                N   = 1'b0;
                H   = 1'b0;
                C   = instruction.operand_a[0];  // Carry is low-bit
            end
            ROTL: begin
                out = {instruction.operand_a[6:0], instruction.operand_a[7]};
                N   = 1'b0;
                H   = 1'b0;
                C   = instruction.operand_a[7];
            end
            ROTL_CARRY: begin
                out = {instruction.operand_a[6:0], carry_in};
                N   = 1'b0;
                H   = 1'b0;
                C   = instruction.operand_a[7];
            end
            ROTR: begin
                out = {1'b0, instruction.operand_a[7:1]};
                N   = 1'b0;
                H   = 1'b0;
                C   = instruction.operand_a[0];  // Carry is low-bit
            end
            ROTR_CARRY: begin
                out = {carry_in, instruction.operand_a[7:1]};
                N   = 1'b0;
                H   = 1'b0;
                C   = instruction.operand_a[0];  // Carry is low-bit
            end
            BIT: begin
                N = 1'b0;
                H = 1'b1;
            end
            SET: begin
                out = instruction.operand_a;
                out[instruction.operand_b[2:0]] = 1'b1;
            end
            RESET: begin
                out = instruction.operand_a;
                out[instruction.operand_b[2:0]] = 1'b0;
            end
            SWAP: begin
                out = {instruction.operand_a[3:0], instruction.operand_a[7:4]};
                C   = 1'b0;
                H   = 1'b0;
                N   = 1'b0;
            end
            default: begin
                out = 8'bxxxx_xxxx;
                C   = 1'bx;
                H   = 1'bx;
                N   = 1'bx;
            end
        endcase
    end

    always_comb begin : setZeroFlag
        if (instruction.opcode == BIT) Z = ~instruction.operand_a[instruction.operand_b[2:0]];
        else Z = (out == 0);
    end : setZeroFlag

endmodule : gb_cpu_alu
