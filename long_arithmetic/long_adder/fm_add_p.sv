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
module fm_add_p #(
    parameter SIZE = 18 // Must be even number
) (
    input clk,
    input [SIZE-1:0] din_a,
    input [SIZE-1:0] din_b,
    output [SIZE:0] dout,
    output pout
);

wire [SIZE/2:0] cout_w;
wire [SIZE:0] dout_w;
wire [SIZE/2+1:0] pout_w;

(* noprune *) reg [SIZE:0] dout_r;
(* noprune *) reg pout_r;

assign cout_w[0] = 1'b0;
assign pout_w[0] = 1'b1;

assign pout = pout_r;
assign dout = dout_r;

genvar i;

for (i = 0; i < SIZE/2; i=i+1) begin : loop

    if (i <= 4)
        tennm_logic_module #(
            .lut_mask(64'hF000_0FF0_F000_0FF0),
            .propagate_tie_off(((i % 2) == 0) ? "tie_off_vcc" : "tie_off_gnd")
        ) alm_i (
            .a(),
            .b(),
            .c0(din_a[2*i]),
            .d0(din_b[2*i]),
            .c1(din_a[2*i+1]),
            .d1(din_b[2*i+1]),
            .e(),
            .f(),
            .pin(pout_w[i]),
            .cin(cout_w[i]),
            .sumout0(dout_w[2*i]),
            .sumout1(dout_w[2*i+1]),
            .pout(pout_w[i+1]),
            .cout(cout_w[i+1])
        );  
    else
        tennm_logic_module #(
            .lut_mask(64'hF000_0FF0_F000_0FF0),
            .propagate_tie_off(((i % 2) == 1) ? "tie_off_vcc" : "tie_off_gnd"),
            .pin_invert((i == 5) ? "on" : "off")
        ) alm_i (
            .a(),
            .b(),
            .c0(din_a[2*i]),
            .d0(din_b[2*i]),
            .c1(din_a[2*i+1]),
            .d1(din_b[2*i+1]),
            .e(),
            .f(),
            .pin(pout_w[i]),
            .cin(cout_w[i]),
            .sumout0(dout_w[2*i]),
            .sumout1(dout_w[2*i+1]),
            .pout(pout_w[i+1]),
            .cout(cout_w[i+1])
        );  



end

if (SIZE <= 8)
    tennm_logic_module #(
        .lut_mask(((SIZE % 4) == 0) ? 64'h0000_FFFF_0000_0000 : 64'h0000_FFFF_FFFF_0000),
        .pin_ctrl("on"),
        .propagate_tie_off(((SIZE % 4) == 0) ? "tie_off_vcc" : "tie_off_gnd")
    ) alm_n (
        .a(),
        .b(),
        .c0(),
        .d0(),
        .c1(),
        .d1(),
        .e(),
        .f(),
        .pin(pout_w[SIZE/2]),
        .cin(cout_w[SIZE/2]),
        .sumout0(dout_w[SIZE]),
        .sumout1(pout_w[SIZE/2+1]),
        .cout()
    );
else
    tennm_logic_module #(
        .lut_mask(((SIZE % 4) != 0) ? 64'h0000_FFFF_0000_0000 : 64'h0000_FFFF_FFFF_0000),
        .pin_ctrl("on"),
        .propagate_tie_off(((SIZE % 4) != 0) ? "tie_off_vcc" : "tie_off_gnd"),
        .pin_invert((SIZE / 2 == 5) ? "on" : "off")
    ) alm_n (
        .a(),
        .b(),
        .c0(),
        .d0(),
        .c1(),
        .d1(),
        .e(),
        .f(),
        .pin(pout_w[SIZE/2]),
        .cin(cout_w[SIZE/2]),
        .sumout0(dout_w[SIZE]),
        .sumout1(pout_w[SIZE/2+1]),
        .cout()
    );


always @(posedge clk) begin
    dout_r <= dout_w;
    pout_r <= pout_w[SIZE/2+1];
end

endmodule
