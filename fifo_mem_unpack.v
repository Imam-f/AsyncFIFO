`ifdef ICARUS
genvar _fifo_i;
generate
    for (_fifo_i = 0; _fifo_i < DEPTH; _fifo_i = _fifo_i + 1) begin : mem_elem
        wire [BITWIDTH-1:0] _data;
        assign _data = fifo_mem[_fifo_i];
    end
endgenerate
`endif
