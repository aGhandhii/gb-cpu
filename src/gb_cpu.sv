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


    // We need to internally flop enable_interrupts to delay a cycle

endmodule : gb_cpu
