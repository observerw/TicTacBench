module wrapper (
    input wire clk,
    input wire rst_n,
    input wire din_serial,
    input wire din_valid
);
    wire [7:0] dout_parallel_a, dout_parallel_b;
    wire dout_valid_a, dout_valid_b;
    reg [3:0] cycle = 0;

    serial2parallel u_a (.clk(clk), .rst_n(rst_n), .din_serial(din_serial), .din_valid(din_valid), .dout_parallel(dout_parallel_a), .dout_valid(dout_valid_a));
    serial2parallel_optimized u_b (.clk(clk), .rst_n(rst_n), .din_serial(din_serial), .din_valid(din_valid), .dout_parallel(dout_parallel_b), .dout_valid(dout_valid_b));

    always @(posedge clk) begin
        if (cycle != 4'd11)
            cycle <= cycle + 1'b1;

        if (cycle == 0)
            assume(!rst_n);
        else
            assume(rst_n);

        if (cycle >= 1)
            assert({dout_parallel_a, dout_valid_a} === {dout_parallel_b, dout_valid_b});
    end
endmodule
