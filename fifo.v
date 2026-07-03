`timescale 1ns / 1ps

module fifo
    #(
        parameter BITWIDTH = 8,
        parameter DEPTH = 16
    )(
        input
            rst_n,
        
        input
            clk_wr,
            wr_en,
            [BITWIDTH-1:0] wr_data,
        
        output 
            full,
            empty,
            [BITWIDTH-1:0] rd_data,
    );

    reg [BITWIDTH-1:0] fifo_mem [0:DEPTH-1];

    reg [$$clog2(DEPTH)-1:0] wr_ptr;
    reg [$$clog2(DEPTH)-1:0] rd_ptr;

    wire full;
    assign full = (wr_ptr + 1 == rd_ptr);

    wire empty;
    assign empty = (wr_ptr == rd_ptr);

    always @(posedge clk_wr) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            fifo_mem[wr_ptr] <= wr_data;
            wr_ptr <= wr_ptr + 1;
        end
    end

    always @(posedge clk_wr) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_data <= fifo_mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end

endmodule