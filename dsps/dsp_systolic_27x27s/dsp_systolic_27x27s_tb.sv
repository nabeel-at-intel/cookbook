// Copyright 2022 Intel Corporation. 
//
// This reference design file is subject licensed to you by the terms and 
// conditions of the applicable License Terms and Conditions for Hardware 
// Reference Designs and/or Design Examples (either as by you or 
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

module dsp_systolic_27x27s_tb ();

parameter FAMILY = "Agilex";
parameter PIPELINE = 3;
parameter AX_WIDTH = 27;
parameter AY_WIDTH = 27;
parameter NUM = 10;
parameter RESULT_A_WIDTH = 64;

parameter OUT_LATENCY = PIPELINE-1;
reg signed [AX_WIDTH-1:0] ax[0:NUM-1];
reg signed [AY_WIDTH-1:0] ay[0:NUM-1];
wire signed [RESULT_A_WIDTH-1:0] result;

reg signed [RESULT_A_WIDTH-1:0] result_etalon[0:OUT_LATENCY-1];
reg signed [RESULT_A_WIDTH-1:0] mult[0:NUM-1];

reg clk = 1'b0;

integer counter = 0;
integer i;
always @(posedge clk) begin
    for (i = 0; i < NUM; i=i+1) begin
        ax[i] <= $random;
        ay[i] <= $random;
    end    
    counter <= (counter + 1) & 4'b1111;
end

always @(posedge clk) begin
    mult[0] <= ax[0] * ay[0];
    for (i = 1; i < NUM; i=i+1) begin
        mult[i] <= ax[i] * ay[i] + mult[i-1];
    end
    result_etalon[0] <= mult[NUM-1];
    for (i = 1; i < OUT_LATENCY; i=i+1) begin
        result_etalon[i] <= result_etalon[i-1];
    end
end

reg flushing = 1'b1;
reg fail = 1'b0;

dsp_systolic_27x27s #(
    .FAMILY(FAMILY),
    .PIPELINE(PIPELINE),
    .AX_WIDTH(AX_WIDTH),
    .AY_WIDTH(AY_WIDTH),
    .NUM(NUM),
    .RESULT_A_WIDTH(RESULT_A_WIDTH)
) dut (.*);


always @(posedge clk) begin
    if (!flushing) 
    begin
        if (result !== result_etalon[OUT_LATENCY-1])
        begin       
            $display ("%d * %d = %d vs %d", ax[0], ay[0], result, result_etalon[OUT_LATENCY-1]);
            fail = 1'b1;
            $stop();
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

