# ========== Verilator Makefile for RISC-V CPU ==========

# 你的RTL目录与源代码
RTL_DIR := ./rtl
RTL_SRCS := $(wildcard $(RTL_DIR)/*.v)

# 测试文件（假定主测试文件名为 tb_top.cpp，需改成你的实际文件名）
TB_DIR := ./test
TB_CPP := $(TB_DIR)/tb_top.cpp

# IVerilog testbench文件（假定为top_tb.v, 修改为你的实际verilog testbench文件）
TB_V := $(TB_DIR)/tb_top.v

# 仿真波形文件名
VCD := dump.vcd
IVCD := wave.vcd  # iverilog生成的vcd

# Verilator仿真对象目录
OBJ_DIR := ./obj_dir
EXEC := $(OBJ_DIR)/Vtop

# ================== 目标 ========================

# 1. 语法检查
lint:
	verilator --lint-only --Wall --unroll-count 4096  $(RTL_SRCS)
	@echo "Linting completed."

# 2. 仿真编译并运行（Verilator）
sim: $(EXEC)
	$(EXEC)

# 3. 编译testbench和RTL（Verilator自动生成执行文件）
$(EXEC): $(TB_CPP) $(RTL_SRCS)
	verilator --cc --exe --build $(TB_CPP) $(RTL_SRCS) --trace --top-module top --unroll-count 4096

# 4. 打开波形（gtkwave默认优先打开Verilator或IVerilog的波形文件）
wave:
	if [ -f $(IVCD) ]; then gtkwave $(IVCD) & \
	elif [ -f $(VCD) ]; then gtkwave $(VCD) & \
	else echo "No wave file found!"; fi

# 5. 一键清理
clean:
	rm -rf $(OBJ_DIR) $(VCD) $(IVCD) simv a.out

# 6. 语法检查（忽略未使用信号警告）
lint-w:
	verilator --lint-only --Wall -Wno-UNUSEDSIGNAL --unroll-count 4096 ./rtl/*.v
	@echo "Linting completed with UNUSED SIGNAL warnings ignored."

# ======= 新增iverilog仿真目标 =======
iverilog:
	iverilog -g2012 -o simv $(RTL_SRCS) $(TB_V)
	vvp simv

.PHONY: lint lint-w sim wave clean iverilog