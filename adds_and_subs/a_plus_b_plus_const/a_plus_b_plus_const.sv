module a_plus_b_plus_const #(
	parameter SIZE = 12,
	parameter CONST = 1
)(
	input signed [SIZE-1:0] a,
	input signed [SIZE-1:0] b,
	output signed [SIZE+1:0] out
);
	wire [SIZE+1:0] left;
	wire [SIZE+1:0] right;
	wire temp;
	
	wire [SIZE-1:0] w_xor;
	wire [SIZE-1:0] w_maj;
	assign w_xor = a ^ b ^ CONST;
	assign w_maj = a & b | a & CONST | b & CONST;
	assign left = {w_xor[SIZE-1], w_xor[SIZE-1], w_xor};
	assign right = {w_maj[SIZE-1], w_maj, 1'b0};
	assign out = left + right;
	
endmodule
