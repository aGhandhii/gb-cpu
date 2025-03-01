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

    // Emulate Memory
    logic [7:0] memory[65536];

    always_ff @(posedge clk) memory[addr_o] <= drive_data_bus ? data_o : memory[addr_o];

    always_comb begin
        data_i = memory[addr_o];
        reg_IF = memory[16'hFF0F];
        reg_IE = memory[16'hFFFF];
    end

    //// print blargg test results
    //always_ff @(posedge clk)
    //    if (memory[16'hFF02] == 8'h81) begin
    //        $write("%s", memory[16'hFF01]);
    //        memory[16'hFF02] <= 8'd0;
    //    end

    // Interrupt Flag
    always_ff @(posedge clk)
        if (clear_interrupt_flag)
            if (reg_IF[0]) memory[16'hFF0F] <= reg_IF ^ 8'h01;
            else if (reg_IF[1]) memory[16'hFF0F] <= reg_IF ^ 8'h02;
            else if (reg_IF[2]) memory[16'hFF0F] <= reg_IF ^ 8'h04;
            else if (reg_IF[3]) memory[16'hFF0F] <= reg_IF ^ 8'h08;
            else if (reg_IF[4]) memory[16'hFF0F] <= reg_IF ^ 8'h10;
            else memory[16'hFF0F] <= reg_IF;

    // Help with conditional prints
    logic cond_fail;
    always_ff @(posedge clk) cond_fail <= dut.curr_controls.cc_check ? dut.cond_not_met : 1'b0;

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    initial begin

        for (int i = 0; i < 65536; i++) memory[i] = 8'h00;

        memory[16'hFF44] = 8'h90;

        $readmemh("./test/roms/11-op-a-hl.gb", memory, 0, 32768);

        $dumpfile("gb_cpu_tb.fst");
        $dumpvars();

        reset = 1'b1;
        @(posedge clk);
        #1;
        reset = 1'b0;

        repeat (19999999) begin
            #1;
            @(posedge clk);
            if (dut.registers.ir != 8'hCB || (dut.registers.ir == 8'hCB && dut.cb_prefix == 1'b1))
                if ((dut.curr_m_cycle == 3'd0)&&(dut.schedule.m_cycles == 3'd0) || (dut.curr_m_cycle == 3'd1)&&(dut.schedule.m_cycles != 3'd0) || cond_fail) begin

                    logic [15:0] addr, addr1, addr2, addr3;

                    if (dut.curr_controls.idu_destination == REG_PC && dut.curr_controls.idu_operand == REG_PC && dut.curr_controls.idu_opcode == IDU_INC) begin
                        addr  = {dut.registers.pc_hi, dut.registers.pc_lo};
                        addr1 = {dut.registers.pc_hi, dut.registers.pc_lo} + 16'd1;
                        addr2 = {dut.registers.pc_hi, dut.registers.pc_lo} + 16'd2;
                        addr3 = {dut.registers.pc_hi, dut.registers.pc_lo} + 16'd3;
                        #2;  // let values resolve
                    end else begin
                        #2;  // let values resolve
                        addr  = {dut.registers.pc_hi, dut.registers.pc_lo} - 16'd1;
                        addr1 = {dut.registers.pc_hi, dut.registers.pc_lo};
                        addr2 = {dut.registers.pc_hi, dut.registers.pc_lo} + 16'd1;
                        addr3 = {dut.registers.pc_hi, dut.registers.pc_lo} + 16'd2;
                    end

                    $display(
                        "A:%02x F:%02x B:%02x C:%02x D:%02x E:%02x H:%02x L:%02x SP:%02x%02x PC:%04x PCMEM:%02x,%02x,%02x,%02x",
                        dut.registers.a, dut.registers.f, dut.registers.b, dut.registers.c, dut.registers.d,
                        dut.registers.e, dut.registers.h, dut.registers.l, dut.registers.sp_hi, dut.registers.sp_lo,
                        cond_fail ? {dut.registers.pc_hi, dut.registers.pc_lo} : ({dut.registers.pc_hi, dut.registers.pc_lo} - 16'd1),
                        memory[addr], memory[addr1], memory[addr2], memory[addr3]);
                end
        end

        $finish();
    end

endmodule : gb_cpu_tb
