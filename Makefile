MODULE=fifo
SIM ?= iverilog
# SIM ?= verilator

.PHONY: sim
sim: waveform.vcd

# --- Icarus Verilog ---
.PHONY: compile-iverilog
compile-iverilog: obj_dir/$(MODULE).vvp

obj_dir/$(MODULE).vvp: $(MODULE).v $(MODULE)_tb.v | obj_dir
	@echo
	@echo "### COMPILING WITH ICARUS VERILOG ###"
	iverilog -g2005 -o obj_dir/$(MODULE).vvp -DVCD_DUMP -DICARUS $(MODULE).v $(MODULE)_tb.v

obj_dir:
	mkdir -p obj_dir

# --- Verilator ---
.PHONY: verilate
verilate: obj_dir/V$(MODULE).v

obj_dir/V$(MODULE).v: $(MODULE).v $(MODULE)_tb.cpp
	@echo
	@echo "### VERILATING ###"
	verilator -Wall --trace --x-assign unique --x-initial unique -cc $(MODULE).v --exe $(MODULE)_tb.cpp

obj_dir/V$(MODULE)$(EXE): obj_dir/V$(MODULE).v
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
	rm -rf obj_dir/ waveform.vcd

# --- Dispatch based on SIM ---
ifeq ($(SIM),iverilog)
waveform.vcd: obj_dir/$(MODULE).vvp
	@echo
	@echo "### SIMULATING (iverilog) ###"
	vvp obj_dir/$(MODULE).vvp
else ifeq ($(SIM),verilator)
waveform.vcd: obj_dir/V$(MODULE)$(EXE)
	@echo
	@echo "### SIMULATING (verilator) ###"
	./obj_dir/V$(MODULE) +verilator+rand+reset+2
else
$(error Unknown simulator: $(SIM). Use SIM=iverilog or SIM=verilator)
endif
