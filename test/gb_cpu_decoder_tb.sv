module gb_cpu_decoder_tb ();

    import gb_cpu_common_pkg::*;

    logic      [7:0] opcode;
    logic            cb_prefix;
    schedule_t       schedule;

    // Instance
    gb_cpu_decoder dut (.*);

    // Testbench
    initial begin
        $dumpfile("gb_cpu_decoder_tb.fst");
        $dumpvars();

        opcode    = 8'b10_000_000;
        cb_prefix = 1'b0;
        #10;

        $finish();
    end

endmodule : gb_cpu_decoder_tb
