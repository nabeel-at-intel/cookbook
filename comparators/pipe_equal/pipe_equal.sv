`include "../../logic/pipe_and/pipe_and.sv"
module pipe_equal #(
    parameter WIDTH = 10
)(
    input clk,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output out
);

generate
    if (WIDTH <= 3) begin
        reg out_r;
        always @(posedge clk) begin
            out_r <= (a == b);
        end
        assign out = out_r;
    end else begin
        localparam N = (WIDTH + 2) / 3;
        localparam WIDTH1 = N * 3;
        wire [WIDTH1-1:0] a1;
        wire [WIDTH1-1:0] b1;
        reg [N-1:0] out1;
        assign a1 = {{(WIDTH1-WIDTH){1'b1}}, a};
        assign b1 = {{(WIDTH1-WIDTH){1'b1}}, b};
        genvar k;
        for (k = 0; k < N; k=k+1) begin : l1
            always @(posedge clk) begin
                out1[k] <= (a1[3*k+2:3*k] == b1[3*k+2:3*k]);
            end            
        end
        pipe_and #(N) inst(.clk(clk), .a(out1), .out(out));
    end
endgenerate
endmodule
