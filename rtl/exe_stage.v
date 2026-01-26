module exe_stage(
    input wire clk,
    input wire rst_n,
    input wire [175:0] id_exe_bus_in,
    output wire [154:0] exe_mem_bus_out,
    output wire [33:0] exe_if_jmp_bus,
    output wire [5:0] exe_id_data_bus
);
reg [175:0] id_exe_bus_r;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        id_exe_bus_r <= {176{1'b0}};
    end else begin
        id_exe_bus_r <= id_exe_bus_in;
    end 
end
wire [31:0] op1_data;
wire [31:0] op2_data;
wire [4:0] rd_out;
wire rd_wen;
wire [19:0] exe_fun;
wire mem_we;
wire mem_re;
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

assign exe_id_data_bus = {rd_out, rd_wen};

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
                         ALU_ADDI ? ($signed(op1_data) + $signed(op2_data)) :
                         ALU_SUB ? (op1_data - op2_data) :
                         ALU_AND ? (op1_data & op2_data) : 
                         ALU_OR  ? (op1_data | op2_data) :
                         ALU_XOR ? (op1_data ^ op2_data) :
                         ALU_SLL ? (op1_data << op2_data[4:0]) :
                         ALU_SRL ? (op1_data >> op2_data[4:0]) :
                         ALU_SRA ? ($signed(op1_data) >>> op2_data[4:0]) :
                         ALU_SLT ? ($signed(op1_data) < $signed(op2_data) ? 32'd1 : 32'd0) :
                         ALU_SLTU? (op1_data < op2_data ? 32'd1 : 32'd0) :
                         ALU_JALR? ((op1_data + op2_data) & ~32'd1) :
                         ALU_COPY1? op1_data :
                         32'b0;     

assign exe_if_jmp_bus = {jmp_flag, alu_result, ALU_B};

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
    op1_data
};

endmodule
