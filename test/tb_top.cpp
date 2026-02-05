#include "Vtop.h"              // 顶层模块头文件，由verilator自动生成
#include "Vtop___024root.h"
#include "verilated.h"         // Verilator主头文件
#include "verilated_vcd_c.h"   // 波形生成支持
#include <vector>
#include <iostream>            // 可选，信息打印
#include <fstream>             // 可选，文件读写（如.hex）
#include <iomanip>

#define MAX_SIM_TIME 10000

vluint64_t main_time = 0;      // 全局变量：仿真时钟（Verilator需求）
// 必需的Verilator回调，用于同步外部时间
double sc_time_stamp() { return main_time; }

std::vector<uint32_t> mem;
void load_hex(const char* filename) {
    std::ifstream fin(filename);
    uint32_t val;
    while (fin >> std::hex >> val) {
        // 转为小端序
        uint32_t le_val = ((val & 0xFF) << 24) |
                         ((val & 0xFF00) << 8) |
                         ((val & 0xFF0000) >> 8) |
                         ((val & 0xFF000000) >> 24);
        mem.push_back(le_val);
    }
}

/* ------ 核心testbench主流程 ------ */
int main(int argc, char **argv, char **env) {
    Verilated::commandArgs(argc, argv);  // 支持命令行参数
    std::ofstream log_file("../results/simulation_log.txt");
    Vtop* top = new Vtop;                // 实例化仿真顶层
    VerilatedVcdC* tfp = new VerilatedVcdC;
    Verilated::traceEverOn(true);
    top->trace(tfp, 99);
    tfp->open("dump.vcd");

    // 1. 上电复位
    top->rst_n = 0;
    top->clk = 0;
    for (int i = 0; i < 10; i++) {
        top->clk = !top->clk;
        top->eval();
        tfp->dump(main_time++);
    }
    top->rst_n = 1;

    // 2. 加载内存文件
    load_hex("hex/riscv-tests/rv32ui-p-sw.hex");

    std::cout << "------------------------" << std::endl;
    log_file << "------------------------" << std::endl;
    std::cout << "Loaded memory contents from hex file." << std::endl;
    log_file << "Loaded memory contents from hex file." << std::endl;
    std::cout << "Starting simulation..." << std::endl;
    log_file << "Starting simulation..." << std::endl;
    std::cout << "------------------------" << std::endl;
    log_file << "------------------------" << std::endl;

    int cycle_count = 0;
    const uint32_t BREAK_INST = 0x11111111;
    const uint32_t BREAK_PC = 0x00000044;
    bool stop = false;
    while(main_time < MAX_SIM_TIME && !stop) {
        cycle_count++;
        if (cycle_count % 5 == 0) {
            std::cout << "Press Enter to continue...";
            std::cin.get();
        }

        // 上升沿：准备输入
        top->clk = 1;
        uint32_t mem_index = top->pc_out >> 2;
        top->inst_in = (mem_index < mem.size()) ? mem[mem_index] : 0;
        uint32_t data_addr = top->data_raddr >> 2;
        top->data_rdata = (top->data_re && data_addr < mem.size()) ? mem[data_addr] : 0;
        top->eval();
        tfp->dump(main_time++);

        // 下降沿：统一打印
        top->clk = 0;
        top->eval();
        tfp->dump(main_time++);

        std::cout << "[time=" << main_time << "]\n"
                  << "PC: 0X" << std::hex << std::setw(8) << std::setfill('0') << top->pc_out << "\n"
                  << "Instruction: 0X" << std::hex << std::setw(8) << std::setfill('0') << top->inst_in << "\n"
                  << "wb_pc: 0X " << std::hex << std::setw(8) << std::setfill('0') << top->debug_wb_pc << "\n"
                  << "wb_addr: " << std::dec << (uint32_t)top->debug_wb_rf_wnum << "\n"
                  << "wb_data: 0X " << std::hex << std::setw(8) << std::setfill('0') << top->debug_wb_rf_wdata << "\n"
                  << "wb_wen: 0x" << std::hex << (uint32_t)(top->debug_wb_rf_wen & 0xF) << "\n"
                  << "mem_wdata: 0X " << std::hex << std::setw(8) << std::setfill('0') << top->data_wdata << "\n"
                  << "mem_waddr: 0X " << std::hex << std::setw(8) << std::setfill('0') << top->data_waddr << "\n"
                  << "mem_we: 0x" << std::hex << (uint32_t)(top->data_we & 0xF) << "\n"
                  << "------------------------\n";

        log_file << "[time=" << main_time << "]\n"
                 << "PC: 0X" << std::hex << std::setw(8) << std::setfill('0') << top->pc_out << "\n"
                 << "Instruction: 0X" << std::hex << std::setw(8) << std::setfill('0') << top->inst_in << "\n"
                 << "wb_pc: 0X " << std::hex << std::setw(8) << std::setfill('0') << top->debug_wb_pc << "\n"
                 << "wb_addr: " << std::dec << (uint32_t)top->debug_wb_rf_wnum << "\n"
                 << "wb_data: 0X " << std::hex << std::setw(8) << std::setfill('0') << top->debug_wb_rf_wdata << "\n"
                 << "wb_wen: 0x" << std::hex << (uint32_t)(top->debug_wb_rf_wen & 0xF) << "\n"
                 << "mem_wdata: 0X " << std::hex << std::setw(8) << std::setfill('0') << top->data_wdata << "\n"
                 << "mem_waddr: 0X " << std::hex << std::setw(8) << std::setfill('0') << top->data_waddr << "\n"
                 << "mem_we: 0x" << std::hex << (uint32_t)(top->data_we & 0xF) << "\n"
                 << "------------------------\n";

        // 打印top中的regs_out内容
        if(top->pc_out == BREAK_PC) {
            std::cout << "regs_out: ";
            log_file << "regs_out: ";
            for (int i = 0; i < 32; ++i) {
                std::cout << std::dec << i << ":0x" << std::hex << std::setw(8) << std::setfill('0') << top->regs_out[i] << " ";
                log_file << std::dec << i << ":0x" << std::hex << std::setw(8) << std::setfill('0') << top->regs_out[i] << " ";
                if ((i+1)%8 == 0) {
                    std::cout << std::endl;
                    log_file << std::endl;
                }
            }
            std::cout << "------------------------" << std::endl;
            log_file << "------------------------" << std::endl;
            if(top->regs_out[3] == 1){
                std::cout << "Simulation PASSED!" << std::endl;
                log_file << "Simulation PASSED!" << std::endl;
            } else {
                std::cout << "Simulation FAILED!" << std::endl;
                log_file << "Simulation FAILED!" << std::endl;
            }
            std::cout << "------------------------" << std::endl;
            log_file << "------------------------" << std::endl;
            std::cout << "Stop simulation: inst reaches 0x" << std::hex << BREAK_INST << std::endl;
            log_file << "Stop simulation: inst reaches 0x" << std::hex << BREAK_INST << std::endl;
            std::cout << "------------------------" << std::endl;
            log_file << "------------------------" << std::endl;
            stop = true;
        }
    }

    top->final();
    tfp->close();
    log_file.close();
    delete tfp;
    delete top;
    return 0;
}