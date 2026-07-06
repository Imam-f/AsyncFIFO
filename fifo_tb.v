`timescale 1ns / 1ps

module fifo_tb;

    localparam BITWIDTH = 8,
    localparam DEPTH = 16;
    localparam MAX_WRITES    = 60;
    localparam MAX_READS     = 60;
    localparam CLK_WR_DELAY  = 3;
    localparam CLK_RD_DELAY  = 5;
    localparam RESET_DELAY   = 10;
    localparam FINAL_DELAY   = 10;

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

    reg wr_done = 0;
    reg rd_done = 0;
    reg [$clog2(MAX_WRITES)-1:0] wr_count = 0;
    reg [$clog2(MAX_READS)-1:0] rd_count = 0;

    initial begin
        `ifdef VCD_DUMP
        $dumpfile("waveform.vcd");
        $dumpvars(0, fifo_tb);
        `endif

        rst_n = 0;
        clk_wr = 0;
        wr_en = 0;
        wr_data = 0;

        clk_rd = 0;
        rd_en = 0;

        #RESET_DELAY rst_n = 1;

        $display("Starting FIFO Testbench...");
        $monitor("Time: %0t | wr_en: %b | wr_data: %h | rd_en: %b | rd_data: %h | full: %b | empty: %b", 
                 $time, wr_en, wr_data, rd_en, rd_data, full, empty);

        @(wr_done && rd_done);

        #FINAL_DELAY;
        $finish;
    end

    always @(posedge clk_wr) begin
        if (!rst_n) begin
            wr_en <= 0;
            wr_data <= 0;
            wr_count <= 0;
            wr_done <= 0;
        end else begin
            if (wr_en) begin
                wr_en <= 0;
                wr_count <= wr_count + 1;
                if (wr_count >= MAX_WRITES - 1) begin
                    wr_done <= 1;
                end
            end else if (!wr_done) begin
                wr_en <= !full;
                if (!full) begin
                    wr_data <= $random % (1 << BITWIDTH);
                end
            end
        end
    end

    always @(posedge clk_rd) begin
        if (!rst_n) begin
            rd_en <= 0;
            rd_count <= 0;
            rd_done <= 0;
        end else begin
            if (rd_en) begin
                rd_en <= 0;
                rd_count <= rd_count + 1;
                if (rd_count >= MAX_READS - 1) begin
                    rd_done <= 1;
                end
            end else if (!rd_done) begin
                rd_en <= !empty;
            end
        end
    end

    always #CLK_WR_DELAY clk_wr = ~clk_wr;
    always #CLK_RD_DELAY clk_rd = ~clk_rd;

endmodule
