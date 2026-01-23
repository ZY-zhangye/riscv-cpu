`include "defines.v"
module mem_stage(
    input wire clk,
    input wire rst_n,
    input wire [EXE_MEM_BUS-1:0] exe_mem_bus_in,
    output wire [MEM_WB_BUS-1:0] mem_wb_bus_out,
    output wire mem_we,
    output wire mem_re,
    output wire [31:0] mem_rd_addr,
    input wire [31:0] mem_rd_data
);

reg [EXE_MEM_BUS-1:0] exe_mem_bus_r;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        exe_mem_bus_r <= {EXE_MEM_BUS{1'b0}};
    end else begin
        exe_mem_bus_r <= exe_mem_bus_in;
    end 
end
wire [31:0] alu_result;
wire [4:0] rd_out;
wire rd_wen;
wire mem_we;
wire mem_re;
wire [2:0] wb_sel;
assign {
    alu_result,
    rd_out,
    rd_wen,
    mem_we,
    mem_re,
    wb_sel
} = exe_mem_bus_r;

assign mem_rd_addr = alu_result;
wire [31:0] wb_data;
assign wb_data = (wb_sel == 3'b000) ? alu_result :
                 (wb_sel == 3'b100) ? mem_rd_data :
                 32'b0;

assign mem_wb_bus_out = {
    rd_out,
    rd_wen,
    wb_data
};