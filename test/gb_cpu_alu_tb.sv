// Testbench for the ALU
module gb_cpu_alu_tb ();

    import gb_cpu_common_pkg::*;

    // Replicate IO
    alu_instruction_t instruction;
    logic carry_in;
    logic [7:0] out;
    logic Z, N, H, C;

    // Help with waveforms
    logic [7:0] op_a, op_b;
    assign op_a = instruction.operand_a;
    assign op_b = instruction.operand_b;

    // Instance
    gb_cpu_alu dut (.*);

    function automatic getALUInfo();
        case (instruction.opcode)
            ADD:           $display("Testing operation ADD");
            SUB:           $display("Testing operation SUB");
            AND:           $display("Testing operation AND");
            OR:            $display("Testing operation OR");
            XOR:           $display("Testing operation XOR");
            SHIFT_L:       $display("Testing operation SHIFT_L");
            SHIFT_R_ARITH: $display("Testing operation SHIFT_R_ARITH");
            SHIFT_R_LOGIC: $display("Testing operation SHIFT_R_LOGIC");
            ROTL:          $display("Testing operation ROTL");
            ROTL_CARRY:    $display("Testing operation ROTL_CARRY");
            ROTR:          $display("Testing operation ROTR");
            ROTR_CARRY:    $display("Testing operation ROTR_CARRY");
            BIT:           $display("Testing operation BIT");
            SET:           $display("Testing operation SET");
            RESET:         $display("Testing operation RESET");
            SWAP:          $display("Testing operation SWAP");
            default:       $display("Testing operation unknown");
        endcase
        $display("Inputs: %d and %d", instruction.operand_a, instruction.operand_b);
    endfunction : getALUInfo

    initial begin
        // Dump Simulation Data
        $dumpfile("gb_cpu_alu_tb.vcd");
        $dumpvars();

        carry_in = 0;

        instruction.operand_a = 8'd25;
        instruction.operand_b = 8'd66;
        instruction.opcode    = ADD;
        getALUInfo();
        #1;
        $display("Result: %d", out);

        instruction.operand_a = 8'd40;
        instruction.operand_b = 8'd5;
        instruction.opcode    = SUB;
        getALUInfo();
        #1;
        $display("Result: %d", out);

        $stop();
    end

endmodule : gb_cpu_alu_tb
