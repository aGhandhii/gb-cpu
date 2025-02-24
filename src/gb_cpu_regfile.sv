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
module gb_cpu_regfile (
    input logic clk,
    logic reset,
    regfile_r8_t alu_req,
    logic [7:0] alu_data,
    alu_flags_t alu_flags,
    logic alu_wren,
    regfile_r16_t idu_req,
    logic [15:0] idu_data,
    logic idu_wren,
    regfile_r8_t data_bus_req,
    logic [7:0] data_bus_data,
    logic data_bus_wren,
    regfile_r16_t overwrite_req,
    logic overwrite_wren,
    logic set_adj,
    logic add_adj_pc,
    logic write_interrupt_vector,
    logic [7:0] interrupt_vector,
    logic restart_cmd,
    output regfile_t registers
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

    // Standardize ALU flags to the F register
    logic [7:0] flagRegNext;
    assign flagRegNext = {alu_flags.Z, alu_flags.N, alu_flags.H, alu_flags.C, 4'h0};

    // Reduce redundancy, takes ALU and IDU requests then returns the output
    // if either request overwrites the existing value.
    // In hardware, this creates a priority scheme - we implement it with the
    // ALU at the highest level: in practice, there should never be multiple
    // drive requests at a time
    function automatic logic [7:0] setNegedgeValue(
        logic [7:0] data_in, regfile_r8_t r8, logic [7:0] data_a, regfile_r8_t r8_a, logic wren_a, logic [7:0] data_b,
        regfile_r8_t r8_b, logic wren_b, logic [7:0] data_c, regfile_r8_t r8_c, logic wren_c);
        if (wren_a && (r8 == r8_a)) return data_a;
        else if (wren_b && (r8 == r8_b)) return data_b;
        else if (wren_c && (r8 == r8_c)) return data_c;
        else return data_in;
    endfunction : setNegedgeValue

    // Handle resets, IR updates, and special operations
    always_ff @(posedge clk) begin
        if (reset) begin
            registers.ir     <= 8'd0;
            registers.a      <= 8'd0;
            registers.f      <= 8'd0;
            registers.b      <= 8'd0;
            registers.c      <= 8'd0;
            registers.d      <= 8'd0;
            registers.e      <= 8'd0;
            registers.h      <= 8'd0;
            registers.l      <= 8'd0;
            registers.sp_lo  <= 8'd0;
            registers.sp_hi  <= 8'd0;
            registers.pc_lo  <= 8'd0;
            registers.pc_hi  <= 8'd0;
            registers.tmp_lo <= 8'd0;
            registers.tmp_hi <= 8'd0;
        end else begin

            registers.ir    <= ir_updated;

            registers.a     <= (overwrite_wren && (overwrite_req == REG_AF)) ? registers.tmp_hi : registers.a;
            registers.f     <= (overwrite_wren && (overwrite_req == REG_AF)) ? registers.tmp_lo : registers.f;
            registers.b     <= (overwrite_wren && (overwrite_req == REG_BC)) ? registers.tmp_hi : registers.b;
            registers.c     <= (overwrite_wren && (overwrite_req == REG_BC)) ? registers.tmp_lo : registers.c;
            registers.d     <= (overwrite_wren && (overwrite_req == REG_DE)) ? registers.tmp_hi : registers.d;
            registers.e     <= (overwrite_wren && (overwrite_req == REG_DE)) ? registers.tmp_lo : registers.e;
            registers.h     <= (overwrite_wren && (overwrite_req == REG_HL)) ? registers.tmp_hi : registers.h;
            registers.l     <= (overwrite_wren && (overwrite_req == REG_HL)) ? registers.tmp_lo : registers.l;
            registers.sp_lo <= (overwrite_wren && (overwrite_req == REG_SP)) ? registers.tmp_lo : registers.sp_lo;
            registers.sp_hi <= (overwrite_wren && (overwrite_req == REG_SP)) ? registers.tmp_hi : registers.sp_hi;

            if (write_interrupt_vector) begin
                registers.pc_lo <= interrupt_vector;
                registers.pc_hi <= 8'd0;
            end else begin
                registers.pc_lo <= (overwrite_wren && (overwrite_req == REG_PC)) ? registers.tmp_lo : registers.pc_lo;
                registers.pc_hi <= (overwrite_wren && (overwrite_req == REG_PC)) ? registers.tmp_hi : registers.pc_hi;
            end

            if (add_adj_pc) begin
                {registers.tmp_hi, registers.tmp_lo} <= ({registers.pc_hi, registers.pc_lo} - 16'd1) + {registers.tmp_hi, registers.tmp_lo};
            end else begin
                registers.tmp_lo <= registers.tmp_lo;
                registers.tmp_hi <= set_adj ? {8{registers.tmp_lo[7]}} : registers.tmp_hi;
            end

        end
    end

    // Handle data bus, ALU, and IDU write requests
    always_ff @(negedge clk) begin
        /* verilog_format: off */
        ir_updated          <= ((data_bus_req == REG_IR) && data_bus_wren) ? data_bus_data : registers.ir;

        if ((idu_req_lo == REG_F || idu_req_hi == REG_F) && idu_wren)
            registers.f     <= setNegedgeValue(registers.f,      REG_F,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        else
            registers.f     <= flagRegNext;

        registers.a         <= setNegedgeValue(registers.a,      REG_A,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.b         <= setNegedgeValue(registers.b,      REG_B,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.c         <= setNegedgeValue(registers.c,      REG_C,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.d         <= setNegedgeValue(registers.d,      REG_D,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.e         <= setNegedgeValue(registers.e,      REG_E,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.h         <= setNegedgeValue(registers.h,      REG_H,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.l         <= setNegedgeValue(registers.l,      REG_L,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.sp_lo     <= setNegedgeValue(registers.sp_lo,  REG_SP_L,  alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.sp_hi     <= setNegedgeValue(registers.sp_hi,  REG_SP_H,  alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.pc_lo     <= setNegedgeValue(registers.pc_lo,  REG_PC_L,  alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.pc_hi     <= setNegedgeValue(registers.pc_hi,  REG_PC_H,  alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);


        if ((data_bus_req == REG_TMP_L) && data_bus_wren)
            registers.tmp_lo <= data_bus_data;
        else
            registers.tmp_lo <= setNegedgeValue(registers.tmp_lo, REG_TMP_L, alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);

        if (restart_cmd)
            registers.tmp_hi <= 8'd0;
        else if ((data_bus_req == REG_TMP_H) && data_bus_wren)
            registers.tmp_hi <= data_bus_data;
        else
            registers.tmp_hi <= setNegedgeValue(registers.tmp_hi, REG_TMP_H, alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);

        /* verilog_format: on */
    end

endmodule : gb_cpu_regfile
/* verilator lint_on MULTIDRIVEN */
