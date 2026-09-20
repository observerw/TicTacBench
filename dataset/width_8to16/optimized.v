`timescale 1ns/1ns
module width_8to16_optimized (
    input clk,
    input rst_n,
    input valid_in,
    input [7:0] data_in,
    output reg valid_out,
    output reg [15:0] data_out
);

    reg [7:0] data_lock;
    reg flag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_lock <= 'd0;
        else if (valid_in && !flag)
            data_lock <= data_in;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            flag <= 'd0;
        else if (valid_in)
            flag <= ~flag;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_out <= 'd0;
        else if (valid_in && flag)
            valid_out <= 1'd1;
        else
            valid_out <= 'd0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 'd0;
        else if (valid_in && flag)
            data_out <= {data_lock, data_in};
    end

endmodule
