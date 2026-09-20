module wrapper (
    input wire [63:0] a,
    input wire [63:0] b,
    input wire [2:0] Oper
);
    wire [63:0] sum_a, sum_b;

    alu_64bit u_a (.a(a), .b(b), .Oper(Oper), .sum(sum_a));
    alu_64bit_optimized u_b (.a(a), .b(b), .Oper(Oper), .sum(sum_b));

    always @(*) begin
        assert(sum_a === sum_b);
    end
endmodule
