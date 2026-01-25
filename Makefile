# ========== Verilator Makefile for RISC-V CPU ==========

# 你的RTL目录与源代码
RTL_DIR := ./rtl
RTL_SRCS := $(wildcard $(RTL_DIR)/*.v)

# 测试文件（假定主测试文件名为 tb_top.cpp，需改成你的实际文件名）
TB_DIR := ./test
TB_CPP := $(TB_DIR)/tb_top.cpp

# 仿真波形文件名
VCD := dump.vcd

# Verilator仿真对象目录
OBJ_DIR := ./obj_dir
EXEC := $(OBJ_DIR)/Vtop

# ================== 目标 ========================

# 1. 语法检查
lint:
	verilator --lint-only --Wall  $(RTL_SRCS)
	@echo "Linting completed."

# 2. 仿真编译并运行
sim: $(EXEC)
	$(EXEC)

# 3. 编译testbench和RTL（自动生成执行文件）
$(EXEC): $(TB_CPP) $(RTL_SRCS)
	verilator --cc --exe --build $(TB_CPP) $(RTL_SRCS) --trace --top-module top
# 4. 打开波形
wave:
	gtkwave $(VCD) &

# 5. 一键清理
clean:
	rm -rf $(OBJ_DIR) $(VCD)
# 6. 语法检查（忽略未使用信号警告）
lint-w:
	verilator --lint-only --Wall -Wno-UNUSEDSIGNAL --unroll-count 4096 ./rtl/*.v
	@echo "Linting completed with UNUSED SIGNAL warnings ignored."
.PHONY: lint lint-w sim wave clean