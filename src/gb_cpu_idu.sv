import gb_cpu_common_pkg::*;
/* IDU module for the gameboy CPU

Specialized unit for 16-bit increment and decrement operations

Inputs:
    instruction - Contains 16-bit Input Data and Opcode

Outputs:
    out         - 16-bit Output Data
*/
module gb_cpu_idu (
    input  idu_instruction_t        instruction,
    output logic             [15:0] out
);

    always_comb begin
        case (instruction.opcode)
            IDU_NOP: out = instruction.operand;
            IDU_INC: out = instruction.operand + 16'd1;
            IDU_DEC: out = instruction.operand - 16'd1;
            default: out = 16'hXXXX;
        endcase
    end

endmodule : gb_cpu_idu
