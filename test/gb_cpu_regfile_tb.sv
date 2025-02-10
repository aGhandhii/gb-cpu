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
        clk = 1'b0;
        forever #1 clk = ~clk;
    end

    gb_cpu_regfile dut (.*);

    initial begin
        $dumpfile("gb_cpu_regfile_tb.fst");
        $dumpvars();


        $finish();
    end

endmodule : gb_cpu_regfile_tb
