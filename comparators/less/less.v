// gribok - 07-27-2022
// Check if "a" is less than "b"

module less (a,b,out);

parameter METHOD = 0;
parameter WIDTH = 12;

input [WIDTH-1:0] a;
input [WIDTH-1:0] b;
output out;
wire out;

generate
    if (METHOD == 0) begin
        ///////////////////////
        // Generic style
        ///////////////////////
        assign out = a < b;
    end else if (METHOD == 1) begin
        //////////////////////////////////
        // carry chain
        //////////////////////////////////
        wire [WIDTH:0] chain;
        assign chain = a - b;
        assign out = chain[WIDTH];
    end else if (METHOD == 2) begin
        //////////////////////////////////
        // optimized carry chain
        //////////////////////////////////
        parameter WIDTH1 = (WIDTH % 3 == 1) ? (WIDTH+1) : WIDTH;
        wire [WIDTH1-1:0] a1;
        wire [WIDTH1-1:0] b1;
        assign a1 = a;
        assign b1 = b;
        
        localparam CHAIN_WIDTH = (WIDTH1-1) * 2 / 3 + 1;
        wire [CHAIN_WIDTH-1:0] left;
        wire [CHAIN_WIDTH-1:0] right;
        wire [CHAIN_WIDTH:0] result;
        
        genvar i;
        for (i = 0; i < CHAIN_WIDTH; i=i+1) begin
            if (i % 2 == 0) begin
                assign left[i] = (a1[i/2*3+1:i/2*3] > b1[i/2*3+1:i/2*3]);
                assign right[i] = (a1[i/2*3+1:i/2*3] < b1[i/2*3+1:i/2*3]);
            end else begin
                assign left[i] = a1[i/2*3+2];
                assign right[i] = b1[i/2*3+2];
            end
        end
        assign result = left - right;
        assign out = result[CHAIN_WIDTH];   
                
    end else if (METHOD == 3) begin
        //////////////////////////////////
        // optimized carry chain using WYSIWYG instances
        //////////////////////////////////
        parameter WIDTH1 = (WIDTH % 3 == 1) ? (WIDTH+1) : WIDTH;
        wire [WIDTH1-1:0] a1;
        wire [WIDTH1-1:0] b1;
        assign a1 = a;
        assign b1 = b;

        localparam CHAIN_WIDTH = (WIDTH1-1) * 2 / 3 + 1;
        wire [CHAIN_WIDTH:0] cin;
        assign cin[0] = 0;
        
        genvar i;
        for (i = 0; i < CHAIN_WIDTH; i=i+1) begin : l1
            if (i % 2 == 0) begin
                tennm_lcell_comb #(
                    .lut_mask(64'h0000_0000_08ce_8421)
                ) w1 (
                    .dataa(b1[i/2*3]),
                    .datab(b1[i/2*3+1]),
                    .datac(a1[i/2*3]),
                    .datad(a1[i/2*3+1]),
                                    
                     // unused
                    .datae(1'b0),
                    .dataf(1'b0),
                    .datag(1'b0),

                    .cin(cin[i]),
                    .sumout(),
                    .cout(cin[i+1])
                );  
            end else begin                
                tennm_lcell_comb #(
                    .lut_mask(64'h0000_0000_00f0_f00f)
                ) w2 (
                    .dataa(),
                    .datab(),
                    .datac(b1[i/2*3+2]),
                    .datad(a1[i/2*3+2]),
                                    
                     // unused
                    .datae(1'b0),
                    .dataf(1'b0),
                    .datag(1'b0),

                    .cin(cin[i]),
                    .sumout(),
                    .cout(cin[i+1])
                );  
            end
        end
                
        tennm_lcell_comb #(
            .lut_mask(64'h0000_0000_0000_0000)
        ) w_last (
            .dataa(),
            .datab(),
            .datac(),
            .datad(),
                            
             // unused
            .datae(1'b0),
            .dataf(1'b0),
            .datag(1'b0),

            .cin(cin[CHAIN_WIDTH]),
            .sumout(out),
            .cout()
        );  
        
    end else if (METHOD == 4) begin
        //////////////////////////////////
        // Optimized unstructured
        //////////////////////////////////
        less_core #(WIDTH) core(.a(a), .b(b), .out(out));
    end 
endgenerate

endmodule
