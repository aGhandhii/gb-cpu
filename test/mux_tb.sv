module mux_tb ();

    // Replicate IO
    logic [1:0] port;
    logic [3:0] in[3:0];
    logic [3:0] out;

    // Create the test instance
    mux #(
        .DATA_SIZE  (4),
        .SELECT_SIZE(2)
    ) dut (
        .*
    );

    integer i;
    initial begin : testBench
        // Record the simulation
        $dumpfile("mux_tb.vcd");
        $dumpvars();

        // Set mux inputs
        in[0] = 4'hE;
        in[1] = 4'hC;
        in[2] = 4'hA;
        in[3] = 4'hF;

        // Read from each port
        for (i = 0; i < 4; i++) begin : testMuxPorts
            port = i[1:0];
            $display("Testing Port %d", port);
            #10;
            assert (out == in[port]);
        end : testMuxPorts

        $stop;
    end : testBench

endmodule : mux_tb
