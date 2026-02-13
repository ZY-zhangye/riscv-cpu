module mem_stage(
    input wire clk,
    input wire rst_n,
    input wire [189:0] exe_mem_bus_in,
    output wire [69:0] mem_wb_bus_out,
    output wire mem_we,
    output wire [31:0] mem_wb_data,
    output wire [31:0] mem_wb_addr,
    output wire [3:0] mem_wb_strb,
    output wire [37:0] mem_wb_regfile,
    output wire [31:0] csr_ecall,
    output wire [31:0] csr_mret,
    input wire [11:0] csr_raddr,
    output wire [31:0] csr_rdata,
    output wire exception_flag,
    output wire exception_stalled,
    input wire [5:0] exception_code_em,
    input wire ws_allowin,
    output wire ms_allowin,
    input wire es_to_ms_valid,
    output wire ms_to_ws_valid,
    output wire [11:0] debug_csr_waddr,
    output wire [31:0] debug_csr_wdata,
    output wire debug_csr_we
);
reg ms_valid;
reg prev_mem_we;
wire ms_ready_go;
assign ms_allowin = !ms_valid || ms_ready_go && ws_allowin;
assign ms_to_ws_valid = es_to_ms_valid && ms_ready_go;
reg [189:0] exe_mem_bus_r;
reg [5:0] exception_code_em_r;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ms_valid <= 1'b0;
    end else if (ms_allowin) begin
        ms_valid <= es_to_ms_valid;
    end
    if (!rst_n || exception_stalled) begin
        exe_mem_bus_r <= {190{1'b0}};
        exception_code_em_r <= 6'b0;
    end else if (ms_allowin && es_to_ms_valid) begin
        exe_mem_bus_r <= exe_mem_bus_in;
        exception_code_em_r <= exception_code_em;
    end 
    if (!rst_n || exception_stalled) begin
        prev_mem_we <= 1'b0;
    end else begin
        prev_mem_we <= mem_we;
    end
end
assign ms_ready_go = (mem_we && !prev_mem_we) ? 1'b0 : 1'b1;
wire mem_re;
wire [31:0] alu_result;
wire [4:0] rd_out;
wire rd_wen;
wire [2:0] wb_sel;
wire [31:0] mem_pc;
wire [31:0] wb_mem_data;
wire [3:0] csr_cmd;
wire [11:0] csr_addr;
wire [31:0] op1_data;
wire [31:0] mem_rd_data;
wire [2:0] mem_size;
wire mem_we_r;
wire rd_wen_r;
assign {
    alu_result,
    rd_out,
    rd_wen_r,
    mem_we_r,
    mem_re,
    wb_sel,
    mem_pc,
    wb_mem_data,
    csr_cmd,
    csr_addr,
    op1_data,
    mem_rd_data,
    mem_size
} = exe_mem_bus_r;

//wire [31:0] csr_rdata;
//assign mem_rd_addr = alu_result;
assign mem_wb_addr = alu_result;
assign mem_wb_data = (mem_size[0] && !mem_size[1]) ? {wb_mem_data[15:0], wb_mem_data[15:0]} : // 16位访存，数据复制到高16位
                        (mem_size[0] && mem_size[1]) ? {wb_mem_data[7:0], wb_mem_data[7:0], wb_mem_data[7:0], wb_mem_data[7:0]} : // 8位访存，数据复制到所有字节
                        wb_mem_data; // 32位访存
// mem_wb_strb根据mem_size赋值
// 修正字节序：原来低位/高位反了，导致低16位被写到高16位，低8位被写到高8位
assign mem_wb_strb =
    (!mem_we) ? 4'b0000 :
    (mem_size[0] && mem_size[1]) ? (4'b0001 << mem_wb_addr[1:0]) : // 8位访存（字节次序反转）
    (mem_size[0] && !mem_size[1]) ? (mem_wb_addr[1] ? 4'b1100 : 4'b0011) : // 16位访存（低/高半字交换）
    (!mem_size[0]) ? 4'b1111 : // 32位访存
    4'b0000;
wire [31:0] wb_data;
assign wb_data = (wb_sel == 3'b000) ? alu_result :
                 (wb_sel == 3'b100) ? mem_rd_data :
                 (wb_sel == 3'b010) ? mem_pc + 32'd4 :
                 (wb_sel == 3'b001) ? alu_result:
                 32'b0;
assign mem_wb_regfile = {rd_out, rd_wen,wb_data};

assign mem_wb_bus_out = {
    rd_out,
    rd_wen,
    wb_data,
    mem_pc
};
wire csr_we;
wire [31:0] csr_data_w;
assign csr_we = |csr_cmd && exception_code_em_r[5] == 1'b0; // 只有在没有异常时才允许CSR写入
assign csr_data_w = exception_code_em_r[5] ? mem_pc : // 发生异常时写入PC到CSR
                    (csr_cmd == 4'b1000) ? 32'h8 : // CSRE
                    (csr_cmd == 4'b0100) ? op1_data : // CSRW
                    (csr_cmd == 4'b0010) ? (alu_result | op1_data) :               // CSRS
                    (csr_cmd == 4'b0001) ? (alu_result & ~op1_data) :             // CSRRC
                    32'b0;
assign debug_csr_we   = csr_we;
assign debug_csr_waddr= csr_addr;
assign debug_csr_wdata= csr_data_w;

//异常处理
wire exception_sam = (mem_we && !mem_size[0] && mem_wb_addr[1:0] != 2'b00) || (mem_we && mem_size[0] && !mem_size[1] && mem_wb_addr[0] != 1'b0); // 地址未对齐异常
wire exception_saf = (mem_we && mem_wb_addr > 32'h6000_0000) ? 1'b1 : 1'b0; // 地址访问异常
wire [5:0] exception_code = (exception_code_em_r[5] && (exception_code_em_r[4:0] != 5'b01011)) ? exception_code_em_r :
                        exception_sam ? 6'b100110 : // Store Address Misaligned
                        exception_saf ? 6'b101000 : // Store Access Fault
                        6'b0; // 无异常
wire [31:0] exception_mtval = exception_code == 6'b100010 ? op1_data :                                 //非法指令存储instruction;复用op1_data，减少信号数量
                       (exception_code == 6'b100000 || exception_code == 6'b100000) ? alu_result :  //取指阶段地址异常存储PC
                       (exception_code == 6'b100011 || exception_code == 6'b101011) ? 32'b0 :   //EBREAK和ECALL指令异常，mtval置0
                       alu_result; //加载和存储地址异常存储访问地址
assign mem_we = ms_valid && mem_we_r && !exception_code[5]; // 只有在没有异常时才允许写内存
assign rd_wen = ms_valid && rd_wen_r && !exception_code[5]; // 只有在没有异常时才允许写回寄存器
assign exception_stalled = exception_code[5] ? 1'b1 : 1'b0; //设定为异常发生时将exception_code的最高位置1，表示当前周期发生异常，供IF阶段判断是否需要暂停取指，另在其最高位为0且其它位为1时标识mret指令
// CSR寄存器模块
regfile_csr u_regfile_csr (
    .clk        (clk),
    .rst_n      (rst_n),
    .csr_addr_r (csr_raddr),
    .csr_data_r (csr_rdata),
    .csr_addr_w (csr_addr),
    .exception_flag(exception_flag),
    .csr_data_w (csr_data_w),
    .csr_we     (csr_we),
    .csr_ecall  (csr_ecall),
    .csr_mret   (csr_mret),
    .exception_code(exception_code),
    .exception_mtval(exception_mtval)
);

endmodule
