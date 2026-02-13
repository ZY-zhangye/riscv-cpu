module exe_stage(
    input wire clk,
    input wire rst_n,
    input wire [179:0] id_exe_bus_in,
    output wire [189:0] exe_mem_bus_out,
    output wire [33:0] exe_if_jmp_bus,
    output wire [37:0] exe_id_data_bus,
    output wire [31:0] mem_rd_addr,
    input wire [31:0] mem_rd_data,
    output wire mem_re,
    output mret_flag,
    input wire ms_allowin,
    output wire es_allowin,
    input wire ds_to_es_valid,
    output wire es_to_ms_valid,
    output wire [11:0] csr_raddr,
    input wire [31:0] csr_rdata,
    input wire [5:0] exception_code_de,
    output wire [5:0] exception_code_em,
    input wire exception_stalled
);
wire es_ready_go;
reg prev_mem_re;
reg es_valid;
assign es_allowin = !es_valid || es_ready_go && ms_allowin;
assign es_to_ms_valid = ds_to_es_valid && es_ready_go;
reg [179:0] id_exe_bus_r;
reg [5:0] exception_code_de_r;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        es_valid <= 1'b0;
    end else if (es_allowin) begin
        es_valid <= ds_to_es_valid;
    end
    if (!rst_n || exception_stalled) begin
        id_exe_bus_r <= {180{1'b0}};
        exception_code_de_r <= 6'b0;
    end else if (ds_to_es_valid && es_allowin) begin
        id_exe_bus_r <= id_exe_bus_in;
        exception_code_de_r <= exception_code_de;
    end 
    if (!rst_n || exception_stalled) begin
        prev_mem_re <= 1'b0;
    end else begin
        prev_mem_re <= mem_re;
    end
end
assign es_ready_go = (mem_re && !prev_mem_re) ? 1'b0 : 1'b1;
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
wire [2:0] mem_size;
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
    csr_addr,
    mem_size,
    mret_flag
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
                         ALU_COPY1? csr_rdata :
                         32'b0;     

wire [31:0] exe_id_data;
wire [31:0] mem_rdata_ext;
// 根据地址低两位选择字节/半字，再进行符号/零扩展
wire [1:0] mem_offset = alu_result[1:0];
wire [7:0] selected_byte = (mem_offset == 2'b00) ? mem_rd_data[7:0] :
                           (mem_offset == 2'b01) ? mem_rd_data[15:8] :
                           (mem_offset == 2'b10) ? mem_rd_data[23:16] : mem_rd_data[31:24];
wire [15:0] selected_half = (mem_offset[1] == 1'b0) ? mem_rd_data[15:0] : mem_rd_data[31:16];

assign mem_rdata_ext =
    (!mem_re) ? 32'b0 :
    (mem_size[0] && mem_size[1]) ? (mem_size[2] ? {{24{selected_byte[7]}}, selected_byte} : {24'b0, selected_byte}) : // byte
    (mem_size[0] && !mem_size[1]) ? (mem_size[2] ? {{16{selected_half[15]}}, selected_half} : {16'b0, selected_half}) : // half
    (!mem_size[0]) ? mem_rd_data : // word
    32'b0;
assign exe_id_data = (mem_re) ? mem_rdata_ext : alu_result;
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
    mem_rdata_ext,
    mem_size
};


// 异常处理：将ID阶段传来的异常代码传递到EXE阶段，并在EXE阶段根据需要进行修改（例如EBREAK指令）
wire exception_lam = ((!mem_size[0] && mem_rd_addr[1:0] != 2'b00 && mem_re) ||
                     (mem_size[0] && !mem_size[1] && mem_rd_addr[0] != 1'b0 && mem_re)) ? 1'b1 : 1'b0; // 地址未对齐异常
wire exception_laf = (mem_re && mem_rd_addr > 32'h6000_0000) ? 1'b1 : 1'b0; // 地址访问异常
assign exception_code_em = ((jmp_flag || ALU_B) && alu_result[1:0] != 2'b00) ? 6'b100000 : // 地址未对齐异常
                           ((jmp_flag || ALU_B) && alu_result > 32'h0000_ffff) ? 6'b100001 : // 地址访问越界异常
                           (exception_code_de_r[5] && (exception_code_de_r[4:0] != 5'b01011)) ? exception_code_de_r :
                           exception_lam ? 6'b100100 : // Load Address Misaligned
                           exception_laf ? 6'b100101 : // Load Access Fault
                           6'b0; // 无异常

endmodule
