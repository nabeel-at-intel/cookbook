module pipe_xor #(
    parameter WIDTH = 10
)(
    input clk,
    input [WIDTH-1:0] a,
    output out
);

generate
    if (WIDTH <= 6) begin
        reg out_r;
        always @(posedge clk) begin
            out_r <= ^a;
        end
        assign out = out_r;
    end else begin
        localparam N = (WIDTH + 5) / 6;
        localparam WIDTH1 = N * 6;
        wire [WIDTH1-1:0] a1;
        reg [N-1:0] out1;
        assign a1 = {{(WIDTH1-WIDTH){1'b0}}, a};
        genvar k;
        for (k = 0; k < N; k=k+1) begin : l1
            always @(posedge clk) begin
                out1[k] <= ^a1[6*k+5:6*k];
            end            
        end
        pipe_xor #(N) inst(.clk(clk), .a(out1), .out(out));
    end
endgenerate
endmodule
