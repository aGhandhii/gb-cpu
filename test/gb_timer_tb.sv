module gb_timer_tb ();

    // IO Replication
    logic clk;
    logic reset;
    logic [7:0] data_i;
    logic [15:0] addr;
    logic wren;
    logic [7:0] data_o;
    logic irq_timer;

    // Instance
    gb_timer dut (.*);

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    task automatic sysReset();
        reset = 1'b1;
        @(posedge clk);
        #2;
        reset = 1'b0;
    endtask : sysReset

    task automatic writeTAC(logic [7:0] data);
        wren   = 1;
        addr   = 16'hFF07;
        data_i = data;
        @(posedge clk);
        #2;
        wren = 0;
    endtask : writeTAC

    task automatic writeTIMA(logic [7:0] data);
        wren   = 1;
        addr   = 16'hFF05;
        data_i = data;
        @(posedge clk);
        #2;
        wren = 0;
    endtask : writeTIMA

    task automatic writeTMA(logic [7:0] data);
        wren   = 1;
        addr   = 16'hFF06;
        data_i = data;
        @(posedge clk);
        #2;
        wren = 0;
    endtask : writeTMA

    task automatic writeDIV(logic [7:0] data);
        wren   = 1;
        addr   = 16'hFF04;
        data_i = data;
        @(posedge clk);
        #2;
        wren = 0;
    endtask : writeDIV

    initial begin
        $dumpfile("gb_timer_tb.fst");
        $dumpvars();

        wren = 0;
        sysReset();

        writeTAC(8'h05);
        writeTMA(8'hFE);
        writeTIMA(8'hFF);

        repeat (254) begin
            @(posedge clk);
            #2;
        end

        writeTMA(8'hEE);

        repeat (5000) begin
            @(posedge clk);
            #2;
        end

        $finish();
    end

endmodule : gb_timer_tb
