module wrapper (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [15:0] ain,
    input wire [15:0] bin
);
    wire [31:0] yout_a, yout_b;
    wire done_a, done_b;
    reg [4:0] cycle = 0;

    multi_16bit u_a (.clk(clk), .rst_n(rst_n), .start(start), .ain(ain), .bin(bin), .yout(yout_a), .done(done_a));
    multi_16bit_optimized u_b (.clk(clk), .rst_n(rst_n), .start(start), .ain(ain), .bin(bin), .yout(yout_b), .done(done_b));

    always @(posedge clk) begin
        if (cycle != 5'd19)
            cycle <= cycle + 1'b1;
        if (cycle == 0)
            assume(!rst_n);
        else
            assume(rst_n);
        if (cycle >= 1)
            assert({yout_a, done_a} === {yout_b, done_b});
    end
endmodule
