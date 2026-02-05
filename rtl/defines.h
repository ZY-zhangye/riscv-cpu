// IF_ID_BUS 定义文件
// IF_ID_BUS = pc(32位) + 指令(32位) = 64
`ifndef DEFINES_H
    `define DEFINES_H
    `define IF_ID_BUS    64    // IF/ID流水线寄存器总线宽度
    `define WB_DATA_BUS  38    // 写回阶段数据总线宽度
    `define ID_EXE_BUS   93    // ID/EXE流水线寄存器总线宽度
    `define EXE_MEM_BUS  43    // EXE/MEM流水线寄存器总线宽度
    `define MEM_WB_BUS   38    // MEM/WB流水线寄存器总线宽度
`endif
