module top(
    input wire clk,
    input wire rst_n,
    //指令存储器接口
    input wire [31:0] inst_in,
    output wire [31:0] pc_out,
    //数据寄存器接口
    input wire [31:0] data_rdata,
    output wire [31:0] data_raddr,
    output wire data_re,
    output wire [31:0] data_wdata,
    output wire [31:0] data_waddr,
    output wire data_we
);
    // IF Stage
    wire [IF_ID_BUS-1:0] if_id_bus;
    if_stage u_if_stage (
        .clk        (clk),
        .rst_n      (rst_n),
        .inst_in    (inst_in),
        .pc_out     (pc_out),
        .if_id_bus_out (if_id_bus)
    );

    // ID Stage
    wire [ID_EXE_BUS-1:0] id_exe_bus;
    id_stage u_id_stage (
        .clk            (clk),
        .rst_n          (rst_n),
        .wb_data_bus    (), // To be connected
        .if_id_bus_in   (if_id_bus),
        .id_exe_bus_out (id_exe_bus)
    );

    //EXE Stage
    wire [EXE_MEM_BUS-1:0] exe_mem_bus;
    exe_stage u_exe_stage (
        .clk            (clk),
        .rst_n          (rst_n),
        .id_exe_bus_in  (id_exe_bus),
        .exe_mem_bus_out(exe_mem_bus)
    );

    //MEM Stage
    wire [MEM_WB_BUS-1:0] mem_wb_bus;
    mem_stage u_mem_stage (
        .clk            (clk),
        .rst_n          (rst_n),
        .exe_mem_bus_in (exe_mem_bus),
        .mem_wb_bus_out (mem_wb_bus),
        .mem_we         (data_we),
        .mem_re         (data_re),
        .mem_rd_addr    (data_raddr),
        .mem_rd_data    (data_rdata)
    );

    //WB Stage
    wire [WB_DATA_BUS-1:0] wb_data_bus;
    wb_stage u_wb_stage (
        .clk            (clk),
        .rst_n          (rst_n),
        .mem_wb_bus_in  (mem_wb_bus),
        .wb_data_bus_out(wb_data_bus)
    );

endmodule