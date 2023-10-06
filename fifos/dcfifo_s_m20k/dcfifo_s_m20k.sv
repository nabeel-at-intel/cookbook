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

// dcfifo_s_m20k is designed as a faster and smaller replacement of dcfifo
// 
// Notes
// 1. rdreq-to-q latency is 2 clock cycles (it is 1 cycle in dcfifo)
//. 
// 2. The only dcfifo port not supported by dcfifo_s is "eccstatus".
//    All the other ports are identical to dcfifo.
//
// 3. "show-ahead" mode is not supported.
//
// 4. almost_empty and almost_full thresholds are supported
//    See parameters ALMOST_EMPTY_VALUE and ALMOST_FULL_VALUE
//
// 5. dcfifo_s_m20k is M20K-based and is able to store up to 2047 words.
//    
// 6. All M20Ks are fully registered.

module dcfifo_s_m20k
#(
    parameter LOG_DEPTH      = 10,
    parameter WIDTH          = 20,
    parameter ALMOST_FULL_VALUE = 1000,
    parameter ALMOST_EMPTY_VALUE = 2,
    parameter FAMILY = "S10", // Agilex, S10, or Other
    parameter NUM_WORDS = 2**LOG_DEPTH - 1,
    parameter OVERFLOW_CHECKING = 0, // Overflow checking circuitry is using extra area. Use only if you need it
    parameter UNDERFLOW_CHECKING = 0 // Underflow checking circuitry is using extra area. Use only if you need it        
)
(
    input aclr,
    
    input wrclk,
    input wrreq,
    input [WIDTH-1:0] data,
    output reg wrempty,
    output reg wrfull,
    output reg wr_almost_empty,
    output reg wr_almost_full,
    output [LOG_DEPTH-1:0] wrusedw,
    
    input rdclk,
    input rdreq,
    output [WIDTH-1:0] q,
    output reg rdempty,
    output reg rdfull,
    output reg rd_almost_empty,    
    output reg rd_almost_full,    
    output [LOG_DEPTH-1:0] rdusedw
);
       
initial begin
    if ((LOG_DEPTH > 11) || (LOG_DEPTH < 2))
        $error("Invalid parameter value: LOG_DEPTH = %0d; valid range is 2 < LOG_DEPTH < 12", LOG_DEPTH);

    if ((LOG_DEPTH >= 2) && (LOG_DEPTH < 6))
        $warning("LOG_DEPTH = %0d is too small for M20K-based FIFO. Consider using MLAB-based FIFO instead", LOG_DEPTH);
        
    if ((ALMOST_FULL_VALUE > 2 ** LOG_DEPTH - 1) || (ALMOST_FULL_VALUE < 1))
        $error("Incorrect parameter value: ALMOST_FULL_VALUE = %0d; valid range is 0 < ALMOST_FULL_VALUE < %0d", 
            ALMOST_FULL_VALUE, 2 ** LOG_DEPTH);     

    if ((ALMOST_EMPTY_VALUE > 2 ** LOG_DEPTH - 1) || (ALMOST_EMPTY_VALUE < 1))
        $error("Incorrect parameter value: ALMOST_EMPTY_VALUE = %0d; valid range is 0 < ALMOST_EMPTY_VALUE < %0d", 
            ALMOST_EMPTY_VALUE, 2 ** LOG_DEPTH);  

    if ((NUM_WORDS > 2 ** LOG_DEPTH - 1) || (NUM_WORDS < 1))
        $error("Incorrect parameter value: NUM_WORDS = %0d; valid range is 0 < NUM_WORDS < %0d", 
            NUM_WORDS, 2 ** LOG_DEPTH);  
end

(* altera_attribute = "-name AUTO_CLOCK_ENABLE_RECOGNITION OFF" *) reg [LOG_DEPTH-1:0] write_addr = 0;
(* altera_attribute = "-name AUTO_CLOCK_ENABLE_RECOGNITION OFF" *) reg [LOG_DEPTH-1:0] read_addr = 0;
reg [LOG_DEPTH-1:0] wrcapacity = 0;
reg [LOG_DEPTH-1:0] rdcapacity = 0;

wire [LOG_DEPTH-1:0] wrcapacity_w;
wire [LOG_DEPTH-1:0] rdcapacity_w;

wire [LOG_DEPTH-1:0] rd_write_addr;
wire [LOG_DEPTH-1:0] wr_read_addr;

wire wrreq_safe;
wire rdreq_safe;
assign wrreq_safe = OVERFLOW_CHECKING ? wrreq & ~wrfull : wrreq;
assign rdreq_safe = UNDERFLOW_CHECKING ? rdreq & ~rdempty : rdreq;

initial begin 
    write_addr = 0;
    read_addr = 0;
    wrempty = 1;
    wrfull = 0;
    rdempty = 1;
    rdfull = 0;
    wrcapacity = 0;
    rdcapacity = 0;    
    rd_almost_empty = 1;
    rd_almost_full = 0;
    wr_almost_empty = 1;
    wr_almost_full = 0;
