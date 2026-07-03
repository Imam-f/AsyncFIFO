#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <iomanip>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vfifo.h"

#define BITWIDTH 8
#define DEPTH 16
#define MAX_WRITES 20
#define MAX_READS 20

struct SimState {
    Vfifo *dut;
    VerilatedVcdC *trace;
    std::mutex mtx;
    std::condition_variable cv;
    uint64_t sim_time = 0;
    bool wr_posedge = false;
    bool rd_posedge = false;
    bool wr_ready = false;
    bool rd_ready = false;
    bool finished = false;
    int  write_cnt = 0;
    int  read_cnt  = 0;
    bool wr_asserted = false;
    bool rd_asserted = false;
};

static void tick(SimState &s) {
    std::unique_lock lock(s.mtx);

    bool clk_wr_prev = s.dut->clk_wr;
    bool clk_rd_prev = s.dut->clk_rd;

    if (s.sim_time > 0) {
        s.dut->clk_wr ^= (s.sim_time % 5 == 0);
        s.dut->clk_rd ^= (s.sim_time % 7 == 0);
    }

    s.wr_posedge = (s.dut->clk_wr == 1 && clk_wr_prev == 0);
    s.rd_posedge = (s.dut->clk_rd == 1 && clk_rd_prev == 0);

    if (s.wr_posedge) s.wr_ready = false;
    if (s.rd_posedge) s.rd_ready = false;

    s.cv.notify_all();

    if (s.wr_posedge) s.cv.wait(lock, [&]{ return s.wr_ready || s.finished; });
    if (s.rd_posedge) s.cv.wait(lock, [&]{ return s.rd_ready || s.finished; });

    s.dut->eval();
    if (s.trace) s.trace->dump(s.sim_time);
    printf("Time: %lu\n", s.sim_time);
    s.sim_time++;
}

static void monitor(const SimState &s) {
    std::cout << std::setw(6) << s.sim_time << "  |  "
              << (int)s.dut->wr_en << "    | "
              << "0x" << std::hex << std::setw(2) << std::setfill('0')
              << (int)s.dut->wr_data << std::dec << std::setfill(' ') << "  |  "
              << (int)s.dut->rd_en << "    | "
              << "0x" << std::hex << std::setw(2) << std::setfill('0')
              << (int)s.dut->rd_data << std::dec << std::setfill(' ') << "  |  "
              << (int)s.dut->full << "    | " << (int)s.dut->empty << std::endl;
}

static void writer_process(SimState &s) {
    std::unique_lock lock(s.mtx);
    while (!s.finished) {
        s.cv.wait(lock, [&]{ return s.wr_posedge || s.finished; });
        if (s.finished) break;

        if (s.write_cnt < MAX_WRITES) {
            if (!s.wr_asserted) {
                s.dut->wr_en = !s.dut->full;
                if (!s.dut->full)
                    s.dut->wr_data = rand() % (1 << BITWIDTH);
                s.wr_asserted = true;
            } else {
                s.dut->wr_en = 0;
                s.wr_asserted = false;
                s.write_cnt++;
            }
        }

        s.wr_ready = true;
        s.cv.notify_all();
    }
}

static void reader_process(SimState &s) {
    std::unique_lock lock(s.mtx);
    while (!s.finished) {
        s.cv.wait(lock, [&]{ return s.rd_posedge || s.finished; });
        if (s.finished) break;

        if (s.read_cnt < MAX_READS) {
            if (!s.rd_asserted) {
                s.dut->rd_en = !s.dut->empty;
                s.rd_asserted = true;
            } else {
                s.dut->rd_en = 0;
                s.rd_asserted = false;
                s.read_cnt++;
                if (s.read_cnt <= 5) monitor(s);
            }
        }

        s.rd_ready = true;
        s.cv.notify_all();
    }
}

int main(int argc, char **argv, char **envp) {
    Vfifo *dut = new Vfifo;
    VerilatedVcdC *trace = nullptr;

    Verilated::traceEverOn(true);
    trace = new VerilatedVcdC;
    dut->trace(trace, 5);
    trace->open("waveform.vcd");

    SimState s{dut, trace};

    s.dut->rst_n = 0;
    s.dut->clk_wr = 0;
    s.dut->clk_rd = 0;
    s.dut->wr_en = 0;
    s.dut->rd_en = 0;
    s.dut->wr_data = 0;

    while (s.sim_time < 10) tick(s);
    s.dut->rst_n = 1;

    std::cout << "Starting FIFO Testbench..." << std::endl;
    std::cout << "Time   | wr_en | wr_data | rd_en | rd_data | full | empty" << std::endl;

    std::thread wr(writer_process, std::ref(s));
    std::thread rd(reader_process, std::ref(s));

    while (s.write_cnt < MAX_WRITES || s.read_cnt < MAX_READS) {
        tick(s);
    }

    s.finished = true;
    s.cv.notify_all();
    wr.join();
    rd.join();

    for (int i = 0; i < 10; i++) tick(s);

    trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
    return 0;
}
