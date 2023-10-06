// Copyright 2017 Altera Corporation. All rights reserved.
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

`timescale 1ps/1ps

module pipe_equal_tb ();
parameter WIDTH = 20;

reg clk = 1'b0;

reg [WIDTH-1:0] a = 0;
reg [WIDTH-1:0] b = 0;

wire out;

parameter LATENCY = (WIDTH <= 3) ? 1 : (
                    (WIDTH <= 18) ? 2 : (
                    (WIDTH <= 108) ? 3 : 4));
reg out_etalon[0:LATENCY-1];

reg [31:0] counter = 0;
always @(negedge clk) begin
    a = (a << 32) | $random;
    b = a ^ ($random & $random & $random);
    counter <= counter + 1;
end

integer i;
always @(negedge clk) begin
    #20 
    out_etalon[0] <= (a == b);
    for (i = 1; i < LATENCY; i=i+1) begin
        out_etalon[i] <= out_etalon[i-1];
    end    
end

reg flushing = 1'b1;
reg fail = 1'b0;

pipe_equal #(.WIDTH(WIDTH)) dut (.*);

always @(posedge clk) begin
    #20
    if (!flushing) 
    begin
        if (out !== out_etalon[LATENCY-1])
        begin       
            $display ("%b == %b: %d, expected %d", a, b, out, out_etalon[LATENCY-1]);
            fail = 1'b1;
            $stop();
        end
        else
            $display ("%b == %b: %d", a, b, out);
    end
end

integer n = 0;
initial begin
    for (n=0; n<10; n=n+1) begin
        @(negedge clk);
    end
    flushing = 1'b0;
    for (n=0; n<1000 ; n=n+1) begin
        @(negedge clk);
    end
    if (!fail) $display ("PASS");
    @(negedge clk);
    $stop();
end

always begin
    #1000 clk = ~clk;
end

endmodule

