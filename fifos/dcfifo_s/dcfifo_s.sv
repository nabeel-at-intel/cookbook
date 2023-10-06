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

// dcfifo_s is designed as a faster and smaller replacement of dcfifo
// 
// Notes
// 1. The only dcfifo port not supported by dcfifo_s is "eccstatus".
//    All the other ports are identical to dcfifo.
//
// 2. Both "normal" and "show-ahead" modes are supported. (parameter SHOW_AHEAD)
//
// 3. almost_empty and almost_full thresholds are supported 
//    See parameters ALMOST_EMPTY_VALUE and ALMOST_FULL_VALUE
//
// 4. dcfifo_s is MLAB-based and is able to store up to 31 words.
//
// 5. All MLABs are fully registered in every mode.
//    This is different from dcfifo which has unregistered MLAB in show-ahead mode
module dcfifo_s
#(
    parameter LOG_DEPTH      = 5,
    parameter WIDTH          = 20,
    parameter ALMOST_FULL_VALUE = 30,
    parameter ALMOST_EMPTY_VALUE = 2,    
    parameter FAMILY = "S10", // Agilex, S10, or Other
    parameter SHOW_AHEAD = 0,  // Show-ahead mode is using a lot of area. Use Normal mode if possible
    parameter OVERFLOW_CHECKING = 0, // Overflow checking circuitry is using extra area. Use only if you need it
    parameter UNDERFLOW_CHECKING = 0 // Underflow checking circuitry is using extra area. Use only if you need it    
)
(
    input aclr,
    
    input wrclk,
    input wrreq,
    input [WIDTH-1:0] data,
    output wrempty,
    output wrfull,
    output wr_almost_empty,
    output wr_almost_full,
    output [LOG_DEPTH-1:0] wrusedw,
    
    input rdclk,
    input rdreq,
    output [WIDTH-1:0] q,
    output rdempty,
    output rdfull,
    output rd_almost_empty,    
    output rd_almost_full,    
    output [LOG_DEPTH-1:0] rdusedw
);
initial begin
    if ((LOG_DEPTH >= 6) || (LOG_DEPTH <= 2))
        $error("Invalid parameter value: LOG_DEPTH = %0d; valid range is 2 < LOG_DEPTH < 6", LOG_DEPTH);

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
if (SHOW_AHEAD == 1)
    dcfifo_s_showahead #(
        .LOG_DEPTH(LOG_DEPTH),
        .WIDTH(WIDTH),
        .ALMOST_FULL_VALUE(ALMOST_FULL_VALUE),
        .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE),
        .FAMILY(FAMILY),
        .OVERFLOW_CHECKING(OVERFLOW_CHECKING),
        .UNDERFLOW_CHECKING(UNDERFLOW_CHECKING)
    ) a1 (
        .aclr(aclr),
        .wrclk(wrclk),
        .wrreq(wrreq),
        .data(data),
        .wrempty(wrempty),
        .wrfull(wrfull),
        .wr_almost_empty(wr_almost_empty),
        .wr_almost_full(wr_almost_full),
        .wrusedw(wrusedw),
        .rdclk(rdclk),
        .rdreq(rdreq),
        .q(q),
        .rdempty(rdempty),
        .rdfull(rdfull),
        .rd_almost_empty(rd_almost_empty),
        .rd_almost_full(rd_almost_full),
        .rdusedw(rdusedw)
    );
else
    dcfifo_s_normal #(
        .LOG_DEPTH(LOG_DEPTH),
        .WIDTH(WIDTH),
        .ALMOST_FULL_VALUE(ALMOST_FULL_VALUE),
        .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE),
        .FAMILY(FAMILY),
        .OVERFLOW_CHECKING(OVERFLOW_CHECKING),
        .UNDERFLOW_CHECKING(UNDERFLOW_CHECKING)        
    ) a2 (
        .aclr(aclr),
        .wrclk(wrclk),
        .wrreq(wrreq),
        .data(data),
        .wrempty(wrempty),
        .wrfull(wrfull),
        .wr_almost_empty(wr_almost_empty),
        .wr_almost_full(wr_almost_full),
        .wrusedw(wrusedw),
        .rdclk(rdclk),
        .rdreq(rdreq),
        .q(q),
        .rdempty(rdempty),
        .rdfull(rdfull),
        .rd_almost_empty(rd_almost_empty),
        .rd_almost_full(rd_almost_full),
        .rdusedw(rdusedw)
    );
endgenerate
endmodule