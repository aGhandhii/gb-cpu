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
    } gb_opcode_t;

    typedef enum logic [3:0] {
        REG_A,
        REG_B,
        REG_C,
        REG_D,
        REG_E,
        REG_F,
        REG_H,
        REG_L,
        PC,
        SP
    } gb_operand_t;

    typedef struct {
        gb_operand_t operand_a;
        gb_operand_t operand_b;
        gb_opcode_t  opcode;
    } gb_instruction_t;

endpackage : gb_cpu_common_pkg
