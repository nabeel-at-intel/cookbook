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

module dcfifo_s_showahead
#(
    parameter LOG_DEPTH      = 5,
    parameter WIDTH          = 20,
    parameter ALMOST_FULL_VALUE = 30,
    parameter ALMOST_EMPTY_VALUE = 2,    
    parameter FAMILY = "S10", // Agilex, S10, or Other
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
    output reg [WIDTH-1:0] q,
    output reg rdempty,
    output rdfull,
    output reg rd_almost_empty,    
    output reg rd_almost_full,    
    output reg [LOG_DEPTH-1:0] rdusedw
);

initial begin
    if ((LOG_DEPTH > 5) || (LOG_DEPTH < 3))
        $error("Invalid parameter value: LOG_DEPTH = %0d; valid range is 2 < LOG_DEPTH < 6", LOG_DEPTH);
        
    if ((ALMOST_FULL_VALUE > 2 ** LOG_DEPTH - 1) || (ALMOST_FULL_VALUE < 1))
        $error("Incorrect parameter value: ALMOST_FULL_VALUE = %0d; valid range is 0 < ALMOST_FULL_VALUE < %0d", 
            ALMOST_FULL_VALUE, 2 ** LOG_DEPTH);     

    if ((ALMOST_EMPTY_VALUE > 2 ** LOG_DEPTH - 1) || (ALMOST_EMPTY_VALUE < 1))
        $error("Incorrect parameter value: ALMOST_EMPTY_VALUE = %0d; valid range is 0 < ALMOST_EMPTY_VALUE < %0d", 
            ALMOST_EMPTY_VALUE, 2 ** LOG_DEPTH);     
end

//wire wrreq_safe;
wire rdreq_safe;
//assign wrreq_safe = OVERFLOW_CHECKING ? wrreq & ~wrfull : wrreq;
assign rdreq_safe = UNDERFLOW_CHECKING ? rdreq & ~rdempty : rdreq;

wire [WIDTH-1:0] w_q;

wire w_empty;
wire w_full;
wire w_almost_empty;
wire w_almost_full;    

wire [LOG_DEPTH-1:0] w_usedw;

reg read_fifo;
reg read_fifo_r; // 1 means that there is a value at fifo output

reg [WIDTH-1:0] r_q2;
reg r_q2_ready;

dcfifo_s_normal #(
    .LOG_DEPTH(LOG_DEPTH), 
    .WIDTH(WIDTH), 
    .ALMOST_FULL_VALUE(ALMOST_FULL_VALUE), 
    .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE),
    .NUM_WORDS(2**LOG_DEPTH - 4),
    .MLAB_ALWAYS_READ(0),
    .FAMILY(FAMILY),
    .OVERFLOW_CHECKING(OVERFLOW_CHECKING)
) fifo_inst(
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
    .rdreq(read_fifo),
    .q(w_q),
    .rdempty(w_empty),
    .rdfull(rdfull),
    .rdusedw(w_usedw)    
);

wire next_empty;

assign next_empty = (w_usedw == 0) || (w_usedw == 1) && (read_fifo == 1);

reg tmp;

always @(posedge rdclk or posedge aclr) begin

    if (aclr) begin
        rdempty <= 1;
        read_fifo <= 0;
        read_fifo_r <= 0;        
        r_q2_ready <= 0;
        rdusedw <= 0;
        rd_almost_full <= 0;
        rd_almost_empty <= 1;
        // No need to reset output data registers
        //q <= 0;
        //r_q2 <= 0;
    end else begin

        if (rdreq_safe || rdempty) begin
            if (r_q2_ready)
                q <= r_q2;
            else
                q <= w_q;
        end
        
        if (rdreq_safe || rdempty) begin
            rdempty <= !(r_q2_ready || read_fifo_r); 
        end
        
        if (r_q2_ready) begin
            if (rdreq_safe || rdempty)
                r_q2 <= w_q;
        end else begin
            r_q2 <= w_q;
        end

        if (r_q2_ready) begin
            if (rdreq_safe || rdempty)
                r_q2_ready <= read_fifo_r;
        end else begin
            if (rdreq_safe || rdempty)
                r_q2_ready <= 0;
            else
                r_q2_ready <= read_fifo_r;
        end
                    
        read_fifo_r <= read_fifo || read_fifo_r && !(rdreq_safe || rdempty || !r_q2_ready);
        
        read_fifo <= !next_empty && (
            rdreq_safe && (!rdempty + r_q2_ready + read_fifo + read_fifo_r < 4) || 
           !rdreq_safe && (!rdempty + r_q2_ready + read_fifo + read_fifo_r < 3)
        ); 
        
        //usedw <= w_usedw + read_fifo_r + r_q2_ready + wrreq + (!empty & !rdreq);
        {rdusedw, tmp} <= {w_usedw, !rdempty & !rdreq_safe} + {
            read_fifo_r & r_q2_ready, 
            read_fifo_r ^ r_q2_ready, 
            !rdempty & !rdreq_safe};
                
        rd_almost_empty <=
            (rdusedw < ALMOST_EMPTY_VALUE) || 
            (rdusedw == ALMOST_EMPTY_VALUE) && (rdreq == 1);
            
        rd_almost_full <= 
            (rdusedw > ALMOST_FULL_VALUE) ||
            (rdusedw == ALMOST_FULL_VALUE) && (rdreq == 0);    

    end
end
endmodule
