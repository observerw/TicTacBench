module fsm_encode (
    input clk,
    input rst_n,
    input start,
    input [7:0] data_in,
    output [7:0] data_out,
    output reg done
);

  localparam
    IDLE    = 8'b00000001,
    LOAD1   = 8'b00000010,
    LOAD2   = 8'b00000100,
    ADD     = 8'b00001000,
    SUB     = 8'b00010000,
    SHIFT   = 8'b00100000,
    STORE1  = 8'b01000000,
    STORE2  = 8'b10000000;

  reg [7:0] current_state, next_state;
  reg [7:0] reg1, reg2;  // Pipeline registers
  reg [7:0] out_reg;  // Output register

  // State transition
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= IDLE;
    else current_state <= next_state;
  end

  // Next state logic
  always @(*) begin
    case (current_state)
      IDLE:   next_state = start ? LOAD1 : IDLE;
      LOAD1:  next_state = LOAD2;
      LOAD2:  next_state = ADD;
      ADD:    next_state = SUB;
      SUB:    next_state = SHIFT;
      SHIFT:  next_state = STORE1;
      STORE1: next_state = STORE2;
      STORE2: next_state = IDLE;
      default:next_state = IDLE;
    endcase
  end

  // Datapath control
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reg1    <= 8'b0;
      reg2    <= 8'b0;
      out_reg <= 8'b0;
      done    <= 1'b0;
    end else begin
      case (current_state)
        IDLE: begin
          done <= 1'b0;
        end
        LOAD1: begin
          reg1 <= data_in;
        end
        LOAD2: begin
          reg2 <= data_in;
        end
        ADD: begin
          reg1 <= reg1 + reg2;  // Simplest ADD
        end
        SUB: begin
          reg1 <= reg1 - reg2;  // Simplest SUB
        end
        SHIFT: begin
          reg1 <= reg1 << 1;  // Left shift by 1
        end
        STORE1: begin
          out_reg <= reg1;
        end
        STORE2: begin
          out_reg <= reg2;
          done <= 1'b1;
        end
      endcase
    end
  end

  assign data_out = out_reg;

endmodule
