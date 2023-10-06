// Copyright 2022 Intel Corporation. 
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

module mux_core #(
    parameter SIZE = 1,
    parameter FAMILY = "Agilex" // "Agilex" or "Stratix 10" 
) (
    input sel3, 
    input sel2, 
    input sel1,
    input [SIZE-1:0] din0,
    input [SIZE-1:0] din1,
    input [SIZE-1:0] din2,
    input [SIZE-1:0] din3,
    
    output [SIZE-1:0] dout
);

genvar i;
generate
for (i = 0; i < SIZE; i=i+1) begin : loop
    /*assign dout[i] = sel3 ? (
                  sel2 ? (
                  sel1 ? din0[i] 
                       : din1[i])
                       : din2[i])
                       : din3[i];*/
    
    if (FAMILY == "Agilex")
        tennm_lcell_comb #(
            .extended_lut("on"),
            .lut_mask(64'h0F0F_4477_0F0F_4477)
        ) alm_i (
            .dataa(~din2[i]),
            .datab(~sel2),
            .datac(~din3[i]),
            .datad(~din0[i]),
            .datae(~sel3),
            .dataf(~din3[i]),
            .datag(~din1[i]),
            .datah(~sel1),
            .combout(dout[i])
        );
    else
        fourteennm_lcell_comb #(
            .extended_lut("on"),
            .lut_mask(64'h0F0F_4477_0F0F_4477)
        ) alm_i (
            .dataa(~din2[i]),
            .datab(~sel2),
            .datac(~din3[i]),
            .datad(~din0[i]),
            .datae(~sel3),
            .dataf(~din3[i]),
            .datag(~din1[i]),
            .datah(~sel1),
            .combout(dout[i])
        );
                       
end
endgenerate

endmodule

