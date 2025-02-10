import gb_cpu_common_pkg::*;
/* Register File for the gameboy CPU

Stores the registers and handles read/write operations.

The regfile gets write requests from the following sources:
  - ALU
  - IDU
  - data bus
  - CPU special instructions (set adjustment, overwrite the stack pointer)

There should never be a condition where multiple sources try and write to a
single source. Regardless, a priority scheme is implemented

The data bus can only write to the IR and TEMP registers, and the write is
performed at the positive edge of the clock. For all other write requests, the
writes are performed at the negative edge to resolve outputs before the next
positive edge.
    - for example, if we drive register A over the data bus but also write to
      it in the same m-cycle, the write needs to occur first so our updated
      register value is on the bus at the next positive edge

Inputs:
    clk             - Machine Clock
    reset           - System Reset

    alu_req         - 8 bit register
    alu_data        - 8 bit value
    alu_flags       - Flag output from the ALU
    alu_wren        - Write Enable for the ALU
    alu_skip_flags  - Do not update flags in the F register

    idu_req         - 16 bit register
    idu_data        - 16 bit value
    idu_wren        - Write Enable for the IDU

    data_bus_req    - 8 bit register (only relevant if IR or TMP)
    data_bus_data   - 8 bit value
    data_bus_wren   - Mirrors the 'drive_data_bus' signal from the top level

    set_adj         - Set the adjustment
    overwrite_sp    - Set the Stack Pointer to the TEMP register

Outputs:
    registers       - Register File for the CPU, all stored as 8-bit values
*/
module gb_cpu_regfile (
    input logic clk,
    logic reset,
    regfile_r8_t alu_req,
    logic [7:0] alu_data,
    alu_flags_t alu_flags,
    logic alu_wren,
    logic alu_skip_flags,
    regfile_r16_t idu_req,
    logic [15:0] idu_data,
    logic idu_wren,
    regfile_r8_t data_bus_req,
    logic [7:0] data_bus_data,
    logic data_bus_wren,
    logic set_adj,
    logic overwrite_sp,
    output regfile_t registers
);

    // Split IDU requests into 8-bit register counterparts
    regfile_r8_t idu_req_lo, idu_req_hi;
    assign idu_req_lo = getRegisterLow(idu_req);
    assign idu_req_hi = getRegisterHigh(idu_req);
    logic [7:0] idu_data_lo, idu_data_hi;
    assign idu_data_lo = idu_data[7:0];
    assign idu_data_hi = idu_data[15:8];

    // Reduce redundancy, takes ALU and IDU requests then returns the output
    // if either request will overwrite the existing value
    function automatic logic [7:0] setNegedgeValue(
        logic [7:0] data_in, regfile_r8_t r8, logic [7:0] data_a, regfile_r8_t r8_a, logic wren_a, logic [7:0] data_b,
        regfile_r8_t r8_b, logic wren_b, logic [7:0] data_c, regfile_r8_t r8_c, logic wren_c);
        if (wren_a && (r8 == r8_a)) return data_a;
        else if (wren_b && (r8 == r8_b)) return data_b;
        else if (wren_c && (r8 == r8_c)) return data_c;
        else return data_in;
    endfunction : setNegedgeValue

    // Handle resets, data bus, and special operations
    always_ff @(posedge clk) begin
        if (reset) begin
            registers.a      <= 8'd0;
            registers.f      <= 8'd0;
            registers.b      <= 8'd0;
            registers.c      <= 8'd0;
            registers.d      <= 8'd0;
            registers.e      <= 8'd0;
            registers.h      <= 8'd0;
            registers.l      <= 8'd0;
            registers.ir     <= 8'd0;
            registers.ie     <= 8'd0;
            registers.sp_lo  <= 8'd0;
            registers.sp_hi  <= 8'd0;
            registers.pc_lo  <= 8'd0;
            registers.pc_hi  <= 8'd0;
            registers.tmp_lo <= 8'd0;
            registers.tmp_hi <= 8'd0;
        end else begin
            registers.a      <= registers.a;
            registers.f      <= registers.f;
            registers.b      <= registers.b;
            registers.c      <= registers.c;
            registers.d      <= registers.d;
            registers.e      <= registers.e;
            registers.h      <= registers.h;
            registers.l      <= registers.l;
            registers.ir     <= ((data_bus_req == REG_IR) && data_bus_wren) ? data_bus_data : registers.ir;
            registers.ie     <= registers.ie;  // FIXME
            registers.sp_lo  <= overwrite_sp ? registers.tmp_lo : registers.sp_lo;
            registers.sp_hi  <= overwrite_sp ? registers.tmp_hi : registers.sp_hi;
            registers.pc_lo  <= registers.pc_lo;
            registers.pc_hi  <= registers.pc_hi;
            registers.tmp_lo <= ((data_bus_req == REG_TMP_L) && data_bus_wren) ? data_bus_data : registers.tmp_lo;
            if (set_adj) registers.tmp_hi <= {8{registers.tmp_lo[7]}};
            else registers.tmp_hi <= ((data_bus_req == REG_TMP_H) && data_bus_wren) ? data_bus_data : registers.tmp_hi;
        end
    end

    // Handle ALU and IDU writes
    always_ff @(negedge clk) begin
        /* verilog_format: off */
        registers.a         <= setNegedgeValue(registers.a,      REG_A,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        if (alu_skip_flags)
            registers.f     <= registers.f;
        else
            registers.f     <= setNegedgeValue(registers.f,      REG_F,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.b         <= setNegedgeValue(registers.b,      REG_B,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.c         <= setNegedgeValue(registers.c,      REG_C,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.d         <= setNegedgeValue(registers.d,      REG_D,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.e         <= setNegedgeValue(registers.e,      REG_E,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.h         <= setNegedgeValue(registers.h,      REG_H,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.l         <= setNegedgeValue(registers.l,      REG_L,     alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.ir        <= setNegedgeValue(registers.ir,     REG_IR,    alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.ie        <= setNegedgeValue(registers.ie,     REG_IE,    alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.sp_lo     <= setNegedgeValue(registers.sp_lo,  REG_SP_L,  alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.sp_hi     <= setNegedgeValue(registers.sp_hi,  REG_SP_H,  alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.pc_lo     <= setNegedgeValue(registers.pc_lo,  REG_PC_L,  alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.pc_hi     <= setNegedgeValue(registers.pc_hi,  REG_PC_H,  alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.tmp_lo    <= setNegedgeValue(registers.tmp_lo, REG_TMP_L, alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        registers.tmp_hi    <= setNegedgeValue(registers.tmp_hi, REG_TMP_H, alu_data, alu_req, alu_wren, idu_data_lo, idu_req_lo, idu_wren, idu_data_hi, idu_req_hi, idu_wren);
        /* verilog_format: on */
    end

endmodule : gb_cpu_regfile