end


// ------------------ Write -------------------------

add_a_b_s0_s1 #(LOG_DEPTH) wr_adder(
    .a(write_addr),
    .b(~wr_read_addr),
    .s0(wrreq_safe),
    .s1(1'b1),
    .out(wrcapacity_w)
);

always @(posedge wrclk or posedge aclr) begin

    if (aclr) begin
        write_addr <= 0;
        wrcapacity <= 0;
        wrempty <= 1;
        wrfull <= 0;
        wr_almost_full <= 0;
        wr_almost_empty <= 1;
    end else begin
        write_addr <= write_addr + wrreq_safe;
        wrcapacity <= wrcapacity_w;
        wrempty <= (wrcapacity == 0) && (wrreq == 0);
        wrfull <= (wrcapacity == NUM_WORDS) || (wrcapacity == NUM_WORDS - 1) && (wrreq == 1);
        
        wr_almost_empty <=
            (wrcapacity < (ALMOST_EMPTY_VALUE-1)) || 
            (wrcapacity == (ALMOST_EMPTY_VALUE-1)) && (wrreq == 0);
        
        wr_almost_full <= 
            (wrcapacity >= ALMOST_FULL_VALUE) ||
            (wrcapacity == ALMOST_FULL_VALUE - 1) && (wrreq == 1);    
    end    
end

assign wrusedw = wrcapacity;

// ------------------ Read -------------------------

add_a_b_s0_s1 #(LOG_DEPTH) rd_adder(
    .a(rd_write_addr),
    .b(~read_addr),
    .s0(1'b0),
    .s1(~rdreq_safe),
    .out(rdcapacity_w)
);

always @(posedge rdclk or posedge aclr) begin
    if (aclr) begin
        read_addr <= 0;
        rdcapacity <= 0;
        rdempty <= 1;
        rdfull <= 0;    
        rd_almost_empty <= 1;
        rd_almost_full <= 0;
    end else begin
        read_addr <= read_addr + rdreq_safe;
        rdcapacity <= rdcapacity_w;
        rdempty <= (rdcapacity == 0) || (rdcapacity == 1) && (rdreq == 1);
        rdfull <= (rdcapacity == NUM_WORDS) && (rdreq == 0);    
        rd_almost_empty <= 
            (rdcapacity < ALMOST_EMPTY_VALUE) || 
            (rdcapacity == ALMOST_EMPTY_VALUE) && (rdreq == 1);
            
        rd_almost_full <= 
            (rdcapacity > ALMOST_FULL_VALUE) ||
            (rdcapacity == ALMOST_FULL_VALUE) && (rdreq == 0);                
    end
end

assign rdusedw = rdcapacity;

// ---------------- Synchronizers --------------------

wire [LOG_DEPTH-1:0] gray_read_addr;
wire [LOG_DEPTH-1:0] wr_gray_read_addr;
wire [LOG_DEPTH-1:0] gray_write_addr;
wire [LOG_DEPTH-1:0] rd_gray_write_addr;

binary_to_gray #(.WIDTH(LOG_DEPTH)) rd_b2g (.clock(rdclk), .aclr(aclr), .din(read_addr), .dout(gray_read_addr));
synchronizer_ff_r2 #(.WIDTH(LOG_DEPTH)) rd2wr (.din_clk(rdclk), .din(gray_read_addr), .aclr(aclr), .dout_clk(wrclk), .dout(wr_gray_read_addr));
gray_to_binary #(.WIDTH(LOG_DEPTH)) rd_g2b (.clock(wrclk), .aclr(aclr), .din(wr_gray_read_addr), .dout(wr_read_addr));


binary_to_gray #(.WIDTH(LOG_DEPTH)) wr_b2g (.clock(wrclk), .aclr(aclr), .din(write_addr), .dout(gray_write_addr));
synchronizer_ff_r2 #(.WIDTH(LOG_DEPTH)) wr2rd (.din_clk(wrclk), .din(gray_write_addr), .aclr(aclr), .dout_clk(rdclk), .dout(rd_gray_write_addr));
gray_to_binary #(.WIDTH(LOG_DEPTH)) wr_g2b (.clock(rdclk), .aclr(aclr), .din(rd_gray_write_addr), .dout(rd_write_addr));

// ------------------ MLAB ---------------------------

generic_m20k_dc #(.WIDTH(WIDTH), .ADDR_WIDTH(LOG_DEPTH), .FAMILY(FAMILY)) m20k_inst (
    .rclk(rdclk),
    .wclk(wrclk),
    .din(data),
    .waddr(write_addr),
    .we(1'b1),
    .re(1'b1),
    .raddr(read_addr),
    .dout(q)
);

endmodule
