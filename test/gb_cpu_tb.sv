/* Top level testbench for CPU */
module gb_cpu_tb ();

    logic        clk;
    logic        reset;
    logic [ 7:0] data_i;
    logic [15:0] addr_o;
    logic [ 7:0] data_o;
    logic        drive_data_bus;

    gb_cpu dut (.*);

    // Emulate Memory
    logic [7:0] memory[65536];
    assign data_i = memory[addr_o];

    // place simple instructions
    assign memory[0] = 8'b11_000_110;  // add a, imm8
    assign memory[1] = 8'h05;
    assign memory[2] = 8'b11_010_110;  // sub a, imm8
    assign memory[3] = 8'h02;

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    initial begin
        $dumpfile("gb_cpu_tb.fst");
        $dumpvars();

        reset = 1'b1;
        @(posedge clk);
        #1;
        reset = 1'b0;

        repeat (10) begin
            #1;
            @(posedge clk);
            #1;
        end

        $finish();
    end

endmodule : gb_cpu_tb
