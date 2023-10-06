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

module int_to_fp #(
    parameter FAMILY = "Stratix 10", // "Stratix 10" or "Agilex"
    parameter EXPONENT_SIZE = 8,
    parameter MANTISSA_SIZE = 7,
    parameter INT_SIZE = 16,
    parameter FIXED_POINT_POSITION = 0,
    parameter SOFTWARE_COMPATIBLE = 0 // If int value falls exactly in between two fp values which one do we take: upper or lower?
                                      // If SOFTWARE_COMPATIBLE=1 then the rounding algorithm is the same as in bfloat16 Python library
                                      // https://gitlab.com/libeigen/eigen/-/blob/master/Eigen/src/Core/arch/Default/BFloat16.h
)(
    input clk,
    
    input signed [INT_SIZE-1:0] din,
    
    output sign,
    output reg [EXPONENT_SIZE-1:0] exponent,
    output reg [MANTISSA_SIZE-1:0] mantissa
);

localparam LZC_LATENCY = 1;
localparam SHIFT_SIZE = $clog2(INT_SIZE+1);
localparam SHIFTER_LATENCY = ($clog2(INT_SIZE)+1) / 2;
localparam LATENCY = 1 + LZC_LATENCY + SHIFTER_LATENCY + 1;

integer i;

wire sign_w;
assign sign_w = din[INT_SIZE-1];
reg [LATENCY-1:0] sign_r;
always @(posedge clk) begin
    sign_r <= {sign_r[LATENCY-2:0], sign_w};
end
assign sign = sign_r[LATENCY-1];


reg [INT_SIZE-1:0] u_din;
reg [INT_SIZE-1:0] u_din_shifted;
reg [INT_SIZE-1:0] u_din_r[0:LZC_LATENCY-1];

wire [SHIFT_SIZE-1:0] shift;

lzc #(.SIZE(INT_SIZE), .OUT_SIZE(SHIFT_SIZE), .FAMILY(FAMILY)) ilzc (
    .clk(clk),
    .din(u_din),
    .dout(shift)
);

barrel_shifter #(.SIZE(INT_SIZE), .SHIFT_SIZE(SHIFT_SIZE), .SHIFT_LEFT(1)) shifter (
    .clk(clk),
    .din(u_din_r[LZC_LATENCY-1]),
    .shift(shift),
    .dout(u_din_shifted)
);

always @(posedge clk) begin
    u_din_r[0] <= u_din;
    for (i = 1; i < LZC_LATENCY; i=i+1) begin
        u_din_r[i] <= u_din_r[i-1];
    end    
end


reg [SHIFT_SIZE-1:0] shift_r[0:SHIFTER_LATENCY-1];
reg zero_flag;
always @(posedge clk) begin
    shift_r[0] <= shift;
    for (i = 1; i < SHIFTER_LATENCY; i=i+1) begin
        shift_r[i] <= shift_r[i-1];
    end    

    zero_flag <= (shift_r[SHIFTER_LATENCY-2] == INT_SIZE);
end

wire [EXPONENT_SIZE-1:0] exponent_one;
assign exponent_one = (127 + INT_SIZE - FIXED_POINT_POSITION);

wire [MANTISSA_SIZE:0] mantissa_draft;

assign mantissa_draft = (INT_SIZE > MANTISSA_SIZE+1) ? u_din_shifted[INT_SIZE-2:INT_SIZE-MANTISSA_SIZE-2] 
                                       : {u_din_shifted[INT_SIZE-2:INT_SIZE-MANTISSA_SIZE-1], 1'b0};


if ((SOFTWARE_COMPATIBLE == 0) || (INT_SIZE <= MANTISSA_SIZE+2)) begin
    wire [EXPONENT_SIZE+MANTISSA_SIZE-1:0] left;
    wire [EXPONENT_SIZE+MANTISSA_SIZE-1:0] right;

    assign left = {exponent_one, mantissa_draft[MANTISSA_SIZE:1]};
    assign right = {{(EXPONENT_SIZE-SHIFT_SIZE){1'b1}}, ~shift_r[SHIFTER_LATENCY-1], {(MANTISSA_SIZE-1){1'b0}}, SOFTWARE_COMPATIBLE ? 1'b0 : mantissa_draft[0]};

    always @(posedge clk) begin
        u_din <= (din ^ {INT_SIZE {sign_w}}) + sign_w;
        
        if (zero_flag) begin
            exponent <= 0;
            mantissa <= 0;
        end else begin
            {exponent, mantissa} <= left + right;
        end
    end
end else begin

    wire [EXPONENT_SIZE+MANTISSA_SIZE:0] left;
    wire [EXPONENT_SIZE+MANTISSA_SIZE:0] right;
    reg tmp;
    assign left = {exponent_one, mantissa_draft[MANTISSA_SIZE:0]};
    assign right = {{(EXPONENT_SIZE-SHIFT_SIZE){1'b1}}, ~shift_r[SHIFTER_LATENCY-1], {(MANTISSA_SIZE){1'b0}}, 
                    |{u_din_shifted[INT_SIZE-MANTISSA_SIZE-1], u_din_shifted[INT_SIZE-MANTISSA_SIZE-3:0]}};

    always @(posedge clk) begin
        u_din <= (din ^ {INT_SIZE {sign_w}}) + sign_w;
        
        if (zero_flag) begin
            exponent <= 0;
            mantissa <= 0;
        end else begin
            {exponent, mantissa, tmp} <= left + right;
        end
    end


end


endmodule