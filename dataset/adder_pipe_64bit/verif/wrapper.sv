module wrapper (
    input wire clk,
    input wire rst_n,
    input wire i_en,
    input wire [63:0] adda,
    input wire [63:0] addb
);
    wire [64:0] result_a, result_b;
    wire o_en_a, o_en_b;
    reg [3:0] cycle = 0;

    adder_pipe_64bit u_a (
        .clk(clk), .rst_n(rst_n), .i_en(i_en), .adda(adda), .addb(addb),
        .result(result_a), .o_en(o_en_a)
    );

    adder_pipe_64bit_optimized u_b (
        .clk(clk), .rst_n(rst_n), .i_en(i_en), .adda(adda), .addb(addb),
        .result(result_b), .o_en(o_en_b)
    );

    always @(posedge clk) begin
        if (cycle != 7)
            cycle <= cycle + 1'b1;
        if (cycle == 0)
            assume(!rst_n);
        else
            assume(rst_n);
        if (cycle >= 1)
            assert({o_en_a, result_a} === {o_en_b, result_b});
    end
endmodule
