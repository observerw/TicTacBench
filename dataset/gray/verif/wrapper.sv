module wrapper (
    input wire clk,
    input wire rst_n,
    input wire [3:0] cmd
);
    wire [7:0] out_a, out_b;
    reg [2:0] cycle = 0;

    gray u_a (.clk(clk), .rst_n(rst_n), .cmd(cmd), .out(out_a));
    gray_optimized u_b (.clk(clk), .rst_n(rst_n), .cmd(cmd), .out(out_b));

    always @(posedge clk) begin
        if (cycle != 3)
            cycle <= cycle + 1'b1;
        if (cycle == 0)
            assume(!rst_n);
        if (cycle >= 1)
            assume(rst_n);
        if (cycle >= 2)
            assert(out_a === out_b);
    end
endmodule
