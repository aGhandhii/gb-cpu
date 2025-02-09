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

    // Current controls for given m-cycle as sent by the scheduler
    control_signals_t curr_controls;

    // We need to internally flop enable_interrupts to delay a cycle
    logic enable_interrupts_delayed;

    always_ff @(posedge clk) enable_interrupts_delayed <= curr_controls.enable_interrupts;

    // NOTE: for 'INC/DEC' operations, pass ALU operand b as operand a, and 8'd1 as operand_b

    // alu/idu results might get written on the negedge of the clock
    //   - an exception should be the IR register, which can only be updated
    //     at the posedge of the clock
    //   - this avoids race conditions so PC can be updated and give memory
    //     time to resolve the next value
    //   - make sure this is a viable system - things might change when I
    //     better understand how memory works

    // for signed arithmetic (adj controls)
    // set_adj - set REG_TMP_H to sign extension of REG_TMP_L
    // add_adj - set alu operand_b to REG_TMP_H and do not write flags

endmodule : gb_cpu
