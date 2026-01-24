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
    output wire data_we,
    //调试接口
    output wire [31:0] debug_wb_pc,
    output wire [3:0]  debug_wb_rf_wen,
    output wire [4:0]  debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,
    output [31:0] regs_out [0:31]
);
    // Debug signals from WB stage
    assign data_wdata = 32'b0; // For now, we do not write data memory
    assign data_waddr = 32'b0; // For now, we do not write data memory

    // IF Stage
    wire [63:0] if_id_bus;
    if_stage u_if_stage  (
        .clk        (clk),
        .rst_n      (rst_n),
        .inst_in    (inst_in),
        .pc_out     (pc_out),
        .if_id_bus_out (if_id_bus)
    );

    // ID Stage
    wire [125:0] id_exe_bus;
    id_stage u_id_stage  (
        .clk            (clk),
        .rst_n          (rst_n),
        .wb_data_bus    (wb_data_bus), // To be connected
        .if_id_bus_in   (if_id_bus),
        .id_exe_bus_out (id_exe_bus),
        .regs_out       (regs_out)
    );

    //EXE Stage
    wire [74:0] exe_mem_bus;
    exe_stage u_exe_stage  (
        .clk            (clk),
        .rst_n          (rst_n),
        .id_exe_bus_in  (id_exe_bus),
        .exe_mem_bus_out(exe_mem_bus)
    );

    //MEM Stage
    wire [69:0] mem_wb_bus;
    mem_stage u_mem_stage  (
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
    wire [37:0] wb_data_bus;
    wb_stage u_wb_stage  (
        .clk            (clk),
        .rst_n          (rst_n),
        .mem_wb_bus_in  (mem_wb_bus),
        .wb_data_bus_out(wb_data_bus),
        .debug_wb_pc       (debug_wb_pc),
        .debug_wb_rf_wen   (debug_wb_rf_wen),
        .debug_wb_rf_wnum  (debug_wb_rf_wnum),
        .debug_wb_rf_wdata (debug_wb_rf_wdata)
    );

endmodule
