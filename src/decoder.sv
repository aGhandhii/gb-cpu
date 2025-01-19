/*
Parameters:
    INPUT_SIZE: size (in bits) of active-high decoder input [default 5]

Inputs:
    enable: decoder enable input
    in: INPUT_SIZE-bit input

Outputs:
    out: INPUT_SIZE**2-bit active-high output [default 32]
*/
module decoder #(
    parameter INPUT_SIZE = 5
) (
    input logic enable,
    input logic [INPUT_SIZE-1:0] in,
    output logic [2**INPUT_SIZE-1:0] out
);

    // Set corresponding bit of 'out' to 'enable'
    always_comb begin
        out = '0;
        out[in] = enable;
    end

endmodule : decoder
