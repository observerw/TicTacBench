module wrapper (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    input wire [7:0] d
);
    wire [7:0] s1_a, s2_a, s3_a, s4_a, s5_a, s6_a;
    wire [7:0] s1_b, s2_b, s3_b, s4_b, s5_b, s6_b;

    calculation u_a (.a(a), .b(b), .c(c), .d(d), .s1(s1_a), .s2(s2_a), .s3(s3_a), .s4(s4_a), .s5(s5_a), .s6(s6_a));
    calculation_optimized u_b (.a(a), .b(b), .c(c), .d(d), .s1(s1_b), .s2(s2_b), .s3(s3_b), .s4(s4_b), .s5(s5_b), .s6(s6_b));

    always @* begin
        assert({s1_b, s2_b, s3_b, s4_b, s5_b, s6_b} === {s1_a, s2_a, s3_a, s4_a, s5_a, s6_a});
    end
endmodule
