// Copyright 2019 Intel Corporation. 
//
// This reference design file is subject licensed to you by the terms and 
// conditions of the applicable License Terms and Conditions for Hardware 
// Reference Designs and/or Design Examples (either as signed by you or 
// found at https://www.altera.com/common/legal/leg-license_agreement.html ).  
//
// As stated in the license, you agree to only use this reference design 
// solely in conjunction with Intel FPGAs or Intel CPLDs.  
//
// THE REFERENCE DESIGN IS PROVIDED "AS IS" WITHOUT ANY EXPRESS OR IMPLIED
// WARRANTY OF ANY KIND INCLUDING WARRANTIES OF MERCHANTABILITY, 
// NONINFRINGEMENT, OR FITNESS FOR A PARTICULAR PURPOSE. Intel does not 
// warrant or assume responsibility for the accuracy or completeness of any
// information, links or other items within the Reference Design and any 
// accompanying materials.
//
// In the event that you do not agree with such terms and conditions, do not
// use the reference design file.
/////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module tester #(
    parameter SIZE = 16,
    parameter LATENCY = 3
)(
    input clk
);


reg [SIZE-1:0] din_a = 0;
reg [SIZE-1:0] din_b = 0;

wire [SIZE-1:0] dout;

long_adder #(.FAMILY("Agilex"), .SIZE(SIZE)) dut (.*);

//reg [2*SIZE-1:0] counter = 0;
always @(negedge clk) begin
	//counter <= counter + 1;
	//{din_a, din_b} <= counter;
	din_a <= (din_a << 32) ^ $random;
	din_b <= (din_b << 32) ^ $random;
end

//reg [SIZE-1:0] alternate_dout;
reg [SIZE-1:0] alternate_dout_r[0:LATENCY-1];
//reg [SIZE-1:0] alternate_dout_r2;
//reg alternate_pout;
integer i;

always @(posedge clk) begin
	alternate_dout_r[0] <= din_a + din_b;
    for (i = 1; i < LATENCY; i=i+1)
        alternate_dout_r[i] <= alternate_dout_r[i-1];
	//alternate_dout_r2 <= alternate_dout_r;
    
    //alternate_pout <= ((din_a ^ din_b) == ((1 << SIZE)-1));
end

reg flushing = 1'b1;
reg fail = 1'b0;
always @(posedge clk) begin
	#10
	if (!flushing) begin
		if ((dout !== alternate_dout_r[LATENCY-1]) /*|| (pout !== alternate_pout)*/ ) begin
			$display ("%d: %b + %b is %b expected %b",SIZE, din_a,din_b,dout, alternate_dout_r[LATENCY-1]);
			fail = 1'b1;
		end
		//else begin
		//	$display ("%b + %b is %b",din_a,din_b,dout);		
		//end

	end
end

integer k;
initial begin
	for (k=0; k<5; k=k+1) @(negedge clk);
	flushing = 1'b0;
	for (k=0; k<10000; k=k+1) @(negedge clk);
	if (!fail) $display ("PASS");
	@(negedge clk);
	$stop();	
end

endmodule




module long_adder_tb ();

reg clk = 1'b0;

localparam ADDER_SIZE = 18; // Make sure it is the same as long_adder.ADDER_SIZE 
genvar i;
generate

for (i = 2*ADDER_SIZE; i < 4*ADDER_SIZE; i = i + ADDER_SIZE) begin
    tester #(i, 2) tester_inst(.*);
end
for (i = 4*ADDER_SIZE; i < 14*ADDER_SIZE; i = i + ADDER_SIZE) begin
    tester #(i, 3) tester_inst(.*);
end
for (i = 14*ADDER_SIZE; i < 50*ADDER_SIZE; i = i + ADDER_SIZE) begin
    tester #(i, 4) tester_inst(.*);
end    
//for (i = 50*ADDER_SIZE; i < 194*ADDER_SIZE; i = i + ADDER_SIZE) begin
//    tester #(i, 5) tester_inst(.*);
//end
//for (i = 194*ADDER_SIZE; i < 770*ADDER_SIZE; i = i + ADDER_SIZE) begin
//    tester #(i, 6) tester_inst(.*);
//end
//for (i = 770*ADDER_SIZE; i < 3074*ADDER_SIZE; i = i + ADDER_SIZE) begin
//    tester #(i, 7) tester_inst(.*);
//end
//for (i = 3074*ADDER_SIZE; i < 3075*ADDER_SIZE; i = i + ADDER_SIZE) begin
//    tester #(i, 8) tester_inst(.*);
//end
    
endgenerate

always begin
	#1000 clk = ~clk;
end

endmodule

