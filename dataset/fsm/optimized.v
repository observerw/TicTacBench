module fsm_optimized (
    input clk,
    input rst_n,
    input start,
    input [7:0] data_in,
    output reg [7:0] data_out,
    output reg done
);

  localparam [8:0] S_IDLE = 9'b000000001;
  localparam [8:0] S_START = 9'b000000010;
  localparam [8:0] S_READ = 9'b000000100;
  localparam [8:0] S_PROC1 = 9'b000001000;
  localparam [8:0] S_PROC2 = 9'b000010000;
  localparam [8:0] S_PROC3 = 9'b000100000;
  localparam [8:0] S_WAIT = 9'b001000000;
  localparam [8:0] S_DONE = 9'b010000000;
  localparam [8:0] S_ERROR = 9'b100000000;

  reg [8:0] state, next_state;

  always @(*) begin
    next_state = S_IDLE;  // Default
    case (state)
      S_IDLE:  next_state = start ? S_START : S_IDLE;
      S_START: next_state = (data_in[0]) ? S_READ : S_ERROR;
      S_READ:  next_state = (data_in[3:1] == 3'b101) ? S_PROC1 : S_WAIT;
      S_PROC1: next_state = S_PROC2;
      S_PROC2: next_state = (data_in[7]) ? S_PROC3 : S_WAIT;
      S_PROC3: next_state = S_DONE;
      S_WAIT:  next_state = (data_in[4]) ? S_READ : S_WAIT;
      S_DONE:  next_state = S_IDLE;
      S_ERROR: next_state = (data_in[2:0] == 3'b111) ? S_IDLE : S_ERROR;
      default: next_state = S_IDLE;
    endcase
  end

  always @(*) begin
    {data_out, done} = {8'h00, 1'b0};
    case (state)
      S_READ:  data_out = data_in;
      S_PROC1: data_out = data_in + 8'h01;
      S_PROC2: data_out = data_in << 1;
      S_PROC3: data_out = data_in ^ 8'hFF;
      S_DONE:  {data_out, done} = {data_in, 1'b1};
      S_ERROR: data_out = 8'hEE;
    endcase
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= S_IDLE;
    end else begin
      state <= next_state;
    end
  end

endmodule
