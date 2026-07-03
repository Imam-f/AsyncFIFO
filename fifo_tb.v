`timescale 1ns / 1ps

module fifo_tb #(
        parameter BITWIDTH = 8,
        parameter DEPTH = 16
    )();

    reg rst_n;
    reg clk_wr;
    reg wr_en;
    reg [BITWIDTH-1:0] wr_data;

    reg clk_rd;
    reg rd_en;

    wire full;
    wire empty;
    wire [BITWIDTH-1:0] rd_data;

    fifo #(
        .BITWIDTH(BITWIDTH),
        .DEPTH(DEPTH)
    ) dut (
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

    initial begin
        rst_n = 0;
        clk_wr = 0;
        wr_en = 0;
        wr_data = 0;

        clk_rd = 0;
        rd_en = 0;

        #10 rst_n = 1;

        $display("Starting FIFO Testbench...");
        $monitor("Time: %0t | wr_en: %b | wr_data: %h | rd_en: %b | rd_data: %h | full: %b | empty: %b", 
                 $time, wr_en, wr_data, rd_en, rd_data, full, empty);

        // Write some data into the FIFO
        repeat (20) begin
            @(posedge clk_wr);
            if (!full) begin
                wr_en <= 1;
                wr_data <= $random % (2**BITWIDTH);
            end else begin
                wr_en <= 0;
            end
            @(posedge clk_wr);
            wr_en <= 0;
        end

        // Read some data from the FIFO
        repeat (20) begin
            @(posedge clk_rd);
            if (!empty) begin
                rd_en <= 1;
            end else begin
                rd_en <= 0;
            end
            @(posedge clk_rd);
            rd_en <= 0;
        end

        #10 $finish;
    end

    always #5 clk_wr = ~clk_wr; // Write clock with a period of 10 time units
    always #7 clk_rd = ~clk_rd; // Read clock with a period of 14 time units

endmodule
