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

module dsp_27x27s_tb ();

parameter FAMILY = "Agilex";
parameter LATENCY = 3;
parameter AX_WIDTH = 27;
parameter AY_WIDTH = 27;
parameter RESULT_A_WIDTH = 54;
parameter RESULT_B_WIDTH = 54;


reg signed [AX_WIDTH-1:0] ax = 0;
reg signed [AY_WIDTH-1:0] ay = 0;
wire signed [RESULT_A_WIDTH-1:0]	resulta;

reg signed [RESULT_A_WIDTH-1:0] resulta_etalon[0:LATENCY-1];

reg clk = 1'b0;

integer counter = 0;
always @(posedge clk) begin
    ax <= $random;
    ay <= $random;
    
    counter <= (counter + 1) & 4'b1111;
end

integer i;
always @(posedge clk) begin
    resulta_etalon[0] <= ax * ay;
    for (i = 1; i < LATENCY; i=i+1) begin
        resulta_etalon[i] <= resulta_etalon[i-1];
    end
end

reg flushing = 1'b1;
reg fail = 1'b0;

dsp_27x27s #(
    .FAMILY(FAMILY),
    .LATENCY(LATENCY),
    .AX_WIDTH(AX_WIDTH),
    .AY_WIDTH(AY_WIDTH),
    .RESULT_A_WIDTH(RESULT_A_WIDTH)
) dut (.*);


always @(posedge clk) begin
    if (!flushing) 
    begin
        if (resulta !== resulta_etalon[LATENCY-1])
        begin       
            $display ("%d * %d = %d vs %d", ax, ay, resulta, resulta_etalon[LATENCY-1]);
            fail = 1'b1;
            //$stop();
        end 
        //else begin
        //    $display ("%d * %d = %d", ax, ay, resulta);        
        //end
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

