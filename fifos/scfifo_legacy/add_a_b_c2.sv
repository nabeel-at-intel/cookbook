// Copyright 2023 Intel Corporation. 
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

module add_a_b_c2 #(
    parameter SIZE = 5
)(
    input [SIZE-1:0] a,
    input [SIZE-1:0] b,
    input [1:0] c2,
    output [SIZE-1:0] out
);
    wire [SIZE:0] left;
    wire [SIZE:0] right;
    wire temp;
    
    assign left = {a[SIZE-1:1] ^ b[SIZE-1:1], a[0], c2[0]};
    assign right = {a[SIZE-2:1] & b[SIZE-2:1], c2[1], b[0], c2[0]};
    assign {out, temp} = left + right;
    
endmodule
