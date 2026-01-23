module wb_stage(
    input wire clk,
    input wire rst_n,
    input wire [MEM_WB_BUS-1:0] mem_wb_bus_in,
    output wire [WB_DATA_BUS-1:0] wb_data_bus_out
);

reg [MEM_WB_BUS-1:0] mem_wb_bus_r;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mem_wb_bus_r <= {MEM_WB_BUS{1'b0}};
    end else begin
        mem_wb_bus_r <= mem_wb_bus_in;
    end
end
wire [4:0] rd_out;
wire rd_wen;
wire [31:0] wb_data;
assign {
    rd_out,
    rd_wen,
    wb_data
} = mem_wb_bus_r;

assign wb_data_bus_out = {
    rd_out,
    rd_wen,
    wb_data
};

endmodule