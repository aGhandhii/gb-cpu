import gb_cpu_common_pkg::*;

// Decoder instruction scheduling
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

    // Returns a schedule with undefined values - use this to pad other instructions
    function automatic schedule_t emptySchedule();
        schedule_t schedule;
        schedule.m_cycles       = 3'bxxx;
        schedule.bit_cmd        = 1'bx;
        schedule.cb_prefix_next = 1'bx;
        schedule.condition      = condition_code_t'(2'bxx);
        for (logic [2:0] i = 0; i < 3'd6; i++) begin
            schedule.instruction_controls[i].addr_bus_source        = addr_bus_source_t'(2'bxx);
            schedule.instruction_controls[i].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[i].addr_bus_source_r16    = regfile_r16_t'(8'hxx);
            schedule.instruction_controls[i].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[i].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[i].drive_data_bus         = 1'bx;
            schedule.instruction_controls[i].idu_opcode             = idu_opcode_t'(2'bxx);
            schedule.instruction_controls[i].idu_operand            = regfile_r16_t'(8'hxx);
            schedule.instruction_controls[i].idu_destination        = regfile_r16_t'(8'hxx);
            schedule.instruction_controls[i].idu_wren               = 1'bx;
            schedule.instruction_controls[i].alu_opcode             = alu_opcode_t'(5'bxxxxx);
            schedule.instruction_controls[i].alu_operand_a_source   = alu_operand_source_t'(2'bxx);
            schedule.instruction_controls[i].alu_operand_b_source   = alu_operand_source_t'(2'bxx);
            schedule.instruction_controls[i].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[i].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[i].alu_inc_dec            = 1'bx;
            schedule.instruction_controls[i].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[i].alu_wren               = 1'bx;
            schedule.instruction_controls[i].enable_interrupts      = 1'bx;
            schedule.instruction_controls[i].disable_interrupts     = 1'bx;
            schedule.instruction_controls[i].rst_cmd                = 1'bx;
            schedule.instruction_controls[i].cc_check               = 1'bx;
        end
        return schedule;
    endfunction : emptySchedule


    // 8-BIT LOAD INSTRUCTIONS {{{

    // }}}

    // 16-BIT LOAD INSTRUCTIONS {{{

    // }}}

    // 8-BIT ARITHMETIC AND LOGICAL INSTRUCTIONS {{{

    function static schedule_t arithmetic8Bit(alu_opcode_t alu_opcode, opcode_r8_t r8 = opcode_r8_t'(3'bxxx),
                                              logic immediate_op = 1'b0, logic writeResult = 1'b1, logic incDec = 1'b0);

        schedule_t schedule, blankSchedule;
        regfile_r8_t operand_b;
        schedule.bit_cmd        = 1'b0;
        schedule.cb_prefix_next = 1'b0;
        schedule.condition      = condition_code_t'(2'bxx);
        blankSchedule           = emptySchedule();  // sim gets mad when a variable and function share a name
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
            schedule.instruction_controls[0].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[0].idu_operand            = regfile_r16_t'(8'hxx);
            schedule.instruction_controls[0].idu_destination        = regfile_r16_t'(8'hxx);
            schedule.instruction_controls[0].idu_wren               = 1'b0;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_source   = alu_operand_source_t'(2'bxx);
            schedule.instruction_controls[0].alu_operand_b_source   = alu_operand_source_t'(2'bxx);
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            // Cycle 2 - inc/dec the memory value and send it back over the data bus
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_HL;
            schedule.instruction_controls[1].data_bus_i_destination = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].data_bus_o_source      = REG_TMP_L;
            schedule.instruction_controls[1].drive_data_bus         = 1'b1;
            schedule.instruction_controls[1].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[1].idu_operand            = regfile_r16_t'(8'hxx);
            schedule.instruction_controls[1].idu_destination        = regfile_r16_t'(8'hxx);
            schedule.instruction_controls[1].idu_wren               = 1'b0;
            schedule.instruction_controls[1].alu_opcode             = alu_opcode;
            schedule.instruction_controls[1].alu_operand_a_source   = ALU_SRC_REG;
            schedule.instruction_controls[1].alu_operand_b_source   = ALU_SRC_REG;
            schedule.instruction_controls[1].alu_operand_a_register = REG_A;
            schedule.instruction_controls[1].alu_operand_b_register = REG_TMP_L;
            schedule.instruction_controls[1].alu_inc_dec            = 1'b1;
            schedule.instruction_controls[1].alu_destination        = REG_TMP_L;
            schedule.instruction_controls[1].alu_wren               = writeResult;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
            // Cycle 3 - request next instruction
            schedule.instruction_controls[2].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[2].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[2].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[2].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].drive_data_bus         = 1'b0;
            schedule.instruction_controls[2].idu_opcode             = IDU_INC;
            schedule.instruction_controls[2].idu_operand            = REG_PC;
            schedule.instruction_controls[2].idu_destination        = REG_PC;
            schedule.instruction_controls[2].idu_wren               = 1'b1;
            schedule.instruction_controls[2].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[2].alu_operand_a_source   = ALU_SRC_REG;
            schedule.instruction_controls[2].alu_operand_b_source   = ALU_SRC_REG;
            schedule.instruction_controls[2].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[2].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[2].alu_wren               = 1'b0;
            schedule.instruction_controls[2].enable_interrupts      = 1'b0;
            schedule.instruction_controls[2].disable_interrupts     = 1'b0;
            schedule.instruction_controls[2].rst_cmd                = 1'b0;
            schedule.instruction_controls[2].cc_check               = 1'b0;
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
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_source   = alu_operand_source_t'(2'bxx);
            schedule.instruction_controls[0].alu_operand_b_source   = alu_operand_source_t'(2'bxx);
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            // Cycle 2 - perform arithmetic with the immediate
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[1].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_PC;
            schedule.instruction_controls[1].idu_destination        = REG_PC;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = alu_opcode;
            schedule.instruction_controls[1].alu_operand_a_source   = ALU_SRC_REG;
            schedule.instruction_controls[1].alu_operand_b_source   = ALU_SRC_REG;
            schedule.instruction_controls[1].alu_operand_a_register = REG_A;
            schedule.instruction_controls[1].alu_operand_b_register = REG_TMP_L;
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = REG_A;
            schedule.instruction_controls[1].alu_wren               = writeResult;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
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
            schedule.instruction_controls[0].idu_opcode             = IDU_NOP;
            schedule.instruction_controls[0].idu_operand            = regfile_r16_t'(8'hxx);
            schedule.instruction_controls[0].idu_destination        = regfile_r16_t'(8'hxx);
            schedule.instruction_controls[0].idu_wren               = 1'b0;
            schedule.instruction_controls[0].alu_opcode             = ALU_NOP;
            schedule.instruction_controls[0].alu_operand_a_source   = alu_operand_source_t'(2'bxx);
            schedule.instruction_controls[0].alu_operand_b_source   = alu_operand_source_t'(2'bxx);
            schedule.instruction_controls[0].alu_operand_a_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_operand_b_register = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[0].alu_destination        = regfile_r8_t'(4'hx);
            schedule.instruction_controls[0].alu_wren               = 1'b0;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
            // Cycle 2 - perform arithmetic
            schedule.instruction_controls[1].addr_bus_source        = ADDR_BUS_REG16;
            schedule.instruction_controls[1].addr_bus_source_r8     = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].addr_bus_source_r16    = REG_PC;
            schedule.instruction_controls[1].data_bus_i_destination = REG_IR;
            schedule.instruction_controls[1].data_bus_o_source      = regfile_r8_t'(4'hx);
            schedule.instruction_controls[1].drive_data_bus         = 1'b0;
            schedule.instruction_controls[1].idu_opcode             = IDU_INC;
            schedule.instruction_controls[1].idu_operand            = REG_PC;
            schedule.instruction_controls[1].idu_destination        = REG_PC;
            schedule.instruction_controls[1].idu_wren               = 1'b1;
            schedule.instruction_controls[1].alu_opcode             = alu_opcode;
            schedule.instruction_controls[1].alu_operand_a_source   = ALU_SRC_REG;
            schedule.instruction_controls[1].alu_operand_b_source   = ALU_SRC_REG;
            schedule.instruction_controls[1].alu_operand_a_register = REG_A;
            schedule.instruction_controls[1].alu_operand_b_register = operand_b;
            schedule.instruction_controls[1].alu_inc_dec            = 1'b0;
            schedule.instruction_controls[1].alu_destination        = REG_A;
            schedule.instruction_controls[1].alu_wren               = writeResult;
            schedule.instruction_controls[1].enable_interrupts      = 1'b0;
            schedule.instruction_controls[1].disable_interrupts     = 1'b0;
            schedule.instruction_controls[1].rst_cmd                = 1'b0;
            schedule.instruction_controls[1].cc_check               = 1'b0;
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
            schedule.instruction_controls[0].idu_opcode             = IDU_INC;
            schedule.instruction_controls[0].idu_operand            = REG_PC;
            schedule.instruction_controls[0].idu_destination        = REG_PC;
            schedule.instruction_controls[0].idu_wren               = 1'b1;
            schedule.instruction_controls[0].alu_opcode             = alu_opcode;
            schedule.instruction_controls[0].alu_operand_a_source   = ALU_SRC_REG;
            schedule.instruction_controls[0].alu_operand_b_source   = ALU_SRC_REG;
            schedule.instruction_controls[0].alu_operand_a_register = REG_A;
            schedule.instruction_controls[0].alu_operand_b_register = operand_b;
            schedule.instruction_controls[0].alu_inc_dec            = incDec;
            schedule.instruction_controls[0].alu_destination        = incDec ? operand_b : REG_A;
            schedule.instruction_controls[0].alu_wren               = writeResult;
            schedule.instruction_controls[0].enable_interrupts      = 1'b0;
            schedule.instruction_controls[0].disable_interrupts     = 1'b0;
            schedule.instruction_controls[0].rst_cmd                = 1'b0;
            schedule.instruction_controls[0].cc_check               = 1'b0;
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

    // }}}

    // ROTATE, SHIFT, AND BIT OPERATION INSTRUCTIONS {{{

    // }}}

endpackage : gb_cpu_decoder_pkg
