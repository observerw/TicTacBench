module gray_optimized (
    input wire clk,
    input wire rst_n,
    input wire [3:0] cmd,
    output reg [7:0] out
);

  localparam [3:0] S0 = 4'b0000;  // 0
  localparam [3:0] S1 = 4'b0001;  // 1
  localparam [3:0] S2 = 4'b0011;  // 3
  localparam [3:0] S3 = 4'b0010;  // 2
  localparam [3:0] S4 = 4'b0110;  // 6
  localparam [3:0] S5 = 4'b0111;  // 7
  localparam [3:0] S6 = 4'b0101;  // 5
  localparam [3:0] S7 = 4'b0100;  // 4
  localparam [3:0] S8 = 4'b1100;  // 12
  localparam [3:0] S9 = 4'b1101;  // 13
  localparam [3:0] S10 = 4'b1111;  // 15
  localparam [3:0] S11 = 4'b1110;  // 14
  localparam [3:0] S12 = 4'b1010;  // 10
  localparam [3:0] S13 = 4'b1011;  // 11
  localparam [3:0] S14 = 4'b1001;  // 9
  localparam [3:0] S15 = 4'b1000;  // 8

  reg [3:0] state, next_state;

  always @(*) begin
    case (state)
      S0: next_state = (cmd[0]) ? S1 : S8;
      S1: next_state = (cmd[1:0] == 2'b11) ? S2 : S0;
      S2: next_state = S3;
      S3: next_state = (cmd[2]) ? S4 : S1;
      S4: next_state = (cmd[3]) ? S5 : S12;
      S5: next_state = S6;
      S6: next_state = (|cmd) ? S7 : S4;
      S7: next_state = S0;
      S8: next_state = (cmd[3:2] == 2'b01) ? S9 : S15;
      S9: next_state = S10;
      S10: next_state = (cmd[1]) ? S11 : S9;
      S11: next_state = S12;
      S12: next_state = (cmd[0] ^ cmd[1]) ? S13 : S14;
      S13: next_state = S0;
      S14: next_state = S15;
      S15: next_state = S0;
      default: next_state = S0;
    endcase
  end

  always @(*) begin
    case (state)
      S0: out = 8'b0000_0001;
      S1: out = 8'b0000_0010;
      S2: out = 8'b0000_0100;
      S3: out = 8'b0000_1000;
      S4: out = 8'b0001_0000;
      S5: out = 8'b0010_0000;
      S6: out = 8'b0100_0000;
      S7: out = 8'b1000_0000;
      S8: out = 8'b0000_0001 << 1;
      S9: out = 8'b0000_0001 << 2;
      S10: out = 8'b0000_0001 << 3;
      S11: out = 8'b0000_0001 << 4;
      S12: out = 8'b0000_0001 << 5;
      S13: out = 8'b0000_0001 << 6;
      S14: out = 8'b0000_0001 << 7;
      S15: out = 8'b0000_0001;
      default: out = 8'b0000_0000;
    endcase
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= S0;
    end else begin
      state <= next_state;
    end
  end

endmodule
