// Testbench for the ALU
module gb_cpu_alu_tb ();

    import gb_cpu_common_pkg::*;

    // Replicate IO
    gb_instruction_t instruction;
    logic [7:0] IN_0, IN_1;
    logic CARRY_IN;
    logic [7:0] OUT;
    logic Z, N, H, C;

    // Instance
    gb_cpu_alu dut (.*);

    // Test
    integer i;
    initial begin
        // Dump Simulation Data
        $dumpfile("gb_cpu_alu_tb.vcd");
        $dumpvars();

        $display("\nARITHMETIC\n");

        $display("Testing ADD");
        IN_0 = 8'd40;
        IN_1 = 8'd5;
        instruction.opcode = ADD;
        #1;
        $display("result: %d", OUT);

        $display("Testing SUB");
        IN_0 = 8'd40;
        IN_1 = 8'd5;
        instruction.opcode = SUB;
        #1;
        $display("result: %d", OUT);

        $stop();
    end

endmodule : gb_cpu_alu_tb
