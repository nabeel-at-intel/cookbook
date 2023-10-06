`timescale 1ps/1ps

module dcfifo_s_m20k_tb ();

localparam WIDTH = 20;
localparam LOG_DEPTH = 6;

localparam ALMOST_FULL_VALUE = 60;
localparam ALMOST_EMPTY_VALUE = 2;

localparam OVERFLOW_CHECKING = 0;
localparam UNDERFLOW_CHECKING = 0;
    
reg [WIDTH-1:0] data;
wire wrreq;
wire rdreq;
wire wrreq_safe;
wire rdreq_safe;

reg rdreq_r = 0;
reg sclr = 0;

wire [WIDTH-1:0] q;
wire [WIDTH-1:0] expected_result;
reg [WIDTH-1:0] expected_result_r;
wire [LOG_DEPTH-1:0] rdusedw;
wire [LOG_DEPTH-1:0] wrusedw;
reg [LOG_DEPTH-1:0] expected_usedw = 0;
wire empty;
wire full;
wire almost_empty;
wire almost_full;  
    
reg expected_almost_empty;
reg expected_almost_full;

reg clk = 1'b0;

reg aclr;

dcfifo_s_m20k #(
    .LOG_DEPTH(LOG_DEPTH), 
    .WIDTH(WIDTH), 
    .ALMOST_FULL_VALUE(ALMOST_FULL_VALUE), 
    .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE), 
    .FAMILY("Other"),
    .OVERFLOW_CHECKING(OVERFLOW_CHECKING),
    .UNDERFLOW_CHECKING(UNDERFLOW_CHECKING)    
) dut (
    .aclr(aclr),
    .wrclk(clk),
    .wrreq(wrreq),
    .data(data),
    .wrempty(),
    .wrfull(full),
    .wrusedw(wrusedw),
    .rdclk(clk),
    .rdempty(empty),
    .rdfull(),
    .rdusedw(rdusedw),
    .rdreq(rdreq),
    .q(q)
);

/*dcfifo #(
    .add_ram_output_register("ON"),
    .almost_full_value(ALMOST_FULL_VALUE),
    .almost_empty_value(ALMOST_EMPTY_VALUE),
    .intended_device_family("Stratix 10"),
    .lpm_hint("RAM_BLOCK_TYPE=MLAB"),
    .lpm_numwords(2**LOG_DEPTH - 1),
    .lpm_showahead("OFF"),
    .lpm_type("dcfifo"),
    .lpm_width(WIDTH),
    .lpm_widthu(LOG_DEPTH),
    .overflow_checking(OVERFLOW_CHECKING ? "ON" : "OFF"),
    .underflow_checking(UNDERFLOW_CHECKING ? "ON" : "OFF"),
    .use_eab("ON")    
) dut2 (
    .aclr(1'b0),
    .wrclk(clk),
    .wrreq(wrreq),
    .data(data),
//    .wrempty(),
    .wrfull(full),
    .wrusedw(wrusedw),
    .rdclk(clk),
    .rdempty(empty),
//    .rdfull(),
    .rdusedw(rdusedw),
    .rdreq(rdreq),
    .q(q)
);*/

initial begin
    data = 0;
end

integer write_counter = 0;
integer read_counter = 0;
integer read_counter_r = 0;
integer counter = 0;
always @(posedge clk) begin
    aclr <= (counter < 5);
    data <= data + wrreq_safe;
	
    read_counter <= read_counter + rdreq_safe;
    read_counter_r <= read_counter;
    rdreq_r <= rdreq_safe;
    
    counter <= counter + 1;
    
    expected_usedw <= expected_usedw + wrreq_safe - rdreq_safe;

    //expected_almost_empty <= (expected_usedw + wrreq_safe - rdreq_safe < ALMOST_EMPTY_VALUE);
    //expected_almost_full <= (expected_usedw + wrreq_safe - rdreq_safe >= ALMOST_FULL_VALUE);
end

assign wrreq = (counter >= 20) & ($random & 1) & (~full | OVERFLOW_CHECKING); //(counter >= 20) && (counter < 52);
assign rdreq = (counter >= 20) & ($random & 1) & (~empty | UNDERFLOW_CHECKING); //(counter >= 60) && (counter < 92);

assign wrreq_safe = OVERFLOW_CHECKING ? wrreq & ~full : wrreq;
assign rdreq_safe = UNDERFLOW_CHECKING ? rdreq & ~empty : rdreq;

wire ready;
reg ready_r;

always @(posedge clk) begin
    ready_r <= ready;
    expected_result_r <= expected_result;
    
end

//assign ready = SHOW_AHEAD ? rdreq_safe : rdreq_r;
assign ready = rdreq_r;
//assign expected_result = SHOW_AHEAD ? read_counter : read_counter_r;
assign expected_result = read_counter_r;

integer full_counter = 0;
integer empty_counter = 0;        
        
reg flushing = 1'b1;
reg fail = 1'b0;
always @(posedge clk) begin
//	#10

    if (full)
        full_counter <= full_counter + 1;
    if (empty)
        empty_counter <= empty_counter + 1;

	if (!flushing) begin
		if (ready_r && ((expected_result_r != q) //|| (usedw != expected_usedw) || (almost_empty != expected_almost_empty) || (almost_full != expected_almost_full)
        )) 
		begin
            $display ("write: %d %d; read %d %d vs %d / empty=%d, full=%d sclr=%d / usedw: %d vs %d vs %d",
                    wrreq, data, ready, q, expected_result, empty, full, sclr, 
                    rdusedw, expected_usedw, wrusedw
                );

            //$display("ERROR:");
			fail = 1'b1;
		end
        //else
        //    $display ("write: %d %d; read %d %d vs %d / empty=%d, full=%d sclr=%d / usedw: %d vs %d vs %d",
        //            wrreq, data, ready, q, expected_result, empty, full, sclr, 
        //            rdusedw, expected_usedw, wrusedw
        //        );
        
        
	end
end

integer k = 0;
initial begin
    sclr = 1'b1;
	for (k=0; k<10; k=k+1) @(negedge clk);
	flushing = 1'b0;
    sclr = 1'b0;
	for (k=0; k<10000; k=k+1) @(negedge clk);
    $display("full_counter=%0d, empty_counter=%0d", full_counter, empty_counter);    
	if (!fail) $display ("PASS");
	@(negedge clk);
	$stop();	
end

always begin
	#1000 clk = ~clk;
end

endmodule

/*module top_tb ();

localparam WIDTH = 20;
localparam LOG_DEPTH = 5;

localparam ALMOST_FULL_VALUE = 30;
localparam ALMOST_EMPTY_VALUE = 2;

localparam SHOW_AHEAD = 0;

reg sclr = 0;
 
reg clk = 1'b0;

wire error;

dcfifo_tester #(
    .WIDTH(WIDTH), 
    .LOG_DEPTH(LOG_DEPTH), 
    .ALMOST_FULL_VALUE(ALMOST_FULL_VALUE), 
    .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE),
    .SHOW_AHEAD(SHOW_AHEAD)
) tester (
    .wrclk(clk),
    .rdclk(clk),
    .aclr(sclr),
    .error(error)
);

reg flushing = 1'b1;
reg fail = 1'b0;
always @(posedge clk) begin
//	#10
	if (!flushing) begin
		if (error)
		begin
            //$display ("ERROR");
			fail = 1'b1;
            //$stop();
		end
	end
end

integer k = 0;
initial begin
    sclr = 1'b1;
	for (k=0; k<10; k=k+1) @(negedge clk);
	flushing = 1'b0;
    sclr = 1'b0;
	for (k=0; k<20000; k=k+1) @(negedge clk);
	if (!fail) $display ("PASS");
	@(negedge clk);
	$stop();	
end

always begin
	#1000 clk = ~clk;
end

endmodule*/

