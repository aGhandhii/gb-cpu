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

    typedef enum logic [3:0] {
        REG_A,
        REG_B,
        REG_C,
        REG_D,
        REG_E,
        REG_F,
        REG_H,
        REG_L,
        REG_IR,
        REG_IE,
        PC,
        SP
    } gb_cpu_registers_t;

endpackage : gb_cpu_common_pkg
