/* Built-in timer circuit for the GameBoy SoC

This currently implements the timer for the DMG model, not the CGB model

TODO: Color - KEY1 register controls Double-Speed mode
TODO: Suspend system counter in STOP mode

The overflow on TIMA takes 2 cycles while in actual hardware this only takes
a single cycle - as the physical register is a toggle flip flop, not clocked
    - do I need to implement this behavior?

Inputs:
    clk                     - Machine (M) Clock
    reset                   - System Reset
    data_i                  - Incoming Data Bus
    addr                    - Address Request
    wren                    - Write to Requested Address

Outputs:
    data_o                  - Value of Requested Register
    irq_timer               - Timer Interrupt Request

*/
/* verilator lint_off MULTIDRIVEN */
module gb_timer (
    input logic clk,
    input logic reset,
    input logic [7:0] data_i,
    input logic [15:0] addr,
    input logic wren,
    output logic [7:0] data_o,
    output logic irq_timer
);
    // Timer Control Registers
    logic [7:0] reg_DIV, reg_TIMA, reg_TMA, reg_TAC;
    logic [1:0] TAC_frequency;
    logic TAC_enable;

    // Parse control bits from TAC register
    assign TAC_frequency = reg_TAC[1:0];
    assign TAC_enable    = reg_TAC[2];

    // TAC write requests
    always_ff @(posedge clk, posedge reset)
        if (reset) reg_TAC <= 8'h00;
        else if (wren && (addr == 16'hFF07)) reg_TAC <= data_i;
        else reg_TAC <= reg_TAC;

    // 6 bits longer than reg_DIV; increment reg_DIV at 16384Hz
    logic [13:0] systemCounter;
    logic DIV_write_req;
    assign DIV_write_req = (wren && (addr == 16'hFF04));

    // reg_DIV is the upper bits of the system counter
    assign reg_DIV = systemCounter[13:6];

    // Any write attempt to DIV will reset the system counter
    always_ff @(posedge clk, posedge reset)
        if (reset) systemCounter <= 14'd0;
        else systemCounter <= systemCounter + 14'd1;
    always_ff @(posedge DIV_write_req) systemCounter <= 14'd0;

    // Logic between DIV and Timer
    logic [3:0] divFrequencySelect;
    logic timerTickReq;
    assign divFrequencySelect = {systemCounter[5], systemCounter[3], systemCounter[1], systemCounter[7]};
    assign timerTickReq = divFrequencySelect[TAC_frequency] & TAC_enable;

    // On the falling edge of a timer tick request, attempt to increment TIMA
    //logic timerTick;
    //always_ff @(posedge clk) timerTick <= 1'b0;
    //always_ff @(negedge timerTickReq) timerTick <= 1'b1;

    // Logic between Timer and Interrupt Request
    logic TIMA_write_req, TMA_write_req;
    assign TIMA_write_req = (wren && (addr == 16'hFF05));
    assign TMA_write_req  = (wren && (addr == 16'hFF06));

    // If TIMA overflows, attempt an interrupt request
    logic TIMA_overflow;
    always_ff @(posedge clk) irq_timer <= 1'b0;
    always_ff @(negedge reg_TIMA[7]) if (~(TIMA_write_req | irq_timer | TIMA_write_last)) irq_timer <= 1'b1;

    // Delay the interrupt request by one cycle
    //assign irq_timer = TIMA_overflow;
    //always_ff @(posedge clk, posedge reset)
    //    if (reset | TIMA_write_req | irq_timer) irq_timer <= 1'b0;
    //    else irq_timer <= TIMA_overflow;
    //assign irq_timer = (reg_TIMA == 8'hFF && timerTick && ~TIMA_write_req) ? 1'b1 : 1'b0;

    // Handle Write Requests to TIMA and TMA
    logic TIMA_write_last;

    always_ff @(posedge clk, posedge reset) begin
        TIMA_write_last <= 1'b0;
        TIMA_overflow   <= irq_timer;
        if (reset) begin
            reg_TIMA <= 8'h00;
            reg_TMA  <= 8'h00;
        end else if (TMA_write_req) reg_TMA <= data_i;
        else reg_TMA <= reg_TMA;
    end

    always_ff @(posedge TIMA_write_req, TIMA_overflow)
        if (TMA_write_req | (TIMA_write_req & ~TIMA_overflow)) begin
            reg_TIMA <= data_i;
            TIMA_write_last <= 1'b1;
        end else begin
            reg_TIMA <= reg_TMA;
            TIMA_write_last <= 1'b0;
        end

    always_ff @(negedge timerTickReq) reg_TIMA <= reg_TIMA + 8'h01;

    // Handle Register Reads
    always_comb begin : timerRegisterReads
        case (addr)
            16'hFF04: data_o = reg_DIV;
            16'hFF05: data_o = reg_TIMA;
            16'hFF06: data_o = reg_TMA;
            16'hFF07: data_o = reg_TAC;
            default:  data_o = 8'hxx;
        endcase
    end : timerRegisterReads

endmodule : gb_timer
/* verilator lint_on MULTIDRIVEN */
