// Copyright 2023 Altera Corporation. All rights reserved.
// Altera products are protected under numerous U.S. and foreign patents, 
// maskwork rights, copyrights and other intellectual property laws.  
//
// This reference design file, and your use thereof, is subject to and governed
// by the terms and conditions of the applicable Altera Reference Design 
// License Agreement (either as signed by you or found at www.altera.com).  By
// using this reference design file, you indicate your acceptance of such terms
// and conditions between you and Altera Corporation.  In the event that you do
// not agree with such terms and conditions, you may not use the reference 
// design file and please promptly destroy any copies you have made.
//
// This reference design file is being provided on an "as-is" basis and as an 
// accommodation and therefore all warranties, representations or guarantees of 
// any kind (whether express, implied or statutory) including, without 
// limitation, warranties of merchantability, non-infringement, or fitness for
// a particular purpose, are specifically disclaimed.  By making this reference
// design file available, Altera expressly does not recommend, suggest or 
// require that this reference design file be used in combination with any 
// other product not provided by Altera.
/////////////////////////////////////////////////////////////////////////////

// Sergey Gribok - 02-06-2023

`timescale 1ps/1ps

module long_accumulator_tb ();

parameter SIZE = 3474;
parameter LATENCY = 6;

reg [SIZE-1:0] din = 0;

wire [SIZE-1:0] dout;

reg clk = 1'b0;
reg sclear = 1'b0;

long_accumulator #(SIZE) dut (.*);


reg [SIZE-1:0] alternate_dout[0:LATENCY-1];
//reg [SIZE-1:0] alternate_dout_r;
//reg [SIZE-1:0] alternate_dout_r2;

integer counter = 0;
integer i;
always @(posedge clk) begin
    din <= (din << 30) ^ $random;
    sclear <= ((counter < 10) || (counter % 17 == 0));
    counter <= counter + 1;
end

always @(posedge clk) begin
    if (sclear)
        alternate_dout[0] <= 0;
    else
        alternate_dout[0] <= alternate_dout[0] + din;

    for (i = 1; i < LATENCY; i=i+1) begin
        alternate_dout[i] <= alternate_dout[i-1];
    end
end

reg flushing = 1'b1;
reg fail = 1'b0;
always @(posedge clk) begin
    #10
    if (!flushing) begin
        if (dout !== alternate_dout[LATENCY-1]) begin
            $display ("%b, expected %b", dout, alternate_dout[LATENCY-1]);
            fail = 1'b1;
        end //else begin
        //  $display ("%b %b %b = %b", din, sclear, dout, alternate_dout[LATENCY-1]);
        //end
        
    end
end

integer k = 0;
initial begin
    for (k=0; k<15; k=k+1) @(negedge clk);
    flushing = 1'b0;
    for (k=0; k<100000; k=k+1) @(negedge clk);
    if (!fail) $display ("PASS");
    @(negedge clk);
    $stop();    
end

always begin
    #1000 clk = ~clk;
end

endmodule
