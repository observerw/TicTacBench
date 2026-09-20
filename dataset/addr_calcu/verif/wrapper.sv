module wrapper (
    input wire [7:0] address,
    input wire [7:0] ptr1,
    input wire [7:0] ptr2,
    input wire [7:0] b,
    input wire control
);
    wire [15:0] count_a, count_b;

    addr_calcu u_a (
        .address(address),
        .ptr1(ptr1),
        .ptr2(ptr2),
        .b(b),
        .control(control),
        .count(count_a)
    );

    addr_calcu_optimized u_b (
        .address(address),
        .ptr1(ptr1),
        .ptr2(ptr2),
        .b(b),
        .control(control),
        .count(count_b)
    );

    always @* begin
        assert(count_b === count_a);
    end
endmodule
