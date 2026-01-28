module if_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] inst_in,
    output wire [31:0] pc_out,
    output wire [63:0] if_id_bus_out,
    input wire stall_flag,
    input wire ecall_flag,
    input wire [31:0] csr_ecall,
    //input  wire [32:0] id_if_br_bus,
    input  wire [33:0] exe_if_jmp_bus
);
    wire [31:0] seq_pc;
    wire [31:0] next_pc;
    reg  [31:0] fs_pc;
    wire [31:0] fs_inst;
    wire        br_flag;
   // wire [31:0] br_target;
    wire        jmp_flag; 
    wire [31:0] jmp_target;

   // assign {br_flag, br_target} = id_if_br_bus;
    assign {jmp_flag, jmp_target, br_flag} = exe_if_jmp_bus;
    assign seq_pc = fs_pc + 4;
    assign next_pc = (br_flag | jmp_flag) ? jmp_target :
                     ecall_flag ? csr_ecall :
                    // stall_flag ? fs_pc :
                     seq_pc;
    assign fs_inst = {inst_in[7:0], inst_in[15:8], inst_in[23:16], inst_in[31:24]}; // 小端转大端
    assign pc_out = next_pc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fs_pc <= 32'hffff_fffc; // -4，确保第一个pc_out为0
        end else if (stall_flag) begin
            fs_pc <= fs_pc;
        end else begin
            fs_pc <= next_pc;
        end
    end
    wire [31:0] nop_inst = 32'b00000000000000000000000000110011; // ADD x0, x0, x0
    assign if_id_bus_out = (br_flag | jmp_flag) ? {nop_inst, fs_pc} : {fs_inst, fs_pc};

endmodule
