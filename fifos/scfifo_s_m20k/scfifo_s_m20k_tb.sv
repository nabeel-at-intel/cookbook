`timescale 1ps/1ps

module scfifo_s_m20k_tb ();

localparam WIDTH = 20;
localparam LOG_DEPTH = 5;

localparam ALMOST_FULL_VALUE = 30;
localparam ALMOST_EMPTY_VALUE = 2;

localparam SHOW_AHEAD = 1;
localparam OUTPUT_REGISTER = 1;

reg [WIDTH-1:0] data;
wire wrreq;
wire rdreq;
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

scfifo_s_m20k #(
    .LOG_DEPTH(LOG_DEPTH), 
    .WIDTH(WIDTH), 
    .ALMOST_FULL_VALUE(ALMOST_FULL_VALUE), 
    .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE),
    .SHOW_AHEAD(SHOW_AHEAD),
    .OUTPUT_REGISTER(OUTPUT_REGISTER),
    .FAMILY("S10")
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
    //.lpm_hint("RAM_BLOCK_TYPE=MLAB"),
    .lpm_hint("RAM_BLOCK_TYPE=M20K"),
    .lpm_numwords(2**LOG_DEPTH - 1),
    .lpm_showahead(SHOW_AHEAD ? "ON" : "OFF"),
    .lpm_type("scfifo"),
    .lpm_width(WIDTH),
    .lpm_widthu(LOG_DEPTH),
    .overflow_checking("OFF"),
    .underflow_checking("OFF"),
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
    data <= data + wrreq;
	
    read_counter <= read_counter + rdreq;
    read_counter_r <= read_counter;
    rdreq_r <= rdreq;
    
    counter <= counter + 1;
    
    expected_usedw <= expected_usedw + wrreq - rdreq;

    expected_almost_empty <= (expected_usedw + wrreq - rdreq < ALMOST_EMPTY_VALUE);
    expected_almost_full <= (expected_usedw + wrreq - rdreq >= ALMOST_FULL_VALUE);
end

assign wrreq = (counter >= 20) & ($random & 1) & ~full; //(counter >= 20) && (counter < 52);
assign rdreq = (counter >= 20) & ($random & 1) & ~empty; //(counter >= 60) && (counter < 92);

wire ready;

assign ready = SHOW_AHEAD ? rdreq : rdreq_r;
assign expected_result = SHOW_AHEAD ? read_counter : read_counter_r;

reg flushing = 1'b1;
reg fail = 1'b0;
always @(posedge clk) begin
//	#10
	if (!flushing) begin
		if (ready && ((expected_result != q) || (usedw != expected_usedw) || (almost_empty != expected_almost_empty) || (almost_full != expected_almost_full))) 
		begin
            $display ("FAIL write: %d %d; read %d: ready=%d: %d vs %d / empty=%d, full=%d sclr=%d / usedw: %d vs %d / AlmostEmpty: %d vs %d / AlmostFull: %d vs %d",
                    wrreq, data, rdreq, ready, q, expected_result, empty, full, sclr, 
                    usedw, expected_usedw, 
                    almost_empty, expected_almost_empty,
                    almost_full, expected_almost_full,
                );

            //$display("ERROR:");
			fail = 1'b1;
		end
        //else
        //    $display ("good write: %d %d; read %d: ready=%d: %d vs %d / empty=%d, full=%d sclr=%d / usedw: %d vs %d / AlmostEmpty: %d vs %d / AlmostFull: %d vs %d",
        //            wrreq, data, rdreq, ready, q, expected_result, empty, full, sclr, 
        //            usedw, expected_usedw, 
        //            almost_empty, expected_almost_empty,
        //            almost_full, expected_almost_full,
        //        );	
    end
end

integer k = 0;
initial begin
    sclr = 1'b1;
	for (k=0; k<10; k=k+1) @(negedge clk);
	flushing = 1'b0;
    sclr = 1'b0;
	for (k=0; k<2000000; k=k+1) @(negedge clk);
	if (!fail) $display ("PASS");
	@(negedge clk);
	$stop();	
end

always begin
	#1000 clk = ~clk;
end

endmodule
