`include "../../logic/pipe_and/pipe_and.sv"
module pipe_equal_const #(
    parameter WIDTH = 10,
    parameter [WIDTH-1:0] CONST = 42
)(
    input clk,
    input [WIDTH-1:0] a,
    output out
);
pipe_and #(WIDTH) inst(.clk(clk), .a(~a ^ CONST), .out(out));
endmodule
