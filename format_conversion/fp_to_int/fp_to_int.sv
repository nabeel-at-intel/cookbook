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

module fp_to_int #(
    parameter EXPONENT_SIZE = 8,
    parameter MANTISSA_SIZE = 7,
    parameter INT_SIZE = 16,
    parameter FIXED_POINT_POSITION = 0
)(
    input clk,
    
    input sign,
    input [EXPONENT_SIZE-1:0] exponent,
    input [MANTISSA_SIZE-1:0] mantissa,
    output reg signed [INT_SIZE-1:0] dout
);

localparam LOG_SIZE = $clog2(INT_SIZE);
localparam SHIFT_SIZE1 = (EXPONENT_SIZE > LOG_SIZE) ? LOG_SIZE : EXPONENT_SIZE;
localparam SHIFTER_LATENCY = (SHIFT_SIZE1 + 1) / 2;

localparam [EXPONENT_SIZE-1:0] MAX_EXPONENT = 125 + INT_SIZE - FIXED_POINT_POSITION;

reg [EXPONENT_SIZE-1:0] shift;
reg [MANTISSA_SIZE-1:0] mantissa_r;
always @(posedge clk) begin    
    shift <= MAX_EXPONENT - exponent;
    mantissa_r <= mantissa;
end

wire [INT_SIZE-1:0] dout_w;
barrel_shifter #(.SIZE(INT_SIZE), .SHIFT_SIZE(EXPONENT_SIZE), .SHIFT_LEFT(0)) shifter (
    .clk(clk),
    .din({1'b1, mantissa_r, {(INT_SIZE-MANTISSA_SIZE-1){1'b0}}}),
    .shift(shift),
    .dout(dout_w)
);

reg [SHIFTER_LATENCY+1:0] sign_r;
wire sign_w;
assign sign_w = sign_r[SHIFTER_LATENCY];

reg [SHIFTER_LATENCY-1:0] inf_flag_r;
wire inf_flag_w;
assign inf_flag_w = inf_flag_r[SHIFTER_LATENCY-1];

reg [SHIFTER_LATENCY-1:0] zero_flag_r;
wire zero_flag_w;
assign zero_flag_w = zero_flag_r[SHIFTER_LATENCY-1];

reg [INT_SIZE-2:0] dout_u;
reg tmp;

reg inf_flag2;
integer n;
always @(posedge clk) begin    
    sign_r[0] <= sign;
    for (n = 1; n < SHIFTER_LATENCY+2; n=n+1) begin
        sign_r[n] <= sign_r[n-1];
    end
    
    inf_flag_r[0] <= (shift[EXPONENT_SIZE-1:0] > MAX_EXPONENT);
    zero_flag_r[0] <= (shift > INT_SIZE) && (shift[EXPONENT_SIZE-1:0] <= MAX_EXPONENT);
    for (n = 1; n < SHIFTER_LATENCY; n=n+1) begin
        inf_flag_r[n] <= inf_flag_r[n-1];
        zero_flag_r[n] <= zero_flag_r[n-1];
    end

    inf_flag2 <= (INT_SIZE <= MANTISSA_SIZE + 1) ? inf_flag_w | (dout_w == {INT_SIZE {1'b1}}) : inf_flag_w;
    {tmp, dout_u} <= zero_flag_w ? 1'b0 : (inf_flag_w ? {(INT_SIZE-1) {1'b1} } : dout_w[INT_SIZE-1:1] + dout_w[0]);
    
    dout <= ({1'b0, dout_u | {(INT_SIZE-1) {inf_flag2}}} ^ {(INT_SIZE) {sign_r[SHIFTER_LATENCY+1]}}) + (sign_r[SHIFTER_LATENCY+1] & ~inf_flag2);
end

endmodule