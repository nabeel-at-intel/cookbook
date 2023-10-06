module add_a_b_s0_s1 #(
	parameter SIZE = 5
)(
	input [SIZE-1:0] a,
	input [SIZE-1:0] b,
	input s0,
	input s1,
	output [SIZE:0] out
);
	wire [SIZE+1:0] left;
	wire [SIZE+1:0] right;
	wire temp;
	
	assign left = {1'b0, a ^ b, s0};
	assign right = {a & b, s1, s0};
	assign {out, temp} = left + right;
	
endmodule
