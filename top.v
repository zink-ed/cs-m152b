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
    input [15:0] A, B,
    input [3:0] SEL,
    output [15:0] S,
    output ADD_OVERFLOW
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
    wire [15:0] INV_RESULT;
    
    wire ADD_COUT, SUB_COUT;
    wire [15:0] ZEROESS = 16'b0;

     inv16 inv(
        .a(A),
        .y(INV_RESULT)
    );
    
    sub16 sub(
        .a(A),
        .b(B),
        .y(SUB_RESULT),
        .cout(SUB_COUT)
    );
    
    add16 add(
        .a(A),
        .b(B),
        .y(ADD_RESULT),
        .cout(ADD_COUT)
    );
    
    sub16 dec(
        .a(A),
        .b(16'b1),
        .y(DEC_RESULT),
        .cout()
    );
    
    add16 inc(
        .a(A),
        .b(16'b1),
        .y(INC_RESULT),
        .cout()
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
    
    and16 and16_inst(
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
    
    
    

    mux16to1_16bit alu_mux(
        .in0(SUB_RESULT), // 0000
        .in1(ADD_RESULT), // 0001
        .in2(OR_RESULT),  // 0010
        .in3(AND_RESULT), // 0011
        .in4(DEC_RESULT), // 0100
        .in5(INC_RESULT), // 0101
        .in6(INV_RESULT), // 0110
        .in7(ZEROESS),           // 0111
        .in8(LSL_RESULT),           // 1000
        .in9(ZEROESS),           // 1001
        .in10(LSR_RESULT),          // 1010
        .in11(ZEROESS),          // 1011
        .in12(ASL_RESULT), // 1100
        .in13(ZEROESS), // 1101
        .in14(ASR_RESULT),          // 1110
        .in15(ZEROESS),           // 1111
        .sel(SEL),
        .out(S)
    );
    
    
    
    // OVERFLOW
    
    wire same_sign;
    wire sign_change;
    xnor (same_sign, A[15], B[15]);
    xor (sign_change, A[15], ADD_RESULT[15]);
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
        for (i = 0; i < 16; i = i + 1) begin : adder_loop
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
    
    wire [15:0] b_tc;
    
    genvar i;
    tci16 tci (
        .a(b),  
        .y(b_tc)
    ); 
            
    add16 add (
        .a(a),
        .b(b_tc),  
        .y(y),
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
module asr16(
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
    
    wire [15:0] inv_a;
    wire cout;
    
    genvar i;
    generate 
        for (i = 0; i < 16; i = i + 1) begin : inv_loop
            not (inv_a[i], a[i]);
        end
    endgenerate
    
    add16 ad16 (
        .a(inv_a), 
        .b(16'b1), 
        .s(y),
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
        for (i = 0; i < 16; i = i + 1) begin : and_loop
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

// MUX

module mux16to1_16bit(
    input [15:0] in0, input [15:0] in1, input [15:0] in2, input [15:0] in3,
    input [15:0] in4, input [15:0] in5, input [15:0] in6, input [15:0] in7,
    input [15:0] in8, input [15:0] in9, input [15:0] in10, input [15:0] in11,
    input [15:0] in12, input [15:0] in13, input [15:0] in14, input [15:0] in15,
    input [3:0] sel,
    output [15:0] out
);

wire [15:0] s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7;

wire [15:0] s2_0, s2_1, s2_2, s2_3;

wire [15:0] s3_0, s3_1;

mux2to1_16bit m1_0 (.a(in0), .b(in1), .sel(sel[0]), .out(s1_0));
mux2to1_16bit m1_1 (.a(in2), .b(in3), .sel(sel[0]), .out(s1_1));
mux2to1_16bit m1_2 (.a(in4), .b(in5), .sel(sel[0]), .out(s1_2));
mux2to1_16bit m1_3 (.a(in6), .b(in7), .sel(sel[0]), .out(s1_3));
mux2to1_16bit m1_4 (.a(in8), .b(in9), .sel(sel[0]), .out(s1_4));
mux2to1_16bit m1_5 (.a(in10), .b(in11), .sel(sel[0]), .out(s1_5));
mux2to1_16bit m1_6 (.a(in12), .b(in13), .sel(sel[0]), .out(s1_6));
mux2to1_16bit m1_7 (.a(in14), .b(in15), .sel(sel[0]), .out(s1_7));

mux2to1_16bit m2_0 (.a(s1_0), .b(s1_1), .sel(sel[1]), .out(s2_0));
mux2to1_16bit m2_1 (.a(s1_2), .b(s1_3), .sel(sel[1]), .out(s2_1));
mux2to1_16bit m2_2 (.a(s1_4), .b(s1_5), .sel(sel[1]), .out(s2_2));
mux2to1_16bit m2_3 (.a(s1_6), .b(s1_7), .sel(sel[1]), .out(s2_3));

mux2to1_16bit m3_0(.a(s2_0), .b(s2_1), .sel(sel[2]), .out(s3_0));
mux2to1_16bit m3_1(.a(s2_2), .b(s2_3), .sel(sel[2]), .out(s3_1));

mux2to1_16bit m4_0(.a(s3_0), .b(s3_1), .sel(sel[3]), .out(out));

endmodule

module mux2to1_16bit(
    input [15:0] a,
    input [15:0] b,
    input sel,
    output[15:0] out
);

wire [15:0] sel_mask;
wire [15:0] sel_n_mask;

// replication operator allowed ?
assign sel_mask = {16{sel}};
assign sel_n_mask = ~sel_mask;

assign out = (a & sel_n_mask) | (b & sel_mask);

endmodule

module inv16(
    input [15:0] a,
    output [15:0] y
);
    genvar i;
    generate 
        for (i = 0; i < 16; i = i + 1) begin : inv_loop
            not (y[i], a[i]);
        end
    endgenerate
endmodule
