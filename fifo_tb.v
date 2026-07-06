`timescale 1ns / 1ps

module fifo_tb #(
        parameter BITWIDTH = 8,
        parameter DEPTH = 16
    )();

    localparam MAX_WRITES    = 20;
    localparam MAX_READS     = 20;
    localparam CLK_WR_DELAY  = 5;
    localparam CLK_RD_DELAY  = 7;
    localparam RESET_DELAY   = 10;
    localparam FINAL_DELAY   = 100;

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

        #RESET_DELAY rst_n = 1;

        `ifdef VCD_DUMP
        $dumpfile("waveform.vcd");
        $dumpvars(0, fifo_tb);
        `endif

        $display("Starting FIFO Testbench...");
        $monitor("Time: %0t | wr_en: %b | wr_data: %h | rd_en: %b | rd_data: %h | full: %b | empty: %b", 
                 $time, wr_en, wr_data, rd_en, rd_data, full, empty);

        fork
            begin
                repeat (MAX_WRITES) begin
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
            end
            begin
                repeat (MAX_READS) begin
                    @(posedge clk_rd);
                    if (!empty) begin
                        rd_en <= 1;
                    end else begin
                        rd_en <= 0;
                    end
                    @(posedge clk_rd);
                    rd_en <= 0;
                end
            end
        join

        #FINAL_DELAY $finish;
    end

    always #CLK_WR_DELAY clk_wr = ~clk_wr;
    always #CLK_RD_DELAY clk_rd = ~clk_rd;

endmodule
