/*
Parameters:
    DATA_SIZE: size (in bits) of data passed through each IO port
    SELECT_SIZE: size (in bits) of selector, input has 2**SELECT_SIZE ports

Inputs:
    in: (2**SELECT_SIZE) DATA_SIZE-bit inputs
    port: SELECT_SIZE-bit port select

Outputs:
    out: DATA_SIZE-bit output
*/
module mux #(
    parameter DATA_SIZE = 1,
    SELECT_SIZE = 1
) (
    input  logic [  DATA_SIZE-1:0] in  [2**SELECT_SIZE-1:0],
    input  logic [SELECT_SIZE-1:0] port,
    output logic [  DATA_SIZE-1:0] out
);

    // Set data_out to 'data' bits at selected 'port' of input
    assign out = in[port];

endmodule : mux
