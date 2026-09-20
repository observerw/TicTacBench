module calculation_pipe_optimized
#(  parameter       BW = 8)
(
    input clk,
    input reset,
    input [BW-1:0] a,
    input [BW-1:0] b,
    input [BW-1:0] c,
    input [BW-1:0] d,
    output [BW-1:0] s1,
    output [BW-1:0] s2,
    output [BW-1:0] s3,
    output [BW-1:0] s4,
    output [BW-1:0] s5,
    output [BW-1:0] s6
);

    wire [BW-1:0] s1_comb, s2_comb, s3_comb, s4_comb, s5_comb, s6_comb;

    reg [BW-1:0] s1_pipe1, s1_pipe2, s1_pipe3;
    reg [BW-1:0] s2_pipe1, s2_pipe2, s2_pipe3;
    reg [BW-1:0] s3_pipe1, s3_pipe2, s3_pipe3;
    reg [BW-1:0] s4_pipe1, s4_pipe2, s4_pipe3;
    reg [BW-1:0] s5_pipe1, s5_pipe2, s5_pipe3;
    reg [BW-1:0] s6_pipe1, s6_pipe2, s6_pipe3;

    assign s1_comb = a + b;
    assign s2_comb = a * b;
    assign s3_comb = a % b + d;
    assign s4_comb = c + d + s2_comb;
    assign s5_comb = a - b;
    assign s6_comb = s4_comb + s5_comb;

    assign s1 = s1_pipe3;
    assign s2 = s2_pipe3;
    assign s3 = s3_pipe3;
    assign s4 = s4_pipe3;
    assign s5 = s5_pipe3;
    assign s6 = s6_pipe3;

    always @(posedge clk) begin
        if (reset) begin
            s1_pipe1 <= {BW{1'b0}};
            s1_pipe2 <= {BW{1'b0}};
            s1_pipe3 <= {BW{1'b0}};
            s2_pipe1 <= {BW{1'b0}};
            s2_pipe2 <= {BW{1'b0}};
            s2_pipe3 <= {BW{1'b0}};
            s3_pipe1 <= {BW{1'b0}};
            s3_pipe2 <= {BW{1'b0}};
            s3_pipe3 <= {BW{1'b0}};
            s4_pipe1 <= {BW{1'b0}};
            s4_pipe2 <= {BW{1'b0}};
            s4_pipe3 <= {BW{1'b0}};
            s5_pipe1 <= {BW{1'b0}};
            s5_pipe2 <= {BW{1'b0}};
            s5_pipe3 <= {BW{1'b0}};
            s6_pipe1 <= {BW{1'b0}};
            s6_pipe2 <= {BW{1'b0}};
            s6_pipe3 <= {BW{1'b0}};
        end else begin
            s1_pipe1 <= s1_comb;
            s2_pipe1 <= s2_comb;
            s3_pipe1 <= s3_comb;
            s4_pipe1 <= s4_comb;
            s5_pipe1 <= s5_comb;
            s6_pipe1 <= s6_comb;

            s1_pipe2 <= s1_pipe1;
            s2_pipe2 <= s2_pipe1;
            s3_pipe2 <= s3_pipe1;
            s4_pipe2 <= s4_pipe1;
            s5_pipe2 <= s5_pipe1;
            s6_pipe2 <= s6_pipe1;

            s1_pipe3 <= s1_pipe2;
            s2_pipe3 <= s2_pipe2;
            s3_pipe3 <= s3_pipe2;
            s4_pipe3 <= s4_pipe2;
            s5_pipe3 <= s5_pipe2;
            s6_pipe3 <= s6_pipe2;
        end
    end
endmodule
