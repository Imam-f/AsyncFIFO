# Async FIFO

A small SystemVerilog-compatible Verilog FIFO example with independent write and read clocks. The design is parameterized by data width and storage depth and includes simulation testbenches for Icarus Verilog and Verilator.

## Features

- Independent `clk_wr` and `clk_rd` clock domains
- Configurable data width (`BITWIDTH`, default `8`)
- Configurable memory depth (`DEPTH`, default `16`)
- `full` and `empty` status signals
- Icarus Verilog simulation with optional VCD dumping
- Verilator simulation and linting
- GTKWave waveform target

## Module Interface

The top-level RTL module is `fifo` in [`fifo.v`](fifo.v).

| Port | Direction | Description |
| --- | --- | --- |
| `rst_n` | input | Active-low reset, sampled by both clock domains |
| `clk_wr` | input | Write clock |
| `wr_en` | input | Write request |
| `wr_data` | input | Data to write |
| `clk_rd` | input | Read clock |
| `rd_en` | input | Read request |
| `full` | output | FIFO cannot accept a write |
| `empty` | output | FIFO has no data available to read |
| `rd_data` | output | Most recently read data |

A write occurs when `wr_en` is high and `full` is low. A read occurs when `rd_en` is high and `empty` is low.

## Requirements

- `make`
- Icarus Verilog (`iverilog`, `vvp`) for the default simulation
- Verilator for linting and the Verilator simulation target
- GTKWave for `make waves` (optional)

## Usage

Run the default Icarus Verilog testbench:

```sh
make
```

This compiles `fifo.v` and `fifo_tb.v`, runs the simulation, and writes `waveform.vcd`.

Run the Verilator testbench instead:

```sh
make SIM=verilator
```

Run linting:

```sh
make lint
```

Open the generated waveform:

```sh
make waves
```

Remove generated simulation artifacts:

```sh
make clean
```

## Parameters

Example instantiation:

```verilog
fifo #(
    .BITWIDTH(16),
    .DEPTH(32)
) u_fifo (
    .rst_n(rst_n),
    .clk_wr(clk_wr),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .clk_rd(clk_rd),
    .rd_en(rd_en),
    .full(full),
    .empty(empty),
    .rd_data(rd_data)
);
```

## Repository Layout

- `fifo.v` - FIFO RTL
- `fifo_mem_unpack.v` - Icarus-specific memory visibility helpers
- `fifo_tb.v` - Icarus Verilog testbench
- `fifo_tb.cpp` - Verilator/C++ testbench
- `Makefile` - build, simulation, lint, waveform, and cleanup targets

## Implementation Notes

This repository is an educational FIFO implementation rather than a production CDC-ready FIFO. The read and write pointers directly inspect state from the other clock domain; they are not synchronized through clock-domain-crossing synchronizers. For hardware use, replace this status logic with a standard asynchronous FIFO design, typically using Gray-coded pointers and multi-flop synchronizers.

The current pointer scheme also reserves one entry to distinguish full from empty, so usable capacity is less than `DEPTH`. Use power-of-two depths unless the pointer and flag logic is updated for other depth values.

## License

No license has been specified yet.

I dont understand how any of the jj works
absolutely no idea
about how this works
i commit this on git how?
really how?