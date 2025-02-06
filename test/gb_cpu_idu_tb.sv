import gb_cpu_common_pkg::*;
/* IDU Testbench */
module gb_cpu_idu_tb ();

    idu_instruction_t        instruction;
    logic             [15:0] out;
    gb_cpu_idu dut (.*);

    function automatic logic [15:0] randIn();
        logic [31:0] randVal;
        randVal = $urandom();
        return randVal[15:0];
    endfunction : randIn

    initial begin
        // Dump Simulation Data
        $dumpfile("gb_cpu_idu_tb.fst");
        $dumpvars();

        instruction.opcode = IDU_NOP;
        for (int i = 0; i < 10; i++) begin : testNoOp
            instruction.operand = randIn();
            $display("Testing %s with input %d", instruction.opcode.name(), instruction.operand);
            #1;
            assert (out == instruction.operand)
            else $display("%s failed", instruction.opcode.name());
        end : testNoOp

        instruction.opcode = IDU_INC;
        for (int i = 0; i < 10; i++) begin : testInc
            instruction.operand = randIn();
            $display("Testing %s with input %d", instruction.opcode.name(), instruction.operand);
            #1;
            assert (out == instruction.operand + 16'd1)
            else $display("%s failed", instruction.opcode.name());
        end : testInc

        instruction.opcode = IDU_DEC;
        for (int i = 0; i < 10; i++) begin : testNoOp
            instruction.operand = randIn();
            $display("Testing %s with input %d", instruction.opcode.name(), instruction.operand);
            #1;
            assert (out == instruction.operand - 16'd1)
            else $display("%s failed", instruction.opcode.name());
        end : testNoOp

        $finish();
    end

endmodule : gb_cpu_idu_tb
