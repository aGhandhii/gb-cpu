# Conditional Compilation Rules
# Verilator doesn't have a native windows port
WINDOWS         = 1
ICARUS          = 1
VERILATOR       =

# Setup
PROJ            = Project
BUILD_DIR       = ./build
SIM_DIR         = ./sim
SV2V_DIR        = ./sv2v
TEST_BIN        = $(SIM_DIR)/$(TOP).vvp
TEST_WAVE       = $(SIM_DIR)/$(TOP).vcd
TEST_LOG        = $(SIM_DIR)/$(TOP).log

# RTL Files
TOP             = decoder_tb
TESTBENCH       = ./test/decoder_tb.sv
ifdef WINDOWS
RTL_FILES       = $(shell fd -e sv -e svh -e v . '.\src')
else
RTL_FILES       = $(shell find ./src -name '*.sv') $(shell find ./src -name '*.svh') $(shell find ./src -name '*.v')
endif

# Synthesis Files
PCF             = icebreaker.pcf

.PHONY: all synth timing prog sv2v test clean

all: synth

synth: $(BUILD_DIR)/$(PROJ).asc $(BUILD_DIR)/$(PROJ).bin
	# Store build files separately
	mkdir -p $(BUILD_DIR)
	# Synthesis -> Yosys with slang for SystemVerilog
	yosys -m slang -f slang -p "synth_ice40 -top $(TOP) -blif $(BUILD_DIR)/$(PROJ).blif -json $(BUILD_DIR)/$(PROJ).json" $(RTL_FILES)
	# Place and Route -> NextPNR 
	nextpnr-ice40 --up5k --package sg48 --json build/$(PROJ).json --pcf $(PCF) --asc build/$(PROJ).asc
	# Convert to Bitstream -> IcePack
	icepack $(BUILD_DIR)/$(PROJ).asc $(BUILD_DIR)/$(PROJ).bin

timing: $(BUILD_DIR)/$(PROJ).asc
	icetime -d up5k $(BUILD_DIR)/$(PROJ).asc

prog: $(BUILD_DIR)/$(PROJ).bin
	iceprog $(BUILD_DIR)/$(PROJ).bin

sv2v:
	# Convert SystemVerilog to Verilog - needed for Icarus
ifdef ICARUS
	mkdir -p $(SV2V_DIR)
	sv2v --write=$(SV2V_DIR) --top=$(TOP) $(TESTBENCH) $(RTL_FILES)
endif

test: sv2v
	mkdir -p $(SIM_DIR)
	# Simulate the design with Icarus
ifdef ICARUS
ifdef WINDOWS
	iverilog -o $(TEST_BIN) -s $(TOP) $(shell fd -I . '.\sv2v')
else
	iverilog -o $(TEST_BIN) -s $(TOP) $(shell find ./sv2v -name '*.v')
endif
	# Run simulation results - obtain wave file if generated
	vvp -l $(TEST_LOG) -n $(TEST_BIN)
	# TODO: only peform if waveform is created
	mv $(TOP).vcd $(TEST_WAVE)
	# Open the wave file in a waveform viewer
	surfer $(TEST_WAVE)
endif
	# TODO: add build instructions for Verilator
ifdef VERILATOR
	# Untested
	verilator -CFLAGS -fcoroutines --binary --timing --trace  --top-module $(TOP) $(RTL_FILES) $(TESTBENCH)
endif

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(SIM_DIR)
	rm -rf $(SV2V_DIR)
