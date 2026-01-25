module regfile_csr (
    input wire clk,
    input wire rst_n,
    // CSR read port
    input wire [11:0] csr_addr_r,
    output wire [31:0] csr_data_r,
    // CSR write port
    input wire [11:0] csr_addr_w,
    input wire [31:0] csr_data_w,
    input wire csr_we,
    // debug port
    output wire [31:0] csr_out [0:4095]
);
    
    reg [31:0] csr_array [0:4095];
    
    // CSR write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            /*integer i;
            for (i = 0; i < 4096; i = i + 1) begin
                csr_array[i] = 32'b0;
            end*/
            csr_array <= '{default: 32'b0}; 
        end else if (csr_we) begin
            csr_array[csr_addr_w] <= csr_data_w;
        end
    end
    
    // CSR read operation
    assign csr_data_r = csr_array[csr_addr_r];
    
    // Debug output
    genvar j;
    generate
        for (j = 0; j < 4096; j = j + 1) begin : CSR_DEBUG_OUTPUT
            assign csr_out[j] = csr_array[j];
        end
    endgenerate
endmodule
