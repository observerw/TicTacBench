module wrapper (
    input wire clk,
    input wire reset,
    input wire [7:0] address,
    input wire [7:0] ptr1,
    input wire [7:0] ptr2,
    input wire [7:0] b,
    input wire control
);
    wire [15:0] count_a, count_b;
    reg started = 0;
    reg [2:0] cycle = 0;

    addr_calcu_pipe u_a (
        .clk(clk),
        .reset(reset),
        .address(address),
        .ptr1(ptr1),
        .ptr2(ptr2),
        .b(b),
        .control(control),
        .count(count_a)
    );

    addr_calcu_pipe_optimized u_b (
        .clk(clk),
        .reset(reset),
        .address(address),
        .ptr1(ptr1),
        .ptr2(ptr2),
        .b(b),
        .control(control),
        .count(count_b)
    );

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
            if (cycle != 3'd4)
                cycle <= cycle + 1'b1;
        end

        if (cycle >= 3)
            assert(count_b === $past(count_a, 1));
    end
endmodule
