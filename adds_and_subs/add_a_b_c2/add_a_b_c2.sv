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


/*
 * This code defines a SystemVerilog module named add_a_b_c2 that performs addition of two input vectors a and b along with a carry-in signal c2. The output of the module is the sum of the inputs along with a carry-out signal.
 *
 * The module uses two intermediate wires left and right to perform the addition operation. The left wire is calculated by performing an XOR operation on the most significant bits of a and b, and the carry-in signal c2[0]. The right wire is calculated by performing an AND operation on the remaining bits of a and b, and the carry-in signal c2[1]. The out wire is calculated by adding the left and right wires along with a temporary wire temp, which holds the carry-out signal.
 *
 * This module is parameterized with a SIZE parameter, which determines the size of the input and output vectors.
 */

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
