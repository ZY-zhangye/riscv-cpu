module regfile (
    input wire clk,
    input wire rst_n,
    input wire [4:0] rs1_addr,
    input wire [4:0] rs2_addr,
    input wire [4:0] rd_addr,
    input wire [31:0] rd_data,
    input wire rd_we,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);
    reg [31:0] regs [0:31];

    // Read ports
    assign rs1_data = (rs1_addr != 0) ? regs[rs1_addr] : 32'b0;
    assign rs2_data = (rs2_addr != 0) ? regs[rs2_addr] : 32'b0;

    // Write port
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            integer i;
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'b0;
            end
        end else if (rd_we && (rd_addr != 0)) begin
            regs[rd_addr] <= rd_data;
        end
    end
endmodule