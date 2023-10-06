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

module scfifo_s_normal_m20k_r #(
    parameter LOG_DEPTH      = 8,
    parameter WIDTH          = 20,
    parameter ALMOST_FULL_VALUE = 30,
    parameter ALMOST_EMPTY_VALUE = 2,
    parameter FAMILY = "S10", // Agilex, S10, or Other
    parameter NUM_WORDS = 2**LOG_DEPTH - 3 
)(
    input clock,
    input aclr,
    input sclr,
    input [WIDTH-1:0] data,
    input wrreq,
    input rdreq,
    output [WIDTH-1:0] q,
    output reg [LOG_DEPTH-1:0] usedw,
    output reg empty,
    output reg full,
    output reg almost_empty,
    output reg almost_full    
);

initial begin
    if ((LOG_DEPTH >= 12) || (LOG_DEPTH <= 3))
        $error("Invalid parameter value: LOG_DEPTH = %0d; valid range is 3 < LOG_DEPTH < 12", LOG_DEPTH);
        
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

wire [WIDTH-1:0] q_w;
reg [WIDTH-1:0] q_r;

reg [LOG_DEPTH-1:0] write_addr = 0;
reg [LOG_DEPTH-1:0] read_addr = 0;
reg [LOG_DEPTH-1:0] capacity = 0;
wire [LOG_DEPTH-1:0] capacity_w;

wire read_increment;
wire read_m20k;
reg read_increment_r;

initial begin 
    empty = 1;
    full = 0;
    almost_empty = 1;
    almost_full = 0;
end

assign read_increment = (rdreq | empty) & (capacity > 0);
assign read_m20k = rdreq | empty /*& (capacity > 0)*/;

localparam LOG_DEPTH_COMPRESSED = (LOG_DEPTH + 1) / 2;
wire [LOG_DEPTH_COMPRESSED-1:0] capacity_compressed;
assign capacity_compressed = capacity[LOG_DEPTH_COMPRESSED-1:0] | capacity[LOG_DEPTH-1:LOG_DEPTH_COMPRESSED];

wire [LOG_DEPTH+LOG_DEPTH_COMPRESSED:0] left;
wire [LOG_DEPTH+LOG_DEPTH_COMPRESSED:0] right;
wire [LOG_DEPTH_COMPRESSED:0] temp;

assign left = {write_addr ^ ~read_addr, (~rdreq & ~empty), ~capacity_compressed};
assign right = {write_addr[LOG_DEPTH-2:0] & ~read_addr[LOG_DEPTH-2:0], wrreq, 1'b1, {(LOG_DEPTH_COMPRESSED-1){1'b0}}, 1'b1};
assign {capacity_w, temp} = left + right;


reg [LOG_DEPTH_COMPRESSED:0] read_addr_temp;

reg tmp;
always @(posedge clock or posedge aclr) begin
    if (aclr) begin
        write_addr <= 0;
        read_addr <= 0;
        capacity <= 0;
        empty <= 1;
        full <= 0;
        almost_empty <= 1;
        almost_full <= 0;  
        usedw <= 0;
        q_r <= 0;        
        read_increment_r <= 0;        
    end else if (sclr) begin
        write_addr <= 0;
        read_addr <= 0;
        capacity <= 0;
        empty <= 1;
        full <= 0;
        almost_empty <= 1;
        almost_full <= 0;
        usedw <= 0;
        q_r <= 0;        
        read_increment_r <= 0;        
    end else begin
        read_increment_r <= ~read_m20k & read_increment_r | read_m20k & read_increment;
        
        write_addr <= write_addr + wrreq;
                
        //read_addr <= read_addr + read_increment;
        {read_addr, read_addr_temp} <= {read_addr, 1'b0, {LOG_DEPTH_COMPRESSED {1'b1}} } + { {LOG_DEPTH {1'b0}}, (rdreq | empty), capacity_compressed };

        capacity <= capacity_w;
        
        empty <= empty & ~read_increment_r | ~empty & /*(capacity == 0) &*/ rdreq & ~read_increment_r;
        
        full <= (capacity == NUM_WORDS) && (read_increment == 0) || (capacity == NUM_WORDS - 1) && (read_increment == 0) && (wrreq == 1);
        
        almost_empty <=
            (usedw < (ALMOST_EMPTY_VALUE-1)) || 
            (usedw == (ALMOST_EMPTY_VALUE-1)) && ((wrreq == 0) || (rdreq == 1)) || 
            (usedw == ALMOST_EMPTY_VALUE) && (rdreq == 1) && (wrreq == 0);
            
        almost_full <= 
            (usedw > ALMOST_FULL_VALUE) ||
            (usedw == ALMOST_FULL_VALUE) && ((rdreq == 0) || (wrreq == 1)) ||
            (usedw == ALMOST_FULL_VALUE - 1) && (rdreq == 0) && (wrreq == 1);    

        //usedw <= capacity + (1 - empty) + read_increment_r + wrreq - rdreq;
        {usedw, tmp} <= {capacity, !empty & !rdreq} + {
            wrreq & read_increment_r, wrreq ^ read_increment_r, 
            !empty & !rdreq};

        q_r <= read_m20k ? q_w : q_r;

    end
end

generic_m20k #(.WIDTH(WIDTH), .ADDR_WIDTH(LOG_DEPTH), .FAMILY(FAMILY)) m20k_inst (
    .clk(clock),
    .din(data),
    .waddr(write_addr),
    .we(1'b1),
    .re(read_m20k),
    .raddr(read_addr),
    .dout(q_w)
);

assign q = q_r;

endmodule