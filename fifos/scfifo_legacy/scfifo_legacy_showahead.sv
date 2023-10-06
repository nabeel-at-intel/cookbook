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

module scfifo_legacy_showahead #(
    parameter LOG_DEPTH      = 5,
    parameter WIDTH          = 20,
    parameter NUM_WORDS = 2**LOG_DEPTH,
    parameter ALMOST_FULL_VALUE = 30,
    parameter ALMOST_EMPTY_VALUE = 2,
    parameter FAMILY = "Agilex",
    parameter OVERFLOW_CHECKING = 0,
    parameter UNDERFLOW_CHECKING = 0,
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
    output reg empty,
    output full,
    output almost_empty,
    output almost_full,
    output [1:0] eccstatus
    
);

localparam MLAB_ALWAYS_WRITE = (NUM_WORDS != 2**LOG_DEPTH);

(* altera_attribute = "-name AUTO_CLOCK_ENABLE_RECOGNITION OFF" *) reg [LOG_DEPTH-1:0] write_addr = 0;
(* altera_attribute = "-name AUTO_CLOCK_ENABLE_RECOGNITION OFF" *) reg [LOG_DEPTH-1:0] read_addr = 0;
reg [LOG_DEPTH-1:0] capacity = 0;
reg [LOG_DEPTH-1:0] mem_capacity = 0;
wire [LOG_DEPTH-1:0] capacity_w;
wire [LOG_DEPTH-1:0] mem_capacity_w;

reg empty_mem;

wire wrreq_safe;
wire rdreq_safe;
assign wrreq_safe = OVERFLOW_CHECKING ? (ALLOW_RWCYCLE_WHEN_FULL ? (wrreq & (~full | rdreq)) : (wrreq & ~full)) : wrreq;
assign rdreq_safe = UNDERFLOW_CHECKING ? rdreq & ~empty : rdreq;

wire read_mem;
assign read_mem = ~empty_mem & (rdreq | empty);

initial begin 
    empty_mem = 1;
    empty = 1;
end

add_a_b_s0_s1 #(LOG_DEPTH) adder1(
    .a(write_addr),
    .b(~read_addr),
    .s1(wrreq_safe),
    .s0(~read_mem),
    .out(mem_capacity_w)
);

add_a_b_s0_s1 #(LOG_DEPTH) adder2(
    .a(mem_capacity),
    .b({LOG_DEPTH{1'b0}}),
    .s1(wrreq_safe),
    .s0((empty || rdreq_safe) ? 0 : 1),
    .out(capacity_w)
);

scfifo_legacy_flags #(
    .LOG_DEPTH(LOG_DEPTH),
    .NUM_WORDS(NUM_WORDS),
    .ALMOST_FULL_VALUE(ALMOST_FULL_VALUE),
    .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE),
    .OVERFLOW_CHECKING(OVERFLOW_CHECKING),
    .UNDERFLOW_CHECKING(OVERFLOW_CHECKING),
    .ADD_RAM_OUTPUT_REGISTER(ADD_RAM_OUTPUT_REGISTER),
    .ALLOW_RWCYCLE_WHEN_FULL(ALLOW_RWCYCLE_WHEN_FULL)
) fifo_state (
    .clock(clock),
    .aclr(aclr),
    .sclr(sclr),
    .capacity(capacity),
    .wrreq(wrreq),
    .rdreq(rdreq),
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
        mem_capacity <= 0;
        empty_mem <= 1;
        empty <= 1;    
    end else if (sclr) begin
        write_addr <= 0;
        read_addr <= 0;
        capacity <= 0;
        mem_capacity <= 0;
        empty_mem <= 1;
        empty <= 1;
    end else begin    
        write_addr <= write_addr + wrreq_safe;
        read_addr <= read_addr + read_mem;

        capacity <= capacity_w;
        mem_capacity <= mem_capacity_w;
        
        if (ADD_RAM_OUTPUT_REGISTER == 1)
            empty_mem <= (mem_capacity == read_mem);
        else
            empty_mem <= (wrreq_safe == 0) && (mem_capacity == read_mem);
        
        empty <= empty_mem & (rdreq | empty);
    end
end

assign usedw = capacity;

if (MLAB_FLAG) begin
    generic_mlab_sc #(.WIDTH(WIDTH), .ADDR_WIDTH(LOG_DEPTH), .FAMILY(FAMILY)) mlab_inst (
        .clk(clock),
        .din(data),
        .waddr(write_addr),
        .we(MLAB_ALWAYS_WRITE ? 1'b1 : wrreq_safe),
        .re(read_mem),
        .raddr(read_addr),
        .dout(q)
    );
    assign eccstatus = 2'b0;
end
else if (ADD_RAM_OUTPUT_REGISTER) begin
    generic_m20k #(.WIDTH(WIDTH), .ADDR_WIDTH(LOG_DEPTH), .FAMILY(FAMILY), .READ_INPUT_ENABLE(0), .READ_OUTPUT_REG(1), .ENABLE_ECC(ENABLE_ECC)) m20k_inst (
        .clk(clock),
        .din(data),
        .waddr(write_addr),
        .we(MLAB_ALWAYS_WRITE ? 1'b1 : wrreq_safe),
        .re(read_mem),
        .raddr(read_addr + read_mem),
        .eccstatus(eccstatus),
        .dout(q)
    );
end else begin
    generic_m20k #(.WIDTH(WIDTH), .ADDR_WIDTH(LOG_DEPTH), .FAMILY(FAMILY), .READ_INPUT_ENABLE(1), .READ_OUTPUT_REG(0), .ENABLE_ECC(ENABLE_ECC)) m20k_inst (
        .clk(clock),
        .din(data),
        .waddr(write_addr),
        .we(MLAB_ALWAYS_WRITE ? 1'b1 : wrreq_safe),
        .re(read_mem),
        .raddr(read_addr),
        .eccstatus(eccstatus),
        .dout(q)
    );
end
    
endmodule