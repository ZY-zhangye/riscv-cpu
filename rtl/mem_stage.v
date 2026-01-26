module mem_stage(
    input wire clk,
    input wire rst_n,
    input wire [154:0] exe_mem_bus_in,
    output wire [69:0] mem_wb_bus_out,
    output wire mem_we,
    output wire mem_re,
    output wire [31:0] mem_rd_addr,
    input wire [31:0] mem_rd_data,
    output wire [31:0] mem_wb_data,
    output wire [31:0] mem_wb_addr,
    output wire [37:0] mem_wb_regfile,
    output wire [31:0] csr_ecall,
    output wire [31:0] csr_out [0:4095]
);

reg [154:0] exe_mem_bus_r;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        exe_mem_bus_r <= {155{1'b0}};
    end else begin
        exe_mem_bus_r <= exe_mem_bus_in;
    end 
end
wire [31:0] alu_result;
wire [4:0] rd_out;
wire rd_wen;
wire [2:0] wb_sel;
wire [31:0] mem_pc;
wire [31:0] wb_mem_data;
wire [3:0] csr_cmd;
wire [11:0] csr_addr;
wire [31:0] op1_data;
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
    op1_data
} = exe_mem_bus_r;


assign mem_rd_addr = alu_result;
assign mem_wb_addr = alu_result;
assign mem_wb_data = wb_mem_data;
wire [31:0] wb_data;
assign wb_data = (wb_sel == 3'b000) ? alu_result :
                 (wb_sel == 3'b100) ? mem_rd_data :
                 (wb_sel == 3'b010) ? mem_pc + 32'd4 :
                 32'b0;
assign mem_wb_regfile = {rd_out, rd_wen,wb_data};

assign mem_wb_bus_out = {
    rd_out,
    rd_wen,
    wb_data,
    mem_pc
};
wire [31:0] csr_data_r;
wire csr_we;
wire [31:0] csr_data_w;
assign csr_we = |csr_cmd;
assign csr_data_w = (csr_cmd == 4'b1000) ? 32'h11 : // CSRE
                    (csr_cmd == 4'b0100) ? op1_data : // CSRW
                    (csr_cmd == 4'b0010) ? (csr_data_r | op1_data) :               // CSRS
                    (csr_cmd == 4'b0001) ? (csr_data_r & ~op1_data) :             // CSRRC
                    32'b0;

regfile_csr u_regfile_csr (
    .clk        (clk),
    .rst_n      (rst_n),
    .csr_addr_r (csr_addr),
    .csr_data_r (csr_data_r),
    .csr_addr_w (csr_addr),
    .csr_data_w (csr_data_w),
    .csr_we     (csr_we),
    .csr_out    (csr_out),
    .csr_ecall  (csr_ecall)
);

endmodule
