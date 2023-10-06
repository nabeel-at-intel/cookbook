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
    parameter FAMILY = "Agilex", // Agilex, Stratix 10, or logic
    parameter READ_INPUT_ENABLE = 1,
    parameter READ_OUTPUT_REG = 1,
    parameter ENABLE_ECC = 0
)(
    input clk,
    input [WIDTH-1:0] din,
    input [ADDR_WIDTH-1:0] waddr,
    input we,
    input re,
    input [ADDR_WIDTH-1:0] raddr,
    output [WIDTH-1:0] dout,
    output [1:0] eccstatus
);
localparam ALTSYNCRAM_FAMILY = (FAMILY == "S10") ? "Stratix 10" : ((FAMILY == "A10") ? "Arria 10" : FAMILY);
                               
genvar i;
generate
if (FAMILY != "Other") begin    

if (ENABLE_ECC == 1) begin
    altsyncram  asr (
            .address_a (waddr),
            .clock0 (clk),
            .data_a (din),
            .wren_a (we),
            .address_b (raddr),
            .clock1 (clk),
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
            .wren_b (1'b0),
            .eccstatus(eccstatus)
            );
  defparam
    asr.address_aclr_b = "NONE",
    asr.address_reg_b = "CLOCK1",
    asr.clock_enable_input_a = "BYPASS",
    //asr.clock_enable_input_b = "NORMAL",
    asr.clock_enable_input_b = READ_INPUT_ENABLE ? "NORMAL" : "BYPASS",
    asr.clock_enable_output_b = READ_OUTPUT_REG ? "NORMAL" : "BYPASS",
    asr.intended_device_family = ALTSYNCRAM_FAMILY,
    asr.lpm_type = "altsyncram",
    asr.numwords_a = 1 << ADDR_WIDTH,
    asr.numwords_b = 1 << ADDR_WIDTH,
    asr.operation_mode = "DUAL_PORT",
    asr.outdata_aclr_b = "NONE",
    asr.outdata_reg_b = READ_OUTPUT_REG ? "CLOCK1" : "UNREGISTERED",
    asr.power_up_uninitialized = "FALSE",
    asr.ram_block_type = "M20K",
    asr.widthad_a = ADDR_WIDTH,
    asr.widthad_b = ADDR_WIDTH,
    asr.width_a = WIDTH,
    asr.width_b = WIDTH,
    asr.width_byteena_a = 1,
    asr.read_during_write_mode_mixed_ports = "DONT_CARE",
    asr.enable_ecc = "TRUE",
    asr.width_eccstatus = 2;

end else begin
    altsyncram  asr (
            .address_a (waddr),
            .clock0 (clk),
            .data_a (din),
            .wren_a (we),
            .address_b (raddr),
            .clock1 (clk),
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
            .wren_b (1'b0),
            .eccstatus()
            );            
  defparam
    asr.address_aclr_b = "NONE",
    asr.address_reg_b = "CLOCK1",
    asr.clock_enable_input_a = "BYPASS",
    //asr.clock_enable_input_b = "NORMAL",
    asr.clock_enable_input_b = READ_INPUT_ENABLE ? "NORMAL" : "BYPASS",
    asr.clock_enable_output_b = READ_OUTPUT_REG ? "NORMAL" : "BYPASS",
    asr.intended_device_family = ALTSYNCRAM_FAMILY,
    asr.lpm_type = "altsyncram",
    asr.numwords_a = 1 << ADDR_WIDTH,
    asr.numwords_b = 1 << ADDR_WIDTH,
    asr.operation_mode = "DUAL_PORT",
    asr.outdata_aclr_b = "NONE",
    asr.outdata_reg_b = READ_OUTPUT_REG ? "CLOCK1" : "UNREGISTERED",
    asr.power_up_uninitialized = "FALSE",
    asr.ram_block_type = "M20K",
    asr.widthad_a = ADDR_WIDTH,
    asr.widthad_b = ADDR_WIDTH,
    asr.width_a = WIDTH,
    asr.width_b = WIDTH,
    asr.width_byteena_a = 1,
    asr.read_during_write_mode_mixed_ports = "DONT_CARE",
    asr.enable_ecc = "FALSE";

    assign eccstatus = 2'b0;
end


    //always @(posedge clk) begin
    //    $display("we=%d waddr=%d din=%d / re=%d raddr=%d mem_out=%d ", we, waddr, din, re, raddr, dout);
    //end

    
end else begin

    localparam DEPTH = 1 << ADDR_WIDTH;
    (* ramstyle = "logic" *) reg [WIDTH-1:0] mem[0:DEPTH-1];

    reg [WIDTH-1:0] dout_r;
    reg [WIDTH-1:0] dout_rr;
    always @(posedge clk) begin
        if (we)
            mem[waddr] <= din;
            
        if (re || (READ_INPUT_ENABLE == 0))
            dout_r <= mem[raddr];
        
        if (re) begin
            dout_rr <= dout_r;
        end
        //$display("we=%d waddr=%d din=%d / re=%d raddr=%d mem[raddr]=%d dout_r=%d dout_rr=%d ", we, waddr, din, re, raddr, mem[raddr], dout_r, dout_rr);
    end
    assign dout = dout_rr;
    assign eccstatus = 2'b0;
end
endgenerate    

endmodule