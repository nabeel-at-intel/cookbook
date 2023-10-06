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
module dsp_systolic_18x18u #(
    parameter FAMILY = "Agilex",
    parameter NUM = 8,
    parameter AX_WIDTH = 18,
    parameter AY_WIDTH = 18,
    parameter PIPELINE = 3,
    parameter RESULT_A_WIDTH = 64
) (
    input clk,
    input [AX_WIDTH-1:0] ax[0:NUM-1],
    input [AY_WIDTH-1:0] ay[0:NUM-1],
    output [RESULT_A_WIDTH-1:0] result
);

initial begin
    if ((FAMILY == "Agilex") && ((PIPELINE < 2) || (PIPELINE > 4)))
        $fatal(0, "(PIPELINE < %d) || (PIPELINE > %d): %d", 2, 4, PIPELINE);
    if ((FAMILY == "Stratix 10") && ((PIPELINE < 2) || (PIPELINE > 4)))
        $fatal(0, "(PIPELINE < %d) || (PIPELINE > %d): %d", 2, 4, PIPELINE);
    if ((FAMILY == "Arria 10") && ((PIPELINE < 2) || (PIPELINE > 3)))
        $fatal(0, "(PIPELINE < %d) || (PIPELINE > %d): %d", 2, 3, PIPELINE);
    if (NUM % 2 == 1)
        $fatal(0, "NUM=%d is not supported", NUM);
end

genvar i;
generate

