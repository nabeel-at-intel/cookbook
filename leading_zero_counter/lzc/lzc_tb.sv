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

`timescale 1ps/1ps

module lzc_tb;

localparam SIZE = 64;
localparam OUT_SIZE = $clog2(SIZE+1);
localparam LATENCY = 1;
localparam FAMILY = "Stratix 10";


reg clk = 1'b0;
reg flushing = 1'b1;
reg fail = 1'b0;

generate 

reg [SIZE-1:0] din = 0;

wire [OUT_SIZE-1:0] dout;

lzc #(.SIZE(SIZE), .OUT_SIZE(OUT_SIZE), .FAMILY(FAMILY)) dut (.*);

integer i, counter;

initial begin
    counter = 0;
end
    
always @(negedge clk) begin
    din <= ((din << 31) ^ $random) & $random & $random;
    counter <= counter + 1;
end

reg [OUT_SIZE-1:0] alternate_dout[LATENCY-1:0];

integer m;

integer tmp;
always @(posedge clk) begin
    alternate_dout[0] <= SIZE;
    for (i = 0; i < SIZE; i=i+1) begin
        if (din[i] == 1)
            alternate_dout[0] <= SIZE-i-1;
    end
    for (m = 1; m < LATENCY; m = m + 1) begin
        alternate_dout[m] <= alternate_dout[m-1];
    end 
end

always @(posedge clk) begin
    #10
    if (!flushing) begin
        if ((dout !== alternate_dout[LATENCY-1])) begin
            $display ("%b: %b - %b",
                din, dout, alternate_dout[LATENCY-1]
            );
            fail = 1'b1;
        end
        //else
        //    $display ("%b: %b", din, dout);
    end
end

endgenerate

integer k = 0;
initial begin
    for (k=0; k<30; k=k+1) @(negedge clk);
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
