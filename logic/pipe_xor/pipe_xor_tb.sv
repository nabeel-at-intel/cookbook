`timescale 1ps/1ps

module pipe_xor_tb ();
parameter WIDTH = 100;

reg clk = 1'b0;

reg [WIDTH-1:0] a = 0;

wire out;

parameter LATENCY = (WIDTH <= 6) ? 1 : (
                    (WIDTH <= 36) ? 2 : (
                    (WIDTH <= 216) ? 3 : 4));
reg out_etalon[0:LATENCY-1];

reg [31:0] counter = 0;
always @(negedge clk) begin
    a = (a << 32) ^ $random & {32{1'b1}};
    counter <= counter + 1;
end

integer i;
always @(negedge clk) begin
    #20 
    out_etalon[0] <= ^a;
    for (i = 1; i < LATENCY; i=i+1) begin
        out_etalon[i] <= out_etalon[i-1];
    end    
end

reg flushing = 1'b1;
reg fail = 1'b0;

pipe_xor #(.WIDTH(WIDTH)) dut (.*);

always @(posedge clk) begin
    #20
    if (!flushing) 
    begin
        if (out !== out_etalon[LATENCY-1])
        begin       
            $display ("%b: %d, expected %d", a, out, out_etalon[LATENCY-1]);
            fail = 1'b1;
            $stop();
        end
        else
            $display ("%b: %d", a, out);
    end
end

integer n = 0;
initial begin
    for (n=0; n<10; n=n+1) begin
        @(negedge clk);
    end
    flushing = 1'b0;
    for (n=0; n<1000 ; n=n+1) begin
        @(negedge clk);
    end
    if (!fail) $display ("PASS");
    @(negedge clk);
    $stop();
end

always begin
    #1000 clk = ~clk;
end

endmodule

