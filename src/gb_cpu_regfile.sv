import gb_cpu_common_pkg::*;
/* Register File for the gameboy CPU

Stores the registers and handles read/write operations.

The regfile gets write requests from the following sources:
  - ALU
  - IDU
  - Data Bus
  - Special CPU Operations
    - Set 'adjustment' value for signed arithmetic
    - Overwrite a 16 bit register with the contents in TEMP
    - Set the Program Counter to an Interrupt Vector

There should never be a condition where multiple sources try and write to a
single source. Regardless, a priority scheme is implemented.

The data bus can only write to the IR and TEMP registers.

Inputs:
    clk                     - Machine Clock
    reset                   - System Reset

    alu_req                 - 8 bit Register
    alu_data                - 8 bit Value
    alu_flags               - Flags from the ALU
    alu_wren                - Write Enable for the ALU

    idu_req                 - 16 bit Register
    idu_data                - 16 bit Value
    idu_wren                - Write Enable for the IDU

    data_bus_req            - 8 bit Register (IR or TMP)
    data_bus_data           - 8 bit Value
    data_bus_wren           - If We Write the Incoming Value on the Data Bus

    overwrite_req           - 16 Bit Register to be Overwritten by TEMP Register
    overwrite_wren          - Write TEMP Register Contents to Another 16-bit Register

    set_adj                 - Set the Adjustment
    add_adj_pc              - Set PC to Sum of PC and TMP, for Relative Jump

    write_interrupt_vector  - Overwrite PC with Interrupt Vector
    interrupt_vector        - Highest Priority Interrupt Vector

    restart_cmd             - Clear TMP_HI Register

Outputs:
    registers               - Register File for the CPU, Stored as 8-bit Values
*/
/* verilator lint_off MULTIDRIVEN */
/* verilog_format: off */
module gb_cpu_regfile (
    input logic         clk,
    input logic         reset,
    input regfile_r8_t  alu_req,
    input logic [7:0]   alu_data,
    input alu_flags_t   alu_flags,
    input logic         alu_wren,
    input regfile_r16_t idu_req,
    input logic [15:0]  idu_data,
    input logic         idu_wren,
    input regfile_r8_t  data_bus_req,
    input logic [7:0]   data_bus_data,
    input logic         data_bus_wren,
    input regfile_r16_t overwrite_req,
    input logic         overwrite_wren,
    input logic         set_adj,
    input logic         add_adj_pc,
    input logic         write_interrupt_vector,
    input logic [7:0]   interrupt_vector,
    input logic         restart_cmd,
    output regfile_t    registers
);

    // Obtain next value for IR at negedge, but apply at posedge
    logic [7:0] ir_updated;

    // Split IDU requests into 8-bit register counterparts
    regfile_r8_t idu_req_lo, idu_req_hi;
    assign idu_req_lo = getRegisterLow(idu_req);
    assign idu_req_hi = getRegisterHigh(idu_req);
    logic [7:0] idu_data_lo, idu_data_hi;
    assign idu_data_lo = idu_data[7:0];
    assign idu_data_hi = idu_data[15:8];

    // Split Overwrite requests into 8-bit register counterparts
    regfile_r8_t overwrite_req_lo, overwrite_req_hi;
    assign overwrite_req_lo = getRegisterLow(overwrite_req);
    assign overwrite_req_hi = getRegisterHigh(overwrite_req);

    // Standardize ALU flags to the F register
    logic [7:0] flagRegNext;
    assign flagRegNext = {alu_flags.Z, alu_flags.N, alu_flags.H, alu_flags.C, 4'h0};

    function automatic logic [7:0] multiSourceWrite(
        logic [7:0] data_in, regfile_r8_t r8,
        logic [7:0] data_a,  regfile_r8_t r8_a, logic wren_a,
        logic [7:0] data_b = 8'hxx,  regfile_r8_t r8_b = regfile_r8_t'(4'hx), logic wren_b = 1'b0
    );
        if      (wren_a && (r8 == r8_a)) return data_a;
        else if (wren_b && (r8 == r8_b)) return data_b;
        else                             return data_in;
    endfunction : multiSourceWrite

    // Handle resets, IDU write requests, IR updates, and special operations
    always_ff @(posedge clk) begin
        if (reset) begin
            registers.ir     <= 8'h00;
            registers.a      <= 8'h01;
            registers.f      <= 8'hB0;
            registers.b      <= 8'h00;
            registers.c      <= 8'h13;
            registers.d      <= 8'h00;
            registers.e      <= 8'hD8;
            registers.h      <= 8'h01;
            registers.l      <= 8'h4D;
            registers.sp_hi  <= 8'hFF;
            registers.sp_lo  <= 8'hFE;
            registers.pc_hi  <= 8'h01;
            registers.pc_lo  <= 8'h00;
            registers.tmp_hi <= 8'd0;
            registers.tmp_lo <= 8'd0;
        end else begin

            registers.ir        <= ir_updated;

            registers.a         <= multiSourceWrite(registers.a,     REG_A,    registers.tmp_hi, overwrite_req_hi, overwrite_wren, idu_data_hi, idu_req_hi, idu_wren);
            registers.f         <= multiSourceWrite(registers.f,     REG_F,    registers.tmp_lo, overwrite_req_lo, overwrite_wren, idu_data_lo, idu_req_lo, idu_wren);
            registers.b         <= multiSourceWrite(registers.b,     REG_B,    registers.tmp_hi, overwrite_req_hi, overwrite_wren, idu_data_hi, idu_req_hi, idu_wren);
            registers.c         <= multiSourceWrite(registers.c,     REG_C,    registers.tmp_lo, overwrite_req_lo, overwrite_wren, idu_data_lo, idu_req_lo, idu_wren);
            registers.d         <= multiSourceWrite(registers.d,     REG_D,    registers.tmp_hi, overwrite_req_hi, overwrite_wren, idu_data_hi, idu_req_hi, idu_wren);
            registers.e         <= multiSourceWrite(registers.e,     REG_E,    registers.tmp_lo, overwrite_req_lo, overwrite_wren, idu_data_lo, idu_req_lo, idu_wren);
            registers.h         <= multiSourceWrite(registers.h,     REG_H,    registers.tmp_hi, overwrite_req_hi, overwrite_wren, idu_data_hi, idu_req_hi, idu_wren);
            registers.l         <= multiSourceWrite(registers.l,     REG_L,    registers.tmp_lo, overwrite_req_lo, overwrite_wren, idu_data_lo, idu_req_lo, idu_wren);
            registers.sp_hi     <= multiSourceWrite(registers.sp_hi, REG_SP_H, registers.tmp_hi, overwrite_req_hi, overwrite_wren, idu_data_hi, idu_req_hi, idu_wren);
            registers.sp_lo     <= multiSourceWrite(registers.sp_lo, REG_SP_L, registers.tmp_lo, overwrite_req_lo, overwrite_wren, idu_data_lo, idu_req_lo, idu_wren);

            if (write_interrupt_vector) begin
                registers.pc_hi <= 8'd0;
                registers.pc_lo <= interrupt_vector;
            end else begin
                registers.pc_hi <= multiSourceWrite(registers.pc_hi, REG_PC_H, registers.tmp_hi, overwrite_req_hi, overwrite_wren, idu_data_hi, idu_req_hi, idu_wren);
                registers.pc_lo <= multiSourceWrite(registers.pc_lo, REG_PC_L, registers.tmp_lo, overwrite_req_lo, overwrite_wren, idu_data_lo, idu_req_lo, idu_wren);
            end

            if (add_adj_pc) begin
                {registers.tmp_hi, registers.tmp_lo} <= ({registers.pc_hi, registers.pc_lo} - 16'd1) + {registers.tmp_hi, registers.tmp_lo};
            end else if (set_adj) begin
                registers.tmp_hi <= {8{registers.tmp_lo[7]}};
                registers.tmp_lo <= registers.tmp_lo;
            end else begin
                registers.tmp_hi <= multiSourceWrite(registers.tmp_hi, REG_TMP_H, idu_data_hi, idu_req_hi, idu_wren);
                registers.tmp_lo <= multiSourceWrite(registers.tmp_lo, REG_TMP_L, idu_data_lo, idu_req_lo, idu_wren);
            end

        end
    end

    // Handle data bus and ALU write requests
    always_ff @(negedge clk) begin

        ir_updated          <= ((data_bus_req == REG_IR) && data_bus_wren) ? data_bus_data : registers.ir;

        registers.f         <= flagRegNext;

        registers.a         <= multiSourceWrite(registers.a,     REG_A,    alu_data, alu_req, alu_wren);
        registers.b         <= multiSourceWrite(registers.b,     REG_B,    alu_data, alu_req, alu_wren);
        registers.c         <= multiSourceWrite(registers.c,     REG_C,    alu_data, alu_req, alu_wren);
        registers.d         <= multiSourceWrite(registers.d,     REG_D,    alu_data, alu_req, alu_wren);
        registers.e         <= multiSourceWrite(registers.e,     REG_E,    alu_data, alu_req, alu_wren);
        registers.h         <= multiSourceWrite(registers.h,     REG_H,    alu_data, alu_req, alu_wren);
        registers.l         <= multiSourceWrite(registers.l,     REG_L,    alu_data, alu_req, alu_wren);
        registers.sp_hi     <= multiSourceWrite(registers.sp_hi, REG_SP_H, alu_data, alu_req, alu_wren);
        registers.sp_lo     <= multiSourceWrite(registers.sp_lo, REG_SP_L, alu_data, alu_req, alu_wren);
        registers.pc_hi     <= multiSourceWrite(registers.pc_hi, REG_PC_H, alu_data, alu_req, alu_wren);
        registers.pc_lo     <= multiSourceWrite(registers.pc_lo, REG_PC_L, alu_data, alu_req, alu_wren);

        if (restart_cmd)
            registers.tmp_hi <= 8'd0;
        else if ((data_bus_req == REG_TMP_H) && data_bus_wren)
            registers.tmp_hi <= data_bus_data;
        else
            registers.tmp_hi <= multiSourceWrite(registers.tmp_hi, REG_TMP_H, alu_data, alu_req, alu_wren);

        if ((data_bus_req == REG_TMP_L) && data_bus_wren)
            registers.tmp_lo <= data_bus_data;
        else
            registers.tmp_lo <= multiSourceWrite(registers.tmp_lo, REG_TMP_L, alu_data, alu_req, alu_wren);

    end

endmodule : gb_cpu_regfile
/* verilog_format: on */
/* verilator lint_on MULTIDRIVEN */
