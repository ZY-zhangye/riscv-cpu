module bridge (
    input wire clk,
    input wire rst_n,
    // CPU侧接口
    input wire [31:0] cpu_raddr,
    input wire cpu_re,
    input wire [31:0] cpu_waddr,
    input wire cpu_we,
    input wire [31:0] cpu_wdata,
    output reg [31:0] cpu_rdata,
    // 外部数据寄存器接口
    output wire [31:0] ext_raddr,
    output wire ext_re,
    input wire [31:0] ext_rdata,
    output wire [31:0] ext_waddr,
    output wire ext_we,
    output wire [31:0] ext_wdata,
    //外设接口
    output wire led
);

// 地址范围检查：只允许访问0-2047 (2KB)
localparam MAX_ADDR = 32'd2048;

assign ext_raddr = cpu_raddr;
assign ext_re = cpu_re && (cpu_raddr < MAX_ADDR);
assign ext_waddr = cpu_waddr;
assign ext_we = cpu_we && (cpu_waddr < MAX_ADDR);
assign ext_wdata = cpu_wdata;

// 改为组合逻辑：cpu_rdata 立即反映当前输入
assign cpu_rdata = (cpu_re && (cpu_raddr < MAX_ADDR)) ? ext_rdata : 32'h0;
assign led = (cpu_we && (cpu_waddr == 32'h0001_0000)) ? 1'b1 : 1'b0;
endmodule