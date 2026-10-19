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

    );
endmodule

//module clk_divider(
    
//);

//endmodule

module rx(
    input wire clk,
    input wire rst,
    input wire rx_line,
    output reg [7:0] data
);
    
    localparam integer HALF = 5; // PLACEHOLDER
    localparam integer FULL = 10;

    localparam [2:0]
        RX_IDLE  = 3'd0,
        RX_START = 3'd1,
        RX_DATA  = 3'd2,
        RX_STOP  = 3'd3,
        RX_DONE  = 3'd4;
    
    reg [2:0] state;
    reg [2:0] data_bit;
    
    reg [31:0] clk_count;

    always @(posedge clk) begin
        if (rst) begin
            state <= RX_IDLE;
            data_bit <= 0;
        end else begin
            case (state) 
                RX_IDLE: begin
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
                        
                        data[data_bit] <= rx_line;
                        if (data_bit == 3'd7) begin
                            state <= RX_STOP;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end
                RX_STOP: begin
                    if (rx_line == 1'b1) begin
                        state <= RX_DONE;
                    end
                end
                RX_DONE: begin
                    state <= RX_IDLE;
                end
            endcase
        end
    end

endmodule


module tx(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    output wire tx_line
);

    localparam [2:0]
        TX_IDLE  = 3'd0,
        TX_START = 3'd1,
        TX_DATA  = 3'd2,
        TX_STOP  = 3'd3,
        TX_DONE  = 3'd4;
    
    reg [2:0] state;
    reg [7:0] tx_data;
    reg [2:0] data_bit;
    reg tx_reg;
    
    reg [31:0] clk_count;
    
    assign tx_line = tx_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= TX_IDLE;
            data_bit <= 0;
            tx_reg <= 1'b1;
        end else begin
            case (state) 
                TX_IDLE: begin
                    tx_reg <= 1'b1;
                    tx_data <= data;
                    state <= TX_IDLE;
                end
                TX_START: begin
                    tx_reg <= 1'b0;
                    state <= TX_DATA;
                end
                TX_DATA: begin
                    tx_reg <= tx_data[data_bit];
                    if (data_bit == 3'd7) begin
                        state <= TX_STOP;
                    end else begin
                        data_bit <= data_bit + 1;
                    end
                end
                TX_STOP: begin
                    tx_reg <= 1'b1;
                end
            endcase
        end
    end


endmodule

