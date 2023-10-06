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

`timescale 1ps/1ps

module int_to_fp_tb ();

reg clk = 1'b0;
reg flushing = 1'b1;
reg fail = 1'b0;

localparam FAMILY = "Stratix 10"; // "Stratix 10" or "Agilex"
localparam EXPONENT_SIZE = 8; // We assume EXPONENT_SIZE = 8. You might need to modify the code if you change it
localparam MANTISSA_SIZE = 7;
localparam INT_SIZE = 16;
localparam FIXED_POINT_POSITION = 0;


localparam LZC_LATENCY = 1;
localparam SHIFTER_LATENCY = ($clog2(INT_SIZE)+1) / 2;
localparam LATENCY = 1 + LZC_LATENCY + SHIFTER_LATENCY + 1;

reg signed [INT_SIZE-1:0] din = 0;

reg signed [INT_SIZE-1:0] din_r[0:LATENCY-1];
    
wire sign;
wire [EXPONENT_SIZE-1:0] exponent;
wire [MANTISSA_SIZE-1:0] mantissa;

int_to_fp #(
    .FAMILY(FAMILY),
    .EXPONENT_SIZE(EXPONENT_SIZE),
    .MANTISSA_SIZE(MANTISSA_SIZE),
    .INT_SIZE(INT_SIZE),
    .FIXED_POINT_POSITION(FIXED_POINT_POSITION),
    .SOFTWARE_COMPATIBLE(1)
) dut (
    .clk(clk),
    .din(din),
    
    .sign(sign),
    .exponent(exponent),
    .mantissa(mantissa)
);

integer i,j;
always @(posedge clk) begin
    din <= din + 1;
    
    din_r[0] <= din;
    for (i = 1; i < LATENCY; i=i+1) begin
        din_r[i] <= din_r[i-1];
    end
end        

shortreal etalon = 0;
reg [31:0] etalon_bits;
reg sign_etalon;
reg [EXPONENT_SIZE-1:0] exponent_etalon;
reg [MANTISSA_SIZE-1:0] mantissa_etalon;

shortreal error = 0.0;
shortreal max_error = 0.0;
shortreal error_bound = 1.0 / (1 << (MANTISSA_SIZE+1));

shortreal dout;

always @(posedge clk) begin

    etalon = din_r[LATENCY-1];
    etalon = etalon / (1 << FIXED_POINT_POSITION);
    etalon_bits = $shortrealtobits(etalon);
    {sign_etalon, exponent_etalon, mantissa_etalon} = etalon_bits[31:31-EXPONENT_SIZE-MANTISSA_SIZE];
    
    dout = $bitstoshortreal({sign, exponent, mantissa, {(31-EXPONENT_SIZE-MANTISSA_SIZE){1'b0}}});
    
    if (flushing == 1'b0) begin
        if ({sign, exponent, mantissa, {(31-EXPONENT_SIZE-MANTISSA_SIZE){1'b0}}} != etalon_bits) begin

            error = (dout - etalon) / dout;
            if (error < 0)
                error = -error;
                
            if (error >= max_error) begin
                max_error = error;
            //end
                $display("%d (%b) -> [%b %b %b] = %f = %h vs  [%b %b %b] = %f | max_error = %f error_bound = %f", 
                    din_r[LATENCY-1],
                    din_r[LATENCY-1],                
                    sign, exponent, mantissa,
                    dout,
                    {sign, exponent, mantissa},
                    sign_etalon, exponent_etalon, mantissa_etalon,
                    etalon,
                    max_error,
                    error_bound
                );
            end
            if (error > error_bound)
                fail = 1;
        end
    end
end

integer k;
initial begin
    for (k=0; k<10; k=k+1) @(negedge clk);
    flushing = 1'b0;
    for (k=0; k<((1 << INT_SIZE) + 100); k=k+1) @(negedge clk);
    if (!fail) $display ("PASS");
    @(negedge clk);
    $stop();    
end

always begin
    #1000 clk = ~clk;
end

endmodule
