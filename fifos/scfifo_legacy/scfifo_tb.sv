`timescale 1ps/1ps

module checker #(
    parameter WIDTH = 20,
    parameter LOG_DEPTH = 5,
    parameter NUM_WORDS = 2**LOG_DEPTH,

    parameter ALMOST_FULL_VALUE = 30,
    parameter ALMOST_EMPTY_VALUE = 2,

    parameter SHOW_AHEAD = 1,

    parameter OVERFLOW_CHECKING = 0,
    parameter UNDERFLOW_CHECKING = 0,

    parameter INTENDED_DEVICE_FAMILY = "Agilex",
    parameter ADD_RAM_OUTPUT_REGISTER = 1,
    parameter ALLOW_RWCYCLE_WHEN_FULL = 0,
    parameter LPM_HINT = "RAM_BLOCK_TYPE=M20K",
    parameter ENABLE_ECC = 0,
    parameter USE_EAB = 1,
    parameter TEST_INDEX = 0
) (
    input clk,
    input sclr,
    input flushing,
    output reg fail
);

initial begin
    fail = 0;
end

reg [WIDTH-1:0] data;
wire wrreq;
wire rdreq;
wire wrreq_safe;
wire rdreq_safe;
reg rdreq_r = 0;

wire [WIDTH-1:0] q, q_test;
wire [WIDTH-1:0] expected_result;
wire [LOG_DEPTH-1:0] usedw, usedw_test;
wire empty, empty_test;
wire full, full_test;
wire almost_empty, almost_empty_test;
wire almost_full, almost_full_test;  
wire [1:0] eccstatus, eccstatus_test;
    
scfifo #(
    .lpm_width(WIDTH),
    .lpm_numwords(NUM_WORDS),
    .lpm_widthu(LOG_DEPTH),
    .lpm_showahead(SHOW_AHEAD ? "ON" : "OFF"),
    .allow_rwcycle_when_full(ALLOW_RWCYCLE_WHEN_FULL ? "ON" : "OFF"),
    .add_ram_output_register(ADD_RAM_OUTPUT_REGISTER ? "ON" : "OFF"),
    .almost_full_value(ALMOST_FULL_VALUE),
    .almost_empty_value(ALMOST_EMPTY_VALUE),
    .intended_device_family(INTENDED_DEVICE_FAMILY),
    .overflow_checking(OVERFLOW_CHECKING ? "ON" : "OFF"),
    .underflow_checking(UNDERFLOW_CHECKING ? "ON" : "OFF"),
    .lpm_hint(LPM_HINT),
    .lpm_type("scfifo"),
    .enable_ecc(ENABLE_ECC ? "TRUE" : "FALSE"),
    .use_eab("ON") // For some reason scfifo changes functionality if use_eab=OFF. So we do not test this mode.
) dut_scfifo (
    .clock(clk),
    .sclr(sclr),
    .aclr(1'b0),
    .data(data),
    .wrreq(wrreq),
    .rdreq(rdreq_safe), // For some reason underflow_checking does not work for scfifo. So we do not send incorrect rdreq to it
    .q(q),
    .usedw(usedw),
    .empty(empty),
    .full(full),
    .almost_empty(almost_empty),
    .almost_full(almost_full),
    .eccstatus(eccstatus)
);


scfifo_legacy #(
    .lpm_width(WIDTH), 
    .lpm_numwords(NUM_WORDS),
    .lpm_widthu(LOG_DEPTH), 
    .lpm_showahead(SHOW_AHEAD ? "ON" : "OFF"),
    .allow_rwcycle_when_full(ALLOW_RWCYCLE_WHEN_FULL ? "ON" : "OFF"),
    .add_ram_output_register(ADD_RAM_OUTPUT_REGISTER ? "ON" : "OFF"),
    .almost_full_value(ALMOST_FULL_VALUE), 
    .almost_empty_value(ALMOST_EMPTY_VALUE),
    .intended_device_family(INTENDED_DEVICE_FAMILY),
    .overflow_checking(OVERFLOW_CHECKING ? "ON" : "OFF"),
    .underflow_checking(UNDERFLOW_CHECKING ? "ON" : "OFF"),
    .lpm_hint(LPM_HINT),
    .lpm_type("scfifo"),
    .enable_ecc(ENABLE_ECC ? "TRUE" : "FALSE"),
    .use_eab(USE_EAB ? "ON" : "OFF")
) dut (
    .clock(clk),
    .sclr(sclr),
    .aclr(1'b0),
    .data(data),
    .wrreq(wrreq),
    .rdreq(rdreq),
    .q(q_test),
    .usedw(usedw_test),
    .empty(empty_test),
    .full(full_test),
    .almost_empty(almost_empty_test),
    .almost_full(almost_full_test),
    .eccstatus(eccstatus_test)
);

initial begin
    data = 10;
end

integer write_counter = 0;
integer read_counter = 0;
integer read_counter_r = 0;
integer counter = 0;
always @(posedge clk) begin
    data <= data + wrreq;
	//sclr <= (($random & 31) == 0);
    rdreq_r <= rdreq_safe;    
    counter <= counter + 1;
end

assign wrreq = (counter >= 20) & ($random & 1) & (~full | OVERFLOW_CHECKING);
assign rdreq = (counter >= 20) & ($random & 1) & (~empty | UNDERFLOW_CHECKING);

assign wrreq_safe = OVERFLOW_CHECKING ? wrreq & ~full : wrreq;
assign rdreq_safe = UNDERFLOW_CHECKING ? rdreq & ~empty : rdreq;

wire ready;

assign ready = SHOW_AHEAD ? rdreq_safe : rdreq_r;

integer full_counter = 0;
integer empty_counter = 0;

always @(posedge clk) begin

    if (full)
        full_counter <= full_counter + 1;
    if (empty)
        empty_counter <= empty_counter + 1;
        
	if (!flushing) begin
		if (/*ready &&*/ (q !== {WIDTH{1'bx}}) && (q_test !== q) || (usedw_test !== usedw) || (empty !== empty_test) || (full !== full_test) || (almost_empty !== almost_empty_test) || (almost_full !== almost_full_test)  || (eccstatus !== eccstatus_test) ) 
		begin
            $display ("ERROR: ready=%d: we=%d din=%d; re=%d q=%b vs q_test=%b / empty=%d vs %d, full=%d vs %d / sclr=%d / usedw: %d vs %d / AlmostEmpty: %d vs %d / AlmostFull: %d vs %d / eccstatus: %d vs %d : TEST_INDEX=%d",
                    ready, wrreq, data, rdreq, q, q_test, empty, empty_test, full, full_test, sclr, 
                    usedw, usedw_test,
                    almost_empty, almost_empty_test,
                    almost_full, almost_full_test,
                    eccstatus, eccstatus_test, TEST_INDEX
                );

			fail = 1'b1;
            $stop();
		end
        /*else
        begin
            $display ("       ready=%d: we=%d din=%d; re=%d q=%d vs q_test=%d / empty=%d vs %d, full=%d vs %d / sclr=%d / usedw: %d vs %d / AlmostEmpty: %d vs %d / AlmostFull: %d vs %d / eccstatus: %d vs %d",
                    ready, wrreq, data, rdreq, q, q_test, empty, empty_test, full, full_test, sclr, 
                    usedw, usedw_test,
                    almost_empty, almost_empty_test,
                    almost_full, almost_full_test,
                    eccstatus, eccstatus_test
                );
        end*/
	end
end
endmodule




module scfifo_tb ();

reg clk = 1'b0;
reg sclr = 0;

reg flushing = 1'b1;

localparam TEST_NUM = 512;
wire [TEST_NUM-1:0] fail;

genvar i;
generate
for (i = 0; i < TEST_NUM; i=i+1) begin
    checker #(.WIDTH(20), .LOG_DEPTH(5+i[4]*i[2:0]), .NUM_WORDS(2**(5+i[4]*i[2:0])-i[8]), .ALMOST_FULL_VALUE(2**(5+i[4]*i[2:0])-i[8:5]), .ALMOST_EMPTY_VALUE(i[7:4]), 
              .SHOW_AHEAD(i[2]), .OVERFLOW_CHECKING(i[1]), .UNDERFLOW_CHECKING(i[0]), 
              .INTENDED_DEVICE_FAMILY("Agilex"), .ADD_RAM_OUTPUT_REGISTER(i[3]), .ALLOW_RWCYCLE_WHEN_FULL(i[6] & i[1]), 
              .LPM_HINT(i[4] ? "RAM_BLOCK_TYPE=M20K" : "RAM_BLOCK_TYPE=MLAB"), .ENABLE_ECC(i[5] & i[4]), .USE_EAB(i[7]), .TEST_INDEX(i)
    ) dut (.clk(clk), .sclr(sclr), .flushing(flushing), .fail(fail[i]));
end
endgenerate

integer k = 0;
initial begin
    sclr = 1'b1;
	for (k=0; k<10; k=k+1) @(negedge clk);
	flushing = 1'b0;
    sclr = 1'b0;
	for (k=0; k<10000; k=k+1) @(negedge clk);
    
	if (fail == 0) 
        $display ("PASS");
    else
        $display ("FAIL: %b", fail);
    
	@(negedge clk);
	$stop();	
end

always begin
	#1000 clk = ~clk;
end

endmodule
