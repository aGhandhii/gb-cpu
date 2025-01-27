import gb_cpu_common_pkg::*;
/* Register File for the gameboy CPU

Inputs:
    clk         - which one? do we do off-cycle writes?
    reset       - system reset
    data8_i     - 8 bit data input
    reg8_rd     - 8 bit register to read from
    reg8_wr     - 8 bit register to write to
    wren8       - write enable for reg8_wr
    data16_i    - 16 bit data input
    reg16_rd    - 16 bit register to read from
    reg16_wr    - 16 bit register to write to
    wren16      - write enable for reg16_wr
    flags_i     - flags from the alu

Outputs:
    reg_a       - value from the 8 bit accumulator register
    reg8_o      - read-requested 8 bit register value
    reg16_o     - read-requested 16 bit register value
    flags_o     - flags to feed into the alu
*/
module gb_cpu_regfile (
    input logic clk,
    reset,
    wren8,
    wren16,
    input logic [7:0] data8_i,
    input logic [15:0] data16_i,
    input alu_flags_t flags_i,
    input regfile_r8_t reg8_rd,
    reg8_wr,
    input regfile_r16_t reg16_rd,
    reg16_wr,
    output logic [7:0] reg_a,
    reg8_o,
    output logic [15:0] reg16_o,
    output alu_flags_t flags_o
);

    // Explicitly Declare Registers
    logic [15:0] sp, pc;
    logic [7:0] ir, ie, a, b, c, d, e, h, l, f;
    assign reg_a = a;
    assign flags_o.Z = f[7];
    assign flags_o.N = f[6];
    assign flags_o.H = f[5];
    assign flags_o.C = f[4];

    // Combinational logic: reads
    always_comb begin
        // Handle Reads
        case (reg8_rd)
            REG_B:   reg8_o = b;
            REG_C:   reg8_o = c;
            REG_D:   reg8_o = d;
            REG_E:   reg8_o = e;
            REG_H:   reg8_o = h;
            REG_L:   reg8_o = l;
            REG_IE:  reg8_o = ie;
            REG_IF:  reg8_o = ir;
            default: reg8_o = 8'hxx;
        endcase
        case (reg16_rd)
            REG_AF:  reg16_o = {a, f};
            REG_BC:  reg16_o = {b, c};
            REG_DE:  reg16_o = {d, e};
            REG_HL:  reg16_o = {h, l};
            REG_SP:  reg16_o = sp;
            REG_PC:  reg16_o = pc;
            default: reg16_o = 16'hxxxx;
        endcase
    end

    // Synchronous logic: writes and reset
    always_ff @(posedge clk) begin
        if (reset) begin
            sp <= 16'd0;
            pc <= 16'd0;
            ir <= 8'd0;
            ie <= 8'd0;
            a  <= 8'd0;
            b  <= 8'd0;
            c  <= 8'd0;
            d  <= 8'd0;
            e  <= 8'd0;
            h  <= 8'd0;
            l  <= 8'd0;
            f  <= 8'd0;
        end else begin
            // Update Flags
            f <= {flags_i.Z, flags_i.N, flags_i.H, flags_i.C, 4'h0};
            // Handle Writes
            case (reg8_wr)
                REG_B:  b <= (wren8 ? data8_i : b);
                REG_C:  c <= (wren8 ? data8_i : c);
                REG_D:  d <= (wren8 ? data8_i : d);
                REG_E:  e <= (wren8 ? data8_i : e);
                REG_H:  h <= (wren8 ? data8_i : h);
                REG_L:  l <= (wren8 ? data8_i : l);
                REG_IE: ie <= (wren8 ? data8_i : ie);
                REG_IF: ir <= (wren8 ? data8_i : ir);
            endcase
            case (reg16_wr)
                REG_AF: {a, f} <= (wren16 ? data16_i : {a, f});
                REG_BC: {b, c} <= (wren16 ? data16_i : {b, c});
                REG_DE: {d, e} <= (wren16 ? data16_i : {d, e});
                REG_HL: {h, l} <= (wren16 ? data16_i : {h, l});
                REG_SP: sp <= (wren16 ? data16_i : sp);
                REG_PC: pc <= (wren16 ? data16_i : pc);
            endcase
        end
    end

endmodule : gb_cpu_regfile
