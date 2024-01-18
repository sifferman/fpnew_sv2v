
module test (
    input   logic       clk,

    input   logic       wen_i,
    input   logic [3:0] waddr_i,
    input   logic       wdata_i,

    input   logic [3:0] raddr_i,
    output  logic       rdata_o
);

logic [1:0][1:0] mem [2][2];

always_ff @(posedge clk) begin
    if (wen_i) begin
        mem[waddr_i[0]][waddr_i[1]][waddr_i[2]][waddr_i[3]] <= wdata_i;
    end
end

assign rdata_o = mem[raddr_i[0]][raddr_i[1]][raddr_i[2]][raddr_i[3]];

endmodule
