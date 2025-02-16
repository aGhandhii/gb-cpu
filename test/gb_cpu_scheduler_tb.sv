import gb_cpu_common_pkg::*;
/* Instruction Scheduler Testbench */
module gb_cpu_scheduler_tb ();

    logic                   clk;
    logic                   reset;
    schedule_t              schedule;
    logic             [2:0] curr_m_cycle;
    logic                   cond_not_met;
    control_signals_t       control_next;
    logic             [2:0] next_m_cycle;
    logic                   cb_prefix_o;

    assign curr_m_cycle = next_m_cycle;

    gb_cpu_scheduler dut (.*);

    initial begin : toggleClock
        clk = 1'b0;
        forever #10 clk = ~clk;
    end : toggleClock

    task automatic sysReset();
        reset = 1'b1;
        @(posedge clk);
        reset = 1'b0;
    endtask : sysReset

    task automatic buildSchedule();

        schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
        schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
        schedule.instruction_controls[0].addr_bus_source_r16    = REG_AF;
        schedule.instruction_controls[0].data_bus_i_destination = REG_C;
        schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
        schedule.instruction_controls[0].drive_data_bus         = 1'b0;
        schedule.instruction_controls[0].receive_data_bus       = 1'b1;
        schedule.instruction_controls[0].idu_opcode             = IDU_DEC;
        schedule.instruction_controls[0].idu_operand            = REG_PC;
        schedule.instruction_controls[0].idu_destination        = REG_PC;
        schedule.instruction_controls[0].idu_wren               = 1'b1;
        schedule.instruction_controls[0].alu_opcode             = SBC;
        schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
        schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
        schedule.instruction_controls[0].alu_inc_dec            = 1'bx;
        schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
        schedule.instruction_controls[0].alu_wren               = 1'b0;
        schedule.instruction_controls[0].enable_interrupts      = 1'b0;
        schedule.instruction_controls[0].disable_interrupts     = 1'b0;
        schedule.instruction_controls[0].rst_cmd                = 1'b0;
        schedule.instruction_controls[0].cc_check               = 1'b0;

        schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG8;
        schedule.instruction_controls[1].addr_bus_source_r8     = REG_E;
        schedule.instruction_controls[1].addr_bus_source_r16    = regfile_r16_t'(8'hxx);
        schedule.instruction_controls[1].data_bus_i_destination = REG_B;
        schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
        schedule.instruction_controls[1].drive_data_bus         = 1'b0;
        schedule.instruction_controls[1].receive_data_bus       = 1'b1;
        schedule.instruction_controls[1].idu_opcode             = IDU_INC;
        schedule.instruction_controls[1].idu_operand            = REG_BC;
        schedule.instruction_controls[1].idu_destination        = REG_BC;
        schedule.instruction_controls[1].idu_wren               = 1'b1;
        schedule.instruction_controls[1].alu_opcode             = DAA;
        schedule.instruction_controls[1].alu_operand_a_register = REG_A;
        schedule.instruction_controls[1].alu_operand_b_register = REG_E;
        schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
        schedule.instruction_controls[1].alu_destination        = REG_A;
        schedule.instruction_controls[1].alu_wren               = 1'b1;
        schedule.instruction_controls[1].enable_interrupts      = 1'b0;
        schedule.instruction_controls[1].disable_interrupts     = 1'b0;
        schedule.instruction_controls[1].rst_cmd                = 1'b0;
        schedule.instruction_controls[1].cc_check               = 1'b0;

        schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
        schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
        schedule.instruction_controls[2].addr_bus_source_r16    = REG_PC;
        schedule.instruction_controls[2].data_bus_i_destination = REG_H;
        schedule.instruction_controls[2].data_bus_o_source      = regfile_r8_t'(4'hx);
        schedule.instruction_controls[2].drive_data_bus         = 1'b0;
        schedule.instruction_controls[2].receive_data_bus       = 1'b1;
        schedule.instruction_controls[2].idu_opcode             = IDU_DEC;
        schedule.instruction_controls[2].idu_operand            = REG_SP;
        schedule.instruction_controls[2].idu_destination        = REG_PC;
        schedule.instruction_controls[2].idu_wren               = 1'b1;
        schedule.instruction_controls[2].alu_opcode             = RRA;
        schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
        schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
        schedule.instruction_controls[2].alu_inc_dec            = 1'b1;
        schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
        schedule.instruction_controls[2].alu_wren               = 1'b0;
        schedule.instruction_controls[2].enable_interrupts      = 1'b0;
        schedule.instruction_controls[2].disable_interrupts     = 1'b0;
        schedule.instruction_controls[2].rst_cmd                = 1'b1;
        schedule.instruction_controls[2].cc_check               = 1'b1;

    endtask : buildSchedule


    initial begin
        $dumpfile("gb_cpu_scheduler_tb.fst");
        $dumpvars();

        schedule.m_cycles = 3'd2;
        buildSchedule();
        sysReset();
        @(posedge clk);
        schedule.cb_prefix_next = 1'b1;
        repeat (3) @(posedge clk);
        schedule.cb_prefix_next = 1'b0;
        repeat (6) @(posedge clk);

        $finish();
    end

endmodule : gb_cpu_scheduler_tb
