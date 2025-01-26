// Package imports for GameBoy CPU
package gb_cpu_common_pkg;

    typedef enum logic [3:0] {
        ADD,
        SUB,
        AND,
        OR,
        XOR,
        SHIFT_L,
        SHIFT_R_ARITH,
        SHIFT_R_LOGIC,
        ROTL,
        ROTL_CARRY,
        ROTR,
        ROTR_CARRY,
        BIT,
        SET,
        RESET,
        SWAP
    } alu_opcode_t;

    typedef struct {
        logic [7:0]  operand_a;
        logic [7:0]  operand_b;
        alu_opcode_t opcode;
    } alu_instruction_t;

    typedef enum logic [2:0] {
        READ_OPCODE,
        READ_CB_OPCODE,
        READ_R8,
        READ_R16_BYTE0,
        READ_R16_BYTE1
    } decoder_state_t;

    typedef enum logic [2:0] {
        r8_b       = 3'o0,
        r8_c       = 3'o1,
        r8_d       = 3'o2,
        r8_e       = 3'o3,
        r8_h       = 3'o4,
        r8_l       = 3'o5,
        r8_hl_addr = 3'o6,
        r8_a       = 3'o7
    } opcode_r8_t;

    typedef enum logic [1:0] {
        r16_bc = 2'b00,
        r16_de = 2'b01,
        r16_hl = 2'b10,
        r16_sp = 2'b11
    } opcode_r16_t;

    typedef enum logic [1:0] {
        r16stk_bc = 2'b00,
        r16stk_de = 2'b01,
        r16stk_hl = 2'b10,
        r16stk_af = 2'b11
    } opcode_r16stk_t;

    typedef enum logic [1:0] {
        r16mem_bc  = 2'b00,
        r16mem_de  = 2'b01,
        r16mem_hli = 2'b10,
        r16mem_hld = 2'b11
    } opcode_r16mem_t;

    typedef enum logic [1:0] {
        cond_nz = 2'b00,
        cond_z  = 2'b01,
        cond_nc = 2'b10,
        cond_c  = 2'b11
    } opcode_cond_t;

endpackage : gb_cpu_common_pkg
