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

module lzc_core #(
    parameter SIZE = 64, // Size must be 2^N, 2^N+1, or 2^N+2
    parameter OUT_SIZE = $clog2(SIZE+1),
    parameter FAMILY = "Agilex" // "Agilex" or "Stratix 10" 
) (
    input [SIZE-1:0] din,
    output [OUT_SIZE-1:0] dout
);

genvar i, j;
generate

if (SIZE == 4) begin
    assign dout = din[3] ? 0 : (din[2] ? 1 : (din[1] ? 2 : (din[0] ? 3 : 4)));
end else if (SIZE == 5) begin
    assign dout = din[4] ? 0 : (din[3] ? 1 : (din[2] ? 2 : (din[1] ? 3 : (din[0] ? 4 : 5))));
end else if (SIZE == 6) begin
    assign dout = din[5] ? 0 : (din[4] ? 1 : (din[3] ? 2 : (din[2] ? 3 : (din[1] ? 4 : (din[0] ? 5 : 6)))));    
end else if (SIZE == 8) begin
    assign dout = din[7] ? 0 : (din[6] ? 1 : (din[5] ? 2 : (din[4] ? 3 : (din[3] ? 4 : (din[2] ? 5 : (din[1] ? 6 : (din[0] ? 7 : 8)))))));    
end else if (SIZE == 9) begin
    assign dout = din[8] ? 0 : (din[7] ? 1 : (din[6] ? 2 : (din[5] ? 3 : (din[4] ? 4 : (din[3] ? 5 : (din[2] ? 6 : (din[1] ? 7 : (din[0] ? 8 : 9))))))));    
end else if (SIZE == 10) begin
    assign dout = din[9] ? 0 : (din[8] ? 1 : (din[7] ? 2 : (din[6] ? 3 : (din[5] ? 4 : (din[4] ? 5 : (din[3] ? 6 : (din[2] ? 7 : (din[1] ? 8 : (din[0] ? 9 : 10)))))))));    
end else begin

    wire [OUT_SIZE-3:0] dout0, dout1, dout2, dout3;
    
    localparam SIZE1 = SIZE/4;
    localparam SIZE0 = SIZE - 3*SIZE1;
    
    lzc_core #(.SIZE(SIZE0), .OUT_SIZE(OUT_SIZE-2), .FAMILY(FAMILY)) lzc0 (.din(din[SIZE0-1:0]), .dout(dout0));
    lzc_core #(.SIZE(SIZE1), .OUT_SIZE(OUT_SIZE-2), .FAMILY(FAMILY)) lzc1 (.din(din[SIZE0+SIZE1-1:SIZE0]), .dout(dout1));
    lzc_core #(.SIZE(SIZE1), .OUT_SIZE(OUT_SIZE-2), .FAMILY(FAMILY)) lzc2 (.din(din[2*SIZE1+SIZE0-1:SIZE0+SIZE1]), .dout(dout2));
    lzc_core #(.SIZE(SIZE1), .OUT_SIZE(OUT_SIZE-2), .FAMILY(FAMILY)) lzc3 (.din(din[SIZE-1:2*SIZE1+SIZE0]), .dout(dout3));
    
    if (OUT_SIZE > 3)
        mux_core #(.SIZE(OUT_SIZE-3), .FAMILY(FAMILY)) mux_core_inst (
            .dout(dout[OUT_SIZE-4:0]), 
            .sel3(dout3[OUT_SIZE-3]),
            .sel2(dout2[OUT_SIZE-3]),
            .sel1(dout1[OUT_SIZE-3]),
            .din0(dout0[OUT_SIZE-4:0]),
            .din1(dout1[OUT_SIZE-4:0]),
            .din2(dout2[OUT_SIZE-4:0]),
            .din3(dout3[OUT_SIZE-4:0]));
    
    assign dout[OUT_SIZE-1:OUT_SIZE-3] = 
        (dout3[OUT_SIZE-3] & dout2[OUT_SIZE-3] & dout1[OUT_SIZE-3] & dout0[OUT_SIZE-3]) ? 3'b100 : (
        (dout3[OUT_SIZE-3] & dout2[OUT_SIZE-3] & dout1[OUT_SIZE-3]) ? 3'b011 : (
        (dout3[OUT_SIZE-3] & dout2[OUT_SIZE-3]) ? 3'b010 : (
        dout3[OUT_SIZE-3] ? 3'b001 : 3'b000
    )));
    
end
endgenerate
endmodule

