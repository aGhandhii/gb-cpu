module decoder_tb ();

    // Replicate IO
    logic enable;
    logic [2:0] in;
    logic [7:0] out;

    // Instance
    decoder #(3) dut (.*);

    // Iteration
    logic [3:0] i;

    // Testbench
    initial begin
        // Record the simulation
        $dumpfile("decoder_tb.vcd");
        $dumpvars();

        enable = 1'b1;
        for (i = 4'd0; i < 4'b1000; i++) begin : testWithEnable
            in = i[2:0];
            #10;
            assert (out[in] == enable);
        end
        enable = 1'b0;
        for (i = 4'd0; i < 4'b1000; i++) begin : testWithoutEnable
            in = i[2:0];
            #10;
            assert (out[in] == enable);
        end
        $stop;
    end

endmodule : decoder_tb
