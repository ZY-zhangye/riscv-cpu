module decoder_control (
    input wire clk,
    input wire rst_n,
    input wire [31:0] pc_in,
    input wire [31:0] inst_in,
    input wire [4:0] wb_addr /* verilator public */,
    input wire wb_we,
    input wire [31:0] wb_data /* verilator public */,
    output wire [31:0] op1_data,
    output wire [31:0] op2_data,
    output wire [4:0] rd_out,
    output wire rd_wen,
    output wire [18:0] exe_fun,
    output wire mem_we,
    output wire mem_re,
    output wire [2:0] wb_sel,
    //debug
    output [31:0] regs_out [0:31]
);

wire [6:0] opcode = inst_in[6:0];
wire [2:0] funct3 = inst_in[14:12];
wire [6:0] funct7 = inst_in[31:25];
wire [4:0] rd = inst_in[11:7];
// ...existing code...
wire [4:0] rs1 = inst_in[19:15];
wire [4:0] rs2 = inst_in[24:20];
wire [11:0] imm_i = inst_in[31:20];
wire [11:0] imm_s = {inst_in[31:25], inst_in[11:7]};
wire [12:0] imm_b = {inst_in[31], inst_in[7], inst_in[30:25], inst_in[11:8], 1'b0};
wire [19:0] imm_u = inst_in[31:12];
wire [20:0] imm_j = {inst_in[31], inst_in[19:12], inst_in[20], inst_in[30:21], 1'b0};
wire [4:0] imm_z = inst_in[19:15];
wire [31:0] imm_i_sext = {{20{imm_i[11]}}, imm_i};
wire [31:0] imm_s_sext = {{20{imm_s[11]}}, imm_s};
wire [31:0] imm_b_sext = {{19{imm_b[12]}}, imm_b};
wire [31:0] imm_u_sext = {imm_u, 12'b0};
wire [31:0] imm_j_sext = {{11{imm_j[20]}}, imm_j};
wire [31:0] imm_z_uext = {27'b0, imm_z};

//指令定义
wire inst_lw = (opcode == 7'b0000011) && (funct3 == 3'b010);






//输出译码内容
wire [31:0] rs1_data;
wire [31:0] rs2_data;
wire OP1_RS1 = inst_lw;
wire OP2_IMM = inst_lw;
assign op1_data = OP1_RS1 ? rs1_data : pc_in;
assign op2_data = OP2_IMM ? imm_i_sext : rs2_data;
assign rd_out = rd;
assign rd_wen = inst_lw;
wire ALU_ADD = inst_lw;
wire ALU_SUB = 1'b0;
wire ALU_AND = 1'b0;
wire ALU_OR  = 1'b0;
wire ALU_XOR = 1'b0;
wire ALU_SLL = 1'b0;
wire ALU_SRL = 1'b0;
wire ALU_SRA = 1'b0;
wire ALU_SLT = 1'b0;
wire ALU_SLTU= 1'b0;
wire ALU_BEQ = 1'b0;
wire ALU_BNE = 1'b0;
wire ALU_BGE = 1'b0;
wire ALU_BGEU= 1'b0;
wire ALU_BLT = 1'b0;
wire ALU_BLTU= 1'b0;
wire ALU_JALR= 1'b0;
wire ALU_COPY1= 1'b0;
wire ALU_X = 1'b0;
assign exe_fun = {ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR,
                  ALU_SLL, ALU_SRL, ALU_SRA, ALU_SLT, ALU_SLTU,
                  ALU_BEQ, ALU_BNE, ALU_BGE, ALU_BGEU, ALU_BLT,
                  ALU_BLTU, ALU_JALR, ALU_COPY1, ALU_X};
assign mem_we = 1'b0; // lw指令不写内存
assign mem_re = inst_lw;
wire WB_SEL_MEM = inst_lw;
wire WB_SEL_PC  = 1'b0;
wire WB_SEL_CSR = 1'b0;
assign wb_sel = {WB_SEL_MEM, WB_SEL_PC, WB_SEL_CSR};


//regfile实例化
regfile u_regfile  (
    .clk(clk),
    .rst_n(rst_n),
    .rs1_addr(rs1),
    .rs2_addr(rs2),
    .rd_addr(wb_addr),
    .rd_data(wb_data),
    .rd_we(wb_we),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .regs_out(regs_out)
);
endmodule
