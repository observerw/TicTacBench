module mac_pipe_optimized (
    input clk,
    input signed [7:0] a, b,
    input reset,
    output reg signed [15:0] z
);
    reg signed [15:0] acc;
    reg signed [15:0] z_mid;

    always @(posedge clk) begin
        if (reset) begin
            acc <= 0;
            z_mid <= 0;
            z <= 0;
        end else begin
            acc <= acc + a * b;
            z_mid <= acc;
            z <= z_mid;
        end
    end

endmodule
