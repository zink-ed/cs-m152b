`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2026 10:28:16 AM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(

    );
endmodule


module alu(
    input A,
    input B,
    output S
    );
    
    wire [15:0] SUB_RESULT;
    wire [15:0] ADD_RESULT;
    wire [15:0] DEC_RESULT;
    wire [15:0] INC_RESULT;
    wire [15:0] ASL_RESULT;
    wire [15:0] ASR_RESULT;
    wire [15:0] OR_RESULT;
    wire [15:0] AND_RESULT;
    wire [15:0] LSL_RESULT;
    wire [15:0] LSR_RESULT;
    
    wire COUT;
    
    sub16 sub(
        .a(A),
        .b(B),
        .y(SUB_RESULT),
        .cout(COUT)
    );
    
    add16 add(
        .a(A),
        .b(B),
        .y(ADD_RESULT),
        .cout(COUT)
    );
    
    sub16 dec(
        .a(A),
        .b(1'b1),
        .y(DEC_RESULT),
        .cout(COUT)
    );
    
    add16 inc(
        .a(A),
        .b(1'b1),
        .y(DEC_RESULT),
        .cout(COUT)
    );
    
    asl16 asl(
        .a(A),
        .y(ASL_RESULT)
    );
    
    asr16 asr(
        .a(A),
        .y(ASR_RESULT)
    );
    
    or16 or16(
        .a(A),
        .b(B),
        .y(OR_RESULT)
    );
    
    and16 and16(
        .a(A),
        .b(B),
        .y(AND_RESULT)
    );
    
    lsl16 lsl(
        .a(A),
        .y(LSL_RESULT)
    );
    
    lsr16 lsr(
        .a(A),
        .y(LSR_RESULT)
    );
    
    
    // ZERO FLAG
    
    
    
    // OVERFLOW
    
    wire same_sign;
    wire sign_change;
    xnor (same_sign, A[15], B[15]);
    xor (sign_change, A[15], ADD_RESULT);
    and (ADD_OVERFLOW, same_sign, sign_change);
    
    
endmodule


// 1-bit full adder
module adder(
    input a,
    input b,
    input cin,
    output s,
    output cout
    );
    
    wire a_xor_b;
    wire cin_and_axb, a_and_b;
    
    xor (a_xor_b, a, b);
    xor (s, cin, a_xor_b);
    
    and (cin_and_axb, cin, a_xor_b);
    and (a_and_b, a, b);
    or (cout, cin_and_axb, a_and_b);
    
endmodule

// 16-bit ADDITION
module add16(
    input [15:0] a,
    input [15:0] b,
    output [15:0] y,
    output cout
    );
    
    wire [16:0] c;
    assign c[0] = 0;
    assign cout = c[16];
    
    genvar i;
    
    generate 
        for (i = 0; i < 16; i = i + 1) begin
            adder ad (
                .a(a[i]), 
                .b(b[i]), 
                .cin(c[i]),
                .s(y[i]),
                .cout(c[i+1])
            );
        end
    endgenerate
    
endmodule

// 16-bit SUBTRACTION
module sub16(
    input [15:0] a,
    input [15:0] b,
    output [15:0] y,
    output cout
    );
    
    wire [15:0] binv;
    
    genvar i;
    
    tci16 tci (
        .b(binv),  
        .s(y)
    ); 
            
    add16 add (
        .a(a[i]),
        .b(binv[i]),  
        .s(y[i]),
        .cout(cout)
    );
    
endmodule

// 16-bit ARITHMETIC SHIFT LEFT
module asl16(
    input [15:0] a,
    output [15:0] y
    );
    
    assign y[0] = 1'b0;
    
    genvar i;
    
    generate 
        for (i = 1; i < 16; i = i + 1) begin
            assign y[i] = a[i-1];
        end
    endgenerate
    
endmodule


// 16-bit ARITHMETIC SHIFT RIGHT
module inc16(
    input [15:0] a,
    output [15:0] y
    );
    
    assign y[15] = a[15];
    
    genvar i;
    
    generate 
        for (i = 0; i < 15; i = i + 1) begin
            assign y[i] = a[i+1];
        end
    endgenerate

endmodule  

// 16-bit TWO'S COMPLIMENT INVERT
module tci16(
    input [15:0] a,
    output [15:0] y
    );
    
    wire [15:0] temp;
    wire cout;
    
    genvar i;
    
    generate 
        for (i = 0; i < 16; i = i + 1) begin
            not (a[i], temp[i]);
        end
    endgenerate
    
    adder16 ad16 (
        .a(a[i]), 
        .b(16'b1), 
        .s(y[i]),
        .cout(cout)
    );
    
endmodule

// 16-bit AND
module and16(
    input [15:0] a,
    input [15:0] b,
    output [15:0] y
    );
    
    genvar i;
    
    generate 
        for (i = 0; i < 16; i = i + 1) begin
            and (y[i], a[i], b[i]);
        end
    endgenerate
    
endmodule

// 16-bit OR
module or16(
    input [15:0] a,
    input [15:0] b,
    output [15:0] y
    );
    
    genvar i;
    
    generate 
        for (i = 0; i < 16; i = i + 1) begin
            or (y[i], a[i], b[i]);
        end
    endgenerate
    
endmodule

// 16-bit LOGICAL SHIFT LEFT
module lsl16(
    input [15:0] a,
    output [15:0] y
    );
    
    assign y[0] = 1'b0;
    
    genvar i;
    
    generate 
        for (i = 1; i < 16; i = i + 1) begin
            assign y[i] = a[i-1];
        end
    endgenerate
    
endmodule

// 16-bit LOGICAL SHIFT RIGHT
module lsr16(
    input [15:0] a,
    output [15:0] y
    );
    
    assign y[15] = 1'b0;
    
    genvar i;
    
    generate 
        for (i = 0; i < 15; i = i + 1) begin
            assign y[i] = a[i+1];
        end
    endgenerate
    
endmodule   

