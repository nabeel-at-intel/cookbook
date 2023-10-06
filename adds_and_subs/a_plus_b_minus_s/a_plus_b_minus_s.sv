module a_plus_b_minus_s #(
    parameter SIZE = 8
)(
    input [SIZE-1:0] a,
    input [SIZE-1:0] b,
    input s,
    output [SIZE-1:0] out
);
    wire [SIZE-1:0] left;
    wire [SIZE-1:0] right;
    
    wire [SIZE-1:0] w_xor;
    wire [SIZE-1:0] w_maj;
    assign w_xor = a ^ b ^ {SIZE {1'b1}};
    assign w_maj = a | b;
    assign left = w_xor;
    assign right = {w_maj[SIZE-2:0], ~s};
    assign out = left + right;
    
endmodule
