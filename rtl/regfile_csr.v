module regfile_csr (
    input wire clk,
    input wire rst_n,
    // CSR read port
    input wire [11:0] csr_addr_r,
    output wire [31:0] csr_data_r,
    output wire [31:0] csr_ecall,
    // CSR write port
    input wire [11:0] csr_addr_w,
    input wire [31:0] csr_data_w,
    input wire csr_we
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
        end
    end
    
    // CSR read operation with write-through (combinational)
    /*always @(*) begin
        if (csr_we && (csr_addr_w == csr_addr_r)) begin
            csr_data_r = csr_data_w;
        end else begin
            case (csr_addr_r)
                12'h300: csr_data_r = mstatus;
                12'h301: csr_data_r = misa;
                12'h305: csr_data_r = mtvec;
                12'h340: csr_data_r = mscratch;
                12'h341: csr_data_r = mepc;
                12'h342: csr_data_r = mcause;
                12'hF14: csr_data_r = mhartid;
                12'h304: csr_data_r = mie;
                12'h344: csr_data_r = mip;
                12'h343: csr_data_r = mtval;
                12'hF11: csr_data_r = mvendorid;
                12'hF12: csr_data_r = marchid;
                12'hF13: csr_data_r = mimpid;
                default: csr_data_r = 32'b0;
            endcase
        end
    end*/
    assign csr_data_r = (csr_addr_r == 12'h300) ? mstatus :
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
    

    assign csr_ecall = mtvec;

endmodule
