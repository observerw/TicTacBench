module wrapper (
    input wire [15:0] A,
    input wire [7:0] B
);
    wire [15:0] result_a, result_b;
    wire [15:0] odd_a, odd_b;

    divider_16bit u_a (.A(A), .B(B), .result(result_a), .odd(odd_a));
    divider_16bit_optimized u_b (.A(A), .B(B), .result(result_b), .odd(odd_b));

    always @(*) begin
        assert({result_a, odd_a} === {result_b, odd_b});
    end
endmodule
