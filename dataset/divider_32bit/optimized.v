module divider_32bit_optimized (
    input wire clk,
    input wire reset,
    input wire [31:0] A,
    input wire [15:0] B,
    output reg [31:0] result,
    output reg [31:0] odd
);

    reg [63:0] s1_a, s1_b;
    reg [63:0] s2_a, s2_b;
    reg [63:0] s3_a, s3_b;
    reg [63:0] s4_a, s4_b;

    always @(posedge clk) begin
        if (reset) begin
            s1_a <= 64'b0;
            s1_b <= 64'b0;
        end else begin
            s1_a <= {32'b0, A};
            s1_b <= {B, 32'b0};
        end
    end

    always @(posedge clk) begin
        integer i;
        reg [63:0] tmp_a;
        if (reset) begin
            s2_a <= 64'b0;
            s2_b <= 64'b0;
        end else begin
            tmp_a = s1_a;
            for (i = 0; i < 8; i = i + 1) begin
                tmp_a = tmp_a << 1;
                if (tmp_a >= s1_b)
                    tmp_a = tmp_a - s1_b + 1;
            end
            s2_a <= tmp_a;
            s2_b <= s1_b;
        end
    end

    always @(posedge clk) begin
        integer i;
        reg [63:0] tmp_a;
        if (reset) begin
            s3_a <= 64'b0;
            s3_b <= 64'b0;
        end else begin
            tmp_a = s2_a;
            for (i = 0; i < 8; i = i + 1) begin
                tmp_a = tmp_a << 1;
                if (tmp_a >= s2_b)
                    tmp_a = tmp_a - s2_b + 1;
            end
            s3_a <= tmp_a;
            s3_b <= s2_b;
        end
    end

    always @(posedge clk) begin
        integer i;
        reg [63:0] tmp_a;
        if (reset) begin
            s4_a <= 64'b0;
            s4_b <= 64'b0;
        end else begin
            tmp_a = s3_a;
            for (i = 0; i < 8; i = i + 1) begin
                tmp_a = tmp_a << 1;
                if (tmp_a >= s3_b)
                    tmp_a = tmp_a - s3_b + 1;
            end
            s4_a <= tmp_a;
            s4_b <= s3_b;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            result <= 32'b0;
            odd    <= 32'b0;
        end else begin
            result <= s4_a[31:0];
            odd    <= s4_a[63:32];
        end
    end

endmodule
