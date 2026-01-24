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
        mem.push_back(val);
    }
}

/* ------ 核心testbench主流程 ------ */
int main(int argc, char **argv, char **env) {
    Verilated::commandArgs(argc, argv);  // 支持命令行参数

    Vtop* top = new Vtop;                // 实例化仿真顶层，相当于Verilog里的module

    // ------- 设置波形保存 -------
    VerilatedVcdC* tfp = new VerilatedVcdC;
    Verilated::traceEverOn(true);
    top->trace(tfp, 99);     // 递归层级
    tfp->open("dump.vcd");   // 输出波形文件名
    // --------------------------
    // 2. 上电复位(假如你有复位信号)
    top->rst_n = 0; top->clk = 0;
    for (int i=0; i<10; i++) {
        top->clk = !top->clk;
        top->eval();
        tfp->dump(main_time++);
    }
    top->rst_n = 1;
    load_hex("hex/lw.hex"); // 加载指令/数据存储器初始化文件
    // --------------------------
    std::cout << "------------------------" << std::endl;
    std::cout << "Loaded memory contents from hex file." << std::endl;
    std::cout << "mem[4]=0x" << std::setw(8) << std::setfill('0') << std::hex << mem[4] << std::endl;
    std::cout << "Starting simulation..." << std::endl;
    std::cout << "------------------------" << std::endl;

    // 3. 仿真主循环&波形保存&信号打印&检测终止条件
    const uint32_t BREAK_PC = 0x0000002C; // 例如到INST为0x20时停止
    while(main_time < MAX_SIM_TIME) {
    /* --------- CLK = 0 相位 --------- */
    top->clk = 0;

    // 在 clk=0 时提前准备下一周期输入（或在clk下降沿试）
    uint32_t mem_index = top->pc_out >> 2;
    top->inst_in = (mem_index < mem.size()) ? mem[mem_index] : 0;

    uint32_t data_addr = top->data_raddr >> 2;
    top->data_rdata = (top->data_re && data_addr < mem.size()) ? mem[data_addr] : 0;

    top->eval();
    tfp->dump(main_time++);

    /* --------- CLK = 1 相位 --------- */
    top->clk = 1;
    top->eval();
    tfp->dump(main_time++);

    // 此处再打印，PC和inst_in必定是“本周期对应”的，且与波形一致
    std::cout << "[time=" << main_time << "]\n"
              << "PC: 0X" << std::hex << std::setw(8) << std::setfill('0') << top->pc_out << "\n"
              << "Instruction: 0X" << std::hex << std::setw(8) << std::setfill('0') << top->inst_in << "\n"
              << "wb_pc: 0X " << std::hex << std::setw(8) << std::setfill('0') << top->debug_wb_pc << "\n"
              << "wb_addr: " << std::dec << (uint32_t)top->debug_wb_rf_wnum << "\n"
              << "wb_data: 0X " << std::hex << std::setw(8) << std::setfill('0') << top->debug_wb_rf_wdata << "\n"
              << "wb_wen: 0x" << std::hex << (uint32_t)(top->debug_wb_rf_wen & 0xF) << "\n"
              << "------------------------\n";

    if(top->pc_out == BREAK_PC) {
        std::cout << "Stop simulation: pc reaches 0x" << std::hex << BREAK_PC << std::endl;
        break;
    }
}

    top->final();
    tfp->close();
    delete tfp;
    delete top;
    return 0;
}