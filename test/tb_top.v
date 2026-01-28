`timescale 1ns/1ps
module tb_top();

reg clk;
reg rst_n;
reg [31:0] inst_in;
wire [31:0] pc_out;
wire [31:0] data_raddr;
wire data_re;
wire [31:0] data_wdata;
wire [31:0] data_waddr;
wire data_we;
wire [31:0] debug_wb_pc;
wire [3:0]  debug_wb_rf_wen;
wire [4:0]  debug_wb_rf_wnum;
wire [31:0] debug_wb_rf_wdata;
wire [31:0] regs_out [0:31];
wire [31:0] csr_out [0:4095];
reg [31:0] data_rdata;
wire [33:0] debug_exe_if_jmp_bus;

top u_top(
    .clk(clk),
    .rst_n(rst_n),
    .inst_in(inst_in),
    .pc_out(pc_out),
    .data_rdata(data_rdata),
    .data_raddr(data_raddr),
    .data_re(data_re),
    .data_wdata(data_wdata),
    .data_waddr(data_waddr),
    .data_we(data_we),
    .debug_wb_pc(debug_wb_pc),
    .debug_wb_rf_wen(debug_wb_rf_wen),
    .debug_wb_rf_wnum(debug_wb_rf_wnum),
    .debug_wb_rf_wdata(debug_wb_rf_wdata),
    .regs_out(regs_out),
    .debug_exe_if_jmp_bus(debug_exe_if_jmp_bus),
    .csr_out(csr_out)
);

reg [31:0] mem [0:3000];
reg [31:0] data_mem [0:3000];

// 时钟生成
initial clk = 0;
always #5 clk = ~clk;

// 复位
initial begin
    rst_n = 0;
    #200;
    rst_n = 1;
end

// 加载内存文件
initial begin
    $readmemh("/home/zy-zhangye/riscv-cpu/hex/riscv-tests/rv32ui-p-sw.hex", mem);
    $dumpfile("wave.vcd");     // 生成vcd波形文件
    $dumpvars(0, tb_top);      // 记录所有变量
    $display("Starting simulation...");
end

// 指令总线和数据端口模拟
always @(posedge clk) begin
    if (!rst_n) begin
        inst_in = 32'b0;
        data_rdata = 32'b0;
    end else begin
        inst_in = mem[pc_out[13:2]];
    end
end

// 数据存储器读写
always @(posedge clk) begin
    if (data_we) begin
        data_mem[data_waddr[13:2]] <= data_wdata;
        $display("Data Write: Addr=%08h Data=%08h", data_waddr, data_wdata);
    end
    if (data_re) begin
        $display("Data Read: Addr=%08h Data=%08h", data_raddr, data_mem[data_raddr[13:2]]);
    end
end
always @(*) begin
    if (data_re) begin
        data_rdata = data_mem[data_raddr[13:2]];
    end else begin
        data_rdata = 32'b0;
    end
end

// 打印调试信息
always @(posedge clk) begin
    if (rst_n) begin
        $display("PC: %08h", pc_out);
        $display("Inst: %08h", inst_in);
        $display("wb_pc: %08h", debug_wb_pc);
        $display("wb_rf_wen: %h", debug_wb_rf_wen);
        $display("wb_rf_wnum: %h", debug_wb_rf_wnum);
        $display("wb_rf_wdata: %08h", debug_wb_rf_wdata);
        $display("gp: %08h", regs_out[3]);
        $display("------------------------");
    end
end

// 仿真终止判定
always @(posedge clk) begin
    if (rst_n && pc_out == 32'h00000044) begin
        $display("Simulation finished.");
        if (regs_out[3] == 32'h00000001) begin
            $display("Test passed.");
        end else begin
            $display("Test failed. Expected 1 in x10, got %08h", regs_out[10]);
        end
        $finish;
    end    
end
initial begin
    #25000;
    $display("Simulation timeout.");
    $stop;
end

endmodule