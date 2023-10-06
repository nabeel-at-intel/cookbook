// Quartus Binary Adder Tree 
module adder_tree_2to1 #(
    parameter SIZE = 10,
    parameter NUM = 1024
)(
    input clk,
    input [SIZE-1:0] din[0:NUM-1],
    output [SIZE-1:0] dout

);

genvar i;
generate

    if (NUM == 1) begin
        assign dout = din[0];
    end if (NUM == 2) begin
        reg [SIZE-1:0] z_r;
        always @(posedge clk) begin : case2
            z_r <= din[0] + din[1];
        end
        assign dout = z_r;
    end else if (NUM == 3) begin : case3
        reg [SIZE-1:0] z_r;
        reg [SIZE-1:0] a01_r;
        reg [SIZE-1:0] a2_r;
        always @(posedge clk) begin
            a01_r <= din[0] + din[1];
            a2_r <= din[2];
            z_r <= a01_r + a2_r;
        end
        assign dout = z_r;
    end else if (NUM > 3) begin : caseN
        localparam NUM_OUT = (NUM + 1) / 2;

        wire [SIZE-1:0] w[0:NUM_OUT-1];
        reg [SIZE-1:0] r[0:NUM_OUT-1];
        for (i = 0; i < NUM/2; i=i+1) begin : for0
            assign w[i] = din[2*i] + din[2*i+1];
        end

        if (NUM % 2 == 1) begin : case2N_plus1
            assign w[NUM_OUT-1] = din[NUM-1];
        end

        always @(posedge clk) begin
            r <= w;
        end
        adder_tree_2to1 #(.SIZE(SIZE), .NUM(NUM_OUT)) inst_tree (
            .clk(clk),
            .din(r),
            .dout(dout)
        );     
        
    end
endgenerate    
endmodule
