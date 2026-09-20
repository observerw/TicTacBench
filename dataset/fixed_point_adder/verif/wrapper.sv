module wrapper (
    input wire [31:0] a,
    input wire [31:0] b
);
    wire [31:0] c_a, c_b;

    fixed_point_adder u_a (.a(a), .b(b), .c(c_a));
    fixed_point_adder_optimized u_b (.a(a), .b(b), .c(c_b));

    always @(*) begin
        assert(c_a === c_b);
    end
endmodule
