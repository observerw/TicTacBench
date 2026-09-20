module wrapper (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [7:0] data_in
);
    wire [7:0] data_out_a, data_out_b;
    wire done_a, done_b;
    reg [3:0] cycle = 0;

    fsm_encode u_a (.clk(clk), .rst_n(rst_n), .start(start), .data_in(data_in), .data_out(data_out_a), .done(done_a));
    fsm_encode_optimized u_b (.clk(clk), .rst_n(rst_n), .start(start), .data_in(data_in), .data_out(data_out_b), .done(done_b));

    always @(posedge clk) begin
        if (cycle != 4'd9)
            cycle <= cycle + 1'b1;
        if (cycle == 0)
            assume(!rst_n);
        else
            assume(rst_n);
        if (cycle >= 1)
            assert({data_out_a, done_a} === {data_out_b, done_b});
    end
endmodule
