# SystemVerilog GameBoy CPU

## Description

This project aims to build a GameBoy CPU with the following functionality:
 
 - [x] Execute GameBoy opcodes with complete Cycle-Accuracy
 - [x] Implement the Timer Circuit
 - [x] Service Timing Interups
 - [x] Handle the Halt Bug (should work, can't confirm until PPU is added)
    - [x] ei before halt, (IE&IF != 0, IME = 0), call ISR but return to halt
    - [x] rst after halt bug (IE&IF != 0, IME = 0), push address of rst to stack, not rst+1
    - [x] halt, (IE&IF != 0, IME = 0), read next opcode twice
    - [x] halt, (IE&IF != 0, IME = 1), call ISR and continue normally
    - [x] ei before halt, (IE&IF != 0, IME = 0), rst after halt. Call ISR, return to halt, rst works normally

The following components are not in the scope of this repository:

- PPU
- APU
- DMA
- Boot ROM
- MBC Cartridges


## Test Status

### blargg
| Test | Result |
| ---  | ---    |
cpu_instrs   | ✅
instr_timing | ✅
mem_timing   | ✅
halt_bug     | ❌ (requires Vblank interrupt, can't test in this scope)


## Resources


| Name | Description |
| ---  | ---         |
[GameBoy Instruction Set](https://gbdev.io/gb-opcodes/optables/)                    | Table View of GameBoy Opcodes
[PanDocs](https://gbdev.io/pandocs/)                                                | General Device Documentation
[rgbds Docs](https://rgbds.gbdev.io/docs)                                           | In-Depth Command Documentation
[GameBoy Complete Technical Reference](https://gekkio.fi/files/gb-docs/gbctr.pdf)   | Cycle-by-Cycle Opcode Breakdowns
[mGBA gbdoc](https://mgba-emu.github.io/gbdoc/)                                     | Additional Device Documentation
[blarggs Test ROMS](https://github.com/retrio/gb-test-roms)                         | Test ROMS
[Mooneye Test ROMS](https://github.com/Gekkio/mooneye-test-suite)                   | Test ROMS
[GameBoy Doctor](https://robertheaton.com/gameboy-doctor/)                          | Support Tool for blargg Test ROMS
