# SystemVerilog GameBoy CPU

## Description

This project aims to build a GameBoy CPU with the following functionality:
 
 - [x] Execute GameBoy opcodes with complete Cycle-Accuracy
 - [x] Implement the Timer Circuit
 - [x] Service Timing Interups
 - [ ] Handle the Halt Bug

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
halt_bug     | ❌


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
