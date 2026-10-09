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
    input [3:0] ALUCtrl,
    output [15:0] S,
    output overflow,
    output zero
    );
    
    wire [15:0] SUB_RESULT;
    wire [15:0] ADD_RESULT;
    wire [15:0] DEC_RESULT;
    wire [15:0] INC_RESULT;
    wire [15:0] TCI_RESULT;
    wire [15:0] ASL_RESULT;
    wire [15:0] ASR_RESULT;
    wire [15:0] OR_RESULT;
    wire [15:0] AND_RESULT;
    wire [15:0] LSL_RESULT;
    wire [15:0] LSR_RESULT;
    wire [15:0] SLE_RESULT;
    
    wire ADD_COUT, SUB_COUT;
    wire [15:0] ZEROESS = 16'b0;
    
    wire ADD_OVERFLOW;
    wire SUB_OVERFLOW;
    wire TCI_OVERFLOW;
    
    sub16 sub(
        .a(A),
        .b(B),
        .y(SUB_RESULT),
        .cout(SUB_COUT),
        .overflow(SUB_OVERFLOW)
    );
    
    add16 add(
        .a(A),
        .b(B),
        .y(ADD_RESULT),
        .cout(ADD_COUT),
        .overflow(ADD_OVERFLOW)
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
    
    tci16 tci(
        .a(A),
        .y(TCI_RESULT),
        .overflow(TCI_OVERFLOW)
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
    
    sle16 sle(
        .a(A),
        .b(B),
        .res(SLE_RESULT)
    );
    
    mux16to1_16bit alu_mux(
        .in0(SUB_RESULT), // 0000
        .in1(ADD_RESULT), // 0001
        .in2(OR_RESULT),  // 0010
        .in3(AND_RESULT), // 0011
        .in4(DEC_RESULT), // 0100
        .in5(INC_RESULT), // 0101
        .in6(TCI_RESULT), // 0110
        .in7(ZEROESS),    // 0111
        .in8(LSL_RESULT), // 1000
        .in9(SLE_RESULT), // 1001
        .in10(LSR_RESULT),// 1010
        .in11(ZEROESS),   // 1011
        .in12(ASL_RESULT),// 1100
        .in13(ZEROESS),   // 1101
        .in14(ASR_RESULT),// 1110
        .in15(ZEROESS),   // 1111
        .sel(ALUCtrl),
        .out(S)
    );
    
    // ZERO
    nor (zero, S[15:0]);

    // OVERFLOW
    mux16to1_16bit overflow_mux(
        .in0(SUB_OVERFLOW),  // 0000
        .in1(ADD_OVERFLOW),  // 0001
        .in2(ZEROESS),  // 0010
        .in3(ZEROESS),  // 0011
        .in4(ZEROESS),  // 0100
        .in5(ZEROESS),  // 0101
        .in6(TCI_OVERFLOW),  // 0110
        .in7(ZEROESS),  // 0111
        .in8(ZEROESS),  // 1000
        .in9(ZEROESS),  // 1001
        .in10(ZEROESS), // 1010
        .in11(ZEROESS), // 1011
        .in12(ZEROESS), // 1100
        .in13(ZEROESS), // 1101
        .in14(ZEROESS), // 1110
        .in15(ZEROESS), // 1111
        .sel(ALUCtrl),
        .out(S)
    );
    
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
    output cout,
    output overflow
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
    
    // overflow
    wire same_sign;
    wire sign_change;
    
    xnor (same_sign, a[15], b[15]);
    xor (sign_change, a[15], y[15]);
    
    and (overflow, same_sign, sign_change);
    
endmodule

// 16-bit SUBTRACTION
module sub16(
    input [15:0] a,
    input [15:0] b,
    output [15:0] y,
    output cout,
    output overflow
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
        .cout(cout),
        .overflow(overflow)
    );
    
endmodule

// 16-bit ARITHMETIC SHIFT LEFT
module asl16(
    input [15:0] a,
    input [15:0] b,
    output [15:0] y
    );
    
    wire [15:0] s0, s1, s2, s3;
    wire [15:0] s4, s5, s6, s7;
    wire [15:0] s8, s9, s10, s11;
    wire [15:0] s12, s13, s14, s15;

    assign s0  = a;
    assign s1  = {a[14:0], 1'b0};
    assign s2  = {a[13:0], 2'b00};
    assign s3  = {a[12:0], 3'b000};
    assign s4  = {a[11:0], 4'b0000};
    assign s5  = {a[10:0], 5'b0};
    assign s6  = {a[9:0], 6'b0};
    assign s7  = {a[8:0], 7'b0};
    assign s8  = {a[7:0], 8'b0};
    assign s9  = {a[6:0], 9'b0};
    assign s10 = {a[5:0], 10'b0};
    assign s11 = {a[4:0], 11'b0};
    assign s12 = {a[3:0], 12'b0};
    assign s13 = {a[2:0], 13'b0};
    assign s14 = {a[1:0], 14'b0};
    assign s15 = {a[0], 15'b0};
    
    wire over16;
    or (over16, b[15:4]);
    
    
    
    mux16to1_16bit overflow_mux(
        .in0(s0),  // 0000
        .in1(s1),  // 0001
        .in2(s2),  // 0010
        .in3(s3),  // 0011
        .in4(s4),  // 0100
        .in5(s5),  // 0101
        .in6(s6),  // 0110
        .in7(s7),  // 0111
        .in8(s8),  // 1000
        .in9(s9),  // 1001
        .in10(s10), // 1010
        .in11(s11), // 1011
        .in12(s12), // 1100
        .in13(s13), // 1101
        .in14(s14), // 1110
        .in15(s15), // 1111
        .sel(ALUCtrl),
        .out(S)
    );
    
    // overflow
    
    
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
    output [15:0] y,
    output overflow
    );
    
    wire [15:0] inv_a;
    wire cout;
    
    inv16 inv (
        .a(a),
        .y(inv_a)
    );
    
    add16 ad16 (
        .a(inv_a), 
        .b(16'b1), 
        .s(y),
        .cout(cout)
    );
    
    wire lower_zero;
    nor (lower_zero, a[14:0]);
    and (overflow, a[15], lower_zero);
    
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

// 16-bit SET LESS THAN OR EQUAL
module sle16(
    input [15:0] a,
    input [15:0] b,
    output[15:0] res
    );
    
    wire [15:0] sub_res;
    wire sub_cout;
    wire sub_overflow;
    
    // A - B
    sub16 sub(
        .a(a),
        .b(b),
        .y(sub_res),
        .cout(sub_cout),
        .overflow(sub_overflow)
    );
    
    wire not_b;
    wire neg_lt_pos;
    wire same_sign_xor;
    wire same_sign;
    wire corrected_sign;
    wire same_sign_lt;
    
    wire a_lt_b;
    wire a_eq_b;
    
    not (not_b, b[15]);
    and (neg_lt_pos, a[15], not_b); // if A neg, B pos
    
    xor (same_sign_xor, a[15], b[15]);
    not (same_sign, same_sign_xor);
    
    xor (corrected_sign, sub_res[15], sub_overflow);
    and (same_sign_lt, same_sign, corrected_sign);
    or (a_lt_b, neg_lt_pos, same_sign_lt);
    
    or (res[0], a_lt_b, a_eq_b);
    
    genvar i;
    generate 
        for (i = 1; i < 16; i = i + 1) begin
            assign res[i] = res[0];
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
    
    genvar i;
    generate 
        for (i = 0; i < 16; i = i + 1) begin
            assign sel_mask[i] = sel;
        end
    endgenerate
    
    inv16 inv(
        .a(sel_mask),
        .y(sel_n_mask)
    );
    
    wire a_and_sel;
    wire b_and_sel;
    
    and (a_and_sel, a, sel_n_mask);
    and (b_and_sel, b, sel_mask);
    or (out, a_and_sel, b_and_sel);

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
