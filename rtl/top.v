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
    output wire [3:0] data_wstrb,
    output wire data_we,
    //调试接口
    output wire [31:0] debug_wb_pc,
    output wire [3:0]  debug_wb_rf_wen,
    output wire [4:0]  debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,
    output wire [33:0] debug_exe_if_jmp_bus,
    output wire [31:0] reg3,
    output wire [31:0] debug_csr_wdata,
    output wire [11:0] debug_csr_waddr,
    output wire        debug_csr_we
);


    
    wire [63:0] if_id_bus;
    wire stall_flag_internal;
    wire [178:0] id_exe_bus;
    wire [33:0] exe_if_jmp_bus;
    wire br_jmp_flag = exe_if_jmp_bus[33] | exe_if_jmp_bus[0];
    wire ecall_flag;
    wire [189:0] exe_mem_bus;
    wire [37:0] exe_id_data_bus;
    wire [69:0] mem_wb_bus;
    wire [37:0] mem_wb_regfile;
    wire [31:0] csr_ecall;
    wire [37:0] wb_data_bus;
    wire         ds_allowin;
    wire         es_allowin;
    wire         ms_allowin;
    wire         ws_allowin;
    wire         fs_to_ds_valid;
    wire         ds_to_es_valid;
    wire         es_to_ms_valid;
    wire         ms_to_ws_valid;
    wire [11:0] csr_raddr;
    

    // Bridge接口
    wire [31:0] bridge_rdata;

    //debug
    assign debug_exe_if_jmp_bus = exe_if_jmp_bus;

    // IF Stage
    if_stage u_if_stage  (
        .clk        (clk),
        .rst_n      (rst_n),
        .inst_in    (inst_in),
        .pc_out     (pc_out),
        .if_id_bus_out (if_id_bus),
        .exe_if_jmp_bus (exe_if_jmp_bus),
        .stall_flag     (stall_flag_internal),
        .ecall_flag     (ecall_flag),
        .csr_ecall      (csr_ecall),
        .ds_allowin     (ds_allowin),
        .fs_to_ds_valid (fs_to_ds_valid)
    );

    // ID Stage
    id_stage u_id_stage  (
        .clk            (clk),
        .rst_n          (rst_n),
        .wb_data_bus    (wb_data_bus), // To be connected
        .if_id_bus_in   (if_id_bus),
        .id_exe_bus_out (id_exe_bus),
        .br_jmp_flag    (br_jmp_flag),
        .mem_wb_regfile (mem_wb_regfile),
        .exe_id_data_bus (exe_id_data_bus),
        .stall_flag     (stall_flag_internal),
        .ecall_flag     (ecall_flag),
        .ds_allowin     (ds_allowin),
        .fs_to_ds_valid (fs_to_ds_valid),
        .ds_to_es_valid (ds_to_es_valid),
        .es_allowin     (es_allowin),
        .csr_raddr      (csr_raddr),
        .reg3           (reg3)
    );

    //EXE Stage
    exe_stage u_exe_stage  (
        .clk            (clk),
        .rst_n          (rst_n),
        .id_exe_bus_in  (id_exe_bus),
        .exe_mem_bus_out(exe_mem_bus),
        .exe_if_jmp_bus (exe_if_jmp_bus),
        .exe_id_data_bus(exe_id_data_bus),
        .mem_rd_addr    (data_raddr),
        .mem_re         (data_re),
        .mem_rd_data    (data_rdata),  
        .ms_allowin     (ms_allowin),
        .es_allowin     (es_allowin),
        .ds_to_es_valid (ds_to_es_valid),
        .es_to_ms_valid (es_to_ms_valid),
        .csr_raddr      (csr_raddr)
    );

    //MEM Stage
    mem_stage u_mem_stage  (
        .clk            (clk),
        .rst_n          (rst_n),
        .exe_mem_bus_in (exe_mem_bus),
        .mem_wb_bus_out (mem_wb_bus),
        .mem_we         (data_we),
        .mem_wb_data    (data_wdata),
        .mem_wb_addr    (data_waddr),
        .mem_wb_strb    (data_wstrb),
        .mem_wb_regfile (mem_wb_regfile),
        .csr_ecall      (csr_ecall),
        .ws_allowin     (ws_allowin),
        .ms_allowin     (ms_allowin),
        .es_to_ms_valid (es_to_ms_valid),
        .ms_to_ws_valid (ms_to_ws_valid),
        .debug_csr_waddr(debug_csr_waddr),
        .debug_csr_wdata(debug_csr_wdata),
        .debug_csr_we   (debug_csr_we)
    );

    //WB Stage
    wb_stage u_wb_stage  (
        .clk            (clk),
        .rst_n          (rst_n),
        .mem_wb_bus_in  (mem_wb_bus),
        .wb_data_bus_out(wb_data_bus),
        .debug_wb_pc       (debug_wb_pc),
        .debug_wb_rf_wen   (debug_wb_rf_wen),
        .debug_wb_rf_wnum  (debug_wb_rf_wnum),
        .debug_wb_rf_wdata (debug_wb_rf_wdata),
        .ws_allowin        (ws_allowin),
        .ms_to_ws_valid    (ms_to_ws_valid)
    );



endmodule