if (FAMILY == "Agilex") begin
    wire [43:0] chain[0:NUM/2-1];
    wire [RESULT_A_WIDTH-1:0] out[0:NUM/2-1];
    
    (* altera_attribute = "-name DSP_REGISTER_PACKING Disable" *)
    tennm_mac  #(
        .ax_width (AX_WIDTH),
        .ay_scan_in_width (AY_WIDTH),
        .bx_width (AX_WIDTH),
        .by_width (AY_WIDTH),
        .operation_mode ("m18x18_systolic"),
        .ax_clken ("0"),
        .ay_scan_in_clken ("0"),
        .bx_clken ("0"),
        .by_clken ("0"),        
        .input_systolic_clken("0"),
        .input_pipeline_clken ((PIPELINE == 4) ? "0" : "no_reg"),
        .second_pipeline_clken ((PIPELINE >= 3) ? "0" : "no_reg"),
        .output_clken ("0"),
        .scan_out_width (AY_WIDTH),
        .result_a_width (RESULT_A_WIDTH),
        //.use_chainadder("true"),
        .chain_inout_width(44)
    ) dsp0 (
        .clr (2'b0),
        .ax (ax[0]),
        .ay (ay[0]),
        .bx (ax[1]),
        .by (ay[1]),
        .clk (clk),
        .ena (3'b111),
        .resulta (out[0]),
        .chainout(chain[0])
    );
    for (i = 1; i < NUM/2; i=i+1) begin : l1
        (* altera_attribute = "-name DSP_REGISTER_PACKING Disable" *)
        tennm_mac  #(
            .ax_width (AX_WIDTH),
            .ay_scan_in_width (AY_WIDTH),
            .bx_width (AX_WIDTH),
            .by_width (AY_WIDTH),
            .operation_mode ("m18x18_systolic"),
            .ax_clken ("0"),
            .ay_scan_in_clken ("0"),
            .bx_clken ("0"),
            .by_clken ("0"),            
            .input_systolic_clken("0"),
            .input_pipeline_clken ((PIPELINE == 4) ? "0" : "no_reg"),
            .second_pipeline_clken ((PIPELINE >= 3) ? "0" : "no_reg"),
            .output_clken ("0"),
            .scan_out_width (AY_WIDTH),
            .result_a_width (RESULT_A_WIDTH),
            .use_chainadder("true"),
            .chain_inout_width(44)
        ) dsp_i (
            .clr (2'b0),
            .ax (ax[2*i]),
            .ay (ay[2*i]),
            .bx (ax[2*i+1]),
            .by (ay[2*i+1]),
            .clk (clk),
            .ena (3'b111),
            .chainin(chain[i-1]),
            .chainout(chain[i]),
            .resulta (out[i])
        );        
    end
    assign result = out[NUM/2-1];
    
    
end else if (FAMILY == "Stratix 10") begin
    wire [43:0] chain[0:NUM/2-1];
    wire [RESULT_A_WIDTH-1:0] out[0:NUM/2-1];
    
    (* altera_attribute = "-name DSP_REGISTER_PACKING Disable" *)
    fourteennm_mac  #(
        .ax_width (AX_WIDTH),
        .ay_scan_in_width (AY_WIDTH),
        .bx_width (AX_WIDTH),
        .by_width (AY_WIDTH),
        .operation_mode ("m18x18_systolic"),
        .ax_clock ("0"),
        .ay_scan_in_clock ("0"),
        .bx_clock ("0"),
        .by_clock ("0"),        
        .input_systolic_clock("0"),
        .input_pipeline_clock ((PIPELINE == 4) ? "0" : "none"),
        .second_pipeline_clock ((PIPELINE >= 3) ? "0" : "none"),
        .output_clock ("0"),
        .scan_out_width (AY_WIDTH),
        .result_a_width (RESULT_A_WIDTH)
        //.use_chainadder("true"),
    ) dsp0 (
        .clr (2'b0),
        .ax (ax[0]),
        .ay (ay[0]),
        .bx (ax[1]),
        .by (ay[1]),
        .clk ({clk, clk, clk}),
        .ena (3'b111),
        .resulta (out[0]),
        .chainout(chain[0])
    );
    for (i = 1; i < NUM/2; i=i+1) begin : l1
        (* altera_attribute = "-name DSP_REGISTER_PACKING Disable" *)
        fourteennm_mac  #(
            .ax_width (AX_WIDTH),
            .ay_scan_in_width (AY_WIDTH),
            .bx_width (AX_WIDTH),
            .by_width (AY_WIDTH),
            .operation_mode ("m18x18_systolic"),
            .ax_clock ("0"),
            .ay_scan_in_clock ("0"),
            .bx_clock ("0"),
            .by_clock ("0"),            
            .input_systolic_clock("0"),
            .input_pipeline_clock ((PIPELINE == 4) ? "0" : "none"),
            .second_pipeline_clock ((PIPELINE >= 3) ? "0" : "none"),
            .output_clock ("0"),
            .scan_out_width (AY_WIDTH),
            .result_a_width (RESULT_A_WIDTH),
            .use_chainadder("true")
        ) dsp_i (
            .clr (2'b0),
            .ax (ax[2*i]),
            .ay (ay[2*i]),
            .bx (ax[2*i+1]),
            .by (ay[2*i+1]),
            .clk ({clk, clk, clk}),
            .ena (3'b111),
            .chainin(chain[i-1]),
            .chainout(chain[i]),
            .resulta (out[i])
        );        
    end
    assign result = out[NUM/2-1];    
end else if (FAMILY == "Arria 10") begin
    wire [63:0] chain[0:NUM/2-1];
    wire [RESULT_A_WIDTH-1:0] out[0:NUM/2-1];
    
    (* altera_attribute = "-name DSP_REGISTER_PACKING Disable" *)
    twentynm_mac  #(
        .ax_width (AX_WIDTH),
        .ay_scan_in_width (AY_WIDTH),
        .bx_width (AX_WIDTH),
        .by_width (AY_WIDTH),
        .operation_mode ("m18x18_systolic"),
        .ax_clock ("0"),
        .ay_scan_in_clock ("0"),
        .bx_clock ("0"),
        .by_clock ("0"),        
        .input_systolic_clock("0"),
        .input_pipeline_clock ((PIPELINE == 3) ? "0" : "none"),
        .output_clock ("0"),
        .scan_out_width (AY_WIDTH),
        .result_a_width (RESULT_A_WIDTH)
        //.use_chainadder("true")
    ) dsp0 (
        .aclr (2'b0),
        .ax (ax[0]),
        .ay (ay[0]),
        .bx (ax[1]),
        .by (ay[1]),
        .clk ({clk, clk, clk}),
        .ena (3'b111),
        .resulta (out[0]),
        //.chainin(44'b0)
        .chainout(chain[0])
    );
    for (i = 1; i < NUM/2; i=i+1) begin : l1
        (* altera_attribute = "-name DSP_REGISTER_PACKING Disable" *)
        twentynm_mac  #(
            .ax_width (AX_WIDTH),
            .ay_scan_in_width (AY_WIDTH),
            .bx_width (AX_WIDTH),
            .by_width (AY_WIDTH),
            .operation_mode ("m18x18_systolic"),
            .ax_clock ("0"),
            .ay_scan_in_clock ("0"),
            .bx_clock ("0"),
            .by_clock ("0"),            
            .input_systolic_clock("0"),
            .input_pipeline_clock ((PIPELINE == 3) ? "0" : "none"),
            .output_clock ("0"),
            .scan_out_width (AY_WIDTH),
            .result_a_width (RESULT_A_WIDTH),
            .use_chainadder("true")
        ) dsp_i (
            .aclr (2'b0),
            .ax (ax[2*i]),
            .ay (ay[2*i]),
            .bx (ax[2*i+1]),
            .by (ay[2*i+1]),
            .clk ({clk, clk, clk}),
            .ena (3'b111),
            .chainin(chain[i-1]),
            .chainout(chain[i]),
            .resulta (out[i])
        );        
    end
    assign result = out[NUM/2-1];    
end else begin
    localparam OUT_LATENCY = PIPELINE-1;
    reg [RESULT_A_WIDTH-1:0] result_r[0:OUT_LATENCY-1];
    reg [RESULT_A_WIDTH-1:0] mult[0:NUM-1];
    integer k;
    always @(posedge clk) begin
        mult[0] <= ax[0] * ay[0];
        for (k = 1; k < NUM; k=k+1) begin
            mult[k] <= ax[k] * ay[k] + mult[k-1];
        end
        result_r[0] <= mult[NUM-1];
        for (k = 1; k < OUT_LATENCY; k=k+1) begin
            result_r[k] <= result_r[k-1];
        end
    end
    assign result = result_r[OUT_LATENCY-1];
end

endgenerate

endmodule
