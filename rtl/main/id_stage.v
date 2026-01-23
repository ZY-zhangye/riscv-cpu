`include "defines.v"
module id_stage (
    input wire clk,
    input wire rst_n,
    input wire [WB_DATA_BUS-1:0] wb_data_bus,
    input wire [IF_ID_BUS-1:0] if_id_bus_in,
    output wire [ID_EXE_BUS-1:0] id_exe_bus_out
);

reg [IF_ID_BUS-1:0] if_id_bus_r;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        if_id_bus_r <= {IF_ID_BUS{1'b0}};
    end else begin
        if_id_bus_r <= if_id_bus_in;
    end
end
wire [31:0] id_pc;
wire [31:0] id_inst;
assign {id_inst, id_pc} = if_id_bus_r;
wire [4:0] wb_addr;
wire wb_we;
wire [31:0] wb_data;
assign {wb_addr, wb_we, wb_data} = wb_data_bus;

wire [31:0] op1_data;
wire [31:0] op2_data;
wire [4:0] rd_out;
wire rd_wen;
wire [17:0] exe_fun;
wire mem_we;
wire mem_re;
wire [2:0] wb_sel;
decoder_control u_decoder_control (
    .clk(clk),
    .rst_n(rst_n),
    .pc_in(id_pc),
    .inst_in(id_inst),
    .wb_addr(wb_addr),
    .wb_we(wb_we),
    .wb_data(wb_data),
    .op1_data(op1_data),
    .op2_data(op2_data),
    .rd_out(rd_out),
    .rd_wen(rd_wen),
    .exe_fun(exe_fun),
    .mem_we(mem_we),
    .mem_re(mem_re),
    .wb_sel(wb_sel)
);

assign id_exe_bus_out = {
    op1_data,
    op2_data,
    rd_out,
    rd_wen,
    exe_fun,
    mem_we,
    mem_re,
    wb_sel
};



endmodule