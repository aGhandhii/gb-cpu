import gb_cpu_common_pkg::*;
/* CISC Scheduler for the gameboy CPU

Synchronous logic to handle instruction incrementation on M-cycles

Also handles event-driven cases:
    - condition code not met
    - CB prefixing

Inputs:
    clk                 - Machine (M) Clock
    reset               - System Reset
    schedule            - the instruction schedule for the current opcode
    curr_m_cycle        - M cycle counter for current instruction
    cond_not_met        - if a condition check was executed but failed

Outputs:
    control             - control signals for the next M-cycle
    cb_prefix_o         - if next instruction will be 0xCB prefixed
*/
module gb_cpu_scheduler (
    input  logic                   clk,
    input  logic                   reset,
    input  schedule_t              schedule,
    input  logic             [2:0] curr_m_cycle,
    input  logic                   cond_not_met,
    output control_signals_t       control_next,
    output logic             [2:0] next_m_cycle,
    output logic                   cb_prefix_o
);

    always_ff @(posedge clk) begin

        // Next instruction scheduling
        if (reset | cond_not_met) begin
            // Fetch the next instruction and store it in IR, increment PC
            control_next.addr_bus_source        <= ADDR_BUS_REG16;
            control_next.addr_bus_source_r8     <= regfile_r8_t'(4'hx);
            control_next.addr_bus_source_r16    <= REG_PC;
            control_next.data_bus_i_destination <= REG_IR;
            control_next.data_bus_o_source      <= regfile_r8_t'(4'hx);
            control_next.drive_data_bus         <= 1'b0;
            control_next.idu_opcode             <= IDU_INC;
            control_next.idu_operand            <= REG_PC;
            control_next.idu_destination        <= REG_PC;
            control_next.idu_wren               <= 1'b1;
            control_next.alu_opcode             <= ALU_NOP;
            control_next.alu_operand_a_source   <= alu_operand_source_t'(2'bxx);
            control_next.alu_operand_b_source   <= alu_operand_source_t'(2'bxx);
            control_next.alu_operand_a_register <= regfile_r8_t'(4'hx);
            control_next.alu_operand_b_register <= regfile_r8_t'(4'hx);
            control_next.alu_inc_dec            <= 1'bx;
            control_next.alu_destination        <= regfile_r8_t'(4'hx);
            control_next.alu_wren               <= 1'b0;
            control_next.enable_interrupts      <= 1'b0;
            control_next.disable_interrupts     <= 1'b0;
            control_next.rst_cmd                <= 1'b0;
            control_next.cc_check               <= 1'b0;
            control_next.overwrite_sp           <= 1'b0;
            control_next.set_adj                <= 1'b0;
            control_next.add_adj                <= 1'b0;
            // This is a single-cycle instruction
            next_m_cycle                        <= 3'd0;
            cb_prefix_o                         <= 1'b0;
        end else if (curr_m_cycle == 3'd0) begin
            // Load the next cycle count
            next_m_cycle <= schedule.m_cycles;
            // Load in the next instruction
            control_next <= schedule.instruction_controls[0];
            // Check for 0xCB prefixing
            cb_prefix_o  <= schedule.cb_prefix_next ? 1'b1 : 1'b0;
        end else begin
            // Decrement the cycle count for the instruction
            next_m_cycle <= curr_m_cycle - 3'd1;
            // Load in the next instruction
            control_next <= schedule.instruction_controls[schedule.m_cycles-(curr_m_cycle-3'd1)];
            cb_prefix_o  <= cb_prefix_o;
        end

    end

endmodule : gb_cpu_scheduler
