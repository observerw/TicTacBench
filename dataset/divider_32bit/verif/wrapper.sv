module wrapper (
    input wire clk,
    input wire reset,
    input wire [31:0] A,
    input wire [15:0] B
);
    wire [31:0] result_a, odd_a;
    wire [31:0] result_b, odd_b;
    reg started = 0;
    reg [2:0] cycle = 0;
    reg [31:0] hold_A = 0;
    reg [15:0] hold_B = 0;

    divider_32bit       u_a (.clk(clk), .reset(reset), .A(A), .B(B), .result(result_a), .odd(odd_a));
    divider_32bit_optimized u_b (.clk(clk), .reset(reset), .A(A), .B(B), .result(result_b), .odd(odd_b));

    always @(posedge clk) begin
        if (!started) begin
            started <= 1'b1;
            cycle <= 0;
            assume(reset);
        end else if (cycle == 0) begin
            assume(!reset);
            hold_A <= A;
            hold_B <= B;
            cycle <= 1;
        end else begin
            assume(!reset);
            assume(A == hold_A);
            assume(B == hold_B);
            if (cycle != 3'd7)
                cycle <= cycle + 1'b1;
        end

        if (cycle >= 4)
            assert({result_b, odd_b} === {result_a, odd_a});
    end
endmodule
