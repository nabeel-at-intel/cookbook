module less_core #(
    parameter WIDTH = 3,
    parameter LSB = 1
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output out,
    output eq
);

generate
    if (WIDTH < 4) begin
        if (LSB)
            assign out = (a < b);
        else
            assign out = ((a & 3'b110) < b);        
        assign eq = (a == b);
    end else begin
        localparam WIDTH3 = (WIDTH+3)/4;
        localparam WIDTH2 = (WIDTH-WIDTH3+2)/3;
        localparam WIDTH1 = (WIDTH-WIDTH3-WIDTH2+1)/2;
        localparam WIDTH0 = WIDTH-WIDTH3-WIDTH2-WIDTH1;
        
        wire out0 /* synthesis keep */, out1 /* synthesis keep */, out2 /* synthesis keep */, out3 /* synthesis keep */;
        wire eq0 /* synthesis keep */, eq1 /* synthesis keep */, eq2 /* synthesis keep */, eq3 /* synthesis keep */;
        
        less_core #(.WIDTH(WIDTH0), .LSB(LSB)) core0 (.a(a[WIDTH0-1:0]), .b(b[WIDTH0-1:0]), .out(out0), .eq(eq0));
        less_core #(.WIDTH(WIDTH1), .LSB(0)) core1 (.a(a[WIDTH1+WIDTH0-1:WIDTH0]), .b(b[WIDTH1+WIDTH0-1:WIDTH0]), .out(out1), .eq(eq1));
        less_core #(.WIDTH(WIDTH2), .LSB(0)) core2 (.a(a[WIDTH-WIDTH3-1:WIDTH0+WIDTH1]), .b(b[WIDTH-WIDTH3-1:WIDTH0+WIDTH1]), .out(out2), .eq(eq2));
        less_core #(.WIDTH(WIDTH3), .LSB(0)) core3 (.a(a[WIDTH-1:WIDTH-WIDTH3]), .b(b[WIDTH-1:WIDTH-WIDTH3]), .out(out3), .eq(eq3));
                
        assign out = eq3 ? (eq2 ? (eq1 ? out0 : out1) : out2) : out3;
        assign eq = eq0 & eq1 & eq2 & eq3;
        
    end
    
endgenerate
endmodule
