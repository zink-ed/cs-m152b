`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2026 10:52:25 AM
// Design Name: 
// Module Name: tb
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


module tb;

    reg  [15:0] A, B;
    reg  [3:0]  ALUCtrl;
    wire [15:0] S;
    wire overflow, zero;
    
    integer tests;
    integer failures;
    
    alu dut (
        .A(A),
        .B(B),
        .ALUCtrl(ALUCtrl),
        .S(S),
        .overflow(overflow),
        .zero(zero)
    );
    
    task check_alu;
        input [3:0]  op;
        input [15:0] a_in;
        input [15:0] b_in;
        input [15:0] expected_s;
        input expected_overflow;
        input expected_zero;
        begin
            A = a_in;
            B = b_in;
            ALUCtrl = op;
            #10;
    
            tests = tests + 1;
    
            if ((S !== expected_s) ||
                (overflow !== expected_overflow) ||
                (zero !== expected_zero)) begin
                failures = failures + 1;
                $display(
                    "FAIL ALU op=%b A=%h B=%h S=%h expected=%h OV=%b expected_OV=%b Z=%b expected_Z=%b",
                    op, a_in, b_in, S, expected_s,
                    overflow, expected_overflow, zero, expected_zero
                );
            end else begin
                $display(
                    "PASS ALU op=%b A=%h B=%h S=%h OV=%b Z=%b",
                    op, a_in, b_in, S, overflow, zero
                );
            end
        end
    endtask
    
    initial begin
        tests = 0;
        failures = 0;
        A = 0;
        B = 0;
        ALUCtrl = 0;
    
        $display("==================================");
        $display("       ALU TESTBENCH START");
        $display("==================================");
    
        // 0000: SUBTRACTION
        check_alu(4'b0000, 16'h000A, 16'h0003, 16'h0007, 1'b0, 1'b0); // 10-3 = 7 
        check_alu(4'b0000, 16'h0005, 16'h0005, 16'h0000, 1'b0, 1'b1); // 5-5 = 0
        check_alu(4'b0000, 16'h0003, 16'h000A, 16'hFFF9, 1'b0, 1'b0); // 3-10 = -7
        check_alu(4'b0000, 16'h0000, 16'h0001, 16'hFFFF, 1'b0, 1'b0); // 0-1 = -1
        check_alu(4'b0000, 16'h8000, 16'hFFFF, 16'h8001, 1'b0, 1'b0); // MIN - (-1)
        check_alu(4'b0000, 16'h8000, 16'h8000, 16'h0000, 1'b0, 1'b1); // MIN - MIN
        
        check_alu(4'b0000, 16'h8000, 16'h0001, 16'h7FFF, 1'b1, 1'b0); // MIN - 1
        check_alu(4'b0000, 16'h8000, 16'h0006, 16'h7FFA, 1'b1, 1'b0); // MIN - 6
        check_alu(4'b0000, 16'h7FFF, 16'hFFFF, 16'h8000, 1'b1, 1'b0); // MAX - (-1)
        check_alu(4'b0000, 16'h7FFF, 16'hFFFA, 16'h8000, 1'b1, 1'b0); // MAX - (-6)
        check_alu(4'b0000, 16'h7FFF, 16'h8000, 16'hFFFF, 1'b1, 1'b0); // MAX - MIN 
    
        // 0001: ADDITION
        check_alu(4'b0001, 16'h000A, 16'h0005, 16'h000F, 1'b0, 1'b0);
        check_alu(4'b0001, 16'hFFFF, 16'h0001, 16'h0000, 1'b0, 1'b1);
        check_alu(4'b0001, 16'h8000, 16'h7FFF, 16'hFFFF, 1'b0, 1'b0); // MIN + MAX
        check_alu(4'b0001, 16'h0000, 16'h8000, 16'h8000, 1'b0, 1'b0); // 0 + MIN
        check_alu(4'b0001, 16'hFFFF, 16'h0000, 16'hFFFF, 1'b0, 1'b0); // -1 + 0
                
        check_alu(4'b0001, 16'h7FFF, 16'h0001, 16'h8000, 1'b1, 1'b0); // MAX + 1
        check_alu(4'b0001, 16'h8000, 16'h8000, 16'h0000, 1'b1, 1'b1); // MIN + MIN
        check_alu(4'b0001, 16'h7FFF, 16'h7FFF, 16'hFFFE, 1'b1, 1'b0); // MAX + MAX
    
        // 0010: OR
        check_alu(4'b0010, 16'h00F0, 16'h0F00, 16'h0FF0, 1'b0, 1'b0);
        check_alu(4'b0010, 16'hAAAA, 16'h5555, 16'hFFFF, 1'b0, 1'b0);
        check_alu(4'b0010, 16'h0000, 16'h0000, 16'h0000, 1'b0, 1'b1);
        check_alu(4'b0010, 16'h8000, 16'h0000, 16'h8000, 1'b0, 1'b0);
        check_alu(4'b0010, 16'hF0F0, 16'h0F0F, 16'hFFFF, 1'b0, 1'b0);
        check_alu(4'b0010, 16'h0000, 16'h0000, 16'h0000, 1'b0, 1'b1);
    
        // 0011: AND
        check_alu(4'b0011, 16'h00F0, 16'h0FF0, 16'h00F0, 1'b0, 1'b0);
        check_alu(4'b0011, 16'hF000, 16'h0FFF, 16'h0000, 1'b0, 1'b1);
        check_alu(4'b0011, 16'hAAAA, 16'h5555, 16'h0000, 1'b0, 1'b1);
        check_alu(4'b0011, 16'hFFFF, 16'hFFFF, 16'hFFFF, 1'b0, 1'b0);
        check_alu(4'b0011, 16'h8000, 16'h8000, 16'h8000, 1'b0, 1'b0);
        check_alu(4'b0011, 16'hFFFF, 16'h0000, 16'h0000, 1'b0, 1'b1);
    
        // 0100: DECREMENT
        check_alu(4'b0100, 16'h000A, 16'h007B, 16'h0009, 1'b0, 1'b0);
        check_alu(4'b0100, 16'h0000, 16'h0000, 16'hFFFF, 1'b0, 1'b0);
        check_alu(4'b0100, 16'h8001, 16'hFFFF, 16'h8000, 1'b0, 1'b0);
        check_alu(4'b0100, 16'h7FFF, 16'h8000, 16'h7FFE, 1'b0, 1'b0);
        check_alu(4'b0100, 16'h0001, 16'hFFFF, 16'h0000, 1'b0, 1'b1);
        
        check_alu(4'b0100, 16'h8000, 16'h0001, 16'h7FFF, 1'b1, 1'b0);
    
        // 0101: INCREMENT
        check_alu(4'b0101, 16'h000A, 16'h007B, 16'h000B, 1'b0, 1'b0);
        check_alu(4'b0101, 16'hFFFF, 16'h0000, 16'h0000, 1'b0, 1'b1);
        check_alu(4'b0101, 16'h8000, 16'hFFFF, 16'h8001, 1'b0, 1'b0);
        check_alu(4'b0101, 16'hFFFE, 16'h7FFF, 16'hFFFF, 1'b0, 1'b0);
        check_alu(4'b0101, 16'h0000, 16'hFFFF, 16'h0001, 1'b0, 1'b0);
        
        check_alu(4'b0101, 16'h7FFF, 16'h0000, 16'h8000, 1'b1, 1'b0);
    
        // 0110: TWO'S-COMPLEMENT INVERT
        check_alu(4'b0110, 16'h0005, 16'h007B, 16'hFFFB, 1'b0, 1'b0);
        check_alu(4'b0110, 16'h0000, 16'h0000, 16'h0000, 1'b0, 1'b1);
        check_alu(4'b0110, 16'hFFFF, 16'h1234, 16'h0001, 1'b0, 1'b0);
        check_alu(4'b0110, 16'h0001, 16'hFFFF, 16'hFFFF, 1'b0, 1'b0);
        check_alu(4'b0110, 16'h7FFF, 16'h8000, 16'h8001, 1'b0, 1'b0);
        check_alu(4'b0110, 16'h0000, 16'hFFFF, 16'h0000, 1'b0, 1'b1);
        
        check_alu(4'b0110, 16'h8000, 16'h0000, 16'h8000, 1'b1, 1'b0); // inverting INT-MIN
    
        // 0111: RESERVED
        check_alu(4'b0111, 16'd1, 16'd2,
                  16'h0000, 1'b0, 1'b1);
    
        // 1000: LOGICAL SHIFT LEFT
        check_alu(4'b1000, 16'h0001, 16'h0004, 16'h0010, 1'b0, 1'b0);
        check_alu(4'b1000, 16'h8001, 16'h0001, 16'h0002, 1'b0, 1'b0);
        check_alu(4'b1000, 16'h1234, 16'h0010, 16'h0000, 1'b0, 1'b1);
        check_alu(4'b1000, 16'h0001, 16'h0000, 16'h0001, 1'b0, 1'b0);
        check_alu(4'b1000, 16'h0001, 16'h000F, 16'h8000, 1'b0, 1'b0);
        check_alu(4'b1000, 16'hFFFF, 16'h0001, 16'hFFFE, 1'b0, 1'b0);
        check_alu(4'b1000, 16'h8000, 16'h000F, 16'h0000, 1'b0, 1'b1);
    
        // 1001: SIGNED SET LESS THAN OR EQUAL
        check_alu(4'b1001, 16'h0005, 16'h0005, 16'h0001, 1'b0, 1'b0);
        check_alu(4'b1001, 16'hFFFF, 16'h0001, 16'h0001, 1'b0, 1'b0);
        check_alu(4'b1001, 16'h0005, 16'h0003, 16'h0000, 1'b0, 1'b1);
        check_alu(4'b1001, 16'h8000, 16'h7FFF, 16'h0001, 1'b0, 1'b0);
        check_alu(4'b1001, 16'h7FFF, 16'h8000, 16'h0000, 1'b0, 1'b1);
        check_alu(4'b1001, 16'h8000, 16'hFFFF, 16'h0001, 1'b0, 1'b0); // MIN <= -1
        check_alu(4'b1001, 16'hFFFF, 16'h8000, 16'h0000, 1'b0, 1'b1); // -1 <= MIN is false
        check_alu(4'b1001, 16'h7FFF, 16'h7FFF, 16'h0001, 1'b0, 1'b0); // Equal maximum
    
        // 1010: LOGICAL SHIFT RIGHT
        check_alu(4'b1010, 16'h8000, 16'h0001, 16'h4000, 1'b0, 1'b0);
        check_alu(4'b1010, 16'h8001, 16'h0004, 16'h0800, 1'b0, 1'b0);
        check_alu(4'b1010, 16'h1234, 16'h0010, 16'h0000, 1'b0, 1'b1);
        check_alu(4'b1010, 16'hFFFF, 16'h0000, 16'hFFFF, 1'b0, 1'b0);
        check_alu(4'b1010, 16'h0001, 16'h0001, 16'h0000, 1'b0, 1'b1);
        check_alu(4'b1010, 16'hFFFF, 16'h000F, 16'h0001, 1'b0, 1'b0);
        check_alu(4'b1010, 16'h8000, 16'h0010, 16'h0000, 1'b0, 1'b1);
    
        // 1011: RESERVED
        check_alu(4'b1011, 16'd1, 16'd2,
                  16'h0000, 1'b0, 1'b1);
    
        // 1100: ARITHMETIC SHIFT LEFT
        check_alu(4'b1100, 16'h1000, 16'h0001, 16'h2000, 1'b0, 1'b0);
        check_alu(4'b1100, 16'h0000, 16'h000F, 16'h0000, 1'b0, 1'b1);
        check_alu(4'b1100, 16'h1234, 16'h0010, 16'h0000, 1'b0, 1'b1);
        
        check_alu(4'b1100, 16'h4000, 16'h0001, 16'h8000, 1'b1, 1'b0);
        check_alu(4'b1100, 16'h8000, 16'h0001, 16'h0000, 1'b1, 1'b1);
        check_alu(4'b1100, 16'h7FFF, 16'h0001, 16'hFFFE, 1'b1, 1'b0);
        check_alu(4'b1100, 16'h0001, 16'h000F, 16'h8000, 1'b1, 1'b0);
        check_alu(4'b1100, 16'h8000, 16'h000F, 16'h0000, 1'b1, 1'b1);
        
    
        // 1101: RESERVED
        check_alu(4'b1101, 16'd1, 16'd2,
                  16'h0000, 1'b0, 1'b1);
    
        // 1110: ARITHMETIC SHIFT RIGHT
        check_alu(4'b1110, 16'h8000, 16'h0001, 16'hC000, 1'b0, 1'b0);
        check_alu(4'b1110, 16'h0001, 16'h0001, 16'h0000, 1'b0, 1'b1);
        check_alu(4'b1110, 16'h8000, 16'h0010, 16'hFFFF, 1'b0, 1'b0);
        check_alu(4'b1110, 16'h7FFF, 16'h0004, 16'h07FF, 1'b0, 1'b0);
        check_alu(4'b1110, 16'hFFFF, 16'h000F, 16'hFFFF, 1'b0, 1'b0);
        check_alu(4'b1110, 16'h7FFF, 16'h0001, 16'h3FFF, 1'b0, 1'b0);
        check_alu(4'b1110, 16'h7FFF, 16'h000F, 16'h0000, 1'b0, 1'b1);
        check_alu(4'b1110, 16'h8001, 16'h0001, 16'hC000, 1'b0, 1'b0);
    
        // 1111: RESERVED
        check_alu(4'b1111, 16'd1, 16'd2,
                  16'h0000, 1'b0, 1'b1);
    
        $display("==================================");
        $display("Tests run: %0d", tests);
        $display("Failures : %0d", failures);
    
        if (failures == 0)
            $display("ALL ALU TESTS PASSED");
        else
            $display("ALU TESTS FAILED");
    
        $display("==================================");
        $finish;
    end

endmodule
