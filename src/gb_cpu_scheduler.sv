import gb_cpu_common_pkg::*;
/* CISC Scheduler for the gameboy CPU

Synchronous logic to handle instruction incrementation on M-cycles
Combinational logic to avoid race conditions and output control signals

Also handles event-driven cases:
    - Condition Code Checks
    - 0xCB Prefix Requests
    - Interrupt Dispatch Requests

Inputs:
    clk                 - Machine (M) Clock
    reset               - System Reset
    schedule            - the instruction schedule for the current opcode
    curr_m_cycle        - M cycle counter for current instruction
    cond_not_met        - if a condition check was executed but failed
    interrupt_queued    - if the next instruction will be the ISR

Outputs:
    control             - control signals for the next M-cycle
    cb_prefix_o         - if next instruction will be 0xCB prefixed
    isr_cmd             - next instruction will be ISR
*/
module gb_cpu_scheduler (
    input  logic                   clk,
    input  logic                   reset,
    input  schedule_t              schedule,
    input  logic             [2:0] curr_m_cycle,
    input  logic                   cond_not_met,
    input  logic                   interrupt_queued,
    output control_signals_t       control_next,
    output logic             [2:0] next_m_cycle,
    output logic                   cb_prefix_o,
    output logic                   isr_cmd
);

    // Internal Signals
    logic load_from_schedule;

    // Combinational Logic : set control signals
    always_comb begin
        if (load_from_schedule) begin
            if (curr_m_cycle == 3'd0) control_next = schedule.instruction_controls[0];
            else control_next = schedule.instruction_controls[schedule.m_cycles-(curr_m_cycle-3'd1)];
        end else begin
            // Fetch the next instruction and store it in IR, increment PC
            control_next.addr_bus_source        = ADDR_BUS_REG16;
            control_next.addr_bus_source_r8     = regfile_r8_t'(4'hx);
            control_next.addr_bus_source_r16    = REG_PC;
            control_next.data_bus_i_destination = REG_IR;
            control_next.data_bus_o_source      = regfile_r8_t'(4'hx);
            control_next.drive_data_bus         = 1'b0;
            control_next.receive_data_bus       = 1'b1;
            control_next.idu_opcode             = IDU_INC;
            control_next.idu_operand            = REG_PC;
            control_next.idu_destination        = REG_PC;
            control_next.idu_wren               = 1'b1;
            control_next.alu_opcode             = ALU_NOP;
            control_next.alu_operand_a_register = regfile_r8_t'(4'hx);
            control_next.alu_operand_b_register = regfile_r8_t'(4'hx);
            control_next.alu_inc_dec            = 1'bx;
            control_next.alu_destination        = regfile_r8_t'(4'hx);
            control_next.alu_wren               = 1'b0;
            control_next.enable_interrupts      = 1'b0;
            control_next.disable_interrupts     = 1'b0;
            control_next.write_interrupt_vector = 1'b0;
            control_next.clear_interrupt_flag   = 1'b0;
            control_next.rst_cmd                = 1'b0;
            control_next.cc_check               = 1'b0;
            control_next.overwrite_wren         = 1'b0;
            control_next.overwrite_req          = regfile_r16_t'(3'bxxx);
            control_next.set_adj                = 1'b0;
            control_next.add_adj                = 1'b0;
        end
    end

    // Synchronous Logic : update conditions for next m-cycle control signals
    always_ff @(posedge clk) begin
        // Next instruction scheduling
        if (reset | cond_not_met) begin
            // This is a single-cycle instruction
            load_from_schedule <= 1'b0;
            next_m_cycle       <= 3'd0;
            cb_prefix_o        <= 1'b0;
            isr_cmd            <= 1'b0;
        end else if (curr_m_cycle == 3'd0) begin
            // Load the next cycle count
            next_m_cycle       <= schedule.m_cycles;
            // Load in the next instruction
            load_from_schedule <= 1'b1;
            // Check for 0xCB prefixing
            cb_prefix_o        <= schedule.cb_prefix_next ? 1'b1 : 1'b0;
            // Check for ISR request
            if (schedule.cb_prefix_next) isr_cmd <= 1'b0;
            else isr_cmd <= interrupt_queued ? 1'b1 : 1'b0;
        end else begin
            // Decrement the cycle count for the instruction
            next_m_cycle       <= curr_m_cycle - 3'd1;
            // Load in the next instruction
            load_from_schedule <= 1'b1;
            cb_prefix_o        <= cb_prefix_o;
            isr_cmd            <= isr_cmd;
        end
    end

endmodule : gb_cpu_scheduler
