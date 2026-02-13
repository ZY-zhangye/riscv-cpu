module regfile_csr (
    input wire clk,
    input wire rst_n,
    // CSR read port
    input wire [11:0] csr_addr_r,
    output wire [31:0] csr_data_r,
    output wire [31:0] csr_ecall,
    output wire [31:0] csr_mret,
    output reg exception_flag,
    // CSR write port
    input wire [11:0] csr_addr_w,
    input wire [31:0] csr_data_w,
    input wire csr_we,
    input wire [5:0] exception_code,
    input wire [31:0] exception_mtval
);
    
    reg [31:0] mstatus;
    reg [31:0] misa;
    reg [31:0] mtvec;
    reg [31:0] mepc;
    reg [31:0] mcause;
    reg [31:0] mhartid;
    reg [31:0] mie;
    reg [31:0] mip;
    reg [31:0] mtval;
    reg [31:0] mvendorid;
    reg [31:0] marchid;
    reg [31:0] mimpid;
    reg [31:0] mscratch;
    
    // CSR write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mstatus <= 32'b0;
            misa <= 32'b0;
            mtvec <= 32'b0;
            mepc <= 32'b0;
            mcause <= 32'b0;
            mhartid <= 32'b0;
            mie <= 32'b0;
            mip <= 32'b0;
            mtval <= 32'b0;
            mvendorid <= 32'b0;
            marchid <= 32'b0;
            mimpid <= 32'b0;
            mscratch <= 32'b0;
        end else if (csr_we) begin
            case (csr_addr_w)
                12'h300: mstatus <= csr_data_w;
                12'h301: misa <= csr_data_w;
                12'h305: mtvec <= csr_data_w;
                12'h340: mscratch <= csr_data_w;
                12'h341: mepc <= csr_data_w;
                12'h342: mcause <= csr_data_w;
                12'hF14: mhartid <= csr_data_w;
                12'h304: mie <= csr_data_w;
                12'h344: mip <= csr_data_w;
                12'h343: mtval <= csr_data_w;
                12'hF11: mvendorid <= csr_data_w;
                12'hF12: marchid <= csr_data_w;
                12'hF13: mimpid <= csr_data_w;
                default: ; // do nothing
            endcase
        end else begin
            if (exception_code[5]) begin
                // 处理异常：根据异常代码设置相关CSR寄存器
                mepc <= csr_data_w; // 将引起异常的指令地址写入mepc
                mcause <= {27'b0, exception_code[4:0]}; // 将异常代码写入mcause
                mtval <= exception_mtval; // 将引起异常的地址或数据写入mtval
            end else if (& exception_code[4:0]) begin
                //mret指令
                mstatus[3] <= mstatus[7];
                mstatus[7] <= 1'b1; // 恢复到M模式
            end
        end
    end
    assign csr_data_r = (csr_addr_r == csr_addr_w && csr_we) ? csr_data_w : // 优先返回写入数据
                        (csr_addr_r == 12'h300) ? mstatus :
                        (csr_addr_r == 12'h301) ? misa :
                        (csr_addr_r == 12'h305) ? mtvec :
                        (csr_addr_r == 12'h340) ? mscratch :
                        (csr_addr_r == 12'h341) ? mepc :
                        (csr_addr_r == 12'h342) ? mcause :
                        (csr_addr_r == 12'hF14) ? mhartid :
                        (csr_addr_r == 12'h304) ? mie :
                        (csr_addr_r == 12'h344) ? mip :
                        (csr_addr_r == 12'h343) ? mtval :
                        (csr_addr_r == 12'hF11) ? mvendorid :
                        (csr_addr_r == 12'hF12) ? marchid :
                        (csr_addr_r == 12'hF13) ? mimpid :
                        32'b0;
    

    assign csr_ecall =(csr_addr_w == 12'h305 && csr_we) ? csr_data_w : mtvec;
    assign csr_mret  = (csr_addr_w == 12'h341 && csr_we) ? csr_data_w : mepc;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            exception_flag <= 1'b0;
        end else if (exception_code[5]) begin
            exception_flag <= 1'b1;
        end else if (& exception_code[4:0]) begin
            exception_flag <= 1'b0; // mret指令清除异常标志
        end
    end

endmodule
