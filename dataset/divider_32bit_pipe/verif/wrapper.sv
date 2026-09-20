module wrapper (
    input wire clk,
    input wire reset,
    input wire [31:0] A,
    input wire [15:0] B
);
    wire [31:0] result_a, odd_a;
    wire [31:0] result_b, odd_b;
    reg started = 0;
    reg [3:0] cycle = 0;

    divider_32bit_pipe u_a (.clk(clk), .reset(reset), .A(A), .B(B), .result(result_a), .odd(odd_a));
    divider_32bit_pipe_optimized u_b (.clk(clk), .reset(reset), .A(A), .B(B), .result(result_b), .odd(odd_b));

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
            if (cycle != 4'd14)
                cycle <= cycle + 1'b1;
        end

        if (cycle >= 7)
            assert({result_b, odd_b} === $past({result_a, odd_a}, 2));
    end
endmodule
