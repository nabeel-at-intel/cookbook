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

(* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION OFF" *)
module generic_m20k #(
    parameter WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter FAMILY = "S10" // Agilex, S10, or Other
)(
    input clk,
    input [WIDTH-1:0] din,
    input [ADDR_WIDTH-1:0] waddr,
    input we,
    input re,
    input [ADDR_WIDTH-1:0] raddr,
    output [WIDTH-1:0] dout
);
localparam ALTSYNCRAM_FAMILY = (FAMILY == "S10") ? "Stratix 10" : ((FAMILY == "A10") ? "Arria 10" : FAMILY);
                               
genvar i;
generate
if (FAMILY != "Other") begin    

    altsyncram  asr (
            .address_a (waddr),
            .clock0 (clk),
            .data_a (din),
            .wren_a (we),
            .address_b (raddr),
            .clock1 (clk),
            .eccstatus (),
            .q_b (dout),
            .aclr0 (1'b0),
            .aclr1 (1'b0),
            .addressstall_a (1'b0),
            .addressstall_b (1'b0),
            .byteena_a (1'b1),
            .byteena_b (1'b1),
            .clocken0 (1'b1),
            .clocken1 (re),
            .clocken2 (1'b1),
            .clocken3 (1'b1),
            .data_b ({WIDTH{1'b1}}),
            .q_a (),
            .rden_a (1'b1),
            .rden_b (1'b1),
            .wren_b (1'b0));
  defparam
    asr.address_aclr_b = "NONE",
    asr.address_reg_b = "CLOCK1",
    asr.clock_enable_input_a = "BYPASS",
    asr.clock_enable_input_b = "NORMAL",
    asr.clock_enable_output_b = "NORMAL",
    asr.intended_device_family = ALTSYNCRAM_FAMILY,
    asr.lpm_type = "altsyncram",
    asr.numwords_a = 1 << ADDR_WIDTH,
    asr.numwords_b = 1 << ADDR_WIDTH,
    asr.operation_mode = "DUAL_PORT",
    asr.outdata_aclr_b = "NONE",
    asr.outdata_reg_b = "CLOCK1",
    asr.power_up_uninitialized = "FALSE",
    asr.ram_block_type = "M20K",
    asr.widthad_a = ADDR_WIDTH,
    asr.widthad_b = ADDR_WIDTH,
    asr.width_a = WIDTH,
    asr.width_b = WIDTH,
    asr.width_byteena_a = 1;
    
end else begin

    localparam DEPTH = 1 << ADDR_WIDTH;
    (* ramstyle = "m20k" *) reg [WIDTH-1:0] mem[0:DEPTH-1];

    reg [WIDTH-1:0] dout_r;
    reg [WIDTH-1:0] dout_rr;
    always @(posedge clk) begin
        if (we)
            mem[waddr] <= din;
        if (re) begin
            dout_r <= mem[raddr];
            dout_rr <= dout_r;
        end
    end
    assign dout = dout_rr;

end
endgenerate    

endmodule