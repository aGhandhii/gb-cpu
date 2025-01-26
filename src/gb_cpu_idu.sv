import gb_cpu_common_pkg::*;
/* IDU module for the gameboy CPU

Specialized unit for 16-bit increment and decrement operations

Inputs:
    in      - 16-bit input data
    opcode  - operation select for the IDU

Outputs:
    out     - 16-bit output data
*/
module gb_cpu_idu (
    input logic [15:0] in,
    idu_opcode_t opcode,
    output logic [15:0] out
);

    always_comb begin
        case (opcode)
            IDU_NOP: out = in;
            IDU_INC: out = in + 16'd1;
            IDU_DEC: out = in - 16'd1;
            default: out = 16'hXXXX;
        endcase
    end

endmodule : gb_cpu_idu
