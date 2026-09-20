module divider_16bit (
    input  wire [15:0] A,
    input  wire [ 7:0] B,
    output wire [15:0] result,
    output wire [15:0] odd
);

  reg [31:0] temp;
  integer i;

  always @(*) begin
    temp = {16'b0, A};

    for (i = 0; i < 16; i = i + 1) begin
      temp = temp << 1;


      if (temp[31] == 1'b0) begin
        temp[31:16] = temp[31:16] - {8'b0, B};
      end else begin
        temp[31:16] = temp[31:16] + {8'b0, B};
      end

      temp[0] = ~temp[31];
    end


    if (temp[31] == 1'b1) begin
      temp[31:16] = temp[31:16] + {8'b0, B};
    end
  end

  assign result = temp[15:0];
  assign odd = temp[31:16];

endmodule
