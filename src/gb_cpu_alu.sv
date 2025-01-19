/* ALU module for the gameboy CPU

Handles 8-bit operations and sets flags

Inputs:
    instruction: contains operand registers and ALU opcode
    CARRY_IN: current carry flag - used for certain rotations

Outputs:
    OUT  - 8-bit result
    Z    - Zero Flag
    N    - Subtract Flag
    H    - Half-Carry Flag
    C    - Carry Flag
*/
import gb_cpu_common_pkg::*;

module gb_cpu_alu (
    gb_instruction_t instruction,
    input logic [7:0] IN_0,
    IN_1,
    input logic CARRY_IN,
    output logic [7:0] OUT,
    output logic Z,
    N,
    H,
    C
);

    always_comb begin
        case (instruction.opcode)
            ADD: begin
                OUT = IN_0 + IN_1;
                N   = 1'b0;
                H   = ({1'b0, IN_0[3:0]} + {1'b0, IN_1[3:0]}) > 5'h0F;
                C   = ({1'b0, IN_0} + {1'b0, IN_1}) > 9'h0FF;
            end
            SUB: begin
                OUT = IN_0 - IN_1;
                N   = 1'b1;
                H   = ({1'b0, IN_0[3:0]} + {1'b0, IN_1[3:0]}) > 5'h0F;
                C   = ({1'b0, IN_0} + {1'b0, IN_1}) > 9'h0FF;
            end
            AND: begin
                OUT = IN_0 & IN_1;
                N   = 1'b0;
                H   = 1'b1;
                C   = 1'b0;
            end
            OR: begin
                OUT = IN_0 | IN_1;
                N   = 1'b0;
                H   = 1'b0;
                C   = 1'b0;
            end
            XOR: begin
                OUT = IN_0 ^ IN_1;
                N   = 1'b0;
                H   = 1'b0;
                C   = 1'b0;
            end
            SHIFT_L: begin
                OUT = {IN_0[6:0], 1'b0};
                N   = 1'b0;
                H   = 1'b0;
                C   = IN_0[7];
            end
            SHIFT_R_ARITH: begin
                OUT = {IN_0[7], IN_0[7:1]};
                N   = 1'b0;
                H   = 1'b0;
                C   = IN_0[0];  // Carry is low-bit
            end
            SHIFT_R_LOGIC: begin
                OUT = {1'b0, IN_0[7:1]};
                N   = 1'b0;
                H   = 1'b0;
                C   = IN_0[0];  // Carry is low-bit
            end
            ROTL: begin
                OUT = {IN_0[6:0], IN_0[7]};
                N   = 1'b0;
                H   = 1'b0;
                C   = IN_0[7];
            end
            ROTL_CARRY: begin
                OUT = {IN_0[6:0], CARRY_IN};
                N   = 1'b0;
                H   = 1'b0;
                C   = IN_0[7];
            end
            ROTR: begin
                OUT = {1'b0, IN_0[7:1]};
                N   = 1'b0;
                H   = 1'b0;
                C   = IN_0[0];  // Carry is low-bit
            end
            ROTR_CARRY: begin
                OUT = {CARRY_IN, IN_0[7:1]};
                N   = 1'b0;
                H   = 1'b0;
                C   = IN_0[0];  // Carry is low-bit
            end
            BIT: begin
                N = 1'b0;
                H = 1'b1;
            end
            SET: begin
                OUT = IN_0;
                OUT[IN_1[2:0]] = 1'b1;
            end
            RESET: begin
                OUT = IN_0;
                OUT[IN_1[2:0]] = 1'b0;
            end
            SWAP: begin
                OUT = {IN_0[3:0], IN_0[7:4]};
                C   = 1'b0;
                H   = 1'b0;
                N   = 1'b0;
            end
            default: begin
                OUT = 8'bxxxx_xxxx;
                C   = 1'bx;
                H   = 1'bx;
                N   = 1'bx;
            end
        endcase
    end

    // Set Zero Flag
    assign Z = (instruction.opcode == BIT) ? (~IN_0[IN_1[2:0]]) : (OUT == 0);

endmodule : gb_cpu_alu
