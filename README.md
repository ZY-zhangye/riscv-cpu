# RISC-V CPU 项目说明

本项目实现了一个基于 RISC-V 指令集的简易 CPU。项目结构如下：

## 目录结构
- rtl/
  - common/         公共模块和定义文件
    - defines.v     全局参数和宏定义
  - main/           核心模块
    - decoder_control.v  指令译码与控制
    - exe_stage.v        执行阶段
    - id_stage.v         指令译码阶段
    - if_stage.v         取指阶段
    - mem_stage.v        存储器访问阶段
    - regfile.v          寄存器文件
    - top.v              顶层模块
    - wb_stage.v         回写阶段
- c/                  C 语言相关文件
- hex/                十六进制指令文件
- test/               测试文件

## 快速开始
1. 克隆仓库：
   ```bash
   git clone <仓库地址>
   ```
2. 进入项目目录，使用支持 Verilog 的仿真工具进行编译和仿真。
3. 相关测试文件位于 test/ 目录。

## 主要模块说明
- `top.v`：CPU 顶层集成模块。
- `if_stage.v`：指令获取阶段。
- `id_stage.v`：指令译码阶段。
- `exe_stage.v`：执行阶段。
- `mem_stage.v`：存储器访问阶段。
- `wb_stage.v`：回写阶段。
- `regfile.v`：寄存器文件。
- `decoder_control.v`：译码与控制逻辑。
- `defines.v`：全局参数和宏定义。

## 贡献
欢迎提交 issue 或 pull request 改进本项目。

## 许可证
本项目采用 MIT 许可证。
