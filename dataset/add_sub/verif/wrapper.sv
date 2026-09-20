module wrapper (
    input wire [15:0] a,
    input wire [15:0] b,
    input wire control
);
    wire [15:0] result_a, result_b;

    add_sub u_a (.a(a), .b(b), .control(control), .result(result_a));
    add_sub_optimized u_b (.a(a), .b(b), .control(control), .result(result_b));

    always @(*) begin
        assert(result_a === result_b);
    end
endmodule
