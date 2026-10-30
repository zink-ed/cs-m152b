`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2026 10:43:02 AM
// Design Name: 
// Module Name: alu
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
    
    wire [15:0] ZEROESS = 16'b0;
    
    wire [15:0] OVERFLOW_RESULT;
    
    wire ADD_OVERFLOW;
    wire SUB_OVERFLOW;
    wire DEC_OVERFLOW;
    wire INC_OVERFLOW;
    wire TCI_OVERFLOW;
    wire ASL_OVERFLOW;
    
    sub16 sub(
        .a(A),
        .b(B),
        .y(SUB_RESULT),
        .cout(),
        .overflow(SUB_OVERFLOW)
    );
    
    add16 add(
        .a(A),
        .b(B),
        .y(ADD_RESULT),
        .cout(),
        .overflow(ADD_OVERFLOW)
    );
    
    sub16 dec(
        .a(A),
        .b(16'b1),
        .y(DEC_RESULT),
        .cout(),
        .overflow(DEC_OVERFLOW)
    );
    
    add16 inc(
        .a(A),
        .b(16'b1),
        .y(INC_RESULT),
        .cout(),
        .overflow(INC_OVERFLOW)
    );
    
    tci16 tci(
        .a(A),
        .y(TCI_RESULT),
        .overflow(TCI_OVERFLOW)
    );
    
    asl16 asl(
        .a(A),
        .b(B),
        .y(ASL_RESULT),
        .overflow(ASL_OVERFLOW)
    );
    
    asr16 asr(
        .a(A),
        .b(B),
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
        .b(B),
        .y(LSL_RESULT)
    );
    
    lsr16 lsr(
        .a(A),
        .b(B),
        .y(LSR_RESULT)
    );
    
    sle16 sle(
        .a(A),
        .b(B),
        .y(SLE_RESULT)
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
    nor (zero, S[0], S[1], S[2], S[3], S[4], S[5], S[6], S[7], S[8], S[9], S[10], S[11], S[12], S[13], S[14], S[15]);

    // OVERFLOW
    mux16to1_16bit overflow_mux(
        .in0({15'b0, SUB_OVERFLOW}),  // 0000
        .in1({15'b0, ADD_OVERFLOW}),  // 0001
        .in2(ZEROESS),  // 0010
        .in3(ZEROESS),  // 0011
        .in4({15'b0, DEC_OVERFLOW}),  // 0100
        .in5({15'b0, INC_OVERFLOW}),  // 0101
        .in6({15'b0, TCI_OVERFLOW}),  // 0110
        .in7(ZEROESS),  // 0111
        .in8(ZEROESS),  // 1000
        .in9(ZEROESS),  // 1001
        .in10(ZEROESS), // 1010
        .in11(ZEROESS), // 1011
        .in12({15'b0, ASL_OVERFLOW}), // 1100
        .in13(ZEROESS), // 1101
        .in14(ZEROESS), // 1110
        .in15(ZEROESS), // 1111
        .sel(ALUCtrl),
        .out(OVERFLOW_RESULT)
    );
    
    assign overflow = OVERFLOW_RESULT[0];
    
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
        .y(b_tc),
        .overflow()
    ); 
            
    add16 add (
        .a(a),
        .b(b_tc),  
        .y(y),
        .cout(cout),
        .overflow()
    );
    
    wire different_signs;
    wire result_sign_changed;

    xor (different_signs, a[15], b[15]);
    xor (result_sign_changed, a[15], y[15]);
    and (overflow, different_signs, result_sign_changed);
    
endmodule

// 16-bit ARITHMETIC SHIFT LEFT
module asl16(
    input [15:0] a,
    input [15:0] b,
    output [15:0] y,
    output overflow
    );
    
    wire [15:0] s0, s1, s2, s3;
    wire [15:0] s4, s5, s6, s7;
    wire [15:0] s8, s9, s10, s11;
    wire [15:0] s12, s13, s14, s15;

    assign s0  = a;
    assign s1  = {a[14:0], 1'b0};
    assign s2  = {a[13:0], 2'b0};
    assign s3  = {a[12:0], 3'b0};
    assign s4  = {a[11:0], 4'b0};
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
    
    wire [15:0] mux_out;
    
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
        .sel(b[3:0]),
        .out(mux_out)
    );
    
    wire over16;
    or (over16, b[15], b[14], b[13], b[12], b[11], b[10], b[9], b[8], b[7], b[6], b[5], b[4]);
    
    mux2to1_16bit over_mux(
       .a(mux_out),
       .b(16'b0),
       .sel(over16),
       .out(y)
    );
    
    // overflow
    xor (overflow, a[15], y[15]);
 
endmodule


// 16-bit ARITHMETIC SHIFT RIGHT
module asr16(
    input [15:0] a,
    input [15:0] b,
    output [15:0] y
    );
    
    wire [15:0] s0, s1, s2, s3;
    wire [15:0] s4, s5, s6, s7;
    wire [15:0] s8, s9, s10, s11;
    wire [15:0] s12, s13, s14, s15;
    
    assign s0  = a;
    assign s1  = {a[15], a[15:1]};
    assign s2  = {{2{a[15]}}, a[15:2]};
    assign s3  = {{3{a[15]}}, a[15:3]};
    assign s4  = {{4{a[15]}}, a[15:4]};
    assign s5  = {{5{a[15]}}, a[15:5]};
    assign s6  = {{6{a[15]}}, a[15:6]};
    assign s7  = {{7{a[15]}}, a[15:7]};
    assign s8  = {{8{a[15]}}, a[15:8]};
    assign s9  = {{9{a[15]}}, a[15:9]};
    assign s10 = {{10{a[15]}}, a[15:10]};
    assign s11 = {{11{a[15]}}, a[15:11]};
    assign s12 = {{12{a[15]}}, a[15:12]};
    assign s13 = {{13{a[15]}}, a[15:13]};
    assign s14 = {{14{a[15]}}, a[15:14]};
    assign s15 = {{15{a[15]}}, a[15]};
    
    wire [15:0] mux_out;
    
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
        .sel(b[3:0]),
        .out(mux_out)
    );
    
    wire over16;
    or (over16, b[15], b[14], b[13], b[12], b[11], b[10], b[9], b[8], b[7], b[6], b[5], b[4]);
    
    wire [15:0] sign_fill = {16{a[15]}};
    
    mux2to1_16bit over_mux(
        .a(mux_out),
        .b(sign_fill),
        .sel(over16),
        .out(y)
    );
    
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
        .y(y),
        .cout(cout),
        .overflow()
    );
    
    wire lower_zero;
    nor (lower_zero, a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10], a[11], a[12], a[13], a[14]);
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
    input [15:0] b,
    output [15:0] y
    );
    
    wire [15:0] s0, s1, s2, s3;
    wire [15:0] s4, s5, s6, s7;
    wire [15:0] s8, s9, s10, s11;
    wire [15:0] s12, s13, s14, s15;
    
    assign s0  = a;
    assign s1  = {a[14:0], 1'b0};
    assign s2  = {a[13:0], 2'b0};
    assign s3  = {a[12:0], 3'b0};
    assign s4  = {a[11:0], 4'b0};
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
    
    wire [15:0] mux_out;
    
    mux16to1_16bit shift_mux(
        .in0(s0),   .in1(s1),   .in2(s2),   .in3(s3),
        .in4(s4),   .in5(s5),   .in6(s6),   .in7(s7),
        .in8(s8),   .in9(s9),   .in10(s10), .in11(s11),
        .in12(s12), .in13(s13), .in14(s14), .in15(s15),
        .sel(b[3:0]),
        .out(mux_out)
    );
    
    wire over16;
    or (over16, b[15], b[14], b[13], b[12], b[11], b[10], b[9], b[8], b[7], b[6], b[5], b[4]);
    
    mux2to1_16bit over_mux(
        .a(mux_out),
        .b(16'b0),
        .sel(over16),
        .out(y)
    );

endmodule

// 16-bit LOGICAL SHIFT RIGHT
module lsr16(
    input [15:0] a,
    input [15:0] b,
    output [15:0] y
    );
    
    wire [15:0] s0, s1, s2, s3;
    wire [15:0] s4, s5, s6, s7;
    wire [15:0] s8, s9, s10, s11;
    wire [15:0] s12, s13, s14, s15;
    
    assign s0  = a;
    assign s1  = {1'b0, a[15:1]};
    assign s2  = {2'b00, a[15:2]};
    assign s3  = {3'b000, a[15:3]};
    assign s4  = {4'b0000, a[15:4]};
    assign s5  = {5'b00000, a[15:5]};
    assign s6  = {6'b000000, a[15:6]};
    assign s7  = {7'b0000000, a[15:7]};
    assign s8  = {8'b00000000, a[15:8]};
    assign s9  = {9'b000000000, a[15:9]};
    assign s10 = {10'b0000000000, a[15:10]};
    assign s11 = {11'b00000000000, a[15:11]};
    assign s12 = {12'b000000000000, a[15:12]};
    assign s13 = {13'b0000000000000, a[15:13]};
    assign s14 = {14'b00000000000000, a[15:14]};
    assign s15 = {15'b000000000000000, a[15]};
    
    wire [15:0] mux_out;
    
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
        .sel(b[3:0]),
        .out(mux_out)
    );
    
    wire over16;
    or (over16, b[15], b[14], b[13], b[12], b[11], b[10], b[9], b[8], b[7], b[6], b[5], b[4]);
    
    mux2to1_16bit over_mux(
        .a(mux_out),
        .b(16'b0),
        .sel(over16),
        .out(y)
    );

endmodule  

// 16-bit SET LESS THAN OR EQUAL
module sle16(
    input [15:0] a,
    input [15:0] b,
    output[15:0] y
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
    
    nor (a_eq_b, sub_res[0], sub_res[1], sub_res[2], sub_res[3], sub_res[4], sub_res[5], sub_res[6], sub_res[7], sub_res[8], sub_res[9], sub_res[10], sub_res[11], sub_res[12], sub_res[13], sub_res[14], sub_res[15]);
    
    not (not_b, b[15]);
    and (neg_lt_pos, a[15], not_b); // if A neg, B pos
    
    xor (same_sign_xor, a[15], b[15]);
    not (same_sign, same_sign_xor);
    
    xor (corrected_sign, sub_res[15], sub_overflow);
    and (same_sign_lt, same_sign, corrected_sign);
    or (a_lt_b, neg_lt_pos, same_sign_lt);
    
    wire res;
    
    or (res, a_lt_b, a_eq_b);
    
    assign y = {15'b0, res};
    
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
    output [15:0] out
);

    wire [15:0] sel_mask;
    wire [15:0] sel_n_mask;
    
    genvar i;
    generate 
        for (i = 0; i < 16; i = i + 1) begin : mask_gen
            assign sel_mask[i] = sel;
        end
    endgenerate
    
    inv16 inv(
        .a(sel_mask),
        .y(sel_n_mask)
    );
    
    wire [15:0] a_and_sel;
    wire [15:0] b_and_sel;
    
    and16 and_a (.a(a), .b(sel_n_mask), .y(a_and_sel));
    and16 and_b (.a(b), .b(sel_mask),   .y(b_and_sel));
    or16  or_out (.a(a_and_sel), .b(b_and_sel), .y(out));

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
