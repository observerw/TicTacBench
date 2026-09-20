module wrapper (
    input wire clk,
    input wire rst,
    input wire [7:0] dividend,
    input wire [7:0] divisor,
    input wire sign,
    input wire opn_valid,
    input wire res_ready
);
    wire res_valid_a, res_valid_b;
    wire [15:0] result_a, result_b;
    reg [3:0] cycle = 0;

    radix2_div u_a (
        .clk(clk), .rst(rst), .dividend(dividend), .divisor(divisor), .sign(sign),
        .opn_valid(opn_valid), .res_valid(res_valid_a), .res_ready(res_ready), .result(result_a)
    );

    radix2_div_optimized u_b (
        .clk(clk), .rst(rst), .dividend(dividend), .divisor(divisor), .sign(sign),
        .opn_valid(opn_valid), .res_valid(res_valid_b), .res_ready(res_ready), .result(result_b)
    );

    always @(posedge clk) begin
        if (cycle != 4'd11)
            cycle <= cycle + 1'b1;
        if (cycle == 0)
            assume(rst);
        else
            assume(!rst);
        if (cycle >= 1)
            assert({res_valid_a, result_a} === {res_valid_b, result_b});
    end
endmodule
