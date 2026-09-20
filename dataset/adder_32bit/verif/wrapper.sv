module wrapper (
    input wire [32:1] A,
    input wire [32:1] B
);
    wire [32:1] S_a, S_b;
    wire C32_a, C32_b;

    adder_32bit u_a (.A(A), .B(B), .S(S_a), .C32(C32_a));
    adder_32bit_optimized u_b (.A(A), .B(B), .S(S_b), .C32(C32_b));

    always @(*) begin
        assert({S_a, C32_a} === {S_b, C32_b});
    end
endmodule
