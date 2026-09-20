module wrapper (
    input wire clk,
    input wire signed [7:0] a,
    input wire signed [7:0] b,
    input wire reset
);
    wire signed [15:0] z_a, z_b;
    reg started = 0;
    reg [2:0] cycle = 0;

    mac u_a (.clk(clk), .a(a), .b(b), .reset(reset), .z(z_a));
    mac_optimized u_b (.clk(clk), .a(a), .b(b), .reset(reset), .z(z_b));

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
            if (cycle != 6)
                cycle <= cycle + 1'b1;
        end

        if (cycle >= 3)
            assert(z_b === z_a);
    end
endmodule
