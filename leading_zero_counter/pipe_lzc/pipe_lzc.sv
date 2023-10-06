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

module pipe_lzc #(
    parameter SIZE = 64,
    parameter OUT_SIZE = $clog2(SIZE+1),
    parameter FAMILY = "Stratix 10" // "Agilex" or "Stratix 10" 
) (
    input clk,
    input [SIZE-1:0] din,
    output [OUT_SIZE-1:0] dout
);

generate

if (SIZE < 7) begin
    // Quartus generates very good circuit if SIZE is small
    reg [OUT_SIZE-1:0] doutr;
    integer i;
    always @(posedge clk) begin
        doutr <= SIZE;
        for (i = 0; i < SIZE; i=i+1)
            if (din[i] == 1)
                doutr <= SIZE-i-1;
    end    
    assign dout = doutr;
end 
else 
begin
    localparam SIZE2 = ((1 << $clog2(SIZE-2)) < SIZE) ? SIZE : (1 << $clog2(SIZE));
    localparam OUT_SIZE2 = $clog2(SIZE2+1);

    wire [SIZE2-1:0] din1;
    assign din1 = {din, {(SIZE2 - SIZE){1'b1}}};

    wire [OUT_SIZE2-1:0] dout1;
    
    pipe_lzc_core #(.SIZE(SIZE2), .OUT_SIZE(OUT_SIZE2), .FAMILY(FAMILY), .LEVEL(0)) lzc (.clk(clk), .din(din1), .dout(dout1)); 
    
    assign dout = dout1[OUT_SIZE-1:0];
    
end
endgenerate

endmodule

