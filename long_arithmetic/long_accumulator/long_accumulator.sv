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
module long_accumulator #(
    parameter SIZE = 256,
    parameter FAMILY = "Agilex" // "Agilex" or "Stratix 10"    
)(  
    input clk,
    input sclear,
    input [SIZE-1:0] din,
    output [SIZE-1:0] dout
);

localparam ADDER_SIZE = 18; // Elementary adder size
localparam ADDER_NUM = (SIZE - 1) / ADDER_SIZE + 1;
localparam SIZE1 = ADDER_SIZE * ADDER_NUM;

wire [SIZE1-1:0] din1;
assign din1 = {{(SIZE1-SIZE){1'b0}}, din};

reg [ADDER_SIZE-1:0] accumulator[0:ADDER_NUM-1];
reg [ADDER_NUM:0] carry = 0;

genvar i;
generate

always @(posedge clk) begin
    if (sclear) begin
        accumulator[0] <= 0;
        carry[1] <= 0;
    end else begin
        {carry[1], accumulator[0]} <= accumulator[0] + din1[ADDER_SIZE-1:0];
    end
end

for (i = 1; i < ADDER_NUM; i=i+1) begin : l1
    reg tmp1;
    always @(posedge clk) begin
        if (sclear) begin
            accumulator[i] <= 0;
            carry[i+1] <= 0;
        end else begin
            {carry[i+1], accumulator[i], tmp1} <= {accumulator[i], carry[i]} + {din1[ADDER_SIZE*(i+1)-1:ADDER_SIZE*i], carry[i]};
        end
    end
end

wire [SIZE1-1:0] dout_a;
wire [SIZE1-1:0] dout_b;

for (i = 0; i < ADDER_NUM; i=i+1) begin : l2
    assign dout_a[ADDER_SIZE*(i+1)-1:ADDER_SIZE*i] = accumulator[i];
    assign dout_b[ADDER_SIZE*(i+1)-1:ADDER_SIZE*i] = {{(ADDER_SIZE-1){1'b0}}, carry[i]};
end

wire [SIZE1-1:0] dout_w;

long_adder #(FAMILY, SIZE1) core (
    .clk(clk),
    .din_a(dout_a),
    .din_b(dout_b),
    .dout(dout_w)
);

assign dout = dout_w[SIZE-1:0];

endgenerate
endmodule

