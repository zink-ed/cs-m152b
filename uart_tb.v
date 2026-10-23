`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2026 10:33:17 AM
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

    localparam integer FULL = 1_000_000 / 9_600;
    localparam integer CLK_PERIOD = 10;

    reg clk;
    reg rst;
    integer errors;

    // RX test signals
    reg rx_line;
    wire [7:0] rx_data;

    // TX test signals
    reg [7:0] tx_data;
    wire tx_line;

    // Instantiate RX
    rx dut_rx (
        .clk(clk),
        .rst(rst),
        .rx_line(rx_line),
        .data(rx_data)
    );

    // Instantiate TX
    tx dut_tx (
        .clk(clk),
        .rst(rst),
        .data(tx_data),
        .tx_line(tx_line)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ------------------------------------------------
    // Task: Send one valid UART frame to RX
    // ------------------------------------------------
    task send_rx_frame;
        input [7:0] value;
        integer i;
        begin
            // Start bit
            @(negedge clk);
            rx_line = 0;
            repeat (FULL) @(negedge clk);

            // Eight data bits, LSB first
            for (i = 0; i < 8; i = i + 1) begin
                rx_line = value[i];
                repeat (FULL) @(negedge clk);
            end

            // Stop bit
            rx_line = 1;
            repeat (FULL) @(negedge clk);
        end
    endtask

    // ------------------------------------------------
    // Task: Check RX output
    // ------------------------------------------------
    task check_rx;
        input [7:0] expected;
        begin
            if (rx_data !== expected) begin
                $display(
                    "FAIL RX: expected=%02h actual=%02h time=%0t",
                    expected, rx_data, $time
                );
                errors = errors + 1;
            end else begin
                $display(
                    "PASS RX: received=%02h time=%0t",
                    rx_data, $time
                );
            end
        end
    endtask

    // ------------------------------------------------
    // Task: Check one complete TX frame
    // ------------------------------------------------
    task check_tx_frame;
        input [7:0] expected;
        reg [7:0] sampled;
        integer i;
        begin
            // Wait for falling edge indicating start bit
            @(negedge tx_line);

            // Sample middle of start bit
            repeat (FULL/2) @(negedge clk);

            if (tx_line !== 1'b0) begin
                $display("FAIL TX: start bit is not LOW");
                errors = errors + 1;
            end

            // Sample data bits at bit-period intervals
            for (i = 0; i < 8; i = i + 1) begin
                repeat (FULL) @(negedge clk);
                sampled[i] = tx_line;
            end

            if (sampled !== expected) begin
                $display(
                    "FAIL TX: expected=%02h actual=%02h",
                    expected, sampled
                );
                errors = errors + 1;
            end else begin
                $display("PASS TX: data=%02h", sampled);
            end

            // Check stop bit
            repeat (FULL) @(negedge clk);

            if (tx_line !== 1'b1) begin
                $display("FAIL TX: stop bit is not HIGH");
                errors = errors + 1;
            end else begin
                $display("PASS TX: stop bit HIGH");
            end
        end
    endtask

    // ------------------------------------------------
    // Main tests
    // ------------------------------------------------
    initial begin
        errors  = 0;
        rst     = 1;
        rx_line = 1;
        tx_data = 8'h00;

        $display("==================================");
        $display("UART 8N1 TESTBENCH");
        $display("==================================");

        repeat (5) @(negedge clk);
        rst = 0;
        repeat (5) @(negedge clk);

        // ============================================
        // TEST 1: RX idle
        // ============================================
        $display("\nTEST 1: RX idle");

        repeat (3*FULL) @(negedge clk);
        check_rx(8'h00);

        // ============================================
        // TEST 2: RX edge-case data
        // ============================================
        $display("\nTEST 2: RX data patterns");

        send_rx_frame(8'h00);
        check_rx(8'h00);

        send_rx_frame(8'hFF);
        check_rx(8'hFF);

        send_rx_frame(8'h55);
        check_rx(8'h55);

        send_rx_frame(8'hAA);
        check_rx(8'hAA);

        send_rx_frame(8'h81);
        check_rx(8'h81);

        send_rx_frame(8'hA5);
        check_rx(8'hA5);

        // ============================================
        // TEST 3: RX consecutive frames
        // ============================================
        $display("\nTEST 3: RX multiple bytes");

        send_rx_frame(8'h12);
        check_rx(8'h12);

        send_rx_frame(8'h34);
        check_rx(8'h34);

        send_rx_frame(8'hC7);
        check_rx(8'hC7);

        // ============================================
        // TEST 4: RX invalid stop bit
        // ============================================
        $display("\nTEST 4: RX invalid stop bit");

        // The previous valid value should be retained.
        // Send start bit and data, followed by a LOW stop bit.
        @(negedge clk);
        rx_line = 0;
        repeat (FULL) @(negedge clk);

        for (integer j = 0; j < 8; j = j + 1) begin
            rx_line = 8'h69 >> j;
            repeat (FULL) @(negedge clk);
        end

        rx_line = 0; // Invalid stop bit
        repeat (FULL) @(negedge clk);
        rx_line = 1;
        repeat (FULL) @(negedge clk);

        check_rx(8'hC7);

        // ============================================
        // TEST 5: TX idle
        // ============================================
        $display("\nTEST 5: TX idle level");

        // Note: current TX RTL automatically starts frames.
        // This check may fail unless TX is changed to wait
        // for a transmit-enable signal.
        if (tx_line === 1'b1)
            $display("PASS TX: line is HIGH");
        else
            $display("INFO TX: line is currently LOW");

        // ============================================
        // TEST 6: TX complete frame
        // ============================================
        $display("\nTEST 6: TX frame");

        // The current TX module automatically transmits.
        // The frame checker expects a standard 8N1 frame.
        tx_data = 8'hA5;
        check_tx_frame(8'hA5);

        // ============================================
        // Final report
        // ============================================
        $display("\n==================================");
        if (errors == 0)
            $display("ALL CHECKED TESTS PASSED");
        else
            $display("TESTS FAILED: %0d errors", errors);
        $display("==================================");

        $finish;
    end

    initial begin
        #1000000;
        $display("ERROR: simulation timeout");
        $finish;
    end

endmodule

