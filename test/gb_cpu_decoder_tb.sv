module gb_cpu_decoder_tb ();

    import gb_cpu_common_pkg::*;

    // IO replication
    logic [23:0] instruction;
    logic [7:0] opcodeByte0, opcodeByte1, opcodeByte2;
    assign instruction[23:16] = opcodeByte0;
    assign instruction[15:8]  = opcodeByte1;
    assign instruction[7:0]   = opcodeByte2;

    logic clk;
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // Instance
    gb_cpu_decoder dut (.*);

    // Testbench
    initial begin
        $dumpfile("gb_cpu_decoder_tb.fst");
        $dumpvars();

        $display("-----------------");
        $display("HEX | INSTRUCTION");
        $display("-----------------");

        // Iterate each opcode and print the outputs
        for (int i = 0; i < 256; i++) begin
            opcodeByte0 = i[7:0];
            if (i[7:0] != 8'hCB) begin
                $write("0x%0h: \t\t", opcodeByte0);
                @(posedge clk);
            end
        end

        // Test the $CB prefix operations
        opcodeByte0 = 8'hCB;
        for (int i = 0; i < 256; i++) begin
            opcodeByte1 = i[7:0];
            $write("0xCB 0x%0h: \t", opcodeByte1);
            @(posedge clk);
        end

        $finish();
    end

endmodule : gb_cpu_decoder_tb
