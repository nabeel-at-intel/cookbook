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

// Make sure to use Quartus 21.3 or later. Otherwise you may get simulation mismatches
module long_adder #(
    parameter FAMILY = "Agilex", // "Agilex" or "Stratix 10"
    parameter SIZE = 1024    // Must be bigger than ADDER_SIZE
) (
    input clk,
    input [SIZE-1:0] din_a,
    input [SIZE-1:0] din_b,
    output [SIZE-1:0] dout
);

localparam ADDER_SIZE = 18; // Elementary adder size. Must be 18 (unless you are running Agilex Rev A, which is HIGHLY unlikely)

localparam REMAINDER = SIZE % ADDER_SIZE;
localparam EXTRA_SIZE = ADDER_SIZE - REMAINDER;
generate

if (REMAINDER == 0)
    long_adder_core #(FAMILY, SIZE, ADDER_SIZE) core (
        .clk(clk),
        .din_a(din_a),
        .din_b(din_b),
        .dout(dout)
    );
else begin

    wire [EXTRA_SIZE-1:0] tmp;
    long_adder_core #(FAMILY, SIZE+EXTRA_SIZE, ADDER_SIZE) core (
        .clk(clk),
        .din_a({{EXTRA_SIZE{1'b0}}, din_a}),
        .din_b({{EXTRA_SIZE{1'b0}}, din_b}),
        .dout({tmp, dout})
    );
end

endgenerate

endmodule
