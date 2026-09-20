module float_multi_pipe (
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] z
);
    reg [2:0] counter;

    reg [23:0] a_mantissa;
    reg [23:0] b_mantissa;
    reg [23:0] z_mantissa;
    reg [9:0] a_exponent;
    reg [9:0] b_exponent;
    reg [9:0] z_exponent;
    reg a_sign;
    reg b_sign;
    reg z_sign;

    reg [49:0] product;

    reg guard_bit;
    reg round_bit;
    reg sticky;
    reg [31:0] z_next;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 3'd0;
            a_mantissa <= 24'd0;
            b_mantissa <= 24'd0;
            z_mantissa <= 24'd0;
            a_exponent <= 10'd0;
            b_exponent <= 10'd0;
            z_exponent <= 10'd0;
            a_sign <= 1'b0;
            b_sign <= 1'b0;
            z_sign <= 1'b0;
            product <= 50'd0;
            guard_bit <= 1'b0;
            round_bit <= 1'b0;
            sticky <= 1'b0;
            z_next <= 32'd0;
            z <= 32'd0;
        end else begin
            counter <= counter + 3'd1;

            case (counter)
                3'b000: begin
                    a_mantissa <= {1'b0, a[22:0]};
                    b_mantissa <= {1'b0, b[22:0]};
                    a_exponent <= a[30:23] - 10'd127;
                    b_exponent <= b[30:23] - 10'd127;
                    a_sign <= a[31];
                    b_sign <= b[31];
                end

                3'b001: begin
                    z_next <= 32'd0;
                    if ((a_exponent == 10'd128 && a_mantissa != 0) || (b_exponent == 10'd128 && b_mantissa != 0)) begin
                        z_next[31] <= 1'b1;
                        z_next[30:23] <= 8'hff;
                        z_next[22] <= 1'b1;
                        z_next[21:0] <= 22'd0;
                    end else if (a_exponent == 10'd128) begin
                        z_next[31] <= a_sign ^ b_sign;
                        z_next[30:23] <= 8'hff;
                        z_next[22:0] <= 23'd0;
                        if (($signed(b_exponent) == -127) && (b_mantissa == 0)) begin
                            z_next[31] <= 1'b1;
                            z_next[30:23] <= 8'hff;
                            z_next[22] <= 1'b1;
                            z_next[21:0] <= 22'd0;
                        end
                    end else if (b_exponent == 10'd128) begin
                        z_next[31] <= a_sign ^ b_sign;
                        z_next[30:23] <= 8'hff;
                        z_next[22:0] <= 23'd0;
                        if (($signed(a_exponent) == -127) && (a_mantissa == 0)) begin
                            z_next[31] <= 1'b1;
                            z_next[30:23] <= 8'hff;
                            z_next[22] <= 1'b1;
                            z_next[21:0] <= 22'd0;
                        end
                    end else if (($signed(a_exponent) == -127) && (a_mantissa == 0)) begin
                        z_next[31] <= a_sign ^ b_sign;
                        z_next[30:23] <= 8'd0;
                        z_next[22:0] <= 23'd0;
                    end else if (($signed(b_exponent) == -127) && (b_mantissa == 0)) begin
                        z_next[31] <= a_sign ^ b_sign;
                        z_next[30:23] <= 8'd0;
                        z_next[22:0] <= 23'd0;
                    end else begin
                        if ($signed(a_exponent) == -127) begin
                            a_exponent <= -126;
                        end else begin
                            a_mantissa[23] <= 1'b1;
                        end

                        if ($signed(b_exponent) == -127) begin
                            b_exponent <= -126;
                        end else begin
                            b_mantissa[23] <= 1'b1;
                        end
                    end
                end

                3'b010: begin
                    if (!a_mantissa[23]) begin
                        a_mantissa <= a_mantissa << 1;
                        a_exponent <= a_exponent - 1'b1;
                    end
                    if (!b_mantissa[23]) begin
                        b_mantissa <= b_mantissa << 1;
                        b_exponent <= b_exponent - 1'b1;
                    end
                end

                3'b011: begin
                    z_sign <= a_sign ^ b_sign;
                    z_exponent <= a_exponent + b_exponent + 1'b1;
                    product <= (a_mantissa * b_mantissa) << 2;
                end

                3'b100: begin
                    z_mantissa <= product[49:26];
                    guard_bit <= product[25];
                    round_bit <= product[24];
                    sticky <= (product[23:0] != 0);
                end

                3'b101: begin
                    if ($signed(z_exponent) < -126) begin
                        z_exponent <= z_exponent + (-126 - $signed(z_exponent));
                        z_mantissa <= z_mantissa >> (-126 - $signed(z_exponent));
                        guard_bit <= z_mantissa[0];
                        round_bit <= guard_bit;
                        sticky <= sticky | round_bit;
                    end else if (z_mantissa[23] == 0) begin
                        z_exponent <= z_exponent - 1'b1;
                        z_mantissa <= z_mantissa << 1;
                        z_mantissa[0] <= guard_bit;
                        guard_bit <= round_bit;
                        round_bit <= 1'b0;
                    end else if (guard_bit && (round_bit | sticky | z_mantissa[0])) begin
                        z_mantissa <= z_mantissa + 1'b1;
                        if (z_mantissa == 24'hffffff) begin
                            z_exponent <= z_exponent + 1'b1;
                        end
                    end
                end

                3'b110: begin
                    z[22:0] <= z_mantissa[22:0];
                    z[30:23] <= z_exponent[7:0] + 8'd127;
                    z[31] <= z_sign;
                    if ($signed(z_exponent) == -126 && z_mantissa[23] == 0) begin
                        z[30:23] <= 8'd0;
                    end
                    if ($signed(z_exponent) > 127) begin
                        z[22:0] <= 23'd0;
                        z[30:23] <= 8'hff;
                        z[31] <= z_sign;
                    end
                    if (z_next != 32'd0) begin
                        z <= z_next;
                    end
                end
            endcase
        end
    end
endmodule
