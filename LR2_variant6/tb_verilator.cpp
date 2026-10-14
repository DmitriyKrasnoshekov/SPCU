#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <string>
#include <vector>

#include "VPico_SoC.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

static vluint64_t sim_time = 0;

static void half_tick(VPico_SoC *top, VerilatedVcdC *trace, int level)
{
    top->clk = level;
    top->f_clk = level;
    top->eval();

    if (trace)
        trace->dump(sim_time);

    sim_time++;
}

static void tick(VPico_SoC *top, VerilatedVcdC *trace)
{
    half_tick(top, trace, 0);
    half_tick(top, trace, 1);
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0]
                  << " quicksort | ram | array <expected_size> [--no-trace]\n";
        return 2;
    }

    const std::string mode = argv[1];
    bool use_trace = true;
    for (int i = 2; i < argc; i++) {
        if (std::string(argv[i]) == "--no-trace")
            use_trace = false;
    }

    int expected_array_size = 0;
    if (mode == "array") {
        if (argc < 3) {
            std::cerr << "array mode needs expected_size\n";
            return 2;
        }
        expected_array_size = std::atoi(argv[2]);
    }

    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(use_trace);

    VPico_SoC *top = new VPico_SoC;
    VerilatedVcdC *trace = nullptr;

    if (use_trace) {
        trace = new VerilatedVcdC;
        top->trace(trace, 99);
        trace->open("verilator.vcd");
    }

    top->rst = 1;
    for (int i = 0; i < 10; i++)
        tick(top, trace);
    top->rst = 0;

    const uint64_t max_cycles = (mode == "array") ? 5000000ULL : 2000000ULL;

    std::vector<int32_t> quicksort_expected = {
        -11, -4, -2, 0, 1, 3, 5, 6, 8, 9,
        12, 14, 17, 19, 21, 23, 27, 31, 35, 42
    };
    uint32_t last_index = 0;

    for (uint64_t cycle = 0; cycle < max_cycles; cycle++) {
        tick(top, trace);

        const uint32_t gpio = top->gpio;
        const uint32_t gpio1 = top->gpio1;

        if (mode == "quicksort") {
            if (gpio1 >= 1 && gpio1 <= quicksort_expected.size() && gpio1 != last_index) {
                const int32_t actual = static_cast<int32_t>(gpio);
                const int32_t expected = quicksort_expected[gpio1 - 1];

                if (actual != expected) {
                    std::cerr << "FAIL: element " << gpio1
                              << ", expected " << expected
                              << ", got " << actual << "\n";
                    if (trace) trace->close();
                    delete trace;
                    delete top;
                    return 1;
                }

                std::cout << "sorted[" << (gpio1 - 1) << "] = " << actual << "\n";
                last_index = gpio1;

                if (last_index == quicksort_expected.size()) {
                    std::cout << "PASS: quicksort result is correct\n";
                    if (trace) trace->close();
                    delete trace;
                    delete top;
                    return 0;
                }
            }
        }
        else if (mode == "ram") {
            if (gpio1 != 0) {
                std::cerr << "FAIL: Wishbone RAM mismatch at word " << gpio1 << "\n";
                if (trace) trace->close();
                delete trace;
                delete top;
                return 1;
            }

            if (gpio == 1) {
                std::cout << "PASS: processor wrote and read the additional Wishbone RAM\n";
                if (trace) trace->close();
                delete trace;
                delete top;
                return 0;
            }
        }
        else if (mode == "array") {
            if (gpio1 == 0x00005A5A) {
                if (static_cast<int32_t>(gpio) == expected_array_size) {
                    if (trace) trace->close();
                    delete trace;
                    delete top;
                    return 0;
                }

                std::cerr << "FAIL: array marker received with wrong size\n";
                if (trace) trace->close();
                delete trace;
                delete top;
                return 1;
            }

            if (gpio1 == 0x0000BAD0) {
                if (trace) trace->close();
                delete trace;
                delete top;
                return 1;
            }
        }
        else {
            std::cerr << "Unknown mode: " << mode << "\n";
            if (trace) trace->close();
            delete trace;
            delete top;
            return 2;
        }

        if (top->trap) {
            std::cerr << "FAIL: CPU entered trap before the expected result\n";
            if (trace) trace->close();
            delete trace;
            delete top;
            return 1;
        }
    }

    std::cerr << "FAIL: simulation timeout\n";
    if (trace) trace->close();
    delete trace;
    delete top;
    return 1;
}
