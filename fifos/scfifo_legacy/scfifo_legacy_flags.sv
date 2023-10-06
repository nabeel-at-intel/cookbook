// Copyright 2023 Intel Corporation. 
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

module scfifo_legacy_flags #(
    parameter LOG_DEPTH      = 5,
    parameter NUM_WORDS = 2**LOG_DEPTH,
    parameter ALMOST_FULL_VALUE = 30,
    parameter ALMOST_EMPTY_VALUE = 2,
    parameter OVERFLOW_CHECKING = 0,
    parameter UNDERFLOW_CHECKING = 0,
    parameter ADD_RAM_OUTPUT_REGISTER = 1,
    parameter ALLOW_RWCYCLE_WHEN_FULL = 0
)(
    input clock,
    input aclr,
    input sclr,
    input [LOG_DEPTH-1:0] capacity,
    input wrreq,
    input rdreq,
    output reg empty,
    output reg full,
    output reg almost_empty,
    output reg almost_full,
    input wrreq_safe,
    input rdreq_safe
);

initial begin 
    empty = 1;
    full = 0;
    almost_empty = 1;
    almost_full = 0;
end

always @(posedge clock or posedge aclr) begin
    if (aclr) begin
        empty <= 1;
        full <= 0;
        almost_empty <= 1;
        almost_full <= 0;      
    end else if (sclr) begin
        empty <= 1;
        full <= 0;
        almost_empty <= 1;
        almost_full <= 0;  
    end else begin
        if (NUM_WORDS < 2 ** LOG_DEPTH) begin

            if (ADD_RAM_OUTPUT_REGISTER == 0)        
                empty <= (capacity == 0) && (wrreq == 0) || (capacity == 1) && (rdreq == 1) && (wrreq == 0);
            else
                empty <= (capacity == 0) || (capacity == 1) && (rdreq_safe == 1);
                
            if (ALLOW_RWCYCLE_WHEN_FULL)    
                full <= (capacity == NUM_WORDS) && ((rdreq == 0) || (wrreq == 1)) || (capacity == NUM_WORDS - 1) && (rdreq == 0) && (wrreq == 1);
            else
                full <= (capacity == NUM_WORDS) && (rdreq == 0) || (capacity == NUM_WORDS - 1) && (rdreq == 0) && (wrreq == 1);
            
            almost_empty <=
                (capacity < (ALMOST_EMPTY_VALUE-1)) || 
                (capacity == (ALMOST_EMPTY_VALUE-1)) && ((wrreq == 0) || (rdreq_safe == 1)) || 
                (capacity == ALMOST_EMPTY_VALUE) && (rdreq_safe == 1) && (wrreq == 0);
            almost_full <= 
                (capacity > ALMOST_FULL_VALUE) ||
                (capacity == ALMOST_FULL_VALUE) && ((rdreq == 0) || (wrreq_safe == 1)) ||
                (capacity == ALMOST_FULL_VALUE - 1) && (rdreq == 0) && (wrreq_safe == 1);    
        end else begin
        
            if (ADD_RAM_OUTPUT_REGISTER == 0)        
                empty <= ({full, capacity} == 0) && (wrreq == 0) || (capacity == 1) && (rdreq == 1) && (wrreq == 0);
            else
                empty <= ({full, capacity} == 0) || (capacity == 1) && (rdreq_safe == 1);
                
            if (ALLOW_RWCYCLE_WHEN_FULL)    
                full <= ({full, capacity} == NUM_WORDS) && ((rdreq == 0) || (wrreq == 1)) || (capacity == NUM_WORDS - 1) && (rdreq == 0) && (wrreq == 1);
            else
                full <= ({full, capacity} == NUM_WORDS) && (rdreq == 0) || (capacity == NUM_WORDS - 1) && (rdreq == 0) && (wrreq == 1);

            almost_empty <=
                ({full, capacity} < (ALMOST_EMPTY_VALUE-1)) || 
                ({full, capacity} == (ALMOST_EMPTY_VALUE-1)) && ((wrreq == 0) || (rdreq_safe == 1)) || 
                (capacity == ALMOST_EMPTY_VALUE) && (rdreq_safe == 1) && (wrreq == 0);
            almost_full <= 
                ({full, capacity} > ALMOST_FULL_VALUE) ||
                (capacity == ALMOST_FULL_VALUE) && ((rdreq == 0) || (wrreq_safe == 1)) ||
                (capacity == ALMOST_FULL_VALUE - 1) && (rdreq == 0) && (wrreq_safe == 1);    
        end            
    end
end
endmodule