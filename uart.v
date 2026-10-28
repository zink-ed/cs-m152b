`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2026 10:34:54 AM
// Design Name: 
// Module Name: uart
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


module uart(
    input  wire clk,        
    input  wire btnC, // reset       
    input  wire btnU, // send button
    input  wire [7:0] sw,   
    input  wire RX, // UART RX GPIO
    output wire TX, // UART TX GPIO
    output wire [7:0] led        
    );
    
    reg  [7:0] tx_data;
    wire [7:0] rx_data;
    
    reg send_d;
    wire send_pulse;

    always @(posedge clk or posedge btnC) begin
        if (btnC)
            send_d <= 1'b0;
        else
            send_d <= btnU;
    end

    // trigger once on the rising edge of the button
    assign send_pulse = btnU & ~send_d;

    // capture switch data when the send button is pressed
    always @(posedge clk or posedge btnC) begin
        if (btnC)
            tx_data <= 8'h00;
        else if (send_pulse)
            tx_data <= sw;
    end

    // UART receiver
    rx receiver (
        .clk(clk),
        .rst(btnC),
        .rx_line(RX),
        .data(rx_data)
    );

    // UART transmitter
    tx transmitter (
        .clk(clk),
        .rst(btnC),
        .start(send_pulse),
        .data(sw),
        .tx_line(TX)
    );
    
    assign led = rx_data;
    
endmodule

module rx(
    input wire clk,
    input wire rst,
    input wire rx_line,
    output reg [7:0] data
);
    
    localparam integer FULL = 100_000_000 / 9_600;
    localparam integer HALF = FULL / 2;

    localparam [2:0]
        RX_IDLE  = 3'd0,
        RX_START = 3'd1,
        RX_DATA  = 3'd2,
        RX_STOP  = 3'd3;
    
    reg [2:0] state;
    reg [2:0] data_bit;
    reg [7:0] temp_data;
    reg [31:0] clk_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= RX_IDLE;
            data_bit <= 0;
            clk_count <= 0;
            data <= 0;
            temp_data <= 0;
        end else begin
            case (state) 
                RX_IDLE: begin
                    clk_count <= 0;
                    data_bit <= 0;
                    if (rx_line == 1'b0) begin
                        state <= RX_START;
                    end
                end
                RX_START: begin
                    // sample at midpoint of start
                    if (clk_count == HALF - 1) begin
                        clk_count <= 0;
                        
                        if (rx_line == 1'b0) begin
                            data_bit <= 0;
                            state <= RX_DATA;
                        end else begin
                            state <= RX_IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end
                RX_DATA: begin
                    // sample at midpoint of each data
                    if (clk_count == FULL - 1) begin
                        clk_count <= 0;
                        temp_data[data_bit] <= rx_line;
                        
                        if (data_bit == 3'd7)
                            state <= RX_STOP;
                        else
                            data_bit <= data_bit + 1'b1;
                            
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end
                RX_STOP: begin
                    if (clk_count == FULL - 1) begin
                        clk_count <= 0;
                        state <= RX_IDLE;
                        
                        if (rx_line == 1'b1)
                            data <= temp_data;

                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end
                default: begin
                    state <= RX_IDLE;
                    clk_count <= 0;
                    data_bit <= 0;
                end
            endcase
        end
    end

endmodule


module tx(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] data,
    output wire tx_line
);

    localparam integer FULL = 100_000_000 / 9_600;
    localparam integer HALF = FULL / 2;

    localparam [2:0]
        TX_IDLE  = 3'd0,
        TX_START = 3'd1,
        TX_DATA  = 3'd2,
        TX_STOP  = 3'd3;
    
    reg [2:0] state;
    reg [7:0] tx_data;
    reg [2:0] data_bit;
    reg [31:0] clk_count;
    
    reg tx_reg;
    assign tx_line = tx_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= TX_IDLE;
            data_bit <= 0;
            tx_reg <= 1'b1;
            clk_count <= 0;
        end else begin
            case (state) 
                TX_IDLE: begin
                    tx_reg <= 1'b1;
                    clk_count <= 0;
                    
                    if (start) begin
                        tx_data <= data;
                        state <= TX_START;
                    end
                end
                TX_START: begin
                    // hold start bit low
                    tx_reg <= 1'b0;
                    
                    if (clk_count == FULL - 1) begin
                        clk_count <= 0;
                        data_bit <= 0;
                        tx_reg <= tx_data[0];
                        state <= TX_DATA;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end
                TX_DATA: begin
                    // hold data for 1 bit period
                    if (clk_count == FULL - 1) begin
                        clk_count <= 0;
                        
                        if (data_bit == 3'd7) begin
                            tx_reg <= 1'b1;
                            state <= TX_STOP;
                        end else begin
                            data_bit <= data_bit + 1'b1;
                            tx_reg <= tx_data[data_bit + 1'b1];
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end
                TX_STOP: begin
                    if (clk_count == FULL - 1) begin
                        clk_count <= 0;
                        state <= TX_IDLE;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end
                default: begin
                    state <= TX_IDLE;
                    clk_count <= 0;
                    data_bit <= 0;
                end
            endcase
        end
    end


endmodule

