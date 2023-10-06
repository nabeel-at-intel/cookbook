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
module long_adder_core #(
    parameter FAMILY = "Agilex", // Agilex or Stratix 10
    parameter SIZE = 10000,   // Multiple of ADDER_SIZE
    parameter ADDER_SIZE = 8  // Elementary adder size (normally 8 or 18)
) (
    input clk,
    input [SIZE-1:0] din_a,
    input [SIZE-1:0] din_b,
    output reg [SIZE-1:0] dout
);

localparam ADDER_NUM = SIZE / ADDER_SIZE; // Number of elementary adders

localparam LATENCY = (ADDER_NUM < 4) ? 2 : 
                     (ADDER_NUM < 14) ? 3 : ($clog2((ADDER_NUM + 1) / 3) + 1) / 2 + 2;

localparam PG_LATENCY = LATENCY-2;
wire [ADDER_NUM-1:0] p;
wire [ADDER_NUM-1:0] g;
wire [ADDER_NUM-2:0] carry;

wire [ADDER_SIZE-1:0] dout1[0:ADDER_NUM-1];
reg [ADDER_SIZE-1:0] dout2[0:PG_LATENCY-1][0:ADDER_NUM-1];

genvar i;

generate
for (i = 0; i < ADDER_NUM; i=i+1) begin : loop1
    if (FAMILY == "Stratix 10")
        s10_add_p #(.SIZE(ADDER_SIZE)) adder_i (
            .clk(clk),
            .din_a(din_a[ADDER_SIZE*i+ADDER_SIZE-1:ADDER_SIZE*i]),
            .din_b(din_b[ADDER_SIZE*i+ADDER_SIZE-1:ADDER_SIZE*i]),
            .dout({g[i], dout1[i]}),
            .pout(p[i])
        );  
    else
        fm_add_p #(.SIZE(ADDER_SIZE)) adder_i (
            .clk(clk),
            .din_a(din_a[ADDER_SIZE*i+ADDER_SIZE-1:ADDER_SIZE*i]),
            .din_b(din_b[ADDER_SIZE*i+ADDER_SIZE-1:ADDER_SIZE*i]),
            .dout({g[i], dout1[i]}),
            .pout(p[i])
        );  
end

for (i = 1; i < PG_LATENCY; i++) begin: loop2
    always @(posedge clk) begin
        dout2[i] <= dout2[i-1];        
    end
end

always @(posedge clk) begin
    if (PG_LATENCY > 0) begin
        dout2[0] <= dout1;
        dout[ADDER_SIZE-1:0] <= dout2[PG_LATENCY-1][0];
    end else begin
        dout[ADDER_SIZE-1:0] <= dout1[0];
    end
end

p_g_carry #(.WIDTH(ADDER_NUM-1)) p_g_carry_inst (
	.clk(clk), .p(p[ADDER_NUM-2:0]), .g(g[ADDER_NUM-2:0]), .carry(carry)
);


for (i = 1; i < ADDER_NUM; i=i+1) begin : loop3
    always @(posedge clk) begin
        if (PG_LATENCY > 0)
            dout[ADDER_SIZE*i+ADDER_SIZE-1:ADDER_SIZE*i] <= dout2[PG_LATENCY-1][i] + carry[i-1];
        else
            dout[ADDER_SIZE*i+ADDER_SIZE-1:ADDER_SIZE*i] <= dout1[i] + carry[i-1];
    end
end

endgenerate

endmodule
