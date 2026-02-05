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
    output wire [19:0] exe_fun,
    output wire mem_we,
    output wire mem_re,
    output wire [2:0] wb_sel,
    output wire [31:0] rs2_data_raw,
    input wire [37:0] mem_wb_regfile,
    input wire [37:0] exe_id_data_bus,
    output wire stall_flag,
    output wire ecall_flag,
    input wire ds_allowin,
    input wire [11:0] csr_raddr,
    output wire [3:0] csr_cmd,
    output wire [11:0] csr_addr,
    output wire [31:0] reg3
);

wire [31:0] mem_wb_data;
wire [4:0] mem_wb_addr;
wire mem_wb_we;
assign {mem_wb_addr, mem_wb_we, mem_wb_data} = mem_wb_regfile;

wire [6:0] opcode = inst_in[6:0];
wire [2:0] funct3 = inst_in[14:12];
wire [6:0] funct7 = inst_in[31:25];
wire [4:0] rd = inst_in[11:7];
wire [4:0] rs1 = inst_in[19:15];
wire [4:0] rs2 = inst_in[24:20];
wire [11:0] imm_i = inst_in[31:20];
wire [11:0] imm_s = {inst_in[31:25], inst_in[11:7]};
wire [12:0] imm_b = {inst_in[31], inst_in[7], inst_in[30:25], inst_in[11:8], 1'b0};
wire [31:0] imm_b_sext = {{19{imm_b[12]}}, imm_b};
wire [19:0] imm_u = inst_in[31:12];
wire [20:0] imm_j = {inst_in[31], inst_in[19:12], inst_in[20], inst_in[30:21], 1'b0};
wire [4:0] imm_z = inst_in[19:15];
wire [31:0] imm_i_sext = {{20{imm_i[11]}}, imm_i};
wire [31:0] imm_s_sext = {{20{imm_s[11]}}, imm_s};
wire [31:0] imm_u_sext = {imm_u, 12'b0};
wire [31:0] imm_j_sext = {{11{imm_j[20]}}, imm_j};
wire [31:0] imm_z_sext = {27'b0, imm_z};

//指令定义（独热码译码，复用比较信号）
wire op_load   = (opcode == 7'b0000011);
wire op_store  = (opcode == 7'b0100011);
wire op_op     = (opcode == 7'b0110011);
wire op_opimm  = (opcode == 7'b0010011);
wire op_branch = (opcode == 7'b1100011);
wire op_jal    = (opcode == 7'b1101111);
wire op_jalr   = (opcode == 7'b1100111);
wire op_lui    = (opcode == 7'b0110111);
wire op_auipc  = (opcode == 7'b0010111);
wire op_system = (opcode == 7'b1110011);

wire f3_000 = (funct3 == 3'b000);
wire f3_001 = (funct3 == 3'b001);
wire f3_010 = (funct3 == 3'b010);
wire f3_011 = (funct3 == 3'b011);
wire f3_100 = (funct3 == 3'b100);
wire f3_101 = (funct3 == 3'b101);
wire f3_110 = (funct3 == 3'b110);
wire f3_111 = (funct3 == 3'b111);

wire f7_0000000 = (funct7 == 7'b0000000);
wire f7_0100000 = (funct7 == 7'b0100000);

wire inst_lw   = op_load  & f3_010;
wire inst_sw   = op_store & f3_010;

wire inst_add  = op_op    & f3_000 & f7_0000000;
wire inst_sub  = op_op    & f3_000 & f7_0100000;
wire inst_and  = op_op    & f3_111 & f7_0000000;
wire inst_or   = op_op    & f3_110 & f7_0000000;
wire inst_xor  = op_op    & f3_100 & f7_0000000;
wire inst_sll  = op_op    & f3_001 & f7_0000000;
wire inst_srl  = op_op    & f3_101 & f7_0000000;
wire inst_sra  = op_op    & f3_101 & f7_0100000;
wire inst_slt  = op_op    & f3_010 & f7_0000000;
wire inst_sltu = op_op    & f3_011 & f7_0000000;

wire inst_addi = op_opimm & f3_000;
wire inst_andi = op_opimm & f3_111;
wire inst_ori  = op_opimm & f3_110;
wire inst_xori = op_opimm & f3_100;
wire inst_slli = op_opimm & f3_001 & f7_0000000;
wire inst_srli = op_opimm & f3_101 & f7_0000000;
wire inst_srai = op_opimm & f3_101 & f7_0100000;
wire inst_slti = op_opimm & f3_010;
wire inst_sltiu= op_opimm & f3_011;

wire inst_beq  = op_branch & f3_000;
wire inst_bne  = op_branch & f3_001;
wire inst_blt  = op_branch & f3_100;
wire inst_bge  = op_branch & f3_101;
wire inst_bltu = op_branch & f3_110;
wire inst_bgeu = op_branch & f3_111;

wire inst_jal  = op_jal;
wire inst_jalr = op_jalr & f3_000;
wire inst_lui  = op_lui;
wire inst_auipc= op_auipc;

wire inst_csrrw  = op_system & f3_001;
wire inst_csrrs  = op_system & f3_010;
wire inst_csrrc  = op_system & f3_011;
wire inst_csrrwi = op_system & f3_101;
wire inst_csrrsi = op_system & f3_110;
wire inst_csrrci = op_system & f3_111;
wire inst_ecall  = op_system & f3_000 & f7_0000000;






//输出译码内容
wire CSR = inst_csrrw || inst_csrrs || inst_csrrc || inst_csrrwi || inst_csrrsi || inst_csrrci;
reg prev_inst_lw;
reg CSR_prev;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prev_inst_lw <= 1'b0;
        CSR_prev <= 1'b0;
    end else if (ds_allowin) begin
        prev_inst_lw <= inst_lw;
        CSR_prev <= CSR;
    end else begin
        prev_inst_lw <= 1'b0;
        CSR_prev <= 1'b0;
    end
end
wire [31:0] rs2_data;
assign ecall_flag = inst_ecall;
assign stall_flag = ((((exe_id_data_bus[4:0] == rs1) && exe_id_data_bus[5]) ||
                    ((exe_id_data_bus[4:0] == rs2) && exe_id_data_bus[5])) && (exe_id_data_bus[4:0] != 5'b0) && prev_inst_lw);
wire [31:0] rs1_data;
wire [31:0] rs1_data_raw = ((csr_addr === csr_raddr) && CSR) ? exe_id_data_bus[37:6] :
                           (rs1 == 5'b0) ? 32'b0 :
                           (exe_id_data_bus[4:0] == rs1 && exe_id_data_bus[5] && (exe_id_data_bus[4:0] != 5'b0)) ? exe_id_data_bus[37:6] :
                           (mem_wb_we && (mem_wb_addr == rs1)) ? mem_wb_data :
                           (wb_we && (wb_addr == rs1)) ? wb_data :
                           rs1_data;
assign rs2_data_raw = (rs2 == 5'b0) ? 32'b0 :
                      ((csr_addr === csr_raddr) && CSR) ? exe_id_data_bus[37:6] :
                      (exe_id_data_bus[4:0] == rs2 && exe_id_data_bus[5] && (exe_id_data_bus[4:0] != 5'b0)) ? exe_id_data_bus[37:6] :
                      (mem_wb_we && (mem_wb_addr == rs2)) ? mem_wb_data :
                      (wb_we && (wb_addr == rs2)) ? wb_data :
                      rs2_data;
wire OP1_RS1 = inst_lw || inst_sw || inst_add || inst_sub || inst_addi || inst_and || inst_or || inst_xor || inst_andi || inst_ori
             || inst_xori || inst_sll || inst_srl || inst_sra || inst_slli || inst_srli || inst_srai || inst_slt || inst_sltu || inst_slti || inst_sltiu
             || inst_jalr || inst_csrrw || inst_csrrs || inst_csrrc;
wire OP1_PC  = inst_jal || inst_auipc || inst_beq || inst_bne || inst_blt || inst_bge || inst_bltu || inst_bgeu;
wire OP1_IMZ = inst_csrrwi || inst_csrrsi || inst_csrrci;
wire OP2_IMI = inst_lw || inst_addi || inst_andi || inst_ori || inst_xori || inst_slli || inst_srli || inst_srai || inst_slti || inst_sltiu || inst_jalr;
wire OP2_IMS = inst_sw;
wire OP2_IMJ = inst_jal;
wire OP2_IMB = inst_beq || inst_bne || inst_blt || inst_bge || inst_bltu || inst_bgeu;
wire OP2_IMU = inst_lui || inst_auipc;
wire OP2_RS2 = inst_add || inst_sub || inst_and || inst_or || inst_xor || inst_sll || inst_srl || inst_sra || inst_slt || inst_sltu;
assign op1_data = OP1_RS1 ? rs1_data_raw : 
                  OP1_PC ? pc_in : 
                  OP1_IMZ ? imm_z_sext :
                  32'b0;
assign op2_data = OP2_IMI ? imm_i_sext : 
                  OP2_IMS ? imm_s_sext : 
                  OP2_IMJ ? imm_j_sext :
                  OP2_RS2 ? rs2_data_raw :
                  OP2_IMU ? imm_u_sext :
                  OP2_IMB ? imm_b_sext :
                  32'b0;

assign rd_out = rd;
assign rd_wen = inst_lw || inst_add || inst_sub || inst_addi || inst_and || inst_or || inst_xor || inst_andi || inst_ori || inst_xori || inst_sll || inst_srl || inst_sra || inst_slli || inst_srli || inst_srai || inst_slt || inst_sltu 
                || inst_slti || inst_sltiu || inst_jal || inst_jalr || inst_lui || inst_auipc || inst_csrrw || inst_csrrs || inst_csrrc || inst_csrrwi || inst_csrrsi || inst_csrrci;

wire ALU_ADD = inst_lw || inst_sw || inst_add  || inst_jal || inst_lui || inst_auipc || inst_beq || inst_bne || inst_blt || inst_bge || inst_bltu || inst_bgeu;
wire ALU_ADDI = inst_addi;
wire ALU_SUB = inst_sub;
wire ALU_AND = inst_and || inst_andi;
wire ALU_OR  = inst_or || inst_ori;
wire ALU_XOR = inst_xor || inst_xori;
wire ALU_SLL = inst_sll || inst_slli;
wire ALU_SRL = inst_srl || inst_srli;
wire ALU_SRA = inst_sra || inst_srai;
wire ALU_SLT = inst_slt || inst_slti;
wire ALU_SLTU= inst_sltu || inst_sltiu;
wire ALU_BEQ = inst_beq && (rs1_data_raw == rs2_data_raw);
wire ALU_BNE = inst_bne && (rs1_data_raw != rs2_data_raw);
wire ALU_BGE = inst_bge && !($signed(rs1_data_raw) < $signed(rs2_data_raw));
wire ALU_BGEU= inst_bgeu && !(rs1_data_raw < rs2_data_raw);
wire ALU_BLT = inst_blt && ($signed(rs1_data_raw) < $signed(rs2_data_raw));
wire ALU_BLTU= inst_bltu && (rs1_data_raw < rs2_data_raw);
wire ALU_JALR= inst_jalr;
wire ALU_COPY1= inst_csrrw || inst_csrrs || inst_csrrc || inst_csrrwi || inst_csrrsi || inst_csrrci;
wire ALU_X = inst_ecall;
assign exe_fun = {ALU_ADD, ALU_ADDI, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR,
                  ALU_SLL, ALU_SRL, ALU_SRA, ALU_SLT, ALU_SLTU,
                  ALU_BEQ, ALU_BNE, ALU_BGE, ALU_BGEU, ALU_BLT,
                  ALU_BLTU, ALU_JALR, ALU_COPY1, ALU_X};
assign mem_we = inst_sw;
assign mem_re = inst_lw;

wire WB_SEL_MEM = inst_lw;
wire WB_SEL_PC  = inst_jal || inst_jalr;
wire WB_SEL_CSR = inst_csrrw || inst_csrrs || inst_csrrc || inst_csrrwi || inst_csrrsi || inst_csrrci;
assign wb_sel = {WB_SEL_MEM, WB_SEL_PC, WB_SEL_CSR};
//assign branch_target = pc_in + imm_b_sext;

wire CSR_E = inst_ecall;
wire CSR_W = inst_csrrw || inst_csrrwi;
wire CSR_S = inst_csrrs || inst_csrrsi;
wire CSR_C = inst_csrrc || inst_csrrci;
assign csr_cmd = {CSR_E, CSR_W, CSR_S, CSR_C};
assign csr_addr = CSR_E ? 12'h342 :
                  CSR_W ? inst_in[31:20] :
                  CSR_S ? inst_in[31:20] :
                  CSR_C ? inst_in[31:20] :
                  12'b0;

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
    .reg3(reg3)
);
endmodule
