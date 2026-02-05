module mem_stage(
    input wire clk,
    input wire rst_n,
    input wire [186:0] exe_mem_bus_in,
    output wire [69:0] mem_wb_bus_out,
    output wire mem_we,
    output wire [31:0] mem_wb_data,
    output wire [31:0] mem_wb_addr,
    output wire [37:0] mem_wb_regfile,
    output wire [31:0] csr_ecall,
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
reg [186:0] exe_mem_bus_r;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ms_valid <= 1'b0;
    end else if (ms_allowin) begin
        ms_valid <= es_to_ms_valid;
    end
    if (!rst_n) begin
        exe_mem_bus_r <= {187{1'b0}};
    end else if (ms_allowin && es_to_ms_valid) begin
        exe_mem_bus_r <= exe_mem_bus_in;
    end 
    if (!rst_n) begin
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
assign {
    alu_result,
    rd_out,
    rd_wen,
    mem_we,
    mem_re,
    wb_sel,
    mem_pc,
    wb_mem_data,
    csr_cmd,
    csr_addr,
    op1_data,
    mem_rd_data
} = exe_mem_bus_r;

wire [31:0] csr_rdata;
//assign mem_rd_addr = alu_result;
assign mem_wb_addr = alu_result;
assign mem_wb_data = wb_mem_data;
wire [31:0] wb_data;
assign wb_data = (wb_sel == 3'b000) ? alu_result :
                 (wb_sel == 3'b100) ? mem_rd_data :
                 (wb_sel == 3'b010) ? mem_pc + 32'd4 :
                 (wb_sel == 3'b001) ? csr_rdata:
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
assign csr_we = |csr_cmd;
assign csr_data_w = (csr_cmd == 4'b1000) ? 32'h8 : // CSRE
                    (csr_cmd == 4'b0100) ? op1_data : // CSRW
                    (csr_cmd == 4'b0010) ? (csr_rdata | op1_data) :               // CSRS
                    (csr_cmd == 4'b0001) ? (csr_rdata & ~op1_data) :             // CSRRC
                    32'b0;
assign debug_csr_we   = csr_we;
assign debug_csr_waddr= csr_addr;
assign debug_csr_wdata= csr_data_w;
regfile_csr u_regfile_csr (
    .clk        (clk),
    .rst_n      (rst_n),
    .csr_addr_r (csr_addr),
    .csr_data_r (csr_rdata),
    .csr_addr_w (csr_addr),
    .csr_data_w (csr_data_w),
    .csr_we     (csr_we),
    .csr_ecall  (csr_ecall)
);

endmodule
