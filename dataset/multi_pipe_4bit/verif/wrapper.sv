module wrapper (
    input wire clk,
    input wire rst_n,
    input wire [3:0] mul_a,
    input wire [3:0] mul_b
);
    wire [7:0] mul_out_a, mul_out_b;
    reg [2:0] cycle = 0;

    multi_pipe_4bit u_a (
        .clk(clk), .rst_n(rst_n), .mul_a(mul_a), .mul_b(mul_b), .mul_out(mul_out_a)
    );

    multi_pipe_4bit_optimized u_b (
        .clk(clk), .rst_n(rst_n), .mul_a(mul_a), .mul_b(mul_b), .mul_out(mul_out_b)
    );

    always @(posedge clk) begin
        if (cycle != 5)
            cycle <= cycle + 1'b1;
        if (cycle == 0)
            assume(!rst_n);
        else
            assume(rst_n);
        if (cycle >= 1)
            assert(mul_out_a === mul_out_b);
    end
endmodule
