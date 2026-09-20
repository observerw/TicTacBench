module wrapper (
    input wire clk,
    input wire rst,
    input wire [31:0] a,
    input wire [31:0] b
);
    wire [31:0] z_a, z_b;
    reg [3:0] cycle = 0;

    float_multi u_a (.clk(clk), .rst(rst), .a(a), .b(b), .z(z_a));
    float_multi_optimized u_b (.clk(clk), .rst(rst), .a(a), .b(b), .z(z_b));

    always @(posedge clk) begin
        if (cycle != 4'd9)
            cycle <= cycle + 1'b1;

        if (cycle == 0) begin
            assume(rst);
        end else begin
            assume(!rst);
        end

        if (cycle >= 1)
            assert(z_b === z_a);
    end
endmodule
