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

module pipe_lzc_core #(
    parameter SIZE = 64, // Size must be 2^N, 2^N+1, or 2^N+2
    parameter OUT_SIZE = $clog2(SIZE+1),
    parameter LEVEL = 0,
    parameter FAMILY = "Agilex" // "Agilex" or "Stratix 10" 
) (
    input clk,
    input [SIZE-1:0] din,
    output reg [OUT_SIZE-1:0] dout
);

genvar i, j;
generate

wire [OUT_SIZE-1:0] doutw;
 
if (SIZE == 2) begin
    assign doutw = din[1] ? 0 : (din[0] ? 1 : /*2*/ ((LEVEL == 0) ? 2 : (2 | 1)));
end else if (SIZE == 3) begin
    assign doutw = din[2] ? 0 : (din[1] ? 1 : (din[0] ? 2 : 3));
end else if (SIZE == 4) begin
    assign doutw = din[3] ? 0 : (din[2] ? 1 : (din[1] ? 2 : (din[0] ? 3 : /*4*/ ((LEVEL == 0) ? 4 : (4 | 3))  )));    
end else if (SIZE == 5) begin
    assign doutw = din[4] ? 0 : (din[3] ? 1 : (din[2] ? 2 : (din[1] ? 3 : (din[0] ? 4 : 5))));
end else if (SIZE == 6) begin
    assign doutw = din[5] ? 0 : (din[4] ? 1 : (din[3] ? 2 : (din[2] ? 3 : (din[1] ? 4 : (din[0] ? 5 : 6)))));    
end else begin
    
    localparam SIZE1 = SIZE/4;
    localparam SIZE0 = SIZE - 3*SIZE1;
    
    localparam OUT_SIZE0 = $clog2(SIZE0+1);
    localparam OUT_SIZE1 = $clog2(SIZE1+1);

    wire [OUT_SIZE0-1:0] dout0;
    wire [OUT_SIZE1-1:0] dout1, dout2, dout3;
    
    
    pipe_lzc_core #(.SIZE(SIZE0), .OUT_SIZE(OUT_SIZE0), .FAMILY(FAMILY), .LEVEL(LEVEL)) lzc0 (.clk(clk), .din(din[SIZE0-1:0]), .dout(dout0));
    pipe_lzc_core #(.SIZE(SIZE1), .OUT_SIZE(OUT_SIZE1), .FAMILY(FAMILY), .LEVEL(LEVEL+1)) lzc1 (.clk(clk), .din(din[SIZE0+SIZE1-1:SIZE0]), .dout(dout1));
    pipe_lzc_core #(.SIZE(SIZE1), .OUT_SIZE(OUT_SIZE1), .FAMILY(FAMILY), .LEVEL(LEVEL+1)) lzc2 (.clk(clk), .din(din[2*SIZE1+SIZE0-1:SIZE0+SIZE1]), .dout(dout2));
    pipe_lzc_core #(.SIZE(SIZE1), .OUT_SIZE(OUT_SIZE1), .FAMILY(FAMILY), .LEVEL(LEVEL+1)) lzc3 (.clk(clk), .din(din[SIZE-1:2*SIZE1+SIZE0]), .dout(dout3));
    
    if (OUT_SIZE > 3)
        mux_core #(.SIZE(OUT_SIZE-3), .FAMILY(FAMILY)) mux_core_inst (
            .dout(doutw[OUT_SIZE-4:0]), 
            .sel3(dout3[OUT_SIZE-3]),
            .sel2(dout2[OUT_SIZE-3]),
            .sel1(dout1[OUT_SIZE-3]),
            .din0(dout0[OUT_SIZE-4:0]),
            .din1(dout1[OUT_SIZE-4:0]),
            .din2(dout2[OUT_SIZE-4:0]),
            .din3(dout3[OUT_SIZE-4:0]));
    
    
    if (SIZE == 10)
        assign doutw[OUT_SIZE-1:OUT_SIZE-3] = 
            (dout3[OUT_SIZE-3] & dout2[OUT_SIZE-3] & dout1[OUT_SIZE-3] & dout0[OUT_SIZE-2]) ? 3'b101 : (
            (dout3[OUT_SIZE-3] & dout2[OUT_SIZE-3] & dout1[OUT_SIZE-3] & dout0[OUT_SIZE-3]) ? 3'b100 : (
            (dout3[OUT_SIZE-3] & dout2[OUT_SIZE-3] & dout1[OUT_SIZE-3]) ? 3'b011 : (
            (dout3[OUT_SIZE-3] & dout2[OUT_SIZE-3]) ? 3'b010 : (
            dout3[OUT_SIZE-3] ? 3'b001 : 3'b000
        ))));
    else
        assign doutw[OUT_SIZE-1:OUT_SIZE-3] = 
            (dout3[OUT_SIZE-3] & dout2[OUT_SIZE-3] & dout1[OUT_SIZE-3] & dout0[OUT_SIZE-3]) ? /*3'b100*/ ((LEVEL == 0) ? 3'b100 : 3'b111) : (
            (dout3[OUT_SIZE-3] & dout2[OUT_SIZE-3] & dout1[OUT_SIZE-3]) ? 3'b011 : (
            (dout3[OUT_SIZE-3] & dout2[OUT_SIZE-3]) ? 3'b010 : (
            dout3[OUT_SIZE-3] ? 3'b001 : 3'b000
        )));
    
end

always @(posedge clk) begin
    dout <= doutw;
end

endgenerate
endmodule

