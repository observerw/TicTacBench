module addr_calcu_pipe_optimized (
    input clk,
    input reset,
    input [7:0] address,
    input [7:0] ptr1,
    ptr2,
    input [7:0] b,
    input control,  // control is late arriving
    output [15:0] count
);

  parameter [7:0] base = 8'b10000000;

  wire [7:0] offset1, offset2;
  wire [15:0] addr1, addr2;
  wire [15:0] count1, count2;
  reg [15:0] count_reg;

  assign offset1 = base - ptr1;
  assign offset2 = base - ptr2;
  assign addr1   = address - {8'h00, offset1};
  assign addr2   = address - {8'h00, offset2};
  assign count1  = addr1 + b;
  assign count2  = addr2 + b;
  assign count   = count_reg;

  always @(posedge clk) begin
    if (reset)
      count_reg <= 16'b0;
    else
      count_reg <= (control == 1'b1) ? count1 : count2;
  end

endmodule
