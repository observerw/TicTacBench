module wrapper (
    input wire [7:0] multiplicand,
    input wire [7:0] multiplier
);
    wire [15:0] product_a, product_b;

    mul_subexpression u_a (.multiplicand(multiplicand), .multiplier(multiplier), .product(product_a));
    mul_subexpression_optimized u_b (.multiplicand(multiplicand), .multiplier(multiplier), .product(product_b));

    always @(*) begin
        assert(product_a === product_b);
    end
endmodule
