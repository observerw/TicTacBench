module wrapper (
    input wire s,
    input wire [31:0] A,
    input wire [31:0] B,
    input wire [31:0] C,
    input wire [31:0] D
);
    wire [32:0] Z_a, Z_b;

    adder_select u_a (.s(s), .A(A), .B(B), .C(C), .D(D), .Z(Z_a));
    adder_select_optimized u_b (.s(s), .A(A), .B(B), .C(C), .D(D), .Z(Z_b));

    always @(*) begin
        assert(Z_a === Z_b);
    end
endmodule
