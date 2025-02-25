/* Top level testbench for CPU */
module gb_cpu_tb ();

    logic        clk;
    logic        reset;
    logic [ 7:0] data_i;
    logic [ 7:0] reg_IF;
    logic [ 7:0] reg_IE;
    logic [15:0] addr_o;
    logic [ 7:0] data_o;
    logic        drive_data_bus;
    logic        clear_interrupt_flag;

    gb_cpu dut (.*);

    // Emulate Memory
    logic [7:0] memory[65536];
    assign data_i = memory[addr_o];
    always_ff @(posedge clk) memory[addr_o] <= drive_data_bus ? data_o : memory[addr_o];

    always_ff @(posedge clk)
        if (clear_interrupt_flag)
            if (reg_IF[0]) reg_IF <= reg_IF ^ 8'h01;
            else if (reg_IF[1]) reg_IF <= reg_IF ^ 8'h02;
            else if (reg_IF[2]) reg_IF <= reg_IF ^ 8'h04;
            else if (reg_IF[3]) reg_IF <= reg_IF ^ 8'h08;
            else if (reg_IF[4]) reg_IF <= reg_IF ^ 8'h10;
            else reg_IF <= reg_IF;

    assign memory[0]  = 8'b11_000_110;  // add a, 5
    assign memory[1]  = 8'h05;
    assign memory[2]  = 8'b11_010_110;  // sub a, 2
    assign memory[3]  = 8'h02;
    assign memory[4]  = 8'b00_01_0011;  // inc de
    assign memory[5]  = 8'b00_01_0011;  // inc de
    assign memory[6]  = 8'b00_01_1011;  // dec de
    assign memory[7]  = 8'b00_001_110;  // ld c imm8
    assign memory[8]  = 8'hCC;
    assign memory[9]  = 8'b01_000_001;  // ld b c
    assign memory[10] = 8'b11_001101;  // call 20
    assign memory[11] = 8'h14;
    assign memory[12] = 8'h00;

    assign memory[13] = 8'b00_01_0011;  // inc de
    assign memory[14] = 8'b01110110;  // halt

    assign memory[20] = 8'b11_000_110;  // add a 7
    assign memory[21] = 8'h07;
    assign memory[22] = 8'b11_001001;  // ret


    //assign memory[ 0] = 8'b00_00_0001; // ld bc 0xBEEF
    //assign memory[ 1] = 8'hEF;
    //assign memory[ 2] = 8'hBE;
    //assign memory[ 3] = 8'b00_10_0001; // ld hl 0xDEAD
    //assign memory[ 4] = 8'hAD;
    //assign memory[ 5] = 8'hDE;
    //assign memory[ 6] = 8'b11_111001;  // ld sp, hl
    //assign memory[ 7] = 8'b11_00_0101; // push bc
    //assign memory[ 8] = 8'b11_01_0001; // pop de
    //assign memory[ 9] = 8'b01110110;   // halt

    //assign memory[ 7] = 8'hCB;
    //assign memory[ 8] = 8'b00_110_001; // swap c
    //assign memory[ 9] = 8'hCB;
    //assign memory[10] = 8'b10_110_001; // res c 6
    //assign memory[11] = 8'hCB;
    //assign memory[12] = 8'b11_110_001; // set c 6
    //assign memory[13] = 8'b11_111011;  // ei
    //assign memory[14] = 8'b11_110011;  // di
    //assign memory[15] = 8'b01110110;   // halt

    //assign memory[ 0] = 8'h18;         // jr + 1 + 9
    //assign memory[ 1] = 8'h09;
    //assign memory[ 7] = 8'b00_001_110; // ld c 0xCC
    //assign memory[ 8] = 8'hCC;
    //assign memory[ 9] = 8'b01110110;   // halt
    //assign memory[10] = 8'h18;         // jr + 1 - 4
    //assign memory[11] = 8'hFC;

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

        repeat (30) begin
            #1;
            @(posedge clk);
            #1;
        end

        $finish();
    end

endmodule : gb_cpu_tb
