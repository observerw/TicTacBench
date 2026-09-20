module wrapper (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [5:0] aluc
);
    wire [31:0] r_a, r_b;
    wire zero_a, zero_b, carry_a, carry_b, negative_a, negative_b;
    wire overflow_a, overflow_b, flag_a, flag_b;

    alu u_a (
        .a(a), .b(b), .aluc(aluc), .r(r_a), .zero(zero_a), .carry(carry_a),
        .negative(negative_a), .overflow(overflow_a), .flag(flag_a)
    );

    alu_optimized u_b (
        .a(a), .b(b), .aluc(aluc), .r(r_b), .zero(zero_b), .carry(carry_b),
        .negative(negative_b), .overflow(overflow_b), .flag(flag_b)
    );

    always @(*) begin
        assert({r_a, zero_a, flag_a} === {r_b, zero_b, flag_b});
    end
endmodule
