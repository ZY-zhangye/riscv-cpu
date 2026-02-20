module if_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] inst_in,
    output wire [31:0] pc_out,
    output wire [63:0] if_id_bus_out,
    input wire stall_flag,
    input wire ecall_flag,
    input wire mret_flag,
    input wire exception_flag,
    input wire exception_stalled,
    input wire [31:0] csr_ecall,
    input wire [31:0] csr_mret,
    input wire ds_allowin,
    output wire fs_to_ds_valid,
    output wire [5:0] exception_code_fd,
    input  wire [33:0] exe_if_jmp_bus
);
    localparam MAX_PC_OUT = 32'h0000_ffff;
    wire [31:0] seq_pc;
    wire [31:0] next_pc;
    reg  [31:0] fs_pc;
    wire [31:0] fs_inst;
    wire        br_flag;
    wire        jmp_flag; 
    wire [31:0] jmp_target;
    reg ecall_flag_reg;
    assign {jmp_flag, jmp_target, br_flag} = exe_if_jmp_bus;
    assign seq_pc = fs_pc + 4;
    assign next_pc = (br_flag | jmp_flag)                                 ? jmp_target :
                     (ecall_flag || exception_stalled)                    ? csr_ecall :
                     (mret_flag && exception_flag)                        ? csr_mret :
                     ecall_flag_reg                                       ? fs_pc :
                     seq_pc;
    assign pc_out = next_pc;

    reg fs_valid;
    wire fs_ready_go = 1'b1;
    wire fs_allowin = !fs_valid || fs_ready_go && ds_allowin;
    assign fs_to_ds_valid = fs_valid && fs_ready_go;
    reg ds_allowin_reg;
    reg [31:0] fs_inst_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fs_valid <= 1'b0;
            ecall_flag_reg <= 1'b0;
        end else if (fs_allowin) begin
            fs_valid <= 1'b1;
            ecall_flag_reg <= ecall_flag || (mret_flag && exception_flag) || exception_stalled;
        end
        if (!rst_n) begin
            fs_pc <= 32'hffff_fffc; // -4，确保第一个pc_out为0
        end else if (fs_allowin) begin
            fs_pc <= next_pc;
        end
        if (!rst_n) begin
            ds_allowin_reg <= 1'b1;
            fs_inst_reg <= 32'b0;
        end else begin
            ds_allowin_reg <= ds_allowin;
            fs_inst_reg <= fs_inst;
        end
    end
    wire [31:0] nop_inst = 32'b00000000000000000000000000110011; // ADD x0, x0, x0
    assign fs_inst = (ecall_flag || (mret_flag && exception_flag) || exception_stalled) ? nop_inst : ds_allowin_reg ? inst_in : fs_inst_reg; // 小端转大端
    assign if_id_bus_out = (br_flag | jmp_flag) ? {nop_inst, fs_pc} : {fs_inst, fs_pc};

    //中断和异常相关标识 共6位，足以表示所有异常类型 最高位标识出现异常或中断，低五位标识异常类型
    wire exception_iam = fs_allowin && (pc_out[1:0] != 2'b00); // 地址未对齐异常
    wire exception_iaf = fs_allowin && (pc_out > MAX_PC_OUT); // 地址访问越界异常
    assign exception_code_fd = //exception_iam ? 6'b100000 : // 地址未对齐异常
                              //exception_iaf ? 6'b100001 : // 地址访问越界异常
                              6'b000000; // 无异常

endmodule
