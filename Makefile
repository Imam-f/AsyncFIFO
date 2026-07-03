MODULE=fifo

.PHONY:verilate
verilate: .stamp.verilate

.stamp.verilate: $(MODULE).v $(MODULE)_tb.cpp
	@echo
	@echo "### VERILATING ###"
	verilator -Wall --trace --x-assign unique --x-initial unique -cc $(MODULE).v --exe $(MODULE)_tb.cpp
	@touch .stamp.verilate

.PHONY:lint
lint: $(MODULE).v
	verilator --lint-only $(MODULE).v

.PHONY: clean
clean:
	rm -rf .stamp.*;
	rm -rf ./obj_dir
	rm -rf waveform.vcd
