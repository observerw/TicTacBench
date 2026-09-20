module wrapper (
    input wire clk,
    input wire reset,
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    input wire [7:0] d
);
    wire [7:0] s1_a, s2_a, s3_a, s4_a, s5_a, s6_a;
    wire [7:0] s1_b, s2_b, s3_b, s4_b, s5_b, s6_b;
    reg started = 0;
    reg [2:0] cycle = 0;

    calculation_pipe u_a (.clk(clk), .reset(reset), .a(a), .b(b), .c(c), .d(d), .s1(s1_a), .s2(s2_a), .s3(s3_a), .s4(s4_a), .s5(s5_a), .s6(s6_a));
    calculation_pipe_optimized u_b (.clk(clk), .reset(reset), .a(a), .b(b), .c(c), .d(d), .s1(s1_b), .s2(s2_b), .s3(s3_b), .s4(s4_b), .s5(s5_b), .s6(s6_b));

    always @(posedge clk) begin
        if (!started) begin
            started <= 1'b1;
            cycle <= 0;
            assume(reset);
        end else if (cycle == 0) begin
            assume(!reset);
            cycle <= 1;
        end else begin
            assume(!reset);
            if (cycle != 3'd6)
                cycle <= cycle + 1'b1;
        end

        if (cycle >= 5)
            assert({s1_b, s2_b, s3_b, s4_b, s5_b, s6_b} === $past({s1_a, s2_a, s3_a, s4_a, s5_a, s6_a}, 3));
    end
endmodule
