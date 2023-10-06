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

module scfifo_legacy_normal #(
    parameter LOG_DEPTH      = 5,
    parameter WIDTH          = 20,
    parameter NUM_WORDS = 2**LOG_DEPTH,
    parameter ALMOST_FULL_VALUE = 30,
    parameter ALMOST_EMPTY_VALUE = 2,
    parameter FAMILY = "Agilex",
    parameter OVERFLOW_CHECKING = 0,
    parameter UNDERFLOW_CHECKING = 0,
    parameter RAM_ALWAYS_READ = 1, // 1 to reduce amount of routing; 0 to reduce power consumption 
    parameter ADD_RAM_OUTPUT_REGISTER = 1,
    parameter ALLOW_RWCYCLE_WHEN_FULL = 0,
    parameter MLAB_FLAG = 1,
    parameter ENABLE_ECC = 0
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
    output almost_full,
    output [1:0] eccstatus    
);

localparam RAM_ALWAYS_WRITE = (NUM_WORDS != 2**LOG_DEPTH);

(* altera_attribute = "-name AUTO_CLOCK_ENABLE_RECOGNITION OFF" *) reg [LOG_DEPTH-1:0] write_addr = 0;
(* altera_attribute = "-name AUTO_CLOCK_ENABLE_RECOGNITION OFF" *) reg [LOG_DEPTH-1:0] read_addr = 0;
reg [LOG_DEPTH-1:0] capacity = 0;
wire [LOG_DEPTH-1:0] capacity_w;

wire wrreq_safe;
wire rdreq_safe;
assign wrreq_safe = OVERFLOW_CHECKING ? (ALLOW_RWCYCLE_WHEN_FULL ? (wrreq & (~full | rdreq)) : (wrreq & ~full)) : wrreq;
assign rdreq_safe = UNDERFLOW_CHECKING ? rdreq & ~empty : rdreq;

add_a_b_s0_s1 #(LOG_DEPTH) adder(
    .a(write_addr),
    .b(~read_addr),
    .s0(wrreq_safe),
    .s1(~rdreq_safe),
    .out(capacity_w)
);

scfifo_legacy_flags #(
    .LOG_DEPTH(LOG_DEPTH),
    .NUM_WORDS(NUM_WORDS),
    .ALMOST_FULL_VALUE(ALMOST_FULL_VALUE),
    .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE),
    .OVERFLOW_CHECKING(OVERFLOW_CHECKING),
    .UNDERFLOW_CHECKING(UNDERFLOW_CHECKING),
    .ADD_RAM_OUTPUT_REGISTER(ADD_RAM_OUTPUT_REGISTER),
    .ALLOW_RWCYCLE_WHEN_FULL(ALLOW_RWCYCLE_WHEN_FULL)
) fifo_state (
    .clock(clock),
    .aclr(aclr),
    .sclr(sclr),
    .capacity(capacity),
    .wrreq(wrreq),
    .rdreq(rdreq),
    .empty(empty),
    .full(full),
    .almost_empty(almost_empty),
    .almost_full(almost_full),
    .wrreq_safe(wrreq_safe),
    .rdreq_safe(rdreq_safe)
);

always @(posedge clock or posedge aclr) begin
    if (aclr) begin
        write_addr <= 0;
        read_addr <= 0;
        capacity <= 0;    
    end else if (sclr) begin
        write_addr <= 0;
        read_addr <= 0;
        capacity <= 0;
    end else begin    
        write_addr <= write_addr + wrreq_safe;
        read_addr <= read_addr + rdreq_safe;
        capacity <= capacity_w;
    end
end

assign usedw = capacity;

if (MLAB_FLAG) begin
    generic_mlab_sc #(.WIDTH(WIDTH), .ADDR_WIDTH(LOG_DEPTH), .FAMILY(FAMILY)) mlab_inst (
        .clk(clock),
        .din(data),
        .waddr(write_addr),
        .we(RAM_ALWAYS_WRITE ? 1'b1 : wrreq_safe),
        .re(RAM_ALWAYS_READ ? 1'b1 : rdreq_safe),
        .raddr(read_addr),
        .dout(q)
    );
    assign eccstatus = 2'b0;
end else if (ADD_RAM_OUTPUT_REGISTER) begin
    generic_m20k #(.WIDTH(WIDTH), .ADDR_WIDTH(LOG_DEPTH), .FAMILY(FAMILY), .READ_INPUT_ENABLE(0), .READ_OUTPUT_REG(1), .ENABLE_ECC(ENABLE_ECC)) m20k_inst (
        .clk(clock),
        .din(data),
        .waddr(write_addr),
        .we(RAM_ALWAYS_WRITE ? 1'b1 : wrreq_safe),
        .re(RAM_ALWAYS_READ ? 1'b1 : rdreq_safe),
        .raddr(read_addr + rdreq_safe),
        .eccstatus(eccstatus),        
        .dout(q)
    );
end else begin
    generic_m20k #(.WIDTH(WIDTH), .ADDR_WIDTH(LOG_DEPTH), .FAMILY(FAMILY), .READ_INPUT_ENABLE(1), .READ_OUTPUT_REG(0), .ENABLE_ECC(ENABLE_ECC)) m20k_inst (
        .clk(clock),
        .din(data),
        .waddr(write_addr),
        .we(RAM_ALWAYS_WRITE ? 1'b1 : wrreq_safe),
        .re(RAM_ALWAYS_READ ? 1'b1 : rdreq_safe),
        .raddr(read_addr),
        .eccstatus(eccstatus),        
        .dout(q)
    );
end

endmodule