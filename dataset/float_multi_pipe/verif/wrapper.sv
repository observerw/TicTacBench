module wrapper (
    input wire clk,
    input wire rst,
    input wire [31:0] a,
    input wire [31:0] b
);
    wire [31:0] z_a, z_b;
    reg started = 0;
    reg [2:0] cycle = 0;

    float_multi_pipe u_a (.clk(clk), .rst(rst), .a(a), .b(b), .z(z_a));
    float_multi_pipe_optimized u_b (.clk(clk), .rst(rst), .a(a), .b(b), .z(z_b));

    always @(posedge clk) begin
        if (!started) begin
            started <= 1'b1;
            cycle <= 0;
            assume(rst);
        end else if (cycle == 0) begin
            assume(!rst);
            cycle <= 1;
        end else begin
            assume(!rst);
            if (cycle != 7)
                cycle <= cycle + 1'b1;
        end

        if (cycle >= 4)
            assert(z_b === $past(z_a, 2));
    end
endmodule
