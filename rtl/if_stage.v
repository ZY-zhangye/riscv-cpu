module if_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] inst_in,
    output wire [31:0] pc_out,
    output wire [63:0] if_id_bus_out
);
    wire [31:0] seq_pc;
    wire [31:0] next_pc;
    reg  [31:0] fs_pc;
    wire [31:0] fs_inst;

    assign seq_pc = fs_pc + 4;
    assign next_pc = seq_pc; // For now, we just use sequential PC
    assign fs_inst = inst_in;
    assign pc_out = next_pc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fs_pc <= 32'b0;
        end else begin
            fs_pc <= next_pc;
        end
    end

    assign if_id_bus_out = {fs_inst, fs_pc};

endmodule
