import gb_cpu_common_pkg::*;
/* Top level module for the gameboy CPU

Inputs:
    clk                     - Machine (M) Clock
    reset                   - System Reset
    data_i                  - Incoming Data Bus
    reg_IF                  - Interrupt Flag Register
    reg_IE                  - Interrupt Enable Register

Outputs:
    addr_o                  - Outgoing Address Bus
    data_o                  - Outgoing Data Bus
    drive_data_bus          - Write Enable for Outgoing Data
    clear_interrupt_flag    - Reset Highest Priority Interrupt Flag Bit
*/
/* verilator lint_off MULTIDRIVEN */
module gb_cpu (
    input  logic        clk,
    input  logic        reset,
    input  logic [ 7:0] data_i,
    input  logic [ 7:0] reg_IF,
    input  logic [ 7:0] reg_IE,
    output logic [15:0] addr_o,
    output logic [ 7:0] data_o,
    output logic        drive_data_bus,
    output logic        clear_interrupt_flag
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
    logic                   last_m_cycle;
    logic                   cond_not_met;
    control_signals_t       curr_controls;
    logic                   cb_prefix;
    logic                   isr_cmd;

    // Detect if a cycle is the last for an instruction
    always_comb
        if ((schedule.m_cycles == 3'd0) && (curr_m_cycle == 3'd0)) last_m_cycle = 1'b1;
        else if ((schedule.m_cycles != 3'd0) && (curr_m_cycle == 3'd1)) last_m_cycle = 1'b1;
        else last_m_cycle = 1'b0;

    // Instructions to feed ALU and IDU
    alu_instruction_t alu_instruction;
    alu_flags_t       alu_flags_i;
    idu_instruction_t idu_instruction;
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
            alu_instruction.operand_a = getRegister8(registers, curr_controls.alu_operand_a_register);
            alu_instruction.operand_b = {5'b00000, registers.ir[5:3]};
        end else if (curr_controls.rst_cmd) begin
            // pass adjusted address to tmp_lo
            // for this command we will write addr to tmp_lo, then 0x00 to tmp_hi, then overwrite SP
            alu_instruction.operand_a = {2'b00, registers.ir[5:3], 3'b000};
            alu_instruction.operand_b = getRegister8(registers, curr_controls.alu_operand_b_register);
        end else if (curr_controls.alu_inc_dec) begin
            // pass ALU operand b as operand a; the other operand is irrelevant
            alu_instruction.operand_a = getRegister8(registers, curr_controls.alu_operand_b_register);
            alu_instruction.operand_b = 8'hxx;
        end else begin
            alu_instruction.operand_a = getRegister8(registers, curr_controls.alu_operand_a_register);
            alu_instruction.operand_b = getRegister8(registers, curr_controls.alu_operand_b_register);
        end
    end : aluInputs

    // Handle Flag Updates
    alu_flags_t alu_flags_next;
    always_comb begin : aluFlags
        if (curr_controls.add_adj) alu_flags_next = alu_flags_i;
        else if (cb_prefix) alu_flags_next = alu_flags_o;
        else begin
            // Certain opcodes require special flag modifiers
            case (registers.ir) inside

                8'b00_??_1001: begin
                    // add HL r16
                    // make sure the Z flag is not impacted
                    alu_flags_next.Z = alu_flags_i.Z;
                    alu_flags_next.N = alu_flags_o.N;
                    alu_flags_next.H = alu_flags_o.H;
                    alu_flags_next.C = alu_flags_o.C;
                end

                8'b11_101000, 8'hF8: begin
                    // add sp imm8, ld HL SP+e
                    // force Z to 0
                    alu_flags_next.Z = 1'b0;
                    alu_flags_next.N = alu_flags_o.N;
                    alu_flags_next.H = alu_flags_o.H;
                    alu_flags_next.C = alu_flags_o.C;
                end

                8'b00_011000, 8'b00_1??000, 8'b11_???_111: begin
                    // jr (relative jump) and rst (restart) instructions
                    alu_flags_next = alu_flags_i;
                end

                default: alu_flags_next = alu_flags_o;

            endcase
        end
    end : aluFlags

    // Handle IME register
    logic enable_interrupts_delayed;
    always_ff @(posedge clk) begin
        enable_interrupts_delayed <= curr_controls.enable_interrupts & ~curr_controls.disable_interrupts;
        if (reset) IME <= 1'b0;
        else if (curr_controls.disable_interrupts & ~curr_controls.enable_interrupts) IME <= 1'b0;
        else if (enable_interrupts_delayed) IME <= 1'b1;
        else IME <= IME;
    end

    // Check if the next instruction will be an interrupt
    logic interrupt_queued, interrupt_queued_no_IME;
    assign interrupt_queued = ((IME || (halt & enable_interrupts_delayed)) && ((reg_IF & reg_IE) != 8'd0)) ? 1'b1 : 1'b0;
    assign interrupt_queued_no_IME = (~IME && ((reg_IF & reg_IE) != 8'd0)) ? 1'b1 : 1'b0;
    assign clear_interrupt_flag = curr_controls.clear_interrupt_flag;

    // Additional handling for HALT and the HALT bug
    logic halt, halt_bug_delay;
    assign halt = (registers.ir == 8'h76 && ~isr_cmd && ~cb_prefix) ? 1'b1 : 1'b0;
    always_ff @(posedge clk)
        if (halt & interrupt_queued_no_IME) halt_bug_delay <= 1'b1;
        else halt_bug_delay <= 1'b0;

    // Get the corresponding interrupt_vector from IF
    logic [7:0] interrupt_vector;
    always_comb begin : getInterruptVector
        if (reg_IF[0]) interrupt_vector = 8'h40;
        else if (reg_IF[1]) interrupt_vector = 8'h48;
        else if (reg_IF[2]) interrupt_vector = 8'h50;
        else if (reg_IF[3]) interrupt_vector = 8'h58;
        else if (reg_IF[4]) interrupt_vector = 8'h60;
        else interrupt_vector = 8'h00;
    end : getInterruptVector

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
    // The condition code is always contained in bits [4:3] of the opcode
    condition_code_t opcode_cond;
    assign opcode_cond  = condition_code_t'(registers.ir[4:3]);
    assign cond_not_met = curr_controls.cc_check ? ~conditionCheck(opcode_cond, alu_flags_i) : 1'b0;

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
        drive_data_bus = curr_controls.drive_data_bus;
        data_o = getRegister8(registers, curr_controls.data_bus_o_source);
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
        .alu_flags(alu_flags_next),
        .alu_wren(curr_controls.alu_wren),
        .idu_req(curr_controls.idu_destination),
        .idu_data(idu_o),
        .idu_wren(curr_controls.idu_wren),
        .data_bus_req(curr_controls.data_bus_i_destination),
        .data_bus_data(data_i),
        .data_bus_wren(curr_controls.receive_data_bus),
        .overwrite_req(curr_controls.overwrite_req),
        .overwrite_wren(curr_controls.overwrite_wren),
        .set_adj(curr_controls.set_adj),
        .add_adj_pc(curr_controls.enable_interrupts & curr_controls.disable_interrupts),
        .write_interrupt_vector(curr_controls.write_interrupt_vector),
        .interrupt_vector(interrupt_vector),
        .halt(halt),
        .halt_bug_delay(halt_bug_delay),
        .enable_interrupts_delayed(enable_interrupts_delayed),
        .interrupt_queued(interrupt_queued),
        .interrupt_queued_no_IME(interrupt_queued_no_IME),
        .last_m_cycle(last_m_cycle),
        .restart_cmd(curr_controls.rst_cmd),
        .registers(registers)
    );

    // Decoder
    gb_cpu_decoder gbDecoder (
        .opcode(registers.ir),
        .cb_prefix(cb_prefix),
        .isr_cmd(isr_cmd),
        .schedule(schedule)
    );

    // Scheduler
    gb_cpu_scheduler gbScheduler (
        .clk(clk),
        .reset(reset),
        .schedule(schedule),
        .curr_m_cycle(curr_m_cycle),
        .last_m_cycle(last_m_cycle),
        .cond_not_met(cond_not_met),
        .interrupt_queued(interrupt_queued),
        .control_next(curr_controls),
        .next_m_cycle(curr_m_cycle),
        .cb_prefix_o(cb_prefix),
        .isr_cmd(isr_cmd)
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
