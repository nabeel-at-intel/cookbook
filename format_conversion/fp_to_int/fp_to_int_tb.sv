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

module fp_to_int_tb ();

localparam INT_SIZE = 25;
localparam EXPONENT_SIZE = 8; // We assume EXPONENT_SIZE = 8. You might need to modify the code if you change it
localparam MANTISSA_SIZE = 7;
localparam FIXED_POINT_POSITION = 0;

localparam LOG_SIZE = $clog2(INT_SIZE);
localparam SHIFT_SIZE1 = (EXPONENT_SIZE > LOG_SIZE) ? LOG_SIZE : EXPONENT_SIZE;
localparam SHIFTER_LATENCY = (SHIFT_SIZE1 + 1) / 2;
localparam LATENCY = SHIFTER_LATENCY + 3;

reg sign;
reg [EXPONENT_SIZE-1:0] exponent;
reg [MANTISSA_SIZE-1:0] mantissa;

wire signed [INT_SIZE-1:0] dout;

reg clk = 1'b0;

fp_to_int #(
    .EXPONENT_SIZE(EXPONENT_SIZE), 
    .MANTISSA_SIZE(MANTISSA_SIZE), 
    .INT_SIZE(INT_SIZE),
    .FIXED_POINT_POSITION(FIXED_POINT_POSITION)
) dut(.*);

integer i;
shortreal din_r[0:LATENCY-1];

always @(negedge clk) begin
    {sign, exponent, mantissa} = $random; 
end

always @(posedge clk) begin
    din_r[0] <= $bitstoshortreal({sign, exponent, mantissa, {(23-MANTISSA_SIZE){1'b0}}});
    for (i = 1; i < LATENCY; i=i+1) begin
        din_r[i] <= din_r[i-1];
    end
end

shortreal error = 0.0;
shortreal max_error = 0.0;

integer max_int = {1'b0, {(INT_SIZE-1){1'b1}}};
integer min_int = -1 - max_int;
shortreal etalon;
shortreal dout_real;

reg flushing = 1'b1;
reg fail = 1'b0;
always @(posedge clk) begin
	if (!flushing) begin
  
        etalon = din_r[LATENCY-1];
        if (etalon < 1.0 * min_int / (1 << FIXED_POINT_POSITION))
            etalon = 1.0 * min_int / (1 << FIXED_POINT_POSITION);
        if (etalon > 1.0 * max_int / (1 << FIXED_POINT_POSITION))
            etalon = 1.0 * max_int / (1 << FIXED_POINT_POSITION);
              
        dout_real = 1.0 * dout / (1 << FIXED_POINT_POSITION);
        
        if (etalon != dout_real) begin      
            error = etalon - dout_real;
            if (error < 0)
                error = -error;
            
            if (error > max_error) begin
                max_error = error;
                $display("%f -> %f -> %b -> %d / %d = %f | max_int = %d | max_error=%f", 
                    din_r[LATENCY-1], 
                    etalon,
                    $shortrealtobits(din_r[LATENCY-1]), 
                    dout, 
                    (1 << FIXED_POINT_POSITION),
                    dout_real,
                    {0, {(INT_SIZE-1){1'b1}}},
                    max_error
                );
                if (error > 0.5 / (1 << FIXED_POINT_POSITION)) begin
                    fail = 1'b1;
                end                    
            end
        end
	end
end

integer k = 0;
initial begin
	for (k=0; k<15; k=k+1) @(negedge clk);
	flushing = 1'b0;
	for (k=0; k<1000000; k=k+1) @(negedge clk);
	if (!fail) $display ("PASS");
	@(negedge clk);
	$stop();	
end

always begin
	#1000 clk = ~clk;
end

endmodule
