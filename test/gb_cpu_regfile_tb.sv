import gb_cpu_common_pkg::*;
/* Register File Testbench */
module gb_cpu_regfile_tb ();

    // IO Replication
    logic clk;
    logic reset;
    regfile_r8_t alu_req;
    logic [7:0] alu_data;
    alu_flags_t alu_flags;
    logic alu_wren;
    logic alu_skip_flags;
    regfile_r16_t idu_req;
    logic [15:0] idu_data;
    logic idu_wren;
    regfile_r8_t data_bus_req;
    logic [7:0] data_bus_data;
    logic data_bus_wren;
    logic set_adj;
    logic overwrite_sp;
    regfile_t registers;

    initial begin
        clk = 1'b1;
        forever #2 clk = ~clk;
    end

    gb_cpu_regfile dut (.*);

    task automatic sysReset();
        reset = 1;
        #1;
        @(posedge clk);
        #1;
        reset = 0;
    endtask : sysReset

    task automatic aluWrite(regfile_r8_t req, logic [7:0] data);
        alu_req  = req;
        alu_data = data;
        alu_wren = 1'b1;
        #1;
        @(negedge clk);
        #1;
        alu_wren = 0;
    endtask : aluWrite

    task automatic iduWrite(regfile_r16_t req, logic [15:0] data);
        idu_req  = req;
        idu_data = data;
        idu_wren = 1'b1;
        #1;
        @(negedge clk);
        #1;
        idu_wren = 1'b0;
    endtask : iduWrite

    task automatic dataBusWrite(regfile_r8_t req, logic [7:0] data);
        data_bus_req  = req;
        data_bus_data = data;
        data_bus_wren = 1'b1;
        #1;
        @(posedge clk);
        #1;
        data_bus_wren = 1'b0;
    endtask : dataBusWrite

    initial begin
        $dumpfile("gb_cpu_regfile_tb.fst");
        $dumpvars();

        sysReset();

        alu_flags.Z = 1'b1;
        alu_skip_flags = 1'b0;
        #1;

        aluWrite(REG_D, 8'hFE);
        aluWrite(REG_A, 8'hAB);

        //iduWrite(REG_PC, 16'hDEAD);
        //dataBusWrite(REG_IR, 8'hCB);

        idu_data = 16'hDEAD;
        idu_wren = 1;
        idu_req = REG_PC;
        data_bus_wren = 1'b1;
        data_bus_data = 8'hCB;
        data_bus_req = REG_IR;
        #1;
        @(posedge clk);
        #1;
        idu_wren = 0;
        data_bus_wren = 0;

        iduWrite(REG_TMP, 16'hBEEF);
        overwrite_sp = 1'b1;
        #1;
        @(posedge clk);
        #1;
        overwrite_sp = 1'b0;

        aluWrite(REG_TMP_L, 8'h7F);
        set_adj = 1'b1;
        #1;
        @(negedge clk);
        set_adj = 1'b0;

        #1;
        dataBusWrite(REG_TMP_L, 8'hBB);
        iduWrite(REG_AF, 16'hFACE);
        dataBusWrite(REG_TMP_H, 8'hCC);
        iduWrite(REG_TMP, 16'hFACE);

        $finish();
    end

endmodule : gb_cpu_regfile_tb
