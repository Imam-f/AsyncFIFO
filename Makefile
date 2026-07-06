MODULE=fifo
SIM ?= iverilog

.PHONY: sim
sim: waveform.vcd

# --- Icarus Verilog ---
.PHONY: compile-iverilog
compile-iverilog: $(MODULE).vvp

$(MODULE).vvp: $(MODULE).v $(MODULE)_tb.v
	@echo
	@echo "### COMPILING WITH ICARUS VERILOG ###"
	iverilog -g2005 -o $(MODULE).vvp -DVCD_DUMP $(MODULE).v $(MODULE)_tb.v

# --- Verilator ---
.PHONY: verilate
verilate: obj_dir/V$(MODULE)

obj_dir/V$(MODULE): $(MODULE).v $(MODULE)_tb.cpp
	@echo
	@echo "### VERILATING ###"
	verilator -Wall --trace --x-assign unique --x-initial unique -cc $(MODULE).v --exe $(MODULE)_tb.cpp

obj_dir/V$(MODULE)$(EXE): obj_dir/V$(MODULE)
	@echo
	@echo "### BUILDING SIM ###"
	make -C obj_dir -f V$(MODULE).mk V$(MODULE)

# --- Shared rules ---
.PHONY: waves
waves: waveform.vcd
	@echo
	@echo "### WAVES ###"
	gtkwave waveform.vcd

.PHONY: lint
lint: $(MODULE).v
	verilator --lint-only $(MODULE).v

.PHONY: clean
clean:
	rm -rf $(MODULE).vvp waveform.vcd obj_dir/

# --- Dispatch based on SIM ---
ifeq ($(SIM),iverilog)
waveform.vcd: $(MODULE).vvp
	@echo
	@echo "### SIMULATING (iverilog) ###"
	vvp $(MODULE).vvp
else ifeq ($(SIM),verilator)
waveform.vcd: obj_dir/V$(MODULE)
	@echo
	@echo "### SIMULATING (verilator) ###"
	./obj_dir/V$(MODULE) +verilator+rand+reset+2
else
$(error Unknown simulator: $(SIM). Use SIM=iverilog or SIM=verilator)
endif
