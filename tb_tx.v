`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2026 11:04:36 AM
// Design Name: 
// Module Name: tb_tx
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


module tb_tx;

    localparam integer FULL = 1_000_000 / 9_600;
    localparam integer HALF = FULL / 2;
    
    reg clk;
    reg rst;
    reg start;
    reg [7:0] data;
    wire tx_line;
    
    integer errors;
    integer i;
    
    tx uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data(data),
        .tx_line(tx_line)
    );
    
    // 100 MHz clock: 10 ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;
    
    // Transmit one byte and verify the complete UART frame.
    task test_frame;
        input [7:0] test_byte;
        integer b;
        
        begin
            // Set up data and request transmission
            @(negedge clk);
            data = test_byte;
            start = 1'b1;
            
            @(negedge clk);
            start = 1'b0;
            
            // Wait for falling edge of the start bit
            @(negedge tx_line);
            
            // Sample the middle of the start bit
            repeat (HALF) @(posedge clk);
            #1;
            
            if (tx_line !== 1'b0) begin
                $display("FAIL: start bit should be 0");
                errors = errors + 1;
            end else begin
                $display("PASS: start bit = 0");
        end
        
        // Sample all eight data bits, LSB first
        for (b = 0; b<8; b = b + 1) begin
            repeat (FULL) @(posedge clk);
            #1;
            
            if (tx_line !== test_byte[b]) begin
                $display(
                    "FAIL: byte=%h bit=%0d expected=%b got=%b",
                    test_byte, b, test_byte[b], tx_line
                );
                errors = errors + 1;
            end else begin
                $display(
                    "PASS: byte=%h bit[%0d]=%b",
                    test_byte, b, tx_line
                );
            end
        end
        
        // Sample the middle of the stop bit
        repeat (FULL) @(posedge clk);
        #1;
        
        if (tx_line !== 1'b1) begin
            $display("FAIL: stop bit should be 1");
            errors = errors + 1;
        end else begin
            $display("PASS: stop bit = 1");
        end
        
        // Wait for transmitter to return to idle
        repeat (HALF + 5) @(negedge clk);
        
        if (tx_line !== 1'b1) begin
            $display("FAIL: TX line did not return to idle");
            errors = errors + 1;
        end else begin
            $display("PASS: TX line returned to idle");
        end
        
            $display("Finished frame for byte %h\n", test_byte);
        end
    endtask
    
    initial begin
        errors = 0;
        rst = 1'b1;
        start = 1'b0;
        data = 8'h00;
        
        // Reset
        repeat (5) @(negedge clk);
        rst = 1'b0;
        repeat (2) @(negedge clk);
        
        if (tx_line !== 1'b1) begin
            $display("FAIL: TX line should idle high after reset");
            errors = errors + 1;
        end else begin
            $display("PASS: reset establishes idle-high output");
        end
        
        // Test 1: all zeros
        test_frame(8'h00);
        
        // Test 2: all ones
        test_frame(8'hFF);
        
        // Test 3: alternating patterns
        test_frame(8'hAA);
        test_frame(8'h55);
        
        // Test 4: individual edge bits
        test_frame(8'h01);
        test_frame(8'h80);
        
        // Test 5: arbitrary data
        test_frame(8'hA6);
        test_frame(8'hC3);
        
        // Test 6: consecutive frames
        test_frame(8'h12);
        test_frame(8'hED);
        
        if (errors == 0)
            $display("\nALL TX TESTS PASSED");
        else
            $display("\nTX TESTS FAILED: %0d error(s)", errors);
        
        $finish;
    end
    
    // Simulation watchdog
    initial begin
        #20000000;
        $display("ERROR: TX simulation timeout");
        $finish;
    end

endmodule
