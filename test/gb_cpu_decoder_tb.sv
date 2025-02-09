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

        cb_prefix = 1'b0;


        // xor a e
        opcode    = 8'b10_101_011;
        #1;

        // dec d
        opcode = 8'b00_010_101;
        #1;

        // inc [HL]
        opcode = 8'b00_110_100;
        #1;

        $finish();
    end

endmodule : gb_cpu_decoder_tb
