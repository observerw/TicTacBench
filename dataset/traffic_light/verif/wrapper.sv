module wrapper (
    input wire rst_n,
    input wire clk,
    input wire pass_request
);
    wire [7:0] clock_a, clock_b;
    wire red_a, yellow_a, green_a;
    wire red_b, yellow_b, green_b;
    reg [2:0] cycle = 0;

    traffic_light u_a (
        .rst_n(rst_n), .clk(clk), .pass_request(pass_request),
        .clock(clock_a), .red(red_a), .yellow(yellow_a), .green(green_a)
    );

    traffic_light_optimized u_b (
        .rst_n(rst_n), .clk(clk), .pass_request(pass_request),
        .clock(clock_b), .red(red_b), .yellow(yellow_b), .green(green_b)
    );

    always @(posedge clk) begin
        if (cycle != 3)
            cycle <= cycle + 1'b1;
        if (cycle == 0)
            assume(!rst_n);
        if (cycle >= 1)
            assume(rst_n);
        if (cycle >= 2)
            assert({clock_a, red_a, yellow_a, green_a} === {clock_b, red_b, yellow_b, green_b});
    end
endmodule
