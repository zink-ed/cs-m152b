`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2026 10:11:39 AM
// Design Name: 
// Module Name: tb_rx
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


module tb_rx;

    localparam integer FULL = 100_000_000 / 9_600;
    localparam integer HALF = FULL / 2;

    reg clk;
    reg rst;
    reg rx_line;
    wire [7:0] data;

    integer i;
    integer errors;

    rx uut (
        .clk(clk),
        .rst(rst),
        .rx_line(rx_line),
        .data(data)
    );

    // 100 MHz clock: 10 ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Send one complete UART frame, LSB first.
    // bad_stop=1 sends an invalid low stop bit.
    task send_frame;
        input [7:0] tx_byte;
        input bad_stop;
        integer b;
        begin
            // Start bit
            rx_line = 1'b0;
            repeat (FULL) @(negedge clk);

            // Eight data bits, LSB first
            for (b = 0; b < 8; b = b + 1) begin
                rx_line = tx_byte[b];
                repeat (FULL) @(negedge clk);
            end

            // Stop bit
            if (bad_stop)
                rx_line = 1'b0;
            else
                rx_line = 1'b1;

            repeat (FULL) @(negedge clk);

            // Return to idle
            rx_line = 1'b1;
            repeat (2) @(negedge clk);
        end
    endtask

    // Verify the parallel output.
    task check_data;
        input [7:0] expected;
        begin
            if (data !== expected) begin
                $display(
                    "FAIL: expected=%h, received=%h at time %0t",
                    expected, data, $time
                );
                errors = errors + 1;
            end else begin
                $display(
                    "PASS: received byte=%h at time %0t",
                    data, $time
                );
            end
        end
    endtask

    initial begin
        errors = 0;
        rst = 1'b1;
        rx_line = 1'b1;

        // Reset
        repeat (5) @(negedge clk);
        rst = 1'b0;
        repeat (2) @(negedge clk);

        if (data !== 8'h00) begin
            $display("FAIL: output not cleared by reset");
            errors = errors + 1;
        end else begin
            $display("PASS: reset clears receiver output");
        end

        // Test 1: all zeros
        send_frame(8'h00, 1'b0);
        check_data(8'h00);

        // Test 2: all ones
        send_frame(8'hFF, 1'b0);
        check_data(8'hFF);

        // Test 3: alternating bits
        send_frame(8'hAA, 1'b0);
        check_data(8'hAA);

        // Test 4: opposite alternating pattern
        send_frame(8'h55, 1'b0);
        check_data(8'h55);

        // Test 5: walking bit at LSB
        send_frame(8'h01, 1'b0);
        check_data(8'h01);

        // Test 6: walking bit at MSB
        send_frame(8'h80, 1'b0);
        check_data(8'h80);

        // Test 7: arbitrary byte
        send_frame(8'hA6, 1'b0);
        check_data(8'hA6);

        // Test 8: invalid stop bit must not update output
        send_frame(8'h3C, 1'b1);
        check_data(8'hA6);

        // Test 9: short false start pulse
        // The receiver should reject it at the half-bit check.
        @(negedge clk);
        rx_line = 1'b0;
        repeat (HALF / 2) @(negedge clk);
        rx_line = 1'b1;
        repeat (HALF + 10) @(negedge clk);
        check_data(8'hA6);

        // Test 10: reset during normal idle
        rst = 1'b1;
        repeat (3) @(negedge clk);
        rst = 1'b0;
        repeat (2) @(negedge clk);
        check_data(8'h00);

        // Confirm receiver recovers after reset
        send_frame(8'hC3, 1'b0);
        check_data(8'hC3);

        if (errors == 0)
            $display("\nALL RX TESTS PASSED");
        else
            $display("\nRX TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

    // Simulation watchdog
    initial begin
        #12000000;
        $display("ERROR: RX simulation timeout");
        $finish;
    end

endmodule

