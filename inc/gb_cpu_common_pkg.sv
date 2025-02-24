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

    typedef struct {
        idu_opcode_t opcode;
        logic [15:0] operand;
    } idu_instruction_t;

    // }}}

    // REGISTER FILE {{{

    // Contains registers from the CPU regfile
    typedef struct packed {
        logic [7:0] a;
        logic [7:0] f;
        logic [7:0] b;
        logic [7:0] c;
        logic [7:0] d;
        logic [7:0] e;
        logic [7:0] h;
        logic [7:0] l;
        logic [7:0] ir;
        logic [7:0] sp_lo;
        logic [7:0] sp_hi;
        logic [7:0] pc_lo;
        logic [7:0] pc_hi;
        logic [7:0] tmp_lo;
        logic [7:0] tmp_hi;
    } regfile_t;

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

    // Return the 'low' byte of a 16-bit register
    function automatic regfile_r8_t getRegisterLow(regfile_r16_t rr);
        case (rr)
            REG_AF:  return REG_F;
            REG_BC:  return REG_C;
            REG_DE:  return REG_E;
            REG_HL:  return REG_L;
            REG_SP:  return REG_SP_L;
            REG_PC:  return REG_PC_L;
            REG_TMP: return REG_TMP_L;
            default: return REG_TMP_L;
        endcase
    endfunction : getRegisterLow

    // Return the 'high' byte of a 16-bit register
    function automatic regfile_r8_t getRegisterHigh(regfile_r16_t rr);
        case (rr)
            REG_AF:  return REG_A;
            REG_BC:  return REG_B;
            REG_DE:  return REG_D;
            REG_HL:  return REG_H;
            REG_SP:  return REG_SP_H;
            REG_PC:  return REG_PC_H;
            REG_TMP: return REG_TMP_H;
            default: return REG_TMP_H;
        endcase
    endfunction : getRegisterHigh

    // Takes a regfile r8 encoding and returns the 8-bit register value
    function automatic logic [7:0] getRegister8(regfile_t registers, regfile_r8_t r8);
        case (r8)
            REG_A:     return registers.a;
            REG_F:     return registers.f;
            REG_B:     return registers.b;
            REG_C:     return registers.c;
            REG_D:     return registers.d;
            REG_E:     return registers.e;
            REG_H:     return registers.h;
            REG_L:     return registers.l;
            REG_IR:    return registers.ir;
            REG_SP_L:  return registers.sp_lo;
            REG_SP_H:  return registers.sp_hi;
            REG_PC_L:  return registers.pc_lo;
            REG_PC_H:  return registers.pc_hi;
            REG_TMP_L: return registers.tmp_lo;
            REG_TMP_H: return registers.tmp_hi;
            default:   return registers.tmp_hi;
        endcase
    endfunction : getRegister8

    // Takes a regfile r16 encoding and returns the 16-bit register value
    function automatic logic [15:0] getRegister16(regfile_t registers, regfile_r16_t r16);
        return {getRegister8(registers, getRegisterHigh(r16)), getRegister8(registers, getRegisterLow(r16))};
    endfunction : getRegister16

    typedef enum logic [2:0] {
        R8_B       = 3'o0,
        R8_C       = 3'o1,
        R8_D       = 3'o2,
        R8_E       = 3'o3,
        R8_H       = 3'o4,
        R8_L       = 3'o5,
        R8_HL_ADDR = 3'o6,
        R8_A       = 3'o7
    } opcode_r8_t;

    typedef enum logic [1:0] {
        R16_BC = 2'b00,
        R16_DE = 2'b01,
        R16_HL = 2'b10,
        R16_SP = 2'b11
    } opcode_r16_t;

    typedef enum logic [1:0] {
        R16STK_BC = 2'b00,
        R16STK_DE = 2'b01,
        R16STK_HL = 2'b10,
        R16STK_AF = 2'b11
    } opcode_r16stk_t;

    typedef enum logic [1:0] {
        R16MEM_BC  = 2'b00,
        R16MEM_DE  = 2'b01,
        R16MEM_HLI = 2'b10,
        R16MEM_HLD = 2'b11
    } opcode_r16mem_t;

    // }}}

    // DECODER AND SCHEDULING {{{

    typedef enum logic [1:0] {
        ADDR_BUS_REG16,
        ADDR_BUS_REG8,
        ADDR_BUS_ZERO
    } addr_bus_source_t;

    typedef enum logic [1:0] {
        COND_NZ = 2'b00,
        COND_Z  = 2'b01,
        COND_NC = 2'b10,
        COND_C  = 2'b11
    } condition_code_t;

    typedef struct packed {

        // Address bus can drive one of the following:
        //  - a 16-bit register value
        //  - 0xFF00 + an 8 bit register value
        //  - 0x0000
        addr_bus_source_t addr_bus_source;
        regfile_r8_t      addr_bus_source_r8;
        regfile_r16_t     addr_bus_source_r16;

        regfile_r8_t data_bus_i_destination;  // where to write incoming data on bus
        regfile_r8_t data_bus_o_source;       // register to drive over data bus
        logic        receive_data_bus;        // write incoming data to registers
        logic        drive_data_bus;          // if high, push output

        idu_opcode_t  idu_opcode;
        regfile_r16_t idu_operand;
        regfile_r16_t idu_destination;
        logic         idu_wren;

        alu_opcode_t alu_opcode;
        regfile_r8_t alu_operand_a_register;
        regfile_r8_t alu_operand_b_register;
        logic        alu_inc_dec;
        regfile_r8_t alu_destination;
        logic        alu_wren;

        // There are a few additional possible 'miscellaneous operations'
        logic         enable_interrupts;       // set IME (delayed by 1 cycle)
        logic         disable_interrupts;      // reset IME
        logic         write_interrupt_vector;  // Write highest priority interrupt vector to PC
        logic         clear_interrupt_flag;    // Clear highest priority flag in IF
        logic         rst_cmd;                 // set PC to restart address
        logic         cc_check;                // check condition code
        logic         overwrite_wren;          // write contents of temp register to other 16-bit register
        regfile_r16_t overwrite_req;           // 16-bit register to overwrite with TEMP
        // These signals are needed for the following instructions:
        //   - ld  HL, SP+e
        //   - add SP, e
        //   - jr
        logic         set_adj;                 // set the signed arithmetic adjust value
        logic         add_adj;                 // force the alu input to be adj, and do not set flags

    } control_signals_t;

    // Instruction scheduling will have an array of control signals, and the
    // m-cycle count for the particular instruction.
    // When new instructions are read, the array will be defined for the next
    // 6 cycles - enough to account for all commands at any given time, the
    // 'current' control signals are held in a separate register at top level.
    // Setting new signals will be done with combinational logic for whatever
    // the value of the IR register is at a given moment
    typedef struct {

        // Contains the schedule of controls
        control_signals_t [5:0] instruction_controls;
        // Duration of the instruction
        logic [2:0]             m_cycles;
        // pass 3-bit 'bit address' from opcode to alu (bit, set, res)
        logic                   bit_cmd;
        // If the following instruction is 0xCB-prefixed
        logic                   cb_prefix_next;

    } schedule_t;

    // }}}

endpackage : gb_cpu_common_pkg
