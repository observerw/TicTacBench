module add_sub_optimized (
    input [15:0] a, b,
    input control,
    output reg [15:0] result
);

    wire [7:0] a_high = a[15:8];
    wire [7:0] a_low = a[7:0];
    wire [7:0] b_high = b[15:8];
    wire [7:0] b_low = b[7:0];

    reg [7:0] result_high;
    reg [7:0] result_low;
    reg carry;

    always @(*) begin
        if (control == 1'b1) begin

            {carry, result_low} = a_low + b_low;

            result_high = a_high + b_high + {7'b0, carry};
        end
        else begin

            {carry, result_low} = a_low - b_low;

            result_high = a_high - b_high - {7'b0, carry};
        end

        result = {result_high, result_low};
    end

endmodule
