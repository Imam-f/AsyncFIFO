`timescale 1ns / 1ps

module fifo #(
        parameter BITWIDTH = 8,
        parameter DEPTH = 16
    ) (
        input rst_n,
        
        input clk_wr,
        input wr_en,
        input [BITWIDTH-1:0] wr_data,
        
        input clk_rd,
        input rd_en,
        
        output full,
        output empty,
        output [BITWIDTH-1:0] rd_data
    );

    reg [BITWIDTH-1:0] fifo_mem [0:DEPTH-1];
    `include "fifo_mem_unpack.v"

    reg [$clog2(DEPTH)-1:0] wr_ptr;
    reg [$clog2(DEPTH)-1:0] rd_ptr;

    assign full = (wr_ptr + 1 == rd_ptr);
    assign empty = (wr_ptr == rd_ptr);

    reg [BITWIDTH-1:0] rd_data_wr;
    assign rd_data = rd_data_wr;
    
    always @(posedge clk_wr) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            fifo_mem[wr_ptr] <= wr_data;
            wr_ptr <= wr_ptr + 1;
        end
    end

    always @(posedge clk_rd) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_data_wr <= fifo_mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end

endmodule
