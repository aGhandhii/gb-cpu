import gb_cpu_common_pkg::*;
/* Top level module for the gameboy CPU

Inputs:
    clk     - Machine (M) Clock
    reset   - System Reset
    data_i  - Incoming Data Bus

Outputs:
    addr_o  - Outgoing Address Bus
    data_o  - Outgoing Data Bus
    drive_data_bus - write enable for data out
*/
/* verilator lint_off MULTIDRIVEN */
module gb_cpu (
    input  logic        clk,
    input  logic        reset,
    input  logic [ 7:0] data_i,
    output logic [15:0] addr_o,
    output logic [ 7:0] data_o,
    output logic        drive_data_bus
);

    // Interrupt Master Enable
    logic                   IME;

    // Store register values from the regfile
    regfile_t               registers;

    // Each instruction yields a schedule from the decoder
    schedule_t              schedule;

    // The decoder and scheduler work in tandem; the scheduler handles clock
    // sensitive control information, giving the control signals for the
    // current m-cycle
    logic             [2:0] curr_m_cycle;
    logic                   cond_not_met;
    control_signals_t       curr_controls;
    logic                   cb_prefix;

    // Instructions to feed ALU and IDU
    alu_instruction_t       alu_instruction;
    alu_flags_t             alu_flags_i;
    idu_instruction_t       idu_instruction;
    assign alu_instruction.opcode  = curr_controls.alu_opcode;
    assign alu_flags_i.Z           = registers.f[7];
    assign alu_flags_i.N           = registers.f[6];
    assign alu_flags_i.H           = registers.f[5];
    assign alu_flags_i.C           = registers.f[4];
    assign idu_instruction.operand = getRegister16(registers, curr_controls.idu_operand);
    assign idu_instruction.opcode  = curr_controls.idu_opcode;

    // Store ALU and IDU outputs
    logic       [ 7:0] alu_o;
    alu_flags_t        alu_flags_o;
    logic       [15:0] idu_o;

    // Handle ALU inputs
    always_comb begin : aluInputs
        if (schedule.bit_cmd) begin
            // pass sign-extended 'bit' value as operand_b
            // this is in IR[5:3], so op_b = {5'b00000, IR[5:3]}
            alu_instruction.operand_a = getRegister8(registers, curr_controls.alu_operand_a_register);
            alu_instruction.operand_b = {5'b00000, registers.ir[5:3]};
        end else if (curr_controls.rst_cmd) begin
            // pass adjusted address to tmp_lo
            // for this command we will write addr to tmp_lo, then 0x00 to tmp_hi, then do overwrite_sp
            alu_instruction.operand_a = {2'b00, registers.ir[5:3], 3'b000};
            alu_instruction.operand_b = getRegister8(registers, curr_controls.alu_operand_b_register);
        end else if (curr_controls.alu_inc_dec) begin
            // pass ALU operand b as operand a, and 8'd1 as operand_b
            alu_instruction.operand_a = getRegister8(registers, curr_controls.alu_operand_b_register);
            alu_instruction.operand_b = 8'd1;
        end else begin
            alu_instruction.operand_a = getRegister8(registers, curr_controls.alu_operand_a_register);
            alu_instruction.operand_b = getRegister8(registers, curr_controls.alu_operand_b_register);
        end
    end : aluInputs

    // Handle IME
    logic enable_interrupts_delayed;
    always_ff @(posedge clk) begin
        enable_interrupts_delayed <= curr_controls.enable_interrupts;
        if (reset) IME <= 1'b1;
        else if (curr_controls.disable_interrupts) IME <= 1'b0;
        else if (enable_interrupts_delayed) IME <= 1'b1;
        else IME <= IME;
    end

    // If an instruction had a condition code, we need to check if it was met
    function automatic logic conditionCheck(condition_code_t cc, alu_flags_t flags);
        case (cc)
            COND_NZ: return ~flags.Z;
            COND_Z:  return flags.Z;
            COND_NC: return ~flags.C;
            COND_C:  return flags.C;
            default: return 1'b0;
        endcase
    endfunction : conditionCheck
    assign cond_not_met = curr_controls.cc_check ? conditionCheck(schedule.condition, alu_flags_o) : 1'b0;

    // Handle the output Address Bus
    always_comb begin : addrBusControl
        case (curr_controls.addr_bus_source)
            ADDR_BUS_REG16: addr_o = getRegister16(registers, curr_controls.addr_bus_source_r16);
            ADDR_BUS_REG8:  addr_o = {8'hFF, getRegister8(registers, curr_controls.addr_bus_source_r8)};
            ADDR_BUS_ZERO:  addr_o = 16'd0;
            default:        addr_o = 16'd0;
        endcase
    end : addrBusControl

    // Handle the output Data Bus
    always_comb begin : dataBusControl
        data_o = getRegister8(registers, curr_controls.data_bus_o_source);
        drive_data_bus = curr_controls.drive_data_bus;
    end : dataBusControl


    ///////////////////////
    // CPU SUBCOMPONENTS //
    ///////////////////////

    // Register File
    gb_cpu_regfile gbRegisterFile (
        .clk(clk),
        .reset(reset),
        .alu_req(curr_controls.alu_destination),
        .alu_data(alu_o),
        .alu_flags(alu_flags_o),
        .alu_wren(curr_controls.alu_wren),
        .idu_req(curr_controls.idu_destination),
        .idu_data(idu_o),
        .idu_wren(curr_controls.idu_wren),
        .data_bus_req(curr_controls.data_bus_i_destination),
        .data_bus_data(data_i),
        .data_bus_wren(~curr_controls.drive_data_bus),
        .set_adj(curr_controls.set_adj),
        .overwrite_sp(curr_controls.overwrite_sp),
        .registers(registers)
    );

    // Decoder
    gb_cpu_decoder gbDecoder (
        .opcode(registers.ir),
        .cb_prefix(cb_prefix),
        .schedule(schedule)
    );

    // Scheduler
    gb_cpu_scheduler gbScheduler (
        .clk(clk),
        .reset(reset),
        .schedule(schedule),
        .curr_m_cycle(curr_m_cycle),
        .cond_not_met(cond_not_met),
        .control_next(curr_controls),
        .next_m_cycle(curr_m_cycle),
        .cb_prefix_o(cb_prefix)
    );

    // ALU
    gb_cpu_alu gbALU (
        .instruction(alu_instruction),
        .flags_i(alu_flags_i),
        .out(alu_o),
        .flags_o(alu_flags_o)
    );

    // IDU
    gb_cpu_idu gbIDU (
        .instruction(idu_instruction),
        .out(idu_o)
    );

endmodule : gb_cpu
/* verilator lint_on MULTIDRIVEN */
