module wrapper (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire valid_in
);
    wire valid_out_a, valid_out_b;
    wire [9:0] data_out_a, data_out_b;
    reg [2:0] cycle = 0;

    accu u_a (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .valid_in(valid_in),
        .valid_out(valid_out_a),
        .data_out(data_out_a)
    );

    accu_optimized u_b (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .valid_in(valid_in),
        .valid_out(valid_out_b),
        .data_out(data_out_b)
    );

    always @(posedge clk) begin
        if (cycle != 5)
            cycle <= cycle + 1'b1;
        if (cycle == 0)
            assume(!rst_n);
        else
            assume(rst_n);
        if (cycle >= 1)
            assert({valid_out_a, data_out_a} === {valid_out_b, data_out_b});
    end
endmodule
