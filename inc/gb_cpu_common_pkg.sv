// Package imports for GameBoy CPU
package gb_cpu_common_pkg;

    // ALU {{{

    typedef enum logic [4:0] {
        ALU_NOP,
        ADD,
        ADC,
        SUB,
        SBC,
        CP,
        INC,
        DEC,
        AND,
        OR,
        XOR,
        CCF,
        SCF,
        DAA,
        CPL,
        SLA,
        SRA,
        SRL,
        RL,
        RLA,
        RLC,
        RLCA,
        RR,
        RRA,
        RRC,
        RRCA,
        BIT,
        SET,
        RES,
        SWAP
    } alu_opcode_t;

    typedef struct {
        logic [7:0]  operand_a;
        logic [7:0]  operand_b;
        alu_opcode_t opcode;
    } alu_instruction_t;

    typedef struct {
        logic Z;
        logic N;
        logic H;
        logic C;
    } alu_flags_t;

    // }}}

    // IDU {{{

    typedef enum logic [1:0] {
        IDU_NOP,
        IDU_INC,
        IDU_DEC
    } idu_opcode_t;

    // }}}

    // DECODER {{{

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

    typedef struct {
        opcode_r8_t     r8;
        opcode_r16_t    r16;
        opcode_r16stk_t r16stk;
        opcode_r16mem_t r16mem;
        opcode_cond_t   cond;
        logic [2:0]     bitIndex;
        logic [7:0]     rst_target_addr;
    } control_signals_t;

    // }}}

    // REGISTER FILE {{{

    // TODO: will we ever need to read from A or F?
    typedef enum logic [2:0] {
        REG_B,
        REG_C,
        REG_D,
        REG_E,
        REG_H,
        REG_L,
        REG_IE,
        REG_IR
    } regfile_r8_t;

    typedef enum logic [2:0] {
        REG_AF,
        REG_BC,
        REG_DE,
        REG_HL,
        REG_SP,
        REG_PC
    } regfile_r16_t;

    // }}}

endpackage : gb_cpu_common_pkg
