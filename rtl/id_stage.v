module id_stage (
    input wire clk,
    input wire rst_n,
    input wire [37:0] wb_data_bus,
    input wire [63:0] if_id_bus_in,
    output wire [181:0] id_exe_bus_out,
    input wire br_jmp_flag,
    input wire [37:0] mem_wb_regfile,
    input wire [37:0] exe_id_data_bus,
    input wire [5:0] exception_code_fd,
    output wire [5:0] exception_code_de,
    input wire exception_stalled,
    output wire stall_flag,
    output wire ecall_flag,
    input wire mret_flag_in,
    input wire exception_flag,
    input wire es_allowin,
    input wire fs_to_ds_valid,
    output wire ds_allowin,
    output wire ds_to_es_valid,
    output wire [31:0] reg3
);
reg [63:0] if_id_bus_r;
reg [5:0] exception_code_fd_r;
wire [31:0] nop_inst = 32'b00000000000000000000000000110011;
 // ADD x0, x0, x0
reg        ds_valid   ;
wire ds_ready_go = !stall_flag;
assign ds_allowin = !ds_valid || ds_ready_go && es_allowin;
assign ds_to_es_valid = ds_valid && ds_ready_go;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ds_valid <= 1'b0;
    end else if (ds_allowin) begin
        ds_valid <= fs_to_ds_valid;
    end
    if (!rst_n || exception_stalled || (mret_flag_in && exception_flag)) begin
        if_id_bus_r <= {64{1'b0}};
        exception_code_fd_r <= 6'b0;
    end else if (ds_allowin && fs_to_ds_valid) begin
        if_id_bus_r <=if_id_bus_in;
        exception_code_fd_r <= exception_code_fd;
    end
end
wire [63:0] if_id_bus_d = (br_jmp_flag) ? {nop_inst, if_id_bus_r[31:0]} :
                          if_id_bus_r;
wire [31:0] id_pc;
wire [31:0] id_inst;
assign {id_inst, id_pc} = if_id_bus_d;
wire [4:0] wb_addr;
wire wb_we;
wire [31:0] wb_data;
assign {wb_addr, wb_we, wb_data} = wb_data_bus;

wire [31:0] op1_data;
wire [31:0] op2_data;
wire [4:0] rd_out;
wire rd_wen;
wire [21:0] exe_fun;
wire mem_we;
wire mem_re;
wire [2:0] wb_sel;
wire [31:0] rs2_data;
wire [31:0] mem_wb_data;
//wire [31:0] branch_target;
assign mem_wb_data = rs2_data;
wire [3:0] csr_cmd;
wire [11:0] csr_addr;
wire [2:0] mem_size;
wire ebreak_flag;
wire exception_ii;
wire mret_flag;

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
    .mem_size(mem_size),
    .wb_sel(wb_sel),
    .rs2_data_raw(rs2_data),
    .csr_cmd(csr_cmd),
    .csr_addr(csr_addr),
    .mem_wb_regfile(mem_wb_regfile),
    .exe_id_data_bus(exe_id_data_bus),
    .stall_flag(stall_flag),
    .ecall_flag(ecall_flag),
    .ebreak_flag(ebreak_flag),
    .exception_ii(exception_ii),
    .mret_flag(mret_flag),
    .ds_allowin(ds_allowin),
    .reg3(reg3)
);


wire jmp_flag = wb_sel[1];

assign id_exe_bus_out = {
    op1_data,
    op2_data,
    rd_out,
    rd_wen,
    exe_fun,
    mem_we,
    mem_re,
    wb_sel,
    id_pc,
    mem_wb_data,
    jmp_flag,
    csr_cmd,
    csr_addr,
    mem_size,
    mret_flag
};


//中断和异常相关标识 共6位，足以表示所有异常类型 最高位标识出现异常或中断，低五位标识异常类型
assign exception_code_de = exception_code_fd_r[5] ? exception_code_fd_r : 
                           exception_ii ? 6'b100010 :
                           ebreak_flag  ? 6'b100011 :
                           ecall_flag   ? 6'b101011 : 
                           mret_flag    ? 6'b011111 :
                           6'b0;


endmodule
