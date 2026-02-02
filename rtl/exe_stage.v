module exe_stage(
    input wire clk,
    input wire rst_n,
    input wire [175:0] id_exe_bus_in,
    output wire [186:0] exe_mem_bus_out,
    output wire [33:0] exe_if_jmp_bus,
    output wire [37:0] exe_id_data_bus,
    output wire [31:0] mem_rd_addr,
    input wire [31:0] mem_rd_data,
    output wire mem_re,
    input wire ms_allowin,
    output wire es_allowin,
    input wire ds_to_es_valid,
    output wire es_to_ms_valid,
    output wire [11:0] csr_raddr
);
wire es_ready_go = 1'b1;
reg es_valid;
assign es_allowin = !ds_to_es_valid || es_ready_go && ms_allowin;
assign es_to_ms_valid = ds_to_es_valid && es_ready_go;
reg [175:0] id_exe_bus_r;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        es_valid <= 1'b0;
    end else if (es_allowin) begin
        es_valid <= ds_to_es_valid;
    end
    if (!rst_n) begin
        id_exe_bus_r <= {176{1'b0}};
    end else if (ds_to_es_valid && es_allowin) begin
        id_exe_bus_r <= id_exe_bus_in;
    end 
end
wire [31:0] op1_data;
wire [31:0] op2_data;
wire signed [31:0] op1_data_s = op1_data;
wire signed [31:0] op2_data_s = op2_data;
wire [4:0] rd_out;
wire rd_wen;
wire [19:0] exe_fun;
wire mem_we;
wire [2:0] wb_sel;
wire [31:0] exe_pc;
wire [31:0] wb_data;
wire jmp_flag;
wire [3:0] csr_cmd;
wire [11:0] csr_addr;
assign {
    op1_data,
    op2_data,
    rd_out,
    rd_wen,
    exe_fun,    
    mem_we,
    mem_re,
    wb_sel,
    exe_pc,
    wb_data,
    jmp_flag,
    csr_cmd,
    csr_addr
} = id_exe_bus_r;


wire ALU_ADD;
wire ALU_SUB;
wire ALU_AND;
wire ALU_OR ;
wire ALU_XOR;
wire ALU_SLL;
wire ALU_SRL;
wire ALU_SRA;
wire ALU_SLT;
wire ALU_SLTU;
wire ALU_BEQ;
wire ALU_BNE;
wire ALU_BGE;
wire ALU_BGEU;
wire ALU_BLT;
wire ALU_BLTU;
wire ALU_JALR;
wire ALU_COPY1;
wire ALU_X;
wire ALU_ADDI;
assign {
    ALU_ADD, ALU_ADDI, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR,
    ALU_SLL, ALU_SRL, ALU_SRA, ALU_SLT, ALU_SLTU,
    ALU_BEQ, ALU_BNE, ALU_BGE, ALU_BGEU, ALU_BLT,
    ALU_BLTU, ALU_JALR, ALU_COPY1, ALU_X
} = exe_fun;
wire ALU_B = ALU_BEQ || ALU_BNE || ALU_BGE || ALU_BGEU || ALU_BLT || ALU_BLTU;
wire [31:0] alu_result = ALU_ADD ? (op1_data + op2_data) :
                         ALU_ADDI ? ($signed(op1_data_s) + $signed(op2_data_s)) :
                         ALU_SUB ? (op1_data - op2_data) :
                         ALU_AND ? (op1_data & op2_data) : 
                         ALU_OR  ? (op1_data | op2_data) :
                         ALU_XOR ? (op1_data ^ op2_data) :
                         ALU_SLL ? (op1_data << op2_data[4:0]) :
                         ALU_SRL ? (op1_data >> op2_data[4:0]) :
                         ALU_SRA ? ( ({ {32{op1_data[31]}}, op1_data } >> op2_data[4:0]) & 32'hFFFFFFFF ) :
                         ALU_SLT ? ($signed(op1_data_s) < $signed(op2_data_s) ? 32'd1 : 32'd0) :
                         ALU_SLTU? (op1_data < op2_data ? 32'd1 : 32'd0) :
                         ALU_JALR? ((op1_data + op2_data) & ~32'd1) :
                         ALU_COPY1? op1_data :
                         32'b0;     

wire [31:0] exe_id_data;
assign exe_id_data = mem_re ? mem_rd_data : alu_result;
assign exe_if_jmp_bus = {jmp_flag, alu_result, ALU_B};
assign exe_id_data_bus = {exe_id_data, rd_wen, rd_out};
assign mem_rd_addr = alu_result;
assign csr_raddr = csr_addr;

assign exe_mem_bus_out = {
    alu_result,
    rd_out,
    rd_wen,
    mem_we,
    mem_re,
    wb_sel,
    exe_pc,
    wb_data,
    csr_cmd,
    csr_addr,
    op1_data,
    mem_rd_data
};

endmodule
