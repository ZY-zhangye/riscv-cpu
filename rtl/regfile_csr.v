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
    
    reg [31:0] csr_array [0:4095];
    integer i;    
    // CSR write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 4096; i = i + 1) begin
                csr_array[i] = 32'b0;
            end
        end else if (csr_we) begin
            csr_array[csr_addr_w] <= csr_data_w;
        end
    end
    
    // CSR read operation
    assign csr_data_r = csr_array[csr_addr_r];
    

    assign csr_ecall = csr_array[12'h305];

endmodule
