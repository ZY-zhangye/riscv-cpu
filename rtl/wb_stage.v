module wb_stage(
    input wire clk,
    input wire rst_n,
    input wire [69:0] mem_wb_bus_in,
    output wire [37:0] wb_data_bus_out,
    output wire ws_allowin,
    input wire ms_to_ws_valid,
    output wire [31:0] debug_wb_pc,
    output wire [3:0]  debug_wb_rf_wen,
    output wire [4:0]  debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

wire ws_ready_go = 1'b1;
reg ws_valid;
assign ws_allowin  = !ws_valid || ws_ready_go;
reg [69:0] mem_wb_bus_r;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ws_valid <= 1'b0;
    end else if (ws_allowin) begin
        ws_valid <= ms_to_ws_valid;
    end
    if (!rst_n) begin
        mem_wb_bus_r <= {70{1'b0}};
    end else if (ws_allowin && ms_to_ws_valid) begin
        mem_wb_bus_r <= mem_wb_bus_in;
    end
end
wire [4:0] rd_out;
wire rd_wen;
wire [31:0] wb_data;
wire [31:0] wb_pc;
assign {
    rd_out,
    rd_wen,
    wb_data,
    wb_pc
} = mem_wb_bus_r;

assign wb_data_bus_out = {
    rd_out,
    rd_wen,
    wb_data
};
assign debug_wb_pc = wb_pc; // Placeholder, should be connected to actual PC
assign debug_wb_rf_wen = {4{rd_wen}};
assign debug_wb_rf_wnum = rd_out;
assign debug_wb_rf_wdata = wb_data;

endmodule
