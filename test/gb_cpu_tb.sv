/* Top level testbench for CPU */
module gb_cpu_tb ();

    logic        clk;
    logic        reset;
    logic [ 7:0] data_i;
    logic [ 7:0] reg_IF;
    logic [ 7:0] reg_IE;
    logic [15:0] addr_o;
    logic [ 7:0] data_o;
    logic        drive_data_bus;
    logic        clear_interrupt_flag;

    gb_cpu dut (.*);

    // Have a timer instance to handle timing interrupts
    logic [7:0] timer_data_o;
    logic irq_timer;

    gb_timer timer (
        .clk(clk),
        .reset(reset),
        .data_i(data_o),
        .addr(addr_o),
        .wren(drive_data_bus),
        .data_o(timer_data_o),
        .irq_timer(irq_timer)
    );

    // Emulate Memory
    /* verilator lint_off MULTIDRIVEN */
    logic [7:0] memory[65536];

    always_ff @(posedge clk) memory[addr_o] <= drive_data_bus ? data_o : memory[addr_o];

    always_comb begin
        if (addr_o >= 16'hFF04 && addr_o <= 16'hFF07) data_i = timer_data_o;
        else data_i = memory[addr_o];
        reg_IF = memory[16'hFF0F];
        reg_IE = memory[16'hFFFF];
    end

    // print blargg test results from Serial Out
    always_ff @(posedge clk)
        if (memory[16'hFF02] == 8'h81) begin
            $write("%s", memory[16'hFF01]);
            memory[16'hFF02] <= 8'd0;
        end

    // Interrupt Flag
    always_ff @(posedge clk)
        if (clear_interrupt_flag)
            if (reg_IF[0]) memory[16'hFF0F] <= reg_IF ^ 8'h01;
            else if (reg_IF[1]) memory[16'hFF0F] <= reg_IF ^ 8'h02;
            else if (reg_IF[2]) memory[16'hFF0F] <= reg_IF ^ 8'h04;
            else if (reg_IF[3]) memory[16'hFF0F] <= reg_IF ^ 8'h08;
            else if (reg_IF[4]) memory[16'hFF0F] <= reg_IF ^ 8'h10;
            else memory[16'hFF0F] <= reg_IF;
    always_ff @(posedge irq_timer) memory[16'hFF0F] <= reg_IF | 8'h04;
    /* verilator lint_on MULTIDRIVEN */

    // Help with conditional prints
    logic cond_fail;
    always_ff @(posedge clk) cond_fail <= dut.curr_controls.cc_check ? dut.cond_not_met : 1'b0;

    // Toggle the Clock
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end


    // Main Test
    initial begin

        for (int i = 0; i < 65536; i++) memory[i] = 8'h00;

        memory[16'hFF44] = 8'h90;

        //$readmemh("./test/roms/blargg/cpu_instrs/02-interrupts.gb", memory, 0, 32768);
        //$readmemh("./test/roms/blargg/cpu_instrs/03-op-sp-hl.gb", memory, 0, 32768);
        $readmemh("./test/roms/blargg/instr_timing.gb", memory, 0, 32768);
        //$readmemh("./test/roms/mooneye/timer/tim11_div_trigger.gb", memory, 0, 32768);

        //memory[16'h0050] = 8'hD9; // reti
        //memory[16'h0100] = 8'h3E; // load imm8 to A
        //memory[16'h0101] = 8'h04;
        //memory[16'h0102] = 8'hE0; // ldh IE A
        //memory[16'h0103] = 8'hFF;
        //memory[16'h0104] = 8'hE0; // ldh IF A
        //memory[16'h0105] = 8'h0F;
        //memory[16'h0106] = 8'hFB; // EI
        //memory[16'h0107] = 8'hCB; // 0xCB prefix
        //memory[16'h0108] = 8'h06;
        //memory[16'h0109] = 8'h76; // halt

        // CURR FAILS
        // C7:8-4 CB 06:57-4 CB 0E:88-4 CB 16:236-4 CB 1E:183-4 CB 26:236-4 CB 2E:88-4

        $dumpfile("gb_cpu_tb.fst");
        $dumpvars();

        reset = 1'b1;
        @(posedge clk);
        #1;
        reset = 1'b0;

        repeat (9999999) begin
            //repeat (99) begin
            #1;
            @(posedge clk);

            // Print output for GameBoy Doctor
            //if (dut.registers.ir != 8'hCB || (dut.registers.ir == 8'hCB && dut.cb_prefix == 1'b1))
            //    if (~(dut.isr_cmd & ~dut.interrupt_queued))
            //        if ((dut.curr_m_cycle == 3'd0)&&(dut.schedule.m_cycles == 3'd0) || (dut.curr_m_cycle == 3'd1)&&(dut.schedule.m_cycles != 3'd0) || cond_fail) begin

            //            logic [15:0] addr, addr1, addr2, addr3;

            //            if (dut.curr_controls.idu_destination == REG_PC && dut.curr_controls.idu_operand == REG_PC && dut.curr_controls.idu_opcode == IDU_INC) begin
            //                addr  = {dut.registers.pc_hi, dut.registers.pc_lo};
            //                addr1 = {dut.registers.pc_hi, dut.registers.pc_lo} + 16'd1;
            //                addr2 = {dut.registers.pc_hi, dut.registers.pc_lo} + 16'd2;
            //                addr3 = {dut.registers.pc_hi, dut.registers.pc_lo} + 16'd3;
            //                #2;  // let values resolve
            //            end else begin
            //                #2;  // let values resolve
            //                addr  = {dut.registers.pc_hi, dut.registers.pc_lo} - 16'd1;
            //                addr1 = {dut.registers.pc_hi, dut.registers.pc_lo};
            //                addr2 = {dut.registers.pc_hi, dut.registers.pc_lo} + 16'd1;
            //                addr3 = {dut.registers.pc_hi, dut.registers.pc_lo} + 16'd2;
            //            end

            //            $display(
            //                "A:%02x F:%02x B:%02x C:%02x D:%02x E:%02x H:%02x L:%02x SP:%02x%02x PC:%04x PCMEM:%02x,%02x,%02x,%02x",
            //                dut.registers.a, dut.registers.f, dut.registers.b, dut.registers.c, dut.registers.d,
            //                dut.registers.e, dut.registers.h, dut.registers.l, dut.registers.sp_hi, dut.registers.sp_lo,
            //                (cond_fail | dut.interrupt_queued) ? {dut.registers.pc_hi, dut.registers.pc_lo} : ({dut.registers.pc_hi, dut.registers.pc_lo} - 16'd1),
            //                memory[addr], memory[addr1], memory[addr2], memory[addr3]);
            //        end

        end

        $finish();
    end

endmodule : gb_cpu_tb
