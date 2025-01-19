# Open-Source SystemVerilog Development Environment for [1BitSquared IceBreaker FPGA](https://docs.icebreaker-fpga.org/)

- Based on the Lattice Ice40UP5
- *NOTE: included pcf file is for IceBreaker 1.0e*

## Open-Source Software Stack:

*NOTE: LAST UPDATED JANUARY 2025*

Name | Description
---  | ---
[Yosys](https://github.com/YosysHQ/yosys)                   | Verilog IEEE 1364-2005 Synthesis
[NextPnR](https://github.com/YosysHQ/nextpnr)               | FPGA Place-and-Route
[Project IceStorm](https://github.com/YosysHQ/icestorm)     | Yosys/NextPnR compatibility layer for Lattice Ice40 FPGA architectures
[Icarus Verilog](https://github.com/steveicarus/iverilog)   | Verilog IEEE 1364-2005 Compiler and Simulator
[Verilator](https://github.com/verilator/verilator)         | SystemVerilog Simulator
[Verible](https://github.com/chipsalliance/verible)         | Formatting and Linting Tools for SystemVerilog
[slang](https://github.com/MikePopoloski/slang)             | SystemVerilog IEEE 1800-2023 Pre-Processor, acts as a plugin for Yosys
[sv2v](https://github.com/zachjs/sv2v)                      | SystemVerilog IEEE 1800-2017 to Verilog IEEE 1364-2005 conversion tool
[Surfer](https://gitlab.com/surfer-project/surfer)          | Waveform Viewer
[CTags](https://ctags.io/)                                  | Source Code Indexer
[fd](https://github.com/sharkdp/fd)                         | WINDOWS ONLY - replacement for unix 'find' tool

** Many of these tools are packaged in the YosysHQ [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build) **

## File Structure

Name | Description
---  | ---
src/            | Contains RTL for synthesis
test/           | Stores RTL testbench files
Makefile        | Scripting to automate Simulation, Synthesis, Place and Route, and Programming
.rules.verible* | Instructions for automated linting, taken from [this template](https://github.com/aGhandhii/systemverilog-auto-lint-format)
icebreaker.pcf  | Pin definitions for the IceBreaker 1.0e

## Git Hooks

*Place in `.git/hooks/*`*

Hook | Description
---  | ---
pre-commit  | Runs verilog linter checks and reformatting tools
post-commit | Regenerates tag file

## Other

Example `.gitignore`

```
*verible*
tags
sv2v/*
build/*
sim/*
```
