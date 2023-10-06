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

module scfifo_legacy #(
    parameter lpm_width,
    parameter lpm_numwords,
    
    parameter lpm_widthu,
    parameter lpm_showahead, // Show-ahead mode is slow. Use only if you need it
    parameter underflow_checking = "ON", // Underflow checking circuitry is using extra area. Use only if you need it
    parameter overflow_checking = "ON", // Overflow checking circuitry is using extra area. Use only if you need it
    parameter allow_rwcycle_when_full = "OFF",
    parameter add_ram_output_register = "OFF",   
    parameter almost_full_value = 0,
    parameter almost_empty_value = 0,
    parameter intended_device_family = "Agilex", // Agilex or Stratix 10
    
    parameter lpm_hint = "RAM_BLOCK_TYPE=MLAB", // "RAM_BLOCK_TYPE=MLAB" or "RAM_BLOCK_TYPE=M20K"
    parameter lpm_type = "SCFIFO", // No-op. Just for legacy
    parameter enable_ecc = "FALSE",
    parameter use_eab = "ON"
    
)(
    input clock,
    input aclr,
    input sclr,
    input [lpm_width-1:0] data,
    input wrreq,
    input rdreq,
    output [lpm_width-1:0] q,
    output [lpm_widthu-1:0] usedw,
    output empty,
    output full,
    output almost_empty,
    output almost_full,
    output [1:0] eccstatus    
);

initial begin

    if ((lpm_showahead != "ON") && (lpm_showahead != "OFF"))
        $error("Incorrect parameter value: lpm_showahead = %s; must be one of {ON, OFF}", lpm_showahead);

    if ((allow_rwcycle_when_full != "ON") && (allow_rwcycle_when_full != "OFF"))
        $error("Incorrect parameter value: allow_rwcycle_when_full = %s; must be one of {ON, OFF}", allow_rwcycle_when_full);

    if ((add_ram_output_register != "ON") && (add_ram_output_register != "OFF"))
        $error("Incorrect parameter value: add_ram_output_register = %s; must be one of {ON, OFF}", add_ram_output_register);

    if ((underflow_checking != "ON") && (underflow_checking != "OFF"))
        $error("Incorrect parameter value: underflow_checking = %s; must be one of {ON, OFF}", underflow_checking);

    if ((overflow_checking != "ON") && (overflow_checking != "OFF"))
        $error("Incorrect parameter value: overflow_checking = %s; must be one of {ON, OFF}", overflow_checking);

    if ((enable_ecc != "TRUE") && (enable_ecc != "FALSE"))
        $error("Incorrect parameter value: enable_ecc = %s; must be one of {TRUE, FALSE}", enable_ecc);

    if ((use_eab != "ON") && (use_eab != "OFF"))
        $error("Incorrect parameter value: use_eab = %s; must be one of {ON, OFF}", use_eab);

    if ((enable_ecc == "TRUE") && (lpm_hint == "RAM_BLOCK_TYPE=MLAB"))
        $error("Incorrect parameter value: enable_ecc=TRUE is not compatible with lpm_hint='RAM_BLOCK_TYPE=MLAB', since MLAB doesn't support ECC");
            
    if ((lpm_numwords <= 2 ** (lpm_widthu - 1)) || (lpm_numwords > 2 ** lpm_widthu))
        $error("Incorrect parameter values: lpm_numwords = %0d, lpm_widthu = %0d; valid range is 2^{lpm_widthu-1} < lpm_numwords <= 2^lpm_widthu", 
            lpm_numwords, lpm_widthu);     
            
    if (lpm_widthu <= 2)
        $error("Invalid parameter value: lpm_widthu = %0d; it must be greater than 2", lpm_widthu);

    if (lpm_width <= 0)
        $error("Invalid parameter value: lpm_width = %0d; it must be greater than 0", lpm_width);
        
    if ((almost_full_value > lpm_numwords) || (almost_full_value < 0))
        $error("Incorrect parameter value: almost_full_value = %0d; valid range is 0 <= almost_full_value < %0d", 
            almost_full_value, lpm_numwords);     

    if ((almost_empty_value > lpm_numwords) || (almost_empty_value < 0))
        $error("Incorrect parameter value: almost_empty_value = %0d; valid range is 0 <= almost_empty_value < %0d", almost_empty_value, lpm_numwords);  

    if ((intended_device_family != "Agilex") && 
        (intended_device_family != "Stratix 10"))
        $error("Incorrect parameter value: intended_device_family = %s; must be one of {Agilex, Stratix 10}", 
            intended_device_family);  
end

generate

wire almost_full_w;
if (almost_full_value == 0)
    assign almost_full = 1'b1;
else if (almost_full_value == lpm_numwords)
    assign almost_full = full;
else
    assign almost_full = almost_full_w;

wire almost_empty_w;
if (almost_empty_value == 0)
    assign almost_empty = 1'b0;
else
    assign almost_empty = almost_empty_w;


if (lpm_showahead == "ON")
    scfifo_legacy_showahead #(
        .LOG_DEPTH(lpm_widthu),
        .WIDTH(lpm_width),
        .NUM_WORDS(lpm_numwords),
        .ALMOST_FULL_VALUE(almost_full_value),
        .ALMOST_EMPTY_VALUE(almost_empty_value),
        .FAMILY((use_eab == "OFF") ? "logic" : intended_device_family),
        .OVERFLOW_CHECKING((overflow_checking == "ON") ? 1 : 0),
        .UNDERFLOW_CHECKING((underflow_checking == "ON") ? 1 : 0),
        .MLAB_FLAG(((lpm_hint == "RAM_BLOCK_TYPE=M20K") || (lpm_numwords > 32)) ? 0 : 1),
        .ADD_RAM_OUTPUT_REGISTER((add_ram_output_register == "ON") ? 1 : 0),
        .ALLOW_RWCYCLE_WHEN_FULL((allow_rwcycle_when_full == "ON") ? 1 : 0),
        .ENABLE_ECC((enable_ecc == "TRUE") ? 1 : 0)
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
        .almost_empty(almost_empty_w),
        .almost_full(almost_full_w),
        .eccstatus(eccstatus)        
    );
else
    scfifo_legacy_normal #(
        .LOG_DEPTH(lpm_widthu),
        .WIDTH(lpm_width),
        .NUM_WORDS(lpm_numwords),
        .ALMOST_FULL_VALUE(almost_full_value),
        .ALMOST_EMPTY_VALUE(almost_empty_value),
        .FAMILY((use_eab == "OFF") ? "logic" : intended_device_family),
        .OVERFLOW_CHECKING((overflow_checking == "ON") ? 1 : 0),
        .UNDERFLOW_CHECKING((underflow_checking == "ON") ? 1 : 0),
        .RAM_ALWAYS_READ(0),
        .MLAB_FLAG(((lpm_hint == "RAM_BLOCK_TYPE=M20K") || (lpm_numwords > 32)) ? 0 : 1),
        .ADD_RAM_OUTPUT_REGISTER((add_ram_output_register == "ON") ? 1 : 0),
        .ALLOW_RWCYCLE_WHEN_FULL((allow_rwcycle_when_full == "ON") ? 1 : 0),
        .ENABLE_ECC((enable_ecc == "TRUE") ? 1 : 0)
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
        .almost_empty(almost_empty_w),
        .almost_full(almost_full_w),
        .eccstatus(eccstatus)          
    );

endgenerate
endmodule