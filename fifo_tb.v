`timescale 1ns / 1ps

module fifo_tb #(
        parameter BITWIDTH = 8,
        parameter DEPTH = 16
    )();

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
    reg wr_state = 0;
    reg rd_state = 0;
    reg [6:0] wr_count = 0;
    reg [6:0] rd_count = 0;

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

        repeat (RESET_DELAY) begin
            #1 clk_wr = ~clk_wr;
            #1 clk_rd = ~clk_rd;
        end

        #RESET_DELAY rst_n = 1;

        $display("Starting FIFO Testbench...");
        $monitor("Time: %0t | wr_en: %b | wr_data: %h | rd_en: %b | rd_data: %h | full: %b | empty: %b", 
                 $time, wr_en, wr_data, rd_en, rd_data, full, empty);

        // Drive the clock until the read and write operations are done
        while (!wr_done || !rd_done) begin
            #CLK_WR_DELAY clk_wr = ~clk_wr;
            #CLK_RD_DELAY clk_rd = ~clk_rd;
        end

        // Finish delay
        repeat (FINAL_DELAY) begin
            #CLK_WR_DELAY clk_wr = ~clk_wr;
            #CLK_RD_DELAY clk_rd = ~clk_rd;
        end
        $finish;
    end

    always @(posedge clk_wr) begin
        if (!rst_n) begin
            wr_state <= 0;
            wr_en <= 0;
            wr_data <= 0;
            wr_count <= 0;
            wr_done <= 0;
        end else begin
            case (wr_state)
                0: begin
                    wr_en <= 0;
                    if (wr_count >= MAX_WRITES) begin
                        wr_done <= 1;
                    end else begin
                        wr_state <= 1;
                    end
                end
                1: begin
                    if (!full) begin
                        wr_en <= 1;
                        wr_data <= $random % (2**BITWIDTH);
                    end else begin
                        wr_en <= 0;
                    end
                    wr_count <= wr_count + 1;
                    wr_state <= 0;
                end
            endcase
        end
    end

    always @(posedge clk_rd) begin
        if (!rst_n) begin
            rd_state <= 0;
            rd_en <= 0;
            rd_count <= 0;
            rd_done <= 0;
        end else begin
            case (rd_state)
                0: begin
                    rd_en <= 0;
                    if (rd_count >= MAX_READS) begin
                        rd_done <= 1;
                    end else begin
                        rd_state <= 1;
                    end
                end
                1: begin
                    if (!empty) begin
                        rd_en <= 1;
                    end else begin
                        rd_en <= 0;
                    end
                    rd_count <= rd_count + 1;
                    rd_state <= 0;
                end
            endcase
        end
    end

    // always #CLK_WR_DELAY clk_wr = ~clk_wr;
    // always #CLK_RD_DELAY clk_rd = ~clk_rd;

endmodule
