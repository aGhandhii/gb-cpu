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

    // Used for control signals - specify alu input source
    // the inputs can be from an 8-bit register or the data bus immediate
    typedef enum logic [1:0] {
        ALU_SRC_REG,
        ALU_SRC_DATA
    } alu_operand_source_t;

    // }}}

    // IDU {{{

    typedef enum logic [1:0] {
        IDU_NOP,
        IDU_INC,
        IDU_DEC
    } idu_opcode_t;

    typedef struct {
        idu_opcode_t opcode;
        logic [15:0] operand;
    } idu_instruction_t;

    // }}}

    // REGISTER FILE {{{

    // IE is memory-mapped to 0xFFFF but is located within the core
    // IR stores the current instruction
    typedef enum logic [3:0] {
        REG_A,
        REG_F,
        REG_B,
        REG_C,
        REG_D,
        REG_E,
        REG_H,
        REG_L,
        REG_IR,
        REG_IE,
        REG_SP_L,
        REG_SP_H,
        REG_PC_L,
        REG_PC_H,
        REG_TMP_L,
        REG_TMP_H
    } regfile_r8_t;

    typedef enum logic [2:0] {
        REG_AF,
        REG_BC,
        REG_DE,
        REG_HL,
        REG_SP,
        REG_PC,
        REG_TMP
    } regfile_r16_t;

    // }}}

    // DECODER AND SCHEDULING {{{

    typedef enum logic [2:0] {
        READ_OPCODE,
        READ_CB_OPCODE,
        READ_R8,
        READ_R16_BYTE0,
        READ_R16_BYTE1
    } decoder_state_t;

    typedef enum logic [1:0] {
        ADDR_BUS_REG16,
        ADDR_BUS_REG8,
        ADDR_BUS_ZERO
    } addr_bus_source_t;

    typedef struct packed {

        // Address bus can drive one of the following:
        //  - a 16-bit register value
        //  - 0xFF00 + an 8 bit register value
        //  - 0x0000
        addr_bus_source_t addr_bus_source;
        regfile_r8_t      addr_bus_source_r8;
        regfile_r16_t     addr_bus_source_r16;

        // This will synthesize on an FPGA, so data bus is split for I/O
        regfile_r8_t data_bus_i_destination;  // where to write incoming data on bus
        regfile_r8_t data_bus_o_source;       // register to drive over data bus
        logic        drive_data_bus;          // if high, push output - else take input

        idu_opcode_t  idu_opcode;
        regfile_r16_t idu_operand;
        regfile_r16_t idu_destination;
        logic         idu_wren;

        alu_opcode_t         alu_opcode;
        alu_operand_source_t alu_operand_a_source;
        alu_operand_source_t alu_operand_b_source;
        regfile_r8_t         alu_operand_a_register;
        regfile_r8_t         alu_operand_b_register;
        logic                alu_inc_dec;             // Pass 1 as operand_b
        regfile_r8_t         alu_destination;
        logic                alu_wren;

        // There are a few additional possible 'miscellaneous operations'
        logic enable_interrupts;  // set IME (delays 1 cycle)
        logic disable_interrupts;  // reset IME
        logic rst_cmd;  // set PC to restart address
        logic cc_check;  // check condition code
        // NOTE:
        //  - for condition codes, if the condition is NOT met, we ALWAYS
        //    proceed with the following instruction:
        //      addrBus: PC
        //      dataBus: write to IR (load next instruction)
        //      IDU:     increment PC (PC <- PC + 1)
        //      ALU:     NoOp
        //      Misc:    NoOp
        // - this handling can be done at the top level

    } control_signals_t;

    // Instruction scheduling will have an array of control signals, and the
    // m-cycle count for the particular instruction.
    // When new instructions are read, the array will be defined for the next
    // 6 cycles - enough to account for all commands at any given time, the
    // 'current' control signals are held in a separate register at top level.
    // Setting new signals will be done with combinational logic for whatever
    // the value of the IR register is at a given moment
    typedef struct {
        control_signals_t [5:0] instruction_controls;
        // Duration of the instruction
        logic [2:0]             m_cycles;
        // pass 3-bit 'bit address' from opcode to alu (bit, set, res)
        logic                   bit_cmd;
        // We also want to signal if an instruction is 0xCB-prefixed
        // - this signal can be flopped so the next address read will be
        //   decoded into the correct instruction, it needs to last for the
        //   entirety of the following instruction
        logic                   cb_prefix_next;
    } schedule_t;

    // }}}

    // REPURPOSE IN INSTRUCTION PARSING

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
