import gb_cpu_common_pkg::*;

/* Handle Scheduling for the Decoder Unit */
package gb_cpu_decoder_pkg;

    // OPCODE ENCODING CONVERTERS {{{

    function automatic regfile_r8_t opcodeR8Decode(opcode_r8_t in);
        case (in)
            R8_B:    return REG_B;
            R8_C:    return REG_C;
            R8_D:    return REG_D;
            R8_E:    return REG_E;
            R8_H:    return REG_H;
            R8_L:    return REG_L;
            R8_A:    return REG_A;
            default: return REG_A;
        endcase
    endfunction : opcodeR8Decode

    function automatic regfile_r16_t opcodeR16Decode(opcode_r16_t in);
        case (in)
            R16_BC:  return REG_BC;
            R16_DE:  return REG_DE;
            R16_HL:  return REG_HL;
            R16_SP:  return REG_SP;
            default: return REG_SP;
        endcase
    endfunction : opcodeR16Decode

    function automatic regfile_r16_t opcodeR16stkDecode(opcode_r16stk_t in);
        case (in)
            R16STK_BC: return REG_BC;
            R16STK_DE: return REG_DE;
            R16STK_HL: return REG_HL;
            R16STK_AF: return REG_AF;
            default:   return REG_AF;
        endcase
    endfunction : opcodeR16stkDecode

    function automatic regfile_r16_t opcodeR16memDecode(opcode_r16mem_t in);
        case (in)
            R16MEM_BC:  return REG_BC;
            R16MEM_DE:  return REG_DE;
            R16MEM_HLI: return REG_HL;
            R16MEM_HLD: return REG_HL;
            default:    return REG_HL;
        endcase
    endfunction : opcodeR16memDecode

    // }}}

    // {{{ HELPER FUNCTIONS

    // Returns a schedule with undefined values - use this to pad other instructions
    function automatic schedule_t emptySchedule();
        schedule_t schedule;
        schedule.m_cycles       = 3'bxxx;
        schedule.bit_cmd        = 1'bx;
        schedule.cb_prefix_next = 1'bx;
        for (logic [2:0] i = 0; i < 3'd6; i++) begin
            schedule.instruction_controls[i].addr_bus_source        = addr_bus_source_t'(2'bxx);
            schedule.instruction_controls[i].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[i].addr_bus_source_r16    = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[i].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[i].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[i].drive_data_bus         = 1'bx;
            schedule.instruction_controls[i].receive_data_bus       = 1'bx;
            schedule.instruction_controls[i].idu_opcode             = idu_opcode_t'(2'bxx);
            schedule.instruction_controls[i].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[i].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[i].idu_wren               = 1'bx;
            schedule.instruction_controls[i].alu_opcode             = alu_opcode_t'(5'bxxxxx);
            schedule.instruction_controls[i].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[i].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[i].alu_inc_dec            = 1'bx;
            schedule.instruction_controls[i].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[i].alu_wren               = 1'bx;
            schedule.instruction_controls[i].enable_interrupts      = 1'bx;
            schedule.instruction_controls[i].disable_interrupts     = 1'bx;
            schedule.instruction_controls[i].write_interrupt_vector = 1'bx;
            schedule.instruction_controls[i].clear_interrupt_flag   = 1'bx;
            schedule.instruction_controls[i].rst_cmd                = 1'bx;
            schedule.instruction_controls[i].cc_check               = 1'bx;
            schedule.instruction_controls[i].overwrite_wren         = 1'bx;
            schedule.instruction_controls[i].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[i].set_adj                = 1'bx;
            schedule.instruction_controls[i].add_adj                = 1'bx;
        end
        return schedule;
    endfunction : emptySchedule

    // }}}

    // INTERRUPT SERVICE ROUTINE (ISR) {{{

    function automatic schedule_t interruptServiceRoutine();

        schedule_t schedule, blankSchedule;
        schedule.m_cycles                                       = 3'd4;
        schedule.bit_cmd                                        = 1'b0;
        schedule.cb_prefix_next                                 = 1'b0;
        blankSchedule                                           = emptySchedule();

        // Cycle 1 - Decrement Stack so Program Counter can be saved
        schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
        schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
        schedule.instruction_controls[0].addr_bus_source_r16    = REG_SP;
        schedule.instruction_controls[0].data_bus_i_destination = regfile_r8_t'(4'hx);
        schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
        schedule.instruction_controls[0].drive_data_bus         = 1'b0;
        schedule.instruction_controls[0].receive_data_bus       = 1'b0;
        schedule.instruction_controls[0].idu_opcode             = IDU_DEC;
        schedule.instruction_controls[0].idu_operand            = REG_SP;
        schedule.instruction_controls[0].idu_destination        = REG_SP;
        schedule.instruction_controls[0].idu_wren               = 1'b1;
        schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
        schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
        schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
        schedule.instruction_controls[0].alu_inc_dec            = 1'bx;
        schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
        schedule.instruction_controls[0].alu_wren               = 1'b0;
        schedule.instruction_controls[0].enable_interrupts      = 1'b0;
        schedule.instruction_controls[0].disable_interrupts     = 1'b0;
        schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
        schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
        schedule.instruction_controls[0].rst_cmd                = 1'b0;
        schedule.instruction_controls[0].cc_check               = 1'b0;
        schedule.instruction_controls[0].overwrite_wren         = 1'b0;
        schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
        schedule.instruction_controls[0].set_adj                = 1'b0;
        schedule.instruction_controls[0].add_adj                = 1'b0;
        // Cycle 2 - Push High Byte of Program Counter to the Stack
        schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
        schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
        schedule.instruction_controls[1].addr_bus_source_r16    = REG_SP;
        schedule.instruction_controls[1].data_bus_i_destination = regfile_r8_t'(4'hx);
        schedule.instruction_controls[1].data_bus_o_source      = REG_PC_H;
        schedule.instruction_controls[1].drive_data_bus         = 1'b1;
        schedule.instruction_controls[1].receive_data_bus       = 1'b0;
        schedule.instruction_controls[1].idu_opcode             = IDU_DEC;
        schedule.instruction_controls[1].idu_operand            = REG_SP;
        schedule.instruction_controls[1].idu_destination        = REG_SP;
        schedule.instruction_controls[1].idu_wren               = 1'b1;
        schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
        schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
        schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
        schedule.instruction_controls[1].alu_inc_dec            = 1'bx;
        schedule.instruction_controls[1].alu_destination        = regfile_r8_t'(4'hx);
        schedule.instruction_controls[1].alu_wren               = 1'b0;
        schedule.instruction_controls[1].enable_interrupts      = 1'b0;
        schedule.instruction_controls[1].disable_interrupts     = 1'b0;
        schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
        schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
        schedule.instruction_controls[1].rst_cmd                = 1'b0;
        schedule.instruction_controls[1].cc_check               = 1'b0;
        schedule.instruction_controls[1].overwrite_wren         = 1'b0;
        schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
        schedule.instruction_controls[1].set_adj                = 1'b0;
        schedule.instruction_controls[1].add_adj                = 1'b0;
        // Cycle 3 - Push Low Byte of Program Counter to the Stack
        schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
        schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
        schedule.instruction_controls[2].addr_bus_source_r16    = REG_SP;
        schedule.instruction_controls[2].data_bus_i_destination = regfile_r8_t'(4'hx);
        schedule.instruction_controls[2].data_bus_o_source      = REG_PC_L;
        schedule.instruction_controls[2].drive_data_bus         = 1'b1;
        schedule.instruction_controls[2].receive_data_bus       = 1'b0;
        schedule.instruction_controls[2].idu_opcode             = IDU_NOP;
        schedule.instruction_controls[2].idu_operand            = regfile_r16_t'(3'bxxx);
        schedule.instruction_controls[2].idu_destination        = regfile_r16_t'(3'bxxx);
        schedule.instruction_controls[2].idu_wren               = 1'b0;
        schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
        schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
        schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
        schedule.instruction_controls[2].alu_inc_dec            = 1'bx;
        schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
        schedule.instruction_controls[2].alu_wren               = 1'b0;
        schedule.instruction_controls[2].enable_interrupts      = 1'b0;
        schedule.instruction_controls[2].disable_interrupts     = 1'b0;
        schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
        schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
        schedule.instruction_controls[2].rst_cmd                = 1'b0;
        schedule.instruction_controls[2].cc_check               = 1'b0;
        schedule.instruction_controls[2].overwrite_wren         = 1'b0;
        schedule.instruction_controls[2].overwrite_req          = regfile_r16_t'(3'bxxx);
        schedule.instruction_controls[2].set_adj                = 1'b0;
        schedule.instruction_controls[2].add_adj                = 1'b0;
        // Cycle 4 - Load the Interrupt Vector into the Program Counter, Clear IF flag, Disable Interrupts
        schedule.instruction_controls[3].addr_bus_source        = ADDR_BUS_REG16;
        schedule.instruction_controls[3].addr_bus_source_r8     = regfile_r8_t'(4'hx);
        schedule.instruction_controls[3].addr_bus_source_r16    = regfile_r16_t'(3'bxxx);
        schedule.instruction_controls[3].data_bus_i_destination = regfile_r8_t'(4'hx);
        schedule.instruction_controls[3].data_bus_o_source      = regfile_r8_t'(4'hx);
        schedule.instruction_controls[3].drive_data_bus         = 1'b0;
        schedule.instruction_controls[3].receive_data_bus       = 1'b0;
        schedule.instruction_controls[3].idu_opcode             = IDU_NOP;
        schedule.instruction_controls[3].idu_operand            = regfile_r16_t'(3'bxxx);
        schedule.instruction_controls[3].idu_destination        = regfile_r16_t'(3'bxxx);
        schedule.instruction_controls[3].idu_wren               = 1'b0;
        schedule.instruction_controls[3].alu_opcode             = ALU_NOP;
        schedule.instruction_controls[3].alu_operand_a_register = regfile_r8_t'(4'hx);
        schedule.instruction_controls[3].alu_operand_b_register = regfile_r8_t'(4'hx);
        schedule.instruction_controls[3].alu_inc_dec            = 1'bx;
        schedule.instruction_controls[3].alu_destination        = regfile_r8_t'(4'hx);
        schedule.instruction_controls[3].alu_wren               = 1'b0;
        schedule.instruction_controls[3].enable_interrupts      = 1'b0;
        schedule.instruction_controls[3].disable_interrupts     = 1'b1;
        schedule.instruction_controls[3].write_interrupt_vector = 1'b1;
        schedule.instruction_controls[3].clear_interrupt_flag   = 1'b1;
        schedule.instruction_controls[3].rst_cmd                = 1'b0;
        schedule.instruction_controls[3].cc_check               = 1'b0;
        schedule.instruction_controls[3].overwrite_wren         = 1'b1;
        schedule.instruction_controls[3].overwrite_req          = REG_PC;
        schedule.instruction_controls[3].set_adj                = 1'b0;
        schedule.instruction_controls[3].add_adj                = 1'b0;
        // Cycle 5 - Load the next instruction to IR, do not increment Program Counter
        schedule.instruction_controls[4].addr_bus_source        = ADDR_BUS_REG16;
        schedule.instruction_controls[4].addr_bus_source_r8     = regfile_r8_t'(4'hx);
        schedule.instruction_controls[4].addr_bus_source_r16    = REG_PC;
        schedule.instruction_controls[4].data_bus_i_destination = REG_IR;
        schedule.instruction_controls[4].data_bus_o_source      = regfile_r8_t'(4'hx);
        schedule.instruction_controls[4].drive_data_bus         = 1'b0;
        schedule.instruction_controls[4].receive_data_bus       = 1'b1;
        schedule.instruction_controls[4].idu_opcode             = IDU_NOP;
        schedule.instruction_controls[4].idu_operand            = regfile_r16_t'(3'bxxx);
        schedule.instruction_controls[4].idu_destination        = regfile_r16_t'(3'bxxx);
        schedule.instruction_controls[4].idu_wren               = 1'b0;
        schedule.instruction_controls[4].alu_opcode             = ALU_NOP;
        schedule.instruction_controls[4].alu_operand_a_register = regfile_r8_t'(4'hx);
        schedule.instruction_controls[4].alu_operand_b_register = regfile_r8_t'(4'hx);
        schedule.instruction_controls[4].alu_inc_dec            = 1'bx;
        schedule.instruction_controls[4].alu_destination        = regfile_r8_t'(4'hx);
        schedule.instruction_controls[4].alu_wren               = 1'b0;
        schedule.instruction_controls[4].enable_interrupts      = 1'b0;
        schedule.instruction_controls[4].disable_interrupts     = 1'b0;
        schedule.instruction_controls[4].write_interrupt_vector = 1'b0;
        schedule.instruction_controls[4].clear_interrupt_flag   = 1'b0;
        schedule.instruction_controls[4].rst_cmd                = 1'b0;
        schedule.instruction_controls[4].cc_check               = 1'b0;
        schedule.instruction_controls[4].overwrite_wren         = 1'b0;
        schedule.instruction_controls[4].overwrite_req          = regfile_r16_t'(3'bxxx);
        schedule.instruction_controls[4].set_adj                = 1'b0;
        schedule.instruction_controls[4].add_adj                = 1'b0;
        // Fill remaining instruction slots
        schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        return schedule;
    endfunction : interruptServiceRoutine

    // }}}

    // 8-BIT LOAD INSTRUCTIONS {{{

    function automatic schedule_t load8Bit(
        opcode_r8_t sourceReg = opcode_r8_t'(4'hx),  // main register to read from or write to
        opcode_r8_t otherReg = opcode_r8_t'(4'hx),  // some loads use the values from an additional register
        opcode_r16mem_t addrReg = opcode_r16mem_t'(3'bxxx),  // 16 bit register exposed on address bus
        logic writeToMem = 1'b0,  // if we write to memory (load from register to memory)
        logic direct = 1'b0,  // 'direct' subset of load commands
        logic offsetAddr = 1'b0,  // if the address is of the format 0xFF00 + n
        logic immediate = 1'b0,  // if we write an immediate value to register/memory
        logic regToReg = 1'b0,  // do 1-cycle register load
        logic indirectInc = 1'b0,  // if we do the indirect inc on HL
        logic indirectDec = 1'b0  // if we do the indirect dec on HL
    );

        schedule_t schedule, blankSchedule;
        regfile_r8_t reg_source, reg_other;
        regfile_r16_t reg_addr;
        schedule.bit_cmd        = 1'b0;
        schedule.cb_prefix_next = 1'b0;
        blankSchedule           = emptySchedule();
        reg_source              = opcodeR8Decode(sourceReg);
        reg_other               = opcodeR8Decode(otherReg);
        reg_addr                = opcodeR16memDecode(addrReg);

        if (regToReg) begin
            // 1 cycle  - place value from one register into another
            schedule.m_cycles                                       = 3'd0;
            // Cycle 1 - load value from other register into source register, get next opcode
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = reg_other;
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = reg_source;
            schedule.instruction_controls[0].alu_wren               = 1'b1;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[1]                        = blankSchedule.instruction_controls[1];
            schedule.instruction_controls[2]                        = blankSchedule.instruction_controls[2];
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (immediate & ~writeToMem) begin
            // 2 cycles - load immediate to register
            schedule.m_cycles                                       = 3'd1;
            // Cycle 1 - get immediate from opcode and increment program counter
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - write immediate to register and get next opcode
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[1].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_PC;
            schedule.instruction_controls[1].idu_destination        = REG_PC;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = REG_TMP_L;
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = reg_source;
            schedule.instruction_controls[1].alu_wren               = 1'b1;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[2]                        = blankSchedule.instruction_controls[2];
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (immediate & writeToMem) begin
            // 3 cycles - write immediate to memory
            schedule.m_cycles                                       = 3'd2;
            // Cycle 1 - get immediate and increment program counter
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - write immediate to value pointed to by HL
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_HL;
            schedule.instruction_controls[1].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].data_bus_o_source      = REG_TMP_L;
            schedule.instruction_controls[1].drive_data_bus         = 1'b1;
            schedule.instruction_controls[1].receive_data_bus       = 1'b0;
            schedule.instruction_controls[1].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[1].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].idu_wren               = 1'b0;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = reg_source;
            schedule.instruction_controls[1].alu_wren               = 1'b0;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - get next opcode
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[2].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[2].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].drive_data_bus         = 1'b0;
            schedule.instruction_controls[2].receive_data_bus       = 1'b1;
            schedule.instruction_controls[2].idu_opcode             = IDU_INC;
            schedule.instruction_controls[2].idu_operand            = REG_PC;
            schedule.instruction_controls[2].idu_destination        = REG_PC;
            schedule.instruction_controls[2].idu_wren               = 1'b1;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_wren               = 1'b0;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b0;
            schedule.instruction_controls[2].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (direct & ~offsetAddr) begin
            // 4 cycles - write to/from accumulator with 16 bit immediate as address
            schedule.m_cycles                                       = 3'd3;
            // Cycle 1 - get immediate lsb and increment program counter
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - get immediate msb and increment program counter
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[1].data_bus_i_destination = REG_TMP_H;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_PC;
            schedule.instruction_controls[1].idu_destination        = REG_PC;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_wren               = 1'b0;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - (write mem) write register A over the bus (read mem) read memory to temp register
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = REG_TMP;
            schedule.instruction_controls[2].data_bus_i_destination = writeToMem ? regfile_r8_t'(4'hx) : REG_TMP_L;
            schedule.instruction_controls[2].data_bus_o_source      = writeToMem ? REG_A : regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].drive_data_bus         = writeToMem;
            schedule.instruction_controls[2].receive_data_bus       = ~writeToMem;
            schedule.instruction_controls[2].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[2].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].idu_wren               = 1'b0;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_wren               = 1'b0;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b0;
            schedule.instruction_controls[2].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b0;
            // Cycle 4 - (both) get next opcode (read mem) write value to register A
            schedule.instruction_controls[3].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[3].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[3].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[3].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].drive_data_bus         = 1'b0;
            schedule.instruction_controls[3].receive_data_bus       = 1'b1;
            schedule.instruction_controls[3].idu_opcode             = IDU_INC;
            schedule.instruction_controls[3].idu_operand            = REG_PC;
            schedule.instruction_controls[3].idu_destination        = REG_PC;
            schedule.instruction_controls[3].idu_wren               = 1'b1;
            schedule.instruction_controls[3].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[3].alu_operand_a_register = writeToMem ? regfile_r8_t'(4'hx) : REG_TMP_L;
            schedule.instruction_controls[3].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[3].alu_destination        = writeToMem ? regfile_r8_t'(4'hx) : REG_A;
            schedule.instruction_controls[3].alu_wren               = ~writeToMem;
            schedule.instruction_controls[3].enable_interrupts      = 1'b0;
            schedule.instruction_controls[3].disable_interrupts     = 1'b0;
            schedule.instruction_controls[3].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[3].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[3].rst_cmd                = 1'b0;
            schedule.instruction_controls[3].cc_check               = 1'b0;
            schedule.instruction_controls[3].overwrite_wren         = 1'b0;
            schedule.instruction_controls[3].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[3].set_adj                = 1'b0;
            schedule.instruction_controls[3].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (direct & offsetAddr) begin
            // 3 cycles - with to/from accumulator with 0xFF00 + 8 bit immediate as address
            schedule.m_cycles                                       = 3'd2;
            // Cycle 1 - get immediate and increment program counter
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - (write mem) write register A over the bus (read mem) read memory to temp register
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG8;
            schedule.instruction_controls[1].addr_bus_source_r8     = REG_TMP_L;
            schedule.instruction_controls[1].addr_bus_source_r16    = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].data_bus_i_destination = writeToMem ? regfile_r8_t'(4'hx) : REG_TMP_L;
            schedule.instruction_controls[1].data_bus_o_source      = writeToMem ? REG_A : regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = writeToMem;
            schedule.instruction_controls[1].receive_data_bus       = ~writeToMem;
            schedule.instruction_controls[1].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[1].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].idu_wren               = 1'b0;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_wren               = 1'b0;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - (write mem) get next opcode (read mem) get next opcode and write value to register A
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[2].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[2].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].drive_data_bus         = 1'b0;
            schedule.instruction_controls[2].receive_data_bus       = 1'b1;
            schedule.instruction_controls[2].idu_opcode             = IDU_INC;
            schedule.instruction_controls[2].idu_operand            = REG_PC;
            schedule.instruction_controls[2].idu_destination        = REG_PC;
            schedule.instruction_controls[2].idu_wren               = 1'b1;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_register = writeToMem ? regfile_r8_t'(4'hx) : REG_TMP_L;
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = writeToMem ? regfile_r8_t'(4'hx) : REG_A;
            schedule.instruction_controls[2].alu_wren               = ~writeToMem;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b0;
            schedule.instruction_controls[2].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else begin
            // 2 cycles - write to/from register from/to specified address
            //            possible special additions (offset address, indirect inc/dec)
            schedule.m_cycles = 3'd1;
            // Cycle 1
            //   Write to Mem:  drive register to address (r16 or 0xFF00 + reg C)
            //   Read from Mem: read in value at address (r16 or 0xFF00 + reg C) to TEMP register low byte
            schedule.instruction_controls[0].addr_bus_source = offsetAddr ? ADDR_BUS_REG8 : ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8 = offsetAddr ? REG_C : regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16 = offsetAddr ? regfile_r16_t'(3'bxxx) : reg_addr;
            schedule.instruction_controls[0].data_bus_i_destination = writeToMem ? regfile_r8_t'(4'hx) : REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source = writeToMem ? reg_source : regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus = writeToMem;
            schedule.instruction_controls[0].receive_data_bus = ~writeToMem;
            schedule.instruction_controls[0].idu_opcode = indirectInc ? IDU_INC : indirectDec ? IDU_DEC : IDU_NOP;
            schedule.instruction_controls[0].idu_operand            = (indirectInc|indirectDec) ? REG_HL : regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_destination        = (indirectInc|indirectDec) ? REG_HL : regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_wren = indirectInc | indirectDec;
            schedule.instruction_controls[0].alu_opcode = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec = 1'b0;
            schedule.instruction_controls[0].alu_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren = 1'b0;
            schedule.instruction_controls[0].enable_interrupts = 1'b0;
            schedule.instruction_controls[0].disable_interrupts = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag = 1'b0;
            schedule.instruction_controls[0].rst_cmd = 1'b0;
            schedule.instruction_controls[0].cc_check = 1'b0;
            schedule.instruction_controls[0].overwrite_wren = 1'b0;
            schedule.instruction_controls[0].overwrite_req = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj = 1'b0;
            schedule.instruction_controls[0].add_adj = 1'b0;
            // Cycle 2
            //   Both: read in next opcode
            //   Read from Mem: write memory value to register
            schedule.instruction_controls[1].addr_bus_source = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8 = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16 = REG_PC;
            schedule.instruction_controls[1].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[1].data_bus_o_source = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus = 1'b0;
            schedule.instruction_controls[1].receive_data_bus = 1'b1;
            schedule.instruction_controls[1].idu_opcode = IDU_INC;
            schedule.instruction_controls[1].idu_operand = REG_PC;
            schedule.instruction_controls[1].idu_destination = REG_PC;
            schedule.instruction_controls[1].idu_wren = 1'b1;
            schedule.instruction_controls[1].alu_opcode = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = writeToMem ? regfile_r8_t'(4'hx) : REG_TMP_L;
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec = 1'b0;
            schedule.instruction_controls[1].alu_destination = writeToMem ? regfile_r8_t'(4'hx) : reg_source;
            schedule.instruction_controls[1].alu_wren = ~writeToMem;
            schedule.instruction_controls[1].enable_interrupts = 1'b0;
            schedule.instruction_controls[1].disable_interrupts = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag = 1'b0;
            schedule.instruction_controls[1].rst_cmd = 1'b0;
            schedule.instruction_controls[1].cc_check = 1'b0;
            schedule.instruction_controls[1].overwrite_wren = 1'b0;
            schedule.instruction_controls[1].overwrite_req = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj = 1'b0;
            schedule.instruction_controls[1].add_adj = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[2] = blankSchedule.instruction_controls[2];
            schedule.instruction_controls[3] = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4] = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5] = blankSchedule.instruction_controls[5];
        end

        return schedule;

    endfunction : load8Bit

    // }}}

    // 16-BIT LOAD INSTRUCTIONS {{{

    function automatic schedule_t load16Bit(opcode_r16stk_t stackOpReg = opcode_r16stk_t'(2'bxx),
                                            opcode_r16_t sourceReg = opcode_r16_t'(2'bxx), logic load16Reg = 1'b0,
                                            logic loadStackDirect = 1'b0, logic loadStackHL = 1'b0, logic pushOp = 1'b0,
                                            logic popOp = 1'b0, logic loadAdjusted = 1'b0);

        schedule_t schedule, blankSchedule;
        regfile_r16_t reg_source;
        schedule.bit_cmd        = 1'b0;
        schedule.cb_prefix_next = 1'b0;
        blankSchedule           = emptySchedule();
        if (pushOp | popOp) reg_source = opcodeR16stkDecode(stackOpReg);
        else if (load16Reg | loadStackDirect) reg_source = opcodeR16Decode(sourceReg);
        else reg_source = regfile_r16_t'(3'bxxx);

        if (load16Reg) begin
            // 3 cycles  - load 16 bit immediate to 16 bit register pair
            schedule.m_cycles                                       = 3'd2;
            // Cycle 1 - get immediate lsb, increment PC
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - get immediate msb, increment PC
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[1].data_bus_i_destination = REG_TMP_H;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_PC;
            schedule.instruction_controls[1].idu_destination        = REG_PC;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_wren               = 1'b0;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - write immediate to register pair, get next opcode
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[2].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[2].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].drive_data_bus         = 1'b0;
            schedule.instruction_controls[2].receive_data_bus       = 1'b1;
            schedule.instruction_controls[2].idu_opcode             = IDU_INC;
            schedule.instruction_controls[2].idu_operand            = REG_PC;
            schedule.instruction_controls[2].idu_destination        = REG_PC;
            schedule.instruction_controls[2].idu_wren               = 1'b1;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_wren               = 1'b0;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b1;
            schedule.instruction_controls[2].overwrite_req          = reg_source;
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (loadStackDirect) begin
            // 5 cycles  - load value of SP to address of 16 bit immediate and address after that
            schedule.m_cycles                                       = 3'd4;
            // Cycle 1 - get immediate lsb, increment PC
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - get immediate msb, increment PC
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[1].data_bus_i_destination = REG_TMP_H;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_PC;
            schedule.instruction_controls[1].idu_destination        = REG_PC;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_wren               = 1'b0;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - write lsb of SP to memory at TMP, increment TMP
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = REG_TMP;
            schedule.instruction_controls[2].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].data_bus_o_source      = REG_SP_L;
            schedule.instruction_controls[2].drive_data_bus         = 1'b1;
            schedule.instruction_controls[2].receive_data_bus       = 1'b0;
            schedule.instruction_controls[2].idu_opcode             = IDU_INC;
            schedule.instruction_controls[2].idu_operand            = REG_TMP;
            schedule.instruction_controls[2].idu_destination        = REG_TMP;
            schedule.instruction_controls[2].idu_wren               = 1'b1;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_wren               = 1'b0;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b0;
            schedule.instruction_controls[2].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b0;
            // Cycle 4 - write msb of SP to memory at TMP
            schedule.instruction_controls[3].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[3].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].addr_bus_source_r16    = REG_TMP;
            schedule.instruction_controls[3].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].data_bus_o_source      = REG_SP_H;
            schedule.instruction_controls[3].drive_data_bus         = 1'b1;
            schedule.instruction_controls[3].receive_data_bus       = 1'b0;
            schedule.instruction_controls[3].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[3].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[3].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[3].idu_wren               = 1'b0;
            schedule.instruction_controls[3].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[3].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[3].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_wren               = 1'b0;
            schedule.instruction_controls[3].enable_interrupts      = 1'b0;
            schedule.instruction_controls[3].disable_interrupts     = 1'b0;
            schedule.instruction_controls[3].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[3].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[3].rst_cmd                = 1'b0;
            schedule.instruction_controls[3].cc_check               = 1'b0;
            schedule.instruction_controls[3].overwrite_wren         = 1'b0;
            schedule.instruction_controls[3].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[3].set_adj                = 1'b0;
            schedule.instruction_controls[3].add_adj                = 1'b0;
            // Cycle 5 - request next opcode
            schedule.instruction_controls[4].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[4].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[4].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[4].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[4].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[4].drive_data_bus         = 1'b0;
            schedule.instruction_controls[4].receive_data_bus       = 1'b1;
            schedule.instruction_controls[4].idu_opcode             = IDU_INC;
            schedule.instruction_controls[4].idu_operand            = REG_PC;
            schedule.instruction_controls[4].idu_destination        = REG_PC;
            schedule.instruction_controls[4].idu_wren               = 1'b1;
            schedule.instruction_controls[4].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[4].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[4].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[4].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[4].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[4].alu_wren               = 1'b0;
            schedule.instruction_controls[4].enable_interrupts      = 1'b0;
            schedule.instruction_controls[4].disable_interrupts     = 1'b0;
            schedule.instruction_controls[4].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[4].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[4].rst_cmd                = 1'b0;
            schedule.instruction_controls[4].cc_check               = 1'b0;
            schedule.instruction_controls[4].overwrite_wren         = 1'b0;
            schedule.instruction_controls[4].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[4].set_adj                = 1'b0;
            schedule.instruction_controls[4].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (loadStackHL) begin
            // 2 cycles  - overwrite SP with the value in HL
            schedule.m_cycles                                       = 3'd1;
            // Cycle 1 - set SP to HL
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_HL;
            schedule.instruction_controls[0].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b0;
            schedule.instruction_controls[0].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[0].idu_operand            = REG_HL;
            schedule.instruction_controls[0].idu_destination        = REG_SP;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - request next opcode
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[1].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_PC;
            schedule.instruction_controls[1].idu_destination        = REG_PC;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_wren               = 1'b0;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[2]                        = blankSchedule.instruction_controls[2];
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (pushOp) begin
            // 4 cycles  - push register pair to stack
            schedule.m_cycles                                       = 3'd3;
            // Cycle 1 - decrement SP
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_SP;
            schedule.instruction_controls[0].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b0;
            schedule.instruction_controls[0].idu_opcode             = IDU_DEC;
            schedule.instruction_controls[0].idu_operand            = REG_SP;
            schedule.instruction_controls[0].idu_destination        = REG_SP;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'bx;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - write register msb to SP, decrement SP
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_SP;
            schedule.instruction_controls[1].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].data_bus_o_source      = getRegisterHigh(reg_source);
            schedule.instruction_controls[1].drive_data_bus         = 1'b1;
            schedule.instruction_controls[1].receive_data_bus       = 1'b0;
            schedule.instruction_controls[1].idu_opcode             = IDU_DEC;
            schedule.instruction_controls[1].idu_operand            = REG_SP;
            schedule.instruction_controls[1].idu_destination        = REG_SP;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'bx;
            schedule.instruction_controls[1].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_wren               = 1'b0;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - write register lsb to SP
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = REG_SP;
            schedule.instruction_controls[2].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].data_bus_o_source      = getRegisterLow(reg_source);
            schedule.instruction_controls[2].drive_data_bus         = 1'b1;
            schedule.instruction_controls[2].receive_data_bus       = 1'b0;
            schedule.instruction_controls[2].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[2].idu_operand            = REG_SP;
            schedule.instruction_controls[2].idu_destination        = REG_SP;
            schedule.instruction_controls[2].idu_wren               = 1'b1;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'bx;
            schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_wren               = 1'b0;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b0;
            schedule.instruction_controls[2].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b0;
            // Cycle 4 - get next opcode
            schedule.instruction_controls[3].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[3].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[3].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[3].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].drive_data_bus         = 1'b0;
            schedule.instruction_controls[3].receive_data_bus       = 1'b1;
            schedule.instruction_controls[3].idu_opcode             = IDU_INC;
            schedule.instruction_controls[3].idu_operand            = REG_PC;
            schedule.instruction_controls[3].idu_destination        = REG_PC;
            schedule.instruction_controls[3].idu_wren               = 1'b1;
            schedule.instruction_controls[3].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[3].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[3].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_wren               = 1'b0;
            schedule.instruction_controls[3].enable_interrupts      = 1'b0;
            schedule.instruction_controls[3].disable_interrupts     = 1'b0;
            schedule.instruction_controls[3].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[3].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[3].rst_cmd                = 1'b0;
            schedule.instruction_controls[3].cc_check               = 1'b0;
            schedule.instruction_controls[3].overwrite_wren         = 1'b0;
            schedule.instruction_controls[3].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[3].set_adj                = 1'b0;
            schedule.instruction_controls[3].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (popOp) begin
            // 3 cycles  - pop 16 bit value from stack to register pair
            schedule.m_cycles                                       = 3'd2;
            // Cycle 1 - store lsb value at SP, increment SP
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_SP;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_SP;
            schedule.instruction_controls[0].idu_destination        = REG_SP;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'bx;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - store msb value at SP, increment SP
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_SP;
            schedule.instruction_controls[1].data_bus_i_destination = REG_TMP_H;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_SP;
            schedule.instruction_controls[1].idu_destination        = REG_SP;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'bx;
            schedule.instruction_controls[1].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_wren               = 1'b0;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - request next opcode and set register to stored stack value
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[2].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[2].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].drive_data_bus         = 1'b0;
            schedule.instruction_controls[2].receive_data_bus       = 1'b1;
            schedule.instruction_controls[2].idu_opcode             = IDU_INC;
            schedule.instruction_controls[2].idu_operand            = REG_PC;
            schedule.instruction_controls[2].idu_destination        = REG_PC;
            schedule.instruction_controls[2].idu_wren               = 1'b1;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_wren               = 1'b0;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b1;
            schedule.instruction_controls[2].overwrite_req          = reg_source;
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else begin
            // 3 cycles  - write the sum of signed 8-bit value 'e' and 16-bit SP register to HL
            schedule.m_cycles                                       = 3'd2;
            // Cycle 1 - get 8-bit signed immediate 'e'
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - set register L to sum (add) of 'e' and SP_low, set the adjustment value
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_ZERO;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b0;
            schedule.instruction_controls[1].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[1].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].idu_wren               = 1'b0;
            schedule.instruction_controls[1].alu_opcode             = ADD;
            schedule.instruction_controls[1].alu_operand_a_register = REG_SP_L;
            schedule.instruction_controls[1].alu_operand_b_register = REG_TMP_L;
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = REG_L;
            schedule.instruction_controls[1].alu_wren               = 1'b1;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b1;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - set register H to sum (adc) of adjustment and SP_high, request next opcode
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[2].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[2].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].drive_data_bus         = 1'b0;
            schedule.instruction_controls[2].receive_data_bus       = 1'b1;
            schedule.instruction_controls[2].idu_opcode             = IDU_INC;
            schedule.instruction_controls[2].idu_operand            = REG_PC;
            schedule.instruction_controls[2].idu_destination        = REG_PC;
            schedule.instruction_controls[2].idu_wren               = 1'b1;
            schedule.instruction_controls[2].alu_opcode             = ADC;
            schedule.instruction_controls[2].alu_operand_a_register = REG_SP_H;
            schedule.instruction_controls[2].alu_operand_b_register = REG_TMP_H;
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = REG_H;
            schedule.instruction_controls[2].alu_wren               = 1'b1;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b0;
            schedule.instruction_controls[2].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b1;
            // Fill remaining instruction slots
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end

        return schedule;

    endfunction : load16Bit

    // }}}

    // 8-BIT ARITHMETIC AND LOGICAL INSTRUCTIONS {{{

    function automatic schedule_t arithmetic8Bit(alu_opcode_t alu_opcode, opcode_r8_t r8 = opcode_r8_t'(3'bxxx),
                                                 logic immediate_op = 1'b0, logic writeResult = 1'b1,
                                                 logic incDec = 1'b0);

        schedule_t schedule, blankSchedule;
        regfile_r8_t operand_b;
        schedule.bit_cmd        = 1'b0;
        schedule.cb_prefix_next = 1'b0;
        blankSchedule           = emptySchedule();
        operand_b               = opcodeR8Decode(r8);

        if (incDec && (r8 == R8_HL_ADDR)) begin
            // Three-cycle memory inc/dec operation (indirect HL)
            schedule.m_cycles                                       = 3'd2;
            // Cycle 1 - get value at address HL
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_HL;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[0].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_wren               = 1'b0;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - inc/dec the memory value and send it back over the data bus
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_HL;
            schedule.instruction_controls[1].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].data_bus_o_source      = REG_TMP_L;
            schedule.instruction_controls[1].drive_data_bus         = 1'b1;
            schedule.instruction_controls[1].receive_data_bus       = 1'b0;
            schedule.instruction_controls[1].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[1].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].idu_wren               = 1'b0;
            schedule.instruction_controls[1].alu_opcode             = alu_opcode;
            schedule.instruction_controls[1].alu_operand_a_register = REG_A;
            schedule.instruction_controls[1].alu_operand_b_register = REG_TMP_L;
            schedule.instruction_controls[1].alu_inc_dec            = 1'b1;
            schedule.instruction_controls[1].alu_destination        = REG_TMP_L;
            schedule.instruction_controls[1].alu_wren               = writeResult;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - request next instruction
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[2].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[2].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].drive_data_bus         = 1'b0;
            schedule.instruction_controls[2].receive_data_bus       = 1'b1;
            schedule.instruction_controls[2].idu_opcode             = IDU_INC;
            schedule.instruction_controls[2].idu_operand            = REG_PC;
            schedule.instruction_controls[2].idu_destination        = REG_PC;
            schedule.instruction_controls[2].idu_wren               = 1'b1;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_wren               = 1'b0;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b0;
            schedule.instruction_controls[2].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (immediate_op) begin
            // Two-cycle immediate arithmetic
            schedule.m_cycles                                       = 3'd1;
            // Cycle 1 - increment the Program Counter to get the immediate
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - perform arithmetic with the immediate
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[1].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_PC;
            schedule.instruction_controls[1].idu_destination        = REG_PC;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = alu_opcode;
            schedule.instruction_controls[1].alu_operand_a_register = REG_A;
            schedule.instruction_controls[1].alu_operand_b_register = REG_TMP_L;
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = REG_A;
            schedule.instruction_controls[1].alu_wren               = writeResult;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[2]                        = blankSchedule.instruction_controls[2];
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (r8 == R8_HL_ADDR) begin
            // Two-cycle memory arithmetic (indirect HL)
            schedule.m_cycles                                       = 3'd1;
            // Cycle 1 - load value from memory at address HL
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_HL;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[0].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_wren               = 1'b0;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - perform arithmetic
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[1].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_PC;
            schedule.instruction_controls[1].idu_destination        = REG_PC;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = alu_opcode;
            schedule.instruction_controls[1].alu_operand_a_register = REG_A;
            schedule.instruction_controls[1].alu_operand_b_register = REG_TMP_L;
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = REG_A;
            schedule.instruction_controls[1].alu_wren               = writeResult;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[2]                        = blankSchedule.instruction_controls[2];
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else begin
            // Single-cycle register arithmetic
            schedule.m_cycles                                       = 3'd0;
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = alu_opcode;
            schedule.instruction_controls[0].alu_operand_a_register = REG_A;
            schedule.instruction_controls[0].alu_operand_b_register = operand_b;
            schedule.instruction_controls[0].alu_inc_dec            = incDec;
            schedule.instruction_controls[0].alu_destination        = incDec ? operand_b : REG_A;
            schedule.instruction_controls[0].alu_wren               = writeResult;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[1]                        = blankSchedule.instruction_controls[1];
            schedule.instruction_controls[2]                        = blankSchedule.instruction_controls[2];
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end

        return schedule;

    endfunction : arithmetic8Bit

    // }}}

    // 16-BIT ARITHMETIC INSTRUCTIONS {{{

    function automatic schedule_t arithmetic16Bit(logic addSP = 1'b0, logic addHL = 1'b0, logic incDec = 1'b0,
                                                  opcode_r16_t r16 = opcode_r16_t'(2'bxx));
        // Internal Variables
        schedule_t schedule, blankSchedule;
        regfile_r8_t rr_lo, rr_hi;
        regfile_r16_t rr;
        // Schedule common values
        schedule.bit_cmd        = 1'b0;
        schedule.cb_prefix_next = 1'b0;
        blankSchedule           = emptySchedule();
        // Set helper registers
        rr                      = opcodeR16Decode(r16);
        rr_lo                   = getRegisterLow(rr);
        rr_hi                   = getRegisterHigh(rr);

        if (addSP) begin
            // Relative add to Stack Pointer - 4 M cycles
            schedule.m_cycles                                       = 3'd3;
            // Cycle 1 - obtain signed immediate from memory
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_SP;
            schedule.instruction_controls[0].idu_destination        = REG_SP;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - unsigned add of immediate and lsb of SP
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_ZERO;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].data_bus_o_source      = REG_TMP_L;
            schedule.instruction_controls[1].drive_data_bus         = 1'b1;
            schedule.instruction_controls[1].receive_data_bus       = 1'b0;
            schedule.instruction_controls[1].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[1].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].idu_wren               = 1'b0;
            schedule.instruction_controls[1].alu_opcode             = ADD;
            schedule.instruction_controls[1].alu_operand_a_register = REG_SP_L;
            schedule.instruction_controls[1].alu_operand_b_register = REG_TMP_L;
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = REG_TMP_L;
            schedule.instruction_controls[1].alu_wren               = 1'b1;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b1;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - adc with sign extension of immediate and msb of SP
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_ZERO;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].data_bus_o_source      = REG_TMP_H;
            schedule.instruction_controls[2].drive_data_bus         = 1'b1;
            schedule.instruction_controls[2].receive_data_bus       = 1'b0;
            schedule.instruction_controls[2].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[2].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].idu_wren               = 1'b0;
            schedule.instruction_controls[2].alu_opcode             = ADC;
            schedule.instruction_controls[2].alu_operand_a_register = REG_SP_H;
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = REG_TMP_H;
            schedule.instruction_controls[2].alu_wren               = 1'b1;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b0;
            schedule.instruction_controls[2].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b1;
            // Cycle 4 - request next opcode and overwrite SP
            schedule.instruction_controls[3].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[3].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[3].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[3].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].drive_data_bus         = 1'b0;
            schedule.instruction_controls[3].receive_data_bus       = 1'b1;
            schedule.instruction_controls[3].idu_opcode             = IDU_INC;
            schedule.instruction_controls[3].idu_operand            = REG_PC;
            schedule.instruction_controls[3].idu_destination        = REG_PC;
            schedule.instruction_controls[3].idu_wren               = 1'b1;
            schedule.instruction_controls[3].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[3].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[3].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_wren               = 1'b0;
            schedule.instruction_controls[3].enable_interrupts      = 1'b0;
            schedule.instruction_controls[3].disable_interrupts     = 1'b0;
            schedule.instruction_controls[3].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[3].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[3].rst_cmd                = 1'b0;
            schedule.instruction_controls[3].cc_check               = 1'b0;
            schedule.instruction_controls[3].overwrite_wren         = 1'b1;
            schedule.instruction_controls[3].overwrite_req          = REG_SP;
            schedule.instruction_controls[3].set_adj                = 1'b0;
            schedule.instruction_controls[3].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (addHL) begin
            // ADD HL, r16, 2 M cycles
            schedule.m_cycles                                       = 3'd1;
            // Cycle 1 - partial addition for lsb
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_ZERO;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b0;
            schedule.instruction_controls[0].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[0].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_wren               = 1'b0;
            schedule.instruction_controls[0].alu_opcode             = ADD;
            schedule.instruction_controls[0].alu_operand_a_register = REG_L;
            schedule.instruction_controls[0].alu_operand_b_register = rr_lo;
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = REG_L;
            schedule.instruction_controls[0].alu_wren               = 1'b1;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - addition for msb and request the next opcode
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[1].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_PC;
            schedule.instruction_controls[1].idu_destination        = REG_PC;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = ADC;
            schedule.instruction_controls[1].alu_operand_a_register = REG_H;
            schedule.instruction_controls[1].alu_operand_b_register = rr_hi;
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = REG_H;
            schedule.instruction_controls[1].alu_wren               = 1'b1;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[2]                        = blankSchedule.instruction_controls[2];
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else begin
            // 16-bit INC/DEC, 2 M cycles
            schedule.m_cycles                                       = 3'd1;
            // Cycle 1 - use the IDU to increment/decrement the specified register
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = rr;
            schedule.instruction_controls[0].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b0;
            schedule.instruction_controls[0].idu_opcode             = incDec ? IDU_INC : IDU_DEC;
            schedule.instruction_controls[0].idu_operand            = rr;
            schedule.instruction_controls[0].idu_destination        = rr;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - request the next opcode
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[1].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_PC;
            schedule.instruction_controls[1].idu_destination        = REG_PC;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_wren               = 1'b0;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[2]                        = blankSchedule.instruction_controls[2];
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end

        return schedule;

    endfunction : arithmetic16Bit

    // }}}

    // ROTATE, SHIFT, AND BIT OPERATION INSTRUCTIONS {{{

    function automatic schedule_t rotateShiftBit(alu_opcode_t opcode,  // ALU operation to execute
                                                 opcode_r8_t r8 = opcode_r8_t'(4'hx),  // register to operate on
                                                 logic indirectHL = 1'b0,  // write result to memory at address HL
                                                 logic bitSetRes = 1'b0 // if command is BIT, SET, RES
    );

        // Internal Variables
        schedule_t schedule, blankSchedule;
        regfile_r8_t reg_source;
        // Schedule common values
        schedule.bit_cmd        = bitSetRes;
        schedule.cb_prefix_next = 1'b0;
        blankSchedule           = emptySchedule();
        // Set helper registers
        reg_source              = opcodeR8Decode(r8);

        // The only unique operation is BIT indirectHL which is 2 cycles (since it doesn't write back to memory)
        if (opcode == BIT && indirectHL) begin
            // Two Cycles - fetch value at memory, perform BIT on value and fetch next instruction
            schedule.m_cycles                                       = 3'd1;
            // Cycle 1 - obtain value from memory
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_HL;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[0].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_wren               = 1'b0;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - perform BIT and fetch next instruction
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[1].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_PC;
            schedule.instruction_controls[1].idu_destination        = REG_PC;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = opcode;
            schedule.instruction_controls[1].alu_operand_a_register = REG_TMP_L;
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = REG_TMP_L;
            schedule.instruction_controls[1].alu_wren               = 1'b1;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[2]                        = blankSchedule.instruction_controls[2];
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (indirectHL) begin
            // Three Cycles - fetch value at memory, perform operation and write back to memory, fetch next instruction
            schedule.m_cycles                                       = 3'd2;
            // Cycle 1 - obtain value from memory
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_HL;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[0].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_wren               = 1'b0;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - perform selected operation and write result to memory
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_HL;
            schedule.instruction_controls[1].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].data_bus_o_source      = REG_TMP_L;
            schedule.instruction_controls[1].drive_data_bus         = 1'b1;
            schedule.instruction_controls[1].receive_data_bus       = 1'b0;
            schedule.instruction_controls[1].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[1].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].idu_wren               = 1'b0;
            schedule.instruction_controls[1].alu_opcode             = opcode;
            schedule.instruction_controls[1].alu_operand_a_register = REG_TMP_L;
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = REG_TMP_L;
            schedule.instruction_controls[1].alu_wren               = 1'b1;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - fetch next instruction
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[2].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[2].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].drive_data_bus         = 1'b0;
            schedule.instruction_controls[2].receive_data_bus       = 1'b1;
            schedule.instruction_controls[2].idu_opcode             = IDU_INC;
            schedule.instruction_controls[2].idu_operand            = REG_PC;
            schedule.instruction_controls[2].idu_destination        = REG_PC;
            schedule.instruction_controls[2].idu_wren               = 1'b1;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_wren               = 1'b0;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b0;
            schedule.instruction_controls[2].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else begin
            schedule.m_cycles                                       = 3'd0;
            // Single Cycle - perform operation on selected register and fetch next instruction
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = opcode;
            schedule.instruction_controls[0].alu_operand_a_register = reg_source;
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = reg_source;
            schedule.instruction_controls[0].alu_wren               = 1'b1;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[1]                        = blankSchedule.instruction_controls[1];
            schedule.instruction_controls[2]                        = blankSchedule.instruction_controls[2];
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end

        return schedule;

    endfunction : rotateShiftBit

    // }}}

    // CONTROL FLOW INSTRUCTIONS {{{

    function automatic schedule_t controlFlow(logic conditional = 1'b0, logic jump = 1'b0, logic jumpHL = 1'b0,
                                              logic jumpRelative = 1'b0, logic call = 1'b0, logic ret = 1'b0,
                                              logic reti = 1'b0, logic restart = 1'b0);

        // Internal Variables
        schedule_t schedule, blankSchedule;
        // Schedule common values
        schedule.bit_cmd        = 1'b0;
        schedule.cb_prefix_next = 1'b0;
        blankSchedule           = emptySchedule();

        if (jumpHL) begin
            // Unconditional jump to address HL
            schedule.m_cycles                                       = 3'd0;
            // Cycle 1 - set program counter to HL, fetch instruction at HL
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_HL;
            schedule.instruction_controls[0].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_HL;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[1]                        = blankSchedule.instruction_controls[1];
            schedule.instruction_controls[2]                        = blankSchedule.instruction_controls[2];
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (jump) begin
            // 4 cycles - jump to address at 16 bit immediate
            schedule.m_cycles                                       = 3'd3;
            // Cycle 1 - get immediate lsb and increment program counter
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - get immediate msb and increment program counter (conditional) check condition code
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[1].data_bus_i_destination = REG_TMP_H;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_PC;
            schedule.instruction_controls[1].idu_destination        = REG_PC;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_wren               = 1'b0;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = conditional;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - set program counter to immediate
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_ZERO;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].drive_data_bus         = 1'b0;
            schedule.instruction_controls[2].receive_data_bus       = 1'b0;
            schedule.instruction_controls[2].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[2].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].idu_wren               = 1'b0;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_wren               = 1'b0;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b1;
            schedule.instruction_controls[2].overwrite_req          = REG_PC;
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b0;
            // Cycle 4 - fetch next instruction
            schedule.instruction_controls[3].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[3].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[3].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[3].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].drive_data_bus         = 1'b0;
            schedule.instruction_controls[3].receive_data_bus       = 1'b1;
            schedule.instruction_controls[3].idu_opcode             = IDU_INC;
            schedule.instruction_controls[3].idu_operand            = REG_PC;
            schedule.instruction_controls[3].idu_destination        = REG_PC;
            schedule.instruction_controls[3].idu_wren               = 1'b1;
            schedule.instruction_controls[3].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[3].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[3].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_wren               = 1'b0;
            schedule.instruction_controls[3].enable_interrupts      = 1'b0;
            schedule.instruction_controls[3].disable_interrupts     = 1'b0;
            schedule.instruction_controls[3].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[3].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[3].rst_cmd                = 1'b0;
            schedule.instruction_controls[3].cc_check               = 1'b0;
            schedule.instruction_controls[3].overwrite_wren         = 1'b0;
            schedule.instruction_controls[3].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[3].set_adj                = 1'b0;
            schedule.instruction_controls[3].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (jumpRelative) begin
            // 3 cycles - jump to current address + sign-extended 8 bit immediate
            schedule.m_cycles                                       = 3'd2;
            // Cycle 1 - get immediate lsb, increment PC, set adjustment (conditional) check condition code
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = conditional;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b1;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - set TMP to the sum of the adjusted immediate and the Program Counter (set both ei and di for this signal)
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_ZERO;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b0;
            schedule.instruction_controls[1].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[1].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].idu_wren               = 1'b0;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_wren               = 1'b0;
            schedule.instruction_controls[1].enable_interrupts      = 1'b1;
            schedule.instruction_controls[1].disable_interrupts     = 1'b1;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - fetch instruction at TMP, set Program Counter to TMP+1
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = REG_TMP;
            schedule.instruction_controls[2].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[2].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].drive_data_bus         = 1'b0;
            schedule.instruction_controls[2].receive_data_bus       = 1'b1;
            schedule.instruction_controls[2].idu_opcode             = IDU_INC;
            schedule.instruction_controls[2].idu_operand            = REG_TMP;
            schedule.instruction_controls[2].idu_destination        = REG_PC;
            schedule.instruction_controls[2].idu_wren               = 1'b1;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_wren               = 1'b0;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b0;
            schedule.instruction_controls[2].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (call) begin
            // 6 cycles - function call to address at 16 bit immediate
            schedule.m_cycles                                       = 3'd5;
            // Cycle 1 - get immediate lsb and increment program counter
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - get immediate msb and increment program counter (conditional) check condition code
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[1].data_bus_i_destination = REG_TMP_H;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_PC;
            schedule.instruction_controls[1].idu_destination        = REG_PC;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_wren               = 1'b0;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = conditional;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - decrement Stack Pointer
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = REG_SP;
            schedule.instruction_controls[2].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].drive_data_bus         = 1'b0;
            schedule.instruction_controls[2].receive_data_bus       = 1'b0;
            schedule.instruction_controls[2].idu_opcode             = IDU_DEC;
            schedule.instruction_controls[2].idu_operand            = REG_SP;
            schedule.instruction_controls[2].idu_destination        = REG_SP;
            schedule.instruction_controls[2].idu_wren               = 1'b1;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_wren               = 1'b0;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b0;
            schedule.instruction_controls[2].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b0;
            // Cycle 4 - push msb of Program Counter to stack, decrement Stack Pointer
            schedule.instruction_controls[3].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[3].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].addr_bus_source_r16    = REG_SP;
            schedule.instruction_controls[3].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].data_bus_o_source      = REG_PC_H;
            schedule.instruction_controls[3].drive_data_bus         = 1'b1;
            schedule.instruction_controls[3].receive_data_bus       = 1'b0;
            schedule.instruction_controls[3].idu_opcode             = IDU_DEC;
            schedule.instruction_controls[3].idu_operand            = REG_SP;
            schedule.instruction_controls[3].idu_destination        = REG_SP;
            schedule.instruction_controls[3].idu_wren               = 1'b1;
            schedule.instruction_controls[3].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[3].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[3].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_wren               = 1'b0;
            schedule.instruction_controls[3].enable_interrupts      = 1'b0;
            schedule.instruction_controls[3].disable_interrupts     = 1'b0;
            schedule.instruction_controls[3].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[3].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[3].rst_cmd                = 1'b0;
            schedule.instruction_controls[3].cc_check               = 1'b0;
            schedule.instruction_controls[3].overwrite_wren         = 1'b0;
            schedule.instruction_controls[3].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[3].set_adj                = 1'b0;
            schedule.instruction_controls[3].add_adj                = 1'b0;
            // Cycle 5 - push lsb of Program Counter to stack, set Program Counter to immediate
            schedule.instruction_controls[4].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[4].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[4].addr_bus_source_r16    = REG_SP;
            schedule.instruction_controls[4].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[4].data_bus_o_source      = REG_PC_L;
            schedule.instruction_controls[4].drive_data_bus         = 1'b1;
            schedule.instruction_controls[4].receive_data_bus       = 1'b0;
            schedule.instruction_controls[4].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[4].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[4].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[4].idu_wren               = 1'b0;
            schedule.instruction_controls[4].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[4].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[4].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[4].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[4].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[4].alu_wren               = 1'b0;
            schedule.instruction_controls[4].enable_interrupts      = 1'b0;
            schedule.instruction_controls[4].disable_interrupts     = 1'b0;
            schedule.instruction_controls[4].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[4].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[4].rst_cmd                = 1'b0;
            schedule.instruction_controls[4].cc_check               = 1'b0;
            schedule.instruction_controls[4].overwrite_wren         = 1'b1;
            schedule.instruction_controls[4].overwrite_req          = REG_PC;
            schedule.instruction_controls[4].set_adj                = 1'b0;
            schedule.instruction_controls[4].add_adj                = 1'b0;
            // Cycle 6 - fetch next instruction
            schedule.instruction_controls[5].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[5].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[5].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[5].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[5].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[5].drive_data_bus         = 1'b0;
            schedule.instruction_controls[5].receive_data_bus       = 1'b1;
            schedule.instruction_controls[5].idu_opcode             = IDU_INC;
            schedule.instruction_controls[5].idu_operand            = REG_PC;
            schedule.instruction_controls[5].idu_destination        = REG_PC;
            schedule.instruction_controls[5].idu_wren               = 1'b1;
            schedule.instruction_controls[5].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[5].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[5].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[5].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[5].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[5].alu_wren               = 1'b0;
            schedule.instruction_controls[5].enable_interrupts      = 1'b0;
            schedule.instruction_controls[5].disable_interrupts     = 1'b0;
            schedule.instruction_controls[5].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[5].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[5].rst_cmd                = 1'b0;
            schedule.instruction_controls[5].cc_check               = 1'b0;
            schedule.instruction_controls[5].overwrite_wren         = 1'b0;
            schedule.instruction_controls[5].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[5].set_adj                = 1'b0;
            schedule.instruction_controls[5].add_adj                = 1'b0;
        end else if ((ret | reti) & ~conditional) begin
            // 4 cycles - return from a function
            schedule.m_cycles                                       = 3'd3;
            // Cycle 1 - pop lsb from stack, increment Stack Pointer
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_SP;
            schedule.instruction_controls[0].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_SP;
            schedule.instruction_controls[0].idu_destination        = REG_SP;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - pop msb from stack, increment Stack Pointer
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_SP;
            schedule.instruction_controls[1].data_bus_i_destination = REG_TMP_H;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_SP;
            schedule.instruction_controls[1].idu_destination        = REG_SP;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_wren               = 1'b0;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - set Program Counter to immediate (reti) enable interrupts
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_ZERO;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].drive_data_bus         = 1'b0;
            schedule.instruction_controls[2].receive_data_bus       = 1'b0;
            schedule.instruction_controls[2].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[2].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].idu_wren               = 1'b0;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_wren               = 1'b0;
            schedule.instruction_controls[2].enable_interrupts      = reti;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b1;
            schedule.instruction_controls[2].overwrite_req          = REG_PC;
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b0;
            // Cycle 4 - fetch next instruction
            schedule.instruction_controls[3].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[3].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[3].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[3].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].drive_data_bus         = 1'b0;
            schedule.instruction_controls[3].receive_data_bus       = 1'b1;
            schedule.instruction_controls[3].idu_opcode             = IDU_INC;
            schedule.instruction_controls[3].idu_operand            = REG_PC;
            schedule.instruction_controls[3].idu_destination        = REG_PC;
            schedule.instruction_controls[3].idu_wren               = 1'b1;
            schedule.instruction_controls[3].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[3].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[3].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_wren               = 1'b0;
            schedule.instruction_controls[3].enable_interrupts      = 1'b0;
            schedule.instruction_controls[3].disable_interrupts     = 1'b0;
            schedule.instruction_controls[3].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[3].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[3].rst_cmd                = 1'b0;
            schedule.instruction_controls[3].cc_check               = 1'b0;
            schedule.instruction_controls[3].overwrite_wren         = 1'b0;
            schedule.instruction_controls[3].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[3].set_adj                = 1'b0;
            schedule.instruction_controls[3].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else if (ret & conditional) begin
            // 5 cycles - check condition, if true return from a function
            schedule.m_cycles                                       = 3'd4;
            // Cycle 1 - condition check
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_ZERO;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b0;
            schedule.instruction_controls[0].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[0].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_wren               = 1'b0;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = conditional;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - pop lsb from stack, increment Stack Pointer
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_SP;
            schedule.instruction_controls[1].data_bus_i_destination = REG_TMP_L;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].receive_data_bus       = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_SP;
            schedule.instruction_controls[1].idu_destination        = REG_SP;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_wren               = 1'b0;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - pop msb from stack, increment Stack Pointer
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = REG_SP;
            schedule.instruction_controls[2].data_bus_i_destination = REG_TMP_H;
            schedule.instruction_controls[2].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].drive_data_bus         = 1'b0;
            schedule.instruction_controls[2].receive_data_bus       = 1'b1;
            schedule.instruction_controls[2].idu_opcode             = IDU_INC;
            schedule.instruction_controls[2].idu_operand            = REG_SP;
            schedule.instruction_controls[2].idu_destination        = REG_SP;
            schedule.instruction_controls[2].idu_wren               = 1'b1;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_wren               = 1'b0;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b0;
            schedule.instruction_controls[2].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b0;
            // Cycle 4 - set Program Counter to immediate
            schedule.instruction_controls[3].addr_bus_source        = ADDR_BUS_ZERO;
            schedule.instruction_controls[3].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].addr_bus_source_r16    = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[3].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].drive_data_bus         = 1'b0;
            schedule.instruction_controls[3].receive_data_bus       = 1'b0;
            schedule.instruction_controls[3].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[3].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[3].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[3].idu_wren               = 1'b0;
            schedule.instruction_controls[3].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[3].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[3].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_wren               = 1'b0;
            schedule.instruction_controls[3].enable_interrupts      = 1'b0;
            schedule.instruction_controls[3].disable_interrupts     = 1'b0;
            schedule.instruction_controls[3].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[3].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[3].rst_cmd                = 1'b0;
            schedule.instruction_controls[3].cc_check               = 1'b0;
            schedule.instruction_controls[3].overwrite_wren         = 1'b1;
            schedule.instruction_controls[3].overwrite_req          = REG_PC;
            schedule.instruction_controls[3].set_adj                = 1'b0;
            schedule.instruction_controls[3].add_adj                = 1'b0;
            // Cycle 5 - fetch next instruction
            schedule.instruction_controls[4].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[4].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[4].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[4].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[4].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[4].drive_data_bus         = 1'b0;
            schedule.instruction_controls[4].receive_data_bus       = 1'b1;
            schedule.instruction_controls[4].idu_opcode             = IDU_INC;
            schedule.instruction_controls[4].idu_operand            = REG_PC;
            schedule.instruction_controls[4].idu_destination        = REG_PC;
            schedule.instruction_controls[4].idu_wren               = 1'b1;
            schedule.instruction_controls[4].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[4].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[4].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[4].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[4].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[4].alu_wren               = 1'b0;
            schedule.instruction_controls[4].enable_interrupts      = 1'b0;
            schedule.instruction_controls[4].disable_interrupts     = 1'b0;
            schedule.instruction_controls[4].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[4].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[4].rst_cmd                = 1'b0;
            schedule.instruction_controls[4].cc_check               = 1'b0;
            schedule.instruction_controls[4].overwrite_wren         = 1'b0;
            schedule.instruction_controls[4].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[4].set_adj                = 1'b0;
            schedule.instruction_controls[4].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else begin
            // 4 cycles - restart call to fixed address in the opcode
            schedule.m_cycles                                       = 3'd3;
            // Cycle 1 - decrement Stack Pointer
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_SP;
            schedule.instruction_controls[0].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b0;
            schedule.instruction_controls[0].idu_opcode             = IDU_DEC;
            schedule.instruction_controls[0].idu_operand            = REG_SP;
            schedule.instruction_controls[0].idu_destination        = REG_SP;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Cycle 2 - push msb of Program Counter to stack, decrement Stack Pointer
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_SP;
            schedule.instruction_controls[1].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].data_bus_o_source      = REG_PC_H;
            schedule.instruction_controls[1].drive_data_bus         = 1'b1;
            schedule.instruction_controls[1].receive_data_bus       = 1'b0;
            schedule.instruction_controls[1].idu_opcode             = IDU_DEC;
            schedule.instruction_controls[1].idu_operand            = REG_SP;
            schedule.instruction_controls[1].idu_destination        = REG_SP;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[1].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].alu_wren               = 1'b0;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[1].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            schedule.instruction_controls[1].overwrite_wren         = 1'b0;
            schedule.instruction_controls[1].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[1].set_adj                = 1'b0;
            schedule.instruction_controls[1].add_adj                = 1'b0;
            // Cycle 3 - push lsb of Program Counter to stack, set Program Counter to restart address
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = REG_SP;
            schedule.instruction_controls[2].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].data_bus_o_source      = REG_PC_L;
            schedule.instruction_controls[2].drive_data_bus         = 1'b1;
            schedule.instruction_controls[2].receive_data_bus       = 1'b0;
            schedule.instruction_controls[2].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[2].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[2].idu_wren               = 1'b0;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_wren               = 1'b0;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[2].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b1;
            schedule.instruction_controls[2].cc_check               = 1'b0;
            schedule.instruction_controls[2].overwrite_wren         = 1'b1;
            schedule.instruction_controls[2].overwrite_req          = REG_PC;
            schedule.instruction_controls[2].set_adj                = 1'b0;
            schedule.instruction_controls[2].add_adj                = 1'b0;
            // Cycle 4 - fetch next instruction
            schedule.instruction_controls[3].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[3].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[3].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[3].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].drive_data_bus         = 1'b0;
            schedule.instruction_controls[3].receive_data_bus       = 1'b1;
            schedule.instruction_controls[3].idu_opcode             = IDU_INC;
            schedule.instruction_controls[3].idu_operand            = REG_PC;
            schedule.instruction_controls[3].idu_destination        = REG_PC;
            schedule.instruction_controls[3].idu_wren               = 1'b1;
            schedule.instruction_controls[3].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[3].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[3].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[3].alu_wren               = 1'b0;
            schedule.instruction_controls[3].enable_interrupts      = 1'b0;
            schedule.instruction_controls[3].disable_interrupts     = 1'b0;
            schedule.instruction_controls[3].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[3].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[3].rst_cmd                = 1'b0;
            schedule.instruction_controls[3].cc_check               = 1'b0;
            schedule.instruction_controls[3].overwrite_wren         = 1'b0;
            schedule.instruction_controls[3].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[3].set_adj                = 1'b0;
            schedule.instruction_controls[3].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end

        return schedule;

    endfunction : controlFlow

    // }}}

    // MISCELLANEOUS INSTRUCTIONS {{{

    function automatic schedule_t miscOp(logic noOp = 1'b0, logic cbNext = 1'b0, logic di = 1'b0, logic ei = 1'b0,
                                         logic halt = 1'b0, logic stop = 1'b0);

        // Internal Variables
        schedule_t schedule, blankSchedule;
        // Schedule common values
        schedule.bit_cmd        = 1'b0;
        schedule.cb_prefix_next = cbNext;
        blankSchedule           = emptySchedule();

        // STOP might be 2-cycle? otherwise everything executes in one cycle
        if (halt | stop) begin
            schedule.m_cycles                                       = 3'd0;
            // Single Cycle - literally do nothing, only interrupts can break this
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b0;
            schedule.instruction_controls[0].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[0].idu_operand            = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_destination        = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].idu_wren               = 1'b0;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[1]                        = blankSchedule.instruction_controls[1];
            schedule.instruction_controls[2]                        = blankSchedule.instruction_controls[2];
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end else begin
            schedule.m_cycles                                       = 3'd0;
            // Single Cycle - fetch next instruction, perform operation if requested
            schedule.instruction_controls[0].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[0].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[0].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[0].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].drive_data_bus         = 1'b0;
            schedule.instruction_controls[0].receive_data_bus       = 1'b1;
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = ei;
            schedule.instruction_controls[0].disable_interrupts     = di;
            schedule.instruction_controls[0].write_interrupt_vector = 1'b0;
            schedule.instruction_controls[0].clear_interrupt_flag   = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            schedule.instruction_controls[0].overwrite_wren         = 1'b0;
            schedule.instruction_controls[0].overwrite_req          = regfile_r16_t'(3'bxxx);
            schedule.instruction_controls[0].set_adj                = 1'b0;
            schedule.instruction_controls[0].add_adj                = 1'b0;
            // Fill remaining instruction slots
            schedule.instruction_controls[1]                        = blankSchedule.instruction_controls[1];
            schedule.instruction_controls[2]                        = blankSchedule.instruction_controls[2];
            schedule.instruction_controls[3]                        = blankSchedule.instruction_controls[3];
            schedule.instruction_controls[4]                        = blankSchedule.instruction_controls[4];
            schedule.instruction_controls[5]                        = blankSchedule.instruction_controls[5];
        end

        return schedule;

    endfunction : miscOp

    // }}}

endpackage : gb_cpu_decoder_pkg
