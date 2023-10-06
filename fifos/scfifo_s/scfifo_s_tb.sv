`timescale 1ps/1ps

module scfifo_s_tb ();

localparam WIDTH = 20;
localparam LOG_DEPTH = 5;

localparam ALMOST_FULL_VALUE = 30;
localparam ALMOST_EMPTY_VALUE = 2;

localparam SHOW_AHEAD = 1;

localparam OVERFLOW_CHECKING = 1;
localparam UNDERFLOW_CHECKING = 1;

reg [WIDTH-1:0] data;
wire wrreq;
wire rdreq;
wire wrreq_safe;
wire rdreq_safe;
reg rdreq_r = 0;
reg sclr = 0;

wire [WIDTH-1:0] q;
wire [WIDTH-1:0] expected_result;
wire [LOG_DEPTH-1:0] usedw;
reg [LOG_DEPTH-1:0] expected_usedw = 0;
wire empty;
wire full;
wire almost_empty;
wire almost_full;  
    
reg expected_almost_empty;
reg expected_almost_full;
    
reg clk = 1'b0;

scfifo_s #(
    .LOG_DEPTH(LOG_DEPTH), 
    .WIDTH(WIDTH), 
    .ALMOST_FULL_VALUE(ALMOST_FULL_VALUE), 
    .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE),
    .SHOW_AHEAD(SHOW_AHEAD),
    .FAMILY("Other"),
    .OVERFLOW_CHECKING(OVERFLOW_CHECKING),
    .UNDERFLOW_CHECKING(UNDERFLOW_CHECKING)
) dut (
    .clock(clk),
    .sclr(sclr),
    .data(data),
    .wrreq(wrreq),
    .rdreq(rdreq),
    .q(q),
    .usedw(usedw),
    //.usedw2(usedw2),
    .empty(empty),
    .full(full),
    .almost_empty(almost_empty),
    .almost_full(almost_full)
);

/*scfifo #(
    .add_ram_output_register("ON"),
    .almost_full_value(ALMOST_FULL_VALUE),
    .almost_empty_value(ALMOST_EMPTY_VALUE),
    .intended_device_family("Stratix 10"),
    .lpm_hint("RAM_BLOCK_TYPE=MLAB"),
    .lpm_numwords(2**LOG_DEPTH - 1),
    .lpm_showahead(SHOW_AHEAD ? "ON" : "OFF"),
    .lpm_type("scfifo"),
    .lpm_width(WIDTH),
    .lpm_widthu(LOG_DEPTH),
    .overflow_checking(OVERFLOW_CHECKING ? "ON" : "OFF"),
    .underflow_checking(UNDERFLOW_CHECKING ? "ON" : "OFF"),
    .use_eab("ON")    
) dut2 (
    .clock(clk),
    .sclr(sclr),
    .aclr(1'b0),
    .data(data),
    .wrreq(wrreq),
    .rdreq(rdreq),
    .q(q),
    .usedw(usedw),
    .empty(empty),
    .full(full),
    .almost_empty(almost_empty),
    .almost_full(almost_full)    
);*/

initial begin
    data = 0;
end

integer write_counter = 0;
integer read_counter = 0;
integer read_counter_r = 0;
integer counter = 0;
always @(posedge clk) begin
    data <= data + wrreq_safe;
	
    read_counter <= read_counter + rdreq_safe;
    read_counter_r <= read_counter;
    rdreq_r <= rdreq_safe;
    
    counter <= counter + 1;
    
    expected_usedw <= expected_usedw + wrreq_safe - rdreq_safe;

    expected_almost_empty <= (expected_usedw + wrreq_safe - rdreq_safe < ALMOST_EMPTY_VALUE);
    expected_almost_full <= (expected_usedw + wrreq_safe - rdreq_safe >= ALMOST_FULL_VALUE);
end

assign wrreq = (counter >= 20) & ($random & 1) & (~full | OVERFLOW_CHECKING); //(counter >= 20) && (counter < 52);
assign rdreq = (counter >= 20) & ($random & 1) & (~empty | UNDERFLOW_CHECKING); //(counter >= 60) && (counter < 92);

assign wrreq_safe = OVERFLOW_CHECKING ? wrreq & ~full : wrreq;
assign rdreq_safe = UNDERFLOW_CHECKING ? rdreq & ~empty : rdreq;



wire ready;

assign ready = SHOW_AHEAD ? rdreq_safe : rdreq_r;
assign expected_result = SHOW_AHEAD ? read_counter : read_counter_r;

reg flushing = 1'b1;
reg fail = 1'b0;

integer full_counter = 0;
integer empty_counter = 0;

always @(posedge clk) begin
    if (full)
        full_counter <= full_counter + 1;
    if (empty)
        empty_counter <= empty_counter + 1;
        

//	#10
	if (!flushing) begin
		if (ready && ((expected_result != q) || (usedw != expected_usedw) || (almost_empty != expected_almost_empty) || (almost_full != expected_almost_full))) 
		begin
            $display ("write: %d %d; read %d %d vs %d / empty=%d, full=%d sclr=%d / usedw: %d vs %d / AlmostEmpty: %d vs %d / AlmostFull: %d vs %d",
                    wrreq, data, ready, q, expected_result, empty, full, sclr, 
                    usedw, expected_usedw, 
                    almost_empty, expected_almost_empty,
                    almost_full, expected_almost_full,
                );

            //$display("ERROR:");
			fail = 1'b1;
		end
	end
end

integer k = 0;
initial begin
    sclr = 1'b1;
	for (k=0; k<10; k=k+1) @(negedge clk);
	flushing = 1'b0;
    sclr = 1'b0;
	for (k=0; k<1000000; k=k+1) @(negedge clk);
    
    $display("full_counter=%0d, empty_counter=%0d", full_counter, empty_counter);
	if (!fail) $display ("PASS");
	@(negedge clk);
	$stop();	
end

always begin
	#1000 clk = ~clk;
end

endmodule
