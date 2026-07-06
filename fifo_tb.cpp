#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vfifo.h"

#define BITWIDTH 8
#define DEPTH 16
#define MAX_WRITES 60
#define MAX_READS 60
#define CLK_WR_TOGGLE 3
#define CLK_RD_TOGGLE 5
#define RESET_CYCLES 10
#define FINAL_CYCLES 10

uint64_t sim_time = 0;

void eval_model(Vfifo *dut, VerilatedVcdC *m_trace) {
    dut->eval();
    if (m_trace) {
        m_trace->dump(sim_time);
    }
    sim_time++;
}

int main(int argc, char **argv, char **envp) {
    Vfifo *dut = new Vfifo;

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    dut->rst_n = 0;
    dut->clk_wr = 0;
    dut->clk_rd = 0;
    dut->wr_en = 0;
    dut->rd_en = 0;
    dut->wr_data = 0;

    for (int i = 0; i < RESET_CYCLES; i++) {
        if (sim_time % CLK_WR_TOGGLE == 0 && sim_time != 0) {
            dut->clk_wr ^= 1;
        }
        if (sim_time % CLK_RD_TOGGLE == 0 && sim_time != 0) {
            dut->clk_rd ^= 1;
        }
        eval_model(dut, m_trace);
    }
    dut->rst_n = 1;

    std::cout << "Starting FIFO Testbench..." << std::endl;

    int write_cnt = 0;
    int read_cnt  = 0;
    bool wr_asserted = false;
    bool rd_asserted = false;

    while (write_cnt < MAX_WRITES || read_cnt < MAX_READS) {
        bool clk_wr_prev = dut->clk_wr;
        bool clk_rd_prev = dut->clk_rd;

        if (sim_time % CLK_WR_TOGGLE == 0) {
            dut->clk_wr ^= 1;
        }
        if (sim_time % CLK_RD_TOGGLE == 0) {
            dut->clk_rd ^= 1;
        }

        bool wr_posedge = (dut->clk_wr == 1 && clk_wr_prev == 0);
        bool rd_posedge = (dut->clk_rd == 1 && clk_rd_prev == 0);

        std::cout << "Time: " << sim_time << ", write_count: " << 
            write_cnt << ", read_count: " << read_cnt << std::endl;

        if (wr_posedge && write_cnt < MAX_WRITES) {
            if (!wr_asserted) {
                dut->wr_en = !dut->full;
                if (!dut->full) {
                    dut->wr_data = rand() % (1 << BITWIDTH);
                    wr_asserted = true;
                }
            } else {
                dut->wr_en = 0;
                wr_asserted = false;
                write_cnt++;
            }
        }

        if (rd_posedge && read_cnt < MAX_READS) {
            if (!rd_asserted) {
                dut->rd_en = !dut->empty;
                if (!dut->empty) {
                    rd_asserted = true;
                }
            } else {
                dut->rd_en = 0;
                rd_asserted = false;
                read_cnt++;
            }
        }

        eval_model(dut, m_trace);
    }

    for (int i = 0; i < FINAL_CYCLES; i++) {
        if (sim_time % CLK_WR_TOGGLE == 0) {
            dut->clk_wr ^= 1;
        }
        if (sim_time % CLK_RD_TOGGLE == 0) {
            dut->clk_rd ^= 1;
        }
        eval_model(dut, m_trace);
    }

    std::cout << "Testbench completed." << std::endl;

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
    
    return 0;
}
