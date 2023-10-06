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
module dsp_2_18x18s #(
    parameter FAMILY = "Agilex",
    parameter LATENCY = 4,
    parameter AX_WIDTH = 18,
    parameter AY_WIDTH = 18,
    parameter BX_WIDTH = 18,
    parameter BY_WIDTH = 18,
    parameter RESULT_A_WIDTH = 36,
    parameter RESULT_B_WIDTH = 36
) (
    input clk,
    input signed [AX_WIDTH-1:0] ax,
    input signed [AY_WIDTH-1:0] ay,
    input signed [BX_WIDTH-1:0] bx,
    input signed [BY_WIDTH-1:0] by,
    output signed [RESULT_A_WIDTH-1:0]	resulta,
    output signed [RESULT_B_WIDTH-1:0]	resultb
);

initial begin
    if ((FAMILY == "Agilex") && ((LATENCY < 2) || (LATENCY > 4)))
        $fatal("(LATENCY < %d) || (LATENCY > %d): %d", 2, 4, LATENCY);
    if ((FAMILY == "Stratix 10") && ((LATENCY < 2) || (LATENCY > 4)))
        $fatal("(LATENCY < %d) || (LATENCY > %d): %d", 2, 4, LATENCY);
    if ((FAMILY == "Arria 10") && ((LATENCY < 2) || (LATENCY > 3)))
        $fatal("(LATENCY < %d) || (LATENCY > %d): %d", 2, 3, LATENCY);
end

generate

if (FAMILY == "Agilex") begin
    (* altera_attribute = "-name DSP_REGISTER_PACKING Disable" *)
    tennm_mac  #(
        .ax_width (AX_WIDTH),
        .ay_scan_in_width (AY_WIDTH),
        .bx_width (BX_WIDTH),
        .by_width (BY_WIDTH),
        .signed_max("true"),
        .signed_mbx("true"),
        .signed_may("true"),
        .signed_mby("true"),
        .operation_mode ("m18x18_full"),
        .ax_clken ("0"),
        .ay_scan_in_clken ("0"),
        .bx_clken ("0"),
        .by_clken ("0"),
        .input_pipeline_clken ((LATENCY == 4) ? "0" : "no_reg"),
        .second_pipeline_clken ((LATENCY >= 3) ? "0" : "no_reg"),
        .output_clken ("0"),
        .scan_out_width (AY_WIDTH),
        .result_a_width (RESULT_A_WIDTH),
        .result_b_width (RESULT_B_WIDTH)
    ) dsp (
        .clr (2'b0),
        .ax (ax),
        .ay (ay),
        .bx (bx),
        .by (by),
        .clk (clk),
        .ena (3'b111),
        .resulta (resulta),
        .resultb (resultb)
    );
end else if (FAMILY == "Stratix 10") begin
    (* altera_attribute = "-name DSP_REGISTER_PACKING Disable" *)
    fourteennm_mac  #(
        .ax_width (AX_WIDTH),
        .ay_scan_in_width (AY_WIDTH),
        .bx_width (BX_WIDTH),
        .by_width (BY_WIDTH),
        .signed_max("true"),
        .signed_mbx("true"),
        .signed_may("true"),
        .signed_mby("true"),
        .operation_mode ("m18x18_full"),
        .ax_clock ("0"),
        .ay_scan_in_clock ("0"),
        .bx_clock ("0"),
        .by_clock ("0"),
        .input_pipeline_clock ((LATENCY >= 3) ? "0" : "none"),
        .second_pipeline_clock ((LATENCY == 4) ? "0" : "none"),
        .output_clock ("0"),
        .scan_out_width (AY_WIDTH),
        .result_a_width (RESULT_A_WIDTH),
        .result_b_width (RESULT_B_WIDTH)
    ) dsp (
        .clr (2'b0),
        .ax (ax),
        .ay (ay),
        .bx (bx),
        .by (by),
        .clk ({clk, clk, clk}),
        .ena (3'b111),
        .resulta (resulta),
        .resultb (resultb)
    );
end else if (FAMILY == "Arria 10") begin
    (* altera_attribute = "-name DSP_REGISTER_PACKING Disable" *)
    twentynm_mac  #(
        .ax_width (AX_WIDTH),
        .ay_scan_in_width (AY_WIDTH),
        .bx_width (BX_WIDTH),
        .by_width (BY_WIDTH),
        .signed_max("true"),
        .signed_mbx("true"),
        .signed_may("true"),
        .signed_mby("true"),
        .operation_mode ("m18x18_full"),
        .ax_clock ("0"),
        .ay_scan_in_clock ("0"),
        .bx_clock ("0"),
        .by_clock ("0"),
        .input_pipeline_clock ((LATENCY == 3) ? "0" : "none"),
        .output_clock ("0"),
        .scan_out_width (AY_WIDTH),
        .result_a_width (RESULT_A_WIDTH),
        .result_b_width (RESULT_B_WIDTH)
    ) dsp (
        .aclr (2'b0),
        .ax (ax),
        .ay (ay),
        .bx (bx),
        .by (by),
        .clk ({clk, clk, clk}),
        .ena (3'b111),
        .resulta (resulta),
        .resultb (resultb)
    );
end else begin
    reg signed [RESULT_A_WIDTH-1:0] resulta_r[0:LATENCY-1];
    reg signed [RESULT_B_WIDTH-1:0] resultb_r[0:LATENCY-1];
    integer i;
    always @(posedge clk) begin
        resulta_r[0] <= ax * ay;
        resultb_r[0] <= bx * by;
        for (i = 1; i < LATENCY; i=i+1) begin
            resulta_r[i] <= resulta_r[i-1];
            resultb_r[i] <= resultb_r[i-1];        
        end
    end
    assign resulta = resulta_r[LATENCY-1];
    assign resultb = resultb_r[LATENCY-1];
end

endgenerate

endmodule
