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

module dsp_2_18x18u_tb ();

parameter FAMILY = "Agilex";
parameter LATENCY = 4;
parameter AX_WIDTH = 18;
parameter AY_WIDTH = 18;
parameter BX_WIDTH = 18;
parameter BY_WIDTH = 18;
parameter RESULT_A_WIDTH = 36;
parameter RESULT_B_WIDTH = 36;


reg [AX_WIDTH-1:0] ax = 0;
reg [AY_WIDTH-1:0] ay = 0;
reg [BX_WIDTH-1:0] bx = 0;
reg [BY_WIDTH-1:0] by = 0;
wire [RESULT_A_WIDTH-1:0]	resulta;
wire [RESULT_B_WIDTH-1:0]	resultb;

reg [RESULT_A_WIDTH-1:0] resulta_etalon[0:LATENCY-1];
reg [RESULT_B_WIDTH-1:0] resultb_etalon[0:LATENCY-1];

reg clk = 1'b0;

integer counter = 0;
always @(posedge clk) begin
    ax <= $random;
    ay <= $random;
    bx <= $random;
    by <= $random;
    
    counter <= (counter + 1) & 4'b1111;
end

integer i;
always @(posedge clk) begin
    resulta_etalon[0] <= ax * ay;
    resultb_etalon[0] <= bx * by;
    for (i = 1; i < LATENCY; i=i+1) begin
        resulta_etalon[i] <= resulta_etalon[i-1];
        resultb_etalon[i] <= resultb_etalon[i-1];        
    end
end

reg flushing = 1'b1;
reg fail = 1'b0;

dsp_2_18x18u #(
    .FAMILY(FAMILY),
    .LATENCY(LATENCY),
    .AX_WIDTH(AX_WIDTH),
    .AY_WIDTH(AY_WIDTH),
    .BX_WIDTH(BX_WIDTH),
    .BY_WIDTH(BY_WIDTH),
    .RESULT_A_WIDTH(RESULT_A_WIDTH),
    .RESULT_B_WIDTH(RESULT_B_WIDTH)
) dut (.*);


always @(posedge clk) begin
    if (!flushing) 
    begin
        if ((resulta !== resulta_etalon[LATENCY-1]) || (resultb !== resultb_etalon[LATENCY-1]))
        begin       
            $display ("{%d * %d, %d * %d} = {%d %d} vs {%d %d}", ax, ay, bx, by, resulta, resultb, resulta_etalon[LATENCY-1], resultb_etalon[LATENCY-1]);
            fail = 1'b1;
            $stop();
        end 
        //else begin
        //    $display ("{%d * %d, %d * %d} = {%d %d}", ax, ay, bx, by, resulta, resultb);        
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

