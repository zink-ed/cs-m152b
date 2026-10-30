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

    localparam integer FULL = 100_000_000 / 9_600;
    localparam integer HALF = FULL / 2;

    reg clk;
    reg rst;
    reg start;
    reg [7:0] data;
    wire tx_line;

    integer errors;

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


    // ---------------------------------------------------------
    // TASK 1: Transmit one byte and verify complete UART frame
    // ---------------------------------------------------------

    task test_frame;
        input [7:0] test_byte;
        integer b;

        begin
            $display("\nTEST: Standard frame, byte = %h", test_byte);

            @(negedge clk);
            data = test_byte;
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            // Wait for start bit
            @(negedge tx_line);

            // Sample middle of start bit
            repeat (HALF) @(posedge clk);
            #1;

            if (tx_line !== 1'b0) begin
                $display("FAIL: Start bit should be 0");
                errors = errors + 1;
            end else begin
                $display("PASS: Start bit = 0");
            end

            // Sample eight data bits, LSB first
            for (b = 0; b < 8; b = b + 1) begin
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

            // Sample stop bit
            repeat (FULL) @(posedge clk);
            #1;

            if (tx_line !== 1'b1) begin
                $display("FAIL: Stop bit should be 1");
                errors = errors + 1;
            end else begin
                $display("PASS: Stop bit = 1");
            end

            // Check idle
            repeat (HALF + 5) @(negedge clk);

            if (tx_line !== 1'b1) begin
                $display("FAIL: TX did not return to idle");
                errors = errors + 1;
            end else begin
                $display("PASS: TX returned to idle");
            end

            $display("Finished frame for byte %h", test_byte);
        end
    endtask


    // ---------------------------------------------------------
    // TASK 2: Reset during transmission
    // ---------------------------------------------------------

    task test_reset_during_transmission;
        begin
            $display("\nTEST: Reset during transmission");

            // Start transmitting
            @(negedge clk);
            data = 8'hA5;
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            // Wait for start bit
            @(negedge tx_line);

            // Allow several data bits to transmit
            repeat (HALF + 3*FULL) @(posedge clk);

            // Assert reset
            @(negedge clk);
            rst = 1'b1;

            repeat (2) @(posedge clk);
            #1;

            if (tx_line !== 1'b1) begin
                $display("FAIL: TX did not return idle after reset");
                errors = errors + 1;
            end else begin
                $display("PASS: Reset aborted transmission");
            end

            // Release reset
            @(negedge clk);
            rst = 1'b0;

            repeat (2) @(negedge clk);

            if (tx_line !== 1'b1) begin
                $display("FAIL: TX not idle after reset release");
                errors = errors + 1;
            end else begin
                $display("PASS: TX remained idle after reset release");
            end
        end
    endtask


    // ---------------------------------------------------------
    // TASK 3: Change data during transmission
    // ---------------------------------------------------------

    task test_data_change_during_transmission;
        input [7:0] original_byte;
        input [7:0] new_byte;

        integer b;

        begin
            $display("\nTEST: Change data during transmission");
            $display("Original = %h, New = %h",
                     original_byte, new_byte);

            // Start transmission
            @(negedge clk);
            data = original_byte;
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            @(negedge tx_line);

            // Sample start bit
            repeat (HALF) @(posedge clk);
            #1;

            if (tx_line !== 1'b0) begin
                $display("FAIL: Invalid start bit");
                errors = errors + 1;
            end

            // Sample first two data bits
            for (b = 0; b < 2; b = b + 1) begin
                repeat (FULL) @(posedge clk);
                #1;

                if (tx_line !== original_byte[b]) begin
                    $display("FAIL: Bit %0d incorrect", b);
                    errors = errors + 1;
                end
            end

            // Change input while transmitting
            @(negedge clk);
            data = new_byte;

            $display("Changed input data to %h", new_byte);

            // Verify remaining bits still match original byte
            for (b = 2; b < 8; b = b + 1) begin
                repeat (FULL) @(posedge clk);
                #1;

                if (tx_line !== original_byte[b]) begin
                    $display(
                        "FAIL: Data corrupted at bit %0d, expected=%b got=%b",
                        b, original_byte[b], tx_line
                    );
                    errors = errors + 1;
                end else begin
                    $display("PASS: Original bit[%0d] correct", b);
                end
            end

            // Check stop bit
            repeat (FULL) @(posedge clk);
            #1;

            if (tx_line !== 1'b1) begin
                $display("FAIL: Invalid stop bit");
                errors = errors + 1;
            end else begin
                $display("PASS: Stop bit correct");
            end

            // Check idle
            repeat (HALF + 5) @(negedge clk);

            if (tx_line !== 1'b1) begin
                $display("FAIL: TX did not return to idle");
                errors = errors + 1;
            end else begin
                $display("PASS: TX returned to idle");
            end
        end
    endtask


    // ---------------------------------------------------------
    // TASK: Assert start while transmitter is busy
    // ---------------------------------------------------------
    
    task test_start_while_busy;
    
        integer b;
        reg [7:0] original_byte;
    
        begin
            $display("\nTEST: Start asserted while busy");
    
            original_byte = 8'h96;
    
            // Start first transmission
            @(negedge clk);
            data = original_byte;
            start = 1'b1;
    
            @(negedge clk);
            start = 1'b0;
    
            // Wait for falling edge of start bit
            @(negedge tx_line);
    
            // Sample middle of start bit
            repeat (HALF) @(posedge clk);
            #1;
    
            if (tx_line !== 1'b0) begin
                $display("FAIL: Invalid start bit");
                errors = errors + 1;
            end
    
            // Sample first two data bits
            for (b = 0; b < 2; b = b + 1) begin
                repeat (FULL) @(posedge clk);
                #1;
    
                if (tx_line !== original_byte[b]) begin
                    $display("FAIL: Original bit %0d incorrect", b);
                    errors = errors + 1;
                end
            end
    
            // Assert another start request while busy
            @(negedge clk);
            data = 8'h5A;
            start = 1'b1;
    
            // Hold start high for one clock cycle
            @(negedge clk);
            start = 1'b0;
    
            $display("Sent second start request while busy");
    
            // Verify remaining original data bits
            for (b = 2; b < 8; b = b + 1) begin
                repeat (FULL) @(posedge clk);
                #1;
    
                if (tx_line !== original_byte[b]) begin
                    $display(
                        "FAIL: Original frame bit %0d expected=%b got=%b",
                        b, original_byte[b], tx_line
                    );
                    errors = errors + 1;
                end else begin
                    $display("PASS: Original frame bit[%0d] correct", b);
                end
            end
    
            // Check stop bit
            repeat (FULL) @(posedge clk);
            #1;
    
            if (tx_line !== 1'b1) begin
                $display("FAIL: Stop bit incorrect");
                errors = errors + 1;
            end else begin
                $display("PASS: Stop bit correct");
            end
    
            // Wait for idle
            repeat (HALF + 5) @(negedge clk);
    
            if (tx_line !== 1'b1) begin
                $display("FAIL: TX did not return to idle");
                errors = errors + 1;
            end else begin
                $display("PASS: TX returned to idle");
            end
    
        end
    endtask


    // ---------------------------------------------------------
    // MAIN TEST SEQUENCE
    // ---------------------------------------------------------

    initial begin

        errors = 0;
        rst = 1'b1;
        start = 1'b0;
        data = 8'h00;

        $display("======================================");
        $display(" UART TRANSMITTER TESTBENCH");
        $display("======================================");

        // Initial reset
        repeat (5) @(negedge clk);
        rst = 1'b0;

        repeat (2) @(negedge clk);

        if (tx_line !== 1'b1) begin
            $display("FAIL: TX should idle high after reset");
            errors = errors + 1;
        end else begin
            $display("PASS: Reset establishes idle-high output");
        end


        // TEST 1: Basic data patterns
        test_frame(8'h00);
        test_frame(8'hFF);
        test_frame(8'hAA);
        test_frame(8'h55);


        // TEST 2: Individual edge bits
        test_frame(8'h01);
        test_frame(8'h80);


        // TEST 3: Arbitrary data
        test_frame(8'hA6);
        test_frame(8'hC3);


        // TEST 4: Consecutive frames
        test_frame(8'h12);
        test_frame(8'hED);


        // TEST 5: Reset during transmission
        test_reset_during_transmission();


        // TEST 6: Change data during transmission
        test_data_change_during_transmission(8'hA5, 8'h3C);
        test_data_change_during_transmission(8'h00, 8'hFF);
        test_data_change_during_transmission(8'h96, 8'h69);


        // TEST 7: Start asserted while busy
        test_start_while_busy();


        // FINAL RESULTS
        $display("\n======================================");

        if (errors == 0) begin
            $display(" ALL TX TESTS PASSED");
        end else begin
            $display(" TX TESTS FAILED: %0d error(s)", errors);
        end

        $display("======================================");

        $finish;
    end


    // ---------------------------------------------------------
    // SIMULATION WATCHDOG
    // ---------------------------------------------------------

    initial begin
        #30000000;
        $display("ERROR: TX simulation timeout");
        $finish;
    end

endmodule
