import gb_cpu_common_pkg::*;
/* Top level module for the gameboy CPU

Inputs:
    clk     - Machine (M) Clock
    reset   - System Reset
    data_i  - Incoming Data Bus

Outputs:
    addr_o  - Outgoing Address Bus
    data_o  - Outgoing Data Bus
    drive_data_bus - write enable for data out
*/
module gb_cpu (
 input  logic        clk,
 input  logic        reset,
 input  logic [ 7:0] data_i,
 output logic [15:0] addr_o,
 output logic [ 7:0] data_o,
 output logic        drive_data_bus
);

    // Interrupt Master Enable
    logic                    IME;

    // Each instruction yields a schedule from the decoder
    schedule_t               schedule;

    // The decoder and scheduler work in tandem; the scheduler handles clock
    // sensitive control information, giving the control signals for the
    // current m-cycle
    logic             [ 2:0] curr_m_cycle;
    logic                    cond_not_met;
    control_signals_t        curr_controls;
    logic                    cb_prefix;

    // Instructions to feed ALU and IDU
    alu_instruction_t        alu_instruction;
    idu_instruction_t        idu_instruction;

    // Store ALU and IDU outputs
    logic             [ 7:0] alu_o;
    alu_flags_t              alu_flags_o;
    logic             [15:0] idu_o;

    // We need to internally flop enable_interrupts to delay a cycle
    logic                    enable_interrupts_delayed;
    always_ff @(posedge clk) enable_interrupts_delayed <= curr_controls.enable_interrupts;

    // NOTE: for 'INC/DEC' operations, pass ALU operand b as operand a, and 8'd1 as operand_b

    // alu/idu results might get written on the negedge of the clock
    //   - an exception should be the IR register, which can only be updated
    //     at the posedge of the clock
    //   - another exception is the TMP_L and TMP_H registers which hold
    //     immediates from memory, if we request them as a data bus destination
    //     they are also updated on the posedge
    //   - this avoids race conditions so PC can be updated and give memory
    //     time to resolve the next value
    //   - make sure this is a viable system - things might change when I
    //     better understand how memory works

    // for signed arithmetic (adj controls)
    // set_adj - set REG_TMP_H to sign extension of REG_TMP_L (at negedge of clock!)
    // add_adj - set alu operand_b to REG_TMP_H and do not write flags

endmodule : gb_cpu
