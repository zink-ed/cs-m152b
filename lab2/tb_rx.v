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


    // --------------------------------------------------
    // Send one complete UART frame, LSB first.
    // bad_stop=1 sends an invalid low stop bit.
    // --------------------------------------------------
    task send_frame;
        input [7:0] tx_byte;
        input bad_stop;
        integer b;
        begin
            rx_line = 1'b0;
            repeat (FULL) @(negedge clk);

            for (b = 0; b < 8; b = b + 1) begin
                rx_line = tx_byte[b];
                repeat (FULL) @(negedge clk);
            end

            if (bad_stop)
                rx_line = 1'b0;
            else
                rx_line = 1'b1;

            repeat (FULL) @(negedge clk);

            rx_line = 1'b1;
            repeat (2) @(negedge clk);
        end
    endtask


    // --------------------------------------------------
    // Send a frame with a configurable number of bits.
    // Used to test 7-bit and 9-bit frames.
    // --------------------------------------------------
    task send_variable_frame;
        input [15:0] tx_byte;
        input integer num_bits;
        input bad_stop;
        integer b;
        begin
            rx_line = 1'b0;
            repeat (FULL) @(negedge clk);

            for (b = 0; b < num_bits; b = b + 1) begin
                rx_line = tx_byte[b];
                repeat (FULL) @(negedge clk);
            end

            if (bad_stop)
                rx_line = 1'b0;
            else
                rx_line = 1'b1;

            repeat (FULL) @(negedge clk);

            rx_line = 1'b1;
            repeat (2) @(negedge clk);
        end
    endtask


    // --------------------------------------------------
    // Send a short invalid start pulse.
    // --------------------------------------------------
    task send_invalid_start;
        begin
            rx_line = 1'b1;
            repeat (5) @(negedge clk);

            rx_line = 1'b0;
            repeat (FULL / 4) @(negedge clk);

            rx_line = 1'b1;
            repeat (FULL) @(negedge clk);
        end
    endtask


    // --------------------------------------------------
    // Reset while a UART frame is being received.
    // --------------------------------------------------
    task reset_during_frame;
        begin
            rx_line = 1'b0;
            repeat (FULL / 2) @(negedge clk);

            rst = 1'b1;
            repeat (5) @(negedge clk);

            rst = 1'b0;
            rx_line = 1'b1;
            repeat (FULL) @(negedge clk);
        end
    endtask


    // --------------------------------------------------
    // Send two frames with no additional idle bit period.
    // --------------------------------------------------
    task send_back_to_back;
        input [7:0] byte1;
        input [7:0] byte2;
        integer b;
        begin
            // First start bit
            rx_line = 1'b0;
            repeat (FULL) @(negedge clk);

            // First data byte
            for (b = 0; b < 8; b = b + 1) begin
                rx_line = byte1[b];
                repeat (FULL) @(negedge clk);
            end

            // First stop bit
            rx_line = 1'b1;
            repeat (FULL) @(negedge clk);

            // Second start bit
            rx_line = 1'b0;
            repeat (FULL) @(negedge clk);

            // Second data byte
            for (b = 0; b < 8; b = b + 1) begin
                rx_line = byte2[b];
                repeat (FULL) @(negedge clk);
            end

            // Second stop bit
            rx_line = 1'b1;
            repeat (FULL) @(negedge clk);

            repeat (2) @(negedge clk);
        end
    endtask


    // --------------------------------------------------
    // Verify parallel output.
    // --------------------------------------------------
    task check_data;
        input [7:0] expected;
        begin
            if (data !== expected) begin
                $display(
                    "FAIL: expected=%h, received=%h at time %0t",
                    expected, data, $time
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: received byte=%h at time %0t",
                    data, $time
                );
            end
        end
    endtask
    
    task test_header;
        input integer test_num;
        input [8*60-1:0] test_name;
        begin
            $display("\n----------------------------------------");
            $display("[TEST %0d] %0s", test_num, test_name);
            $display("----------------------------------------");
        end
    endtask


    // --------------------------------------------------
    // MAIN TEST SEQUENCE
    // --------------------------------------------------
    initial begin

        errors = 0;
        rst = 1'b1;
        rx_line = 1'b1;

        // Initial reset
        repeat (5) @(negedge clk);
        rst = 1'b0;
        repeat (2) @(negedge clk);

        if (data !== 8'h00) begin
            $display("FAIL: output not cleared by reset");
            errors = errors + 1;
        end
        else begin
            $display("PASS: reset clears receiver output");
        end


        // TEST 1
        test_header(1, "All zeros");
        send_frame(8'h00, 1'b0);
        check_data(8'h00);
        
        
        // TEST 2
        test_header(2, "All ones");
        send_frame(8'hFF, 1'b0);
        check_data(8'hFF);
        
        
        // TEST 3
        test_header(3, "Alternating bits AA");
        send_frame(8'hAA, 1'b0);
        check_data(8'hAA);
        
        
        // TEST 4
        test_header(4, "Opposite alternating bits 55");
        send_frame(8'h55, 1'b0);
        check_data(8'h55);
        
        
        // TEST 5
        test_header(5, "Walking bit at LSB");
        send_frame(8'h01, 1'b0);
        check_data(8'h01);
        
        
        // TEST 6
        test_header(6, "Walking bit at MSB");
        send_frame(8'h80, 1'b0);
        check_data(8'h80);
        
        
        // TEST 7
        test_header(7, "Arbitrary byte A6");
        send_frame(8'hA6, 1'b0);
        check_data(8'hA6);
        
        
        // TEST 8
        test_header(8, "Invalid stop bit");
        send_frame(8'h3C, 1'b1);
        check_data(8'hA6);
        
        
        // TEST 9
        test_header(9, "Short false start pulse");
        @(negedge clk);
        rx_line = 1'b0;
        repeat (HALF / 2) @(negedge clk);
        rx_line = 1'b1;
        repeat (HALF + 10) @(negedge clk);
        check_data(8'hA6);
        
        
        // TEST 10
        test_header(10, "Reset during idle");
        rst = 1'b1;
        repeat (3) @(negedge clk);
        rst = 1'b0;
        repeat (2) @(negedge clk);
        check_data(8'h00);
        
        
        // TEST 11
        test_header(11, "Recovery after reset");
        send_frame(8'hC3, 1'b0);
        check_data(8'hC3);
        
        
        // TEST 12
        test_header(12, "Invalid start bit");
        send_invalid_start();
        check_data(8'hC3);
        
        
        // TEST 13
        test_header(13, "Seven-bit frame and recovery");
        send_variable_frame(16'h0055, 7, 1'b0);
        send_frame(8'h96, 1'b0);
        check_data(8'h96);
        
        
        // TEST 14
        test_header(14, "Nine-bit frame and recovery");
        send_variable_frame(16'h01A5, 9, 1'b0);
        send_frame(8'h69, 1'b0);
        check_data(8'h69);
        
        
        // TEST 15
        test_header(15, "Invalid stop followed by valid frame");
        send_frame(8'h12, 1'b1);
        check_data(8'h69);
        send_frame(8'hE7, 1'b0);
        check_data(8'hE7);
        
        
        // TEST 16
        test_header(16, "Reset during frame reception");
        reset_during_frame();
        check_data(8'h00);
        
        
        // TEST 17
        test_header(17, "Recovery after interrupted frame");
        send_frame(8'hD5, 1'b0);
        check_data(8'hD5);
        
        
        // TEST 18
        test_header(18, "Back-to-back frames");
        send_back_to_back(8'hAA, 8'h55);
        repeat (FULL) @(negedge clk);
        check_data(8'h55);
        
        
        // TEST 19
        test_header(19, "Consecutive frames with different data");
        send_frame(8'h12, 1'b0);
        check_data(8'h12);
        send_frame(8'hE7, 1'b0);
        check_data(8'hE7);
        
        
        // TEST 20
        test_header(20, "Long break condition");
        rx_line = 1'b0;
        repeat (FULL * 12) @(negedge clk);
        rx_line = 1'b1;
        repeat (FULL * 3) @(negedge clk);
        check_data(8'hE7);


        // --------------------------------------------------
        // FINAL RESULTS
        // --------------------------------------------------
        if (errors == 0)
            $display("\nALL RX TESTS PASSED");
        else
            $display("\nRX TESTS FAILED: %0d error(s)", errors);

        $finish;
    end


    // --------------------------------------------------
    // Simulation watchdog
    // --------------------------------------------------
    initial begin
        #30000000;
        $display("ERROR: RX simulation timeout");
        $finish;
    end

endmodule
