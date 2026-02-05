module data_ram (
    input wire clk,
    input wire [31:0] raddr,
    input wire re,
    output wire [31:0] rdata,
    input wire [31:0] waddr,
    input wire we,
    input wire [31:0] wdata
);

// 2KB数据RAM，512个32位字
localparam WORDS = 512;
reg [31:0] ram [0:WORDS-1];
wire [8:0] idx_r = raddr[10:2]; // 字地址索引 0..511
wire [8:0] idx_w = waddr[10:2]; // 写地址索引 0..511

// 初始化：仿真使用 $readmemh；Quartus 上板使用 altsyncram + data.mif；SYNTH_INIT 仍然支持 data_init.vh
`ifdef SIM
initial begin
    $readmemh("data.hex", ram);
end
`elsif QUARTUS
// 使用 Quartus 提供的 altsyncram，在合成时由 data.mif 初始化
// 写端口（A）用于写，读端口（B）用于读
wire [8:0] addr_a = idx_w;
wire [8:0] addr_b = idx_r;

altsyncram #(
    .operation_mode("DUAL_PORT"),
    .init_file("data.mif"),
    .width_a(32), .widthad_a(9), .numwords_a(WORDS),
    .width_b(32), .widthad_b(9), .numwords_b(WORDS)
) u_altsyncram (
    .clock0(clk),
    .address_a(addr_a),
    .wren_a(we),
    .data_a(wdata),
    .address_b(addr_b),
    .rden_b(re),
    .q_b(rdata)
);

`elsif SYNTH_INIT
initial begin
    `include "data_init.vh"
end
`endif

`ifndef QUARTUS
// 写入：同步生效（写入在时钟沿发生）
always @(posedge clk) begin
    if (we) begin
        ram[idx_w] <= wdata;
    end
end
`endif

`ifndef QUARTUS
// 读取：组合逻辑无周期延迟（直接反映当前寄存器内容），当未使能读取时返回0
assign rdata = re ? ram[idx_r] : 32'h0;
`endif

endmodule
