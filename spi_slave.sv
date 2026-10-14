`timescale 1ns/1ps

// SPI Slave: Mode 0 (CPOL=0, CPHA=0).
// Samples MOSI on rising SCLK edges and advances MISO data on falling edges.
module spi_slave #(
    parameter DATA_WIDTH = 8
) (
    input  logic                   reset,
    input  logic                   sclk,
    input  logic                   ss,
    input  logic                   mosi,
    input  logic [DATA_WIDTH-1:0]  tx_data,
    output logic                   miso,
    output logic [DATA_WIDTH-1:0]  rx_data,
    output logic                   done
);

    logic [DATA_WIDTH-1:0] shift_out;
    logic [DATA_WIDTH-1:0] shift_in;
    logic [$clog2(DATA_WIDTH):0] bit_cnt;
    logic selected_prev;

    // Preload on selection, then shift the outgoing byte on each falling
    // SCLK edge. selected_prev distinguishes the SS selection event from
    // subsequent falling SCLK events in this single process.
    always @(negedge ss or posedge ss or negedge sclk or posedge reset) begin
        if (reset) begin
            shift_out    <= '0;
            miso         <= 1'b0;
            selected_prev <= 1'b0;
        end else if (ss) begin
            selected_prev <= 1'b0;
        end else if (!selected_prev) begin
            shift_out     <= tx_data;
            miso          <= tx_data[DATA_WIDTH-1];
            selected_prev <= 1'b1;
        end else begin
            shift_out <= {shift_out[DATA_WIDTH-2:0], 1'b0};
            miso      <= shift_out[DATA_WIDTH-2];
        end
    end

    // Sample incoming MOSI on rising SCLK edges.
    always_ff @(posedge sclk or posedge reset) begin
        if (reset) begin
            shift_in <= '0;
            bit_cnt  <= '0;
            done     <= 1'b0;
            rx_data  <= '0;
        end else if (!ss) begin
            shift_in <= {shift_in[DATA_WIDTH-2:0], mosi};

            if (bit_cnt == DATA_WIDTH-1) begin
                rx_data <= {shift_in[DATA_WIDTH-2:0], mosi};
                done    <= 1'b1;
                bit_cnt <= '0;
            end else begin
                bit_cnt <= bit_cnt + 1'b1;
                done    <= 1'b0;
            end
        end else begin
            done    <= 1'b0;
            bit_cnt <= '0;
        end
    end

endmodule
