// Copyright 2021 Intel Corporation. 
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


// scfifo_s_m20k is designed as a faster and smaller replacement of scfifo based on M20K
// 
// Notes
// 1. The only scfifo port not supported by scfifo_s is "eccstatus".
//    All the other ports are identical to scfifo.
//
// 2. Both "normal" and "show-ahead" modes are supported. (parameter SHOW_AHEAD)
//
// 3. almost_empty and almost_full thresholds are supported 
//    See parameters ALMOST_EMPTY_VALUE and ALMOST_FULL_VALUE
//
// 4. scfifo_s_m20k is M20K-based and is able to store up to 2047 words.

module scfifo_s_m20k #(
    parameter LOG_DEPTH      = 9,
    parameter WIDTH          = 20,
    parameter ALMOST_FULL_VALUE = 510,
    parameter ALMOST_EMPTY_VALUE = 2,
    parameter SHOW_AHEAD = 0,
    parameter OUTPUT_REGISTER = 0,
    parameter FAMILY = "S10" // Agilex, S10, or Other
)(
    input clock,
    input aclr,
    input sclr,
    input [WIDTH-1:0] data,
    input wrreq,
    input rdreq,
    output [WIDTH-1:0] q,
    output [LOG_DEPTH-1:0] usedw,
    output empty,
    output full,
    output almost_empty,
    output almost_full    
);

initial begin
    if ((LOG_DEPTH >= 12) || (LOG_DEPTH <= 3))
        $error("Invalid parameter value: LOG_DEPTH = %0d; valid range is 3 < LOG_DEPTH < 12", LOG_DEPTH);

    if (WIDTH <= 0)
        $error("Invalid parameter value: WIDTH = %0d; it must be greater than 0", WIDTH);
        
    if ((ALMOST_FULL_VALUE >= 2 ** LOG_DEPTH) || (ALMOST_FULL_VALUE <= 0))
        $error("Incorrect parameter value: ALMOST_FULL_VALUE = %0d; valid range is 0 < ALMOST_FULL_VALUE < %0d", 
            ALMOST_FULL_VALUE, 2 ** LOG_DEPTH);     

    if ((ALMOST_EMPTY_VALUE >= 2 ** LOG_DEPTH) || (ALMOST_EMPTY_VALUE <= 0))
        $error("Incorrect parameter value: ALMOST_EMPTY_VALUE = %0d; valid range is 0 < ALMOST_EMPTY_VALUE < %0d", 
            ALMOST_EMPTY_VALUE, 2 ** LOG_DEPTH);  

    if ((FAMILY != "Agilex") && (FAMILY != "S10") && (FAMILY != "Other"))
        $error("Incorrect parameter value: FAMILY = %s; must be one of {Agilex, S10, Other}", FAMILY);  
end

generate
if (OUTPUT_REGISTER == 0) begin
    if (SHOW_AHEAD == 1)
        scfifo_s_showahead_m20k #(
            .LOG_DEPTH(LOG_DEPTH),
            .WIDTH(WIDTH),
            .ALMOST_FULL_VALUE(ALMOST_FULL_VALUE),
            .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE),
            .FAMILY(FAMILY)
        ) a1 (
            .clock(clock),
            .aclr(aclr),
            .sclr(sclr),
            .data(data),
            .wrreq(wrreq),
            .rdreq(rdreq),
            .q(q),
            .usedw(usedw),
            .empty(empty),
            .full(full),
            .almost_empty(almost_empty),
            .almost_full(almost_full)    
        );
    else
        scfifo_s_normal_m20k #(
            .LOG_DEPTH(LOG_DEPTH),
            .WIDTH(WIDTH),
            .ALMOST_FULL_VALUE(ALMOST_FULL_VALUE),
            .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE),
            .FAMILY(FAMILY)
        ) a2 (
            .clock(clock),
            .aclr(aclr),
            .sclr(sclr),
            .data(data),
            .wrreq(wrreq),
            .rdreq(rdreq),
            .q(q),
            .usedw(usedw),
            .empty(empty),
            .full(full),
            .almost_empty(almost_empty),
            .almost_full(almost_full)    
        );
end else begin
    if (SHOW_AHEAD == 1)
        scfifo_s_showahead_m20k_r #(
            .LOG_DEPTH(LOG_DEPTH),
            .WIDTH(WIDTH),
            .ALMOST_FULL_VALUE(ALMOST_FULL_VALUE),
            .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE),
            .FAMILY(FAMILY)
        ) a1 (
            .clock(clock),
            .aclr(aclr),
            .sclr(sclr),
            .data(data),
            .wrreq(wrreq),
            .rdreq(rdreq),
            .q(q),
            .usedw(usedw),
            .empty(empty),
            .full(full),
            .almost_empty(almost_empty),
            .almost_full(almost_full)    
        );
    else
        scfifo_s_normal_m20k_r #(
            .LOG_DEPTH(LOG_DEPTH),
            .WIDTH(WIDTH),
            .ALMOST_FULL_VALUE(ALMOST_FULL_VALUE),
            .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE),
            .FAMILY(FAMILY)
        ) a2 (
            .clock(clock),
            .aclr(aclr),
            .sclr(sclr),
            .data(data),
            .wrreq(wrreq),
            .rdreq(rdreq),
            .q(q),
            .usedw(usedw),
            .empty(empty),
            .full(full),
            .almost_empty(almost_empty),
            .almost_full(almost_full)    
        );
end
endgenerate
endmodule