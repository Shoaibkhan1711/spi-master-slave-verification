`timescale 1ns/1ps

// Connects one SPI master and one SPI slave for full-duplex verification.
module spi_top #(
    parameter DATA_WIDTH = 8,
    parameter CLK_DIV    = 4
) (
    input  logic                  clk,
    input  logic                  reset,
    input  logic                  start,
    input  logic [DATA_WIDTH-1:0] master_tx_data,
    input  logic [DATA_WIDTH-1:0] slave_tx_data,
    output logic [DATA_WIDTH-1:0] master_rx_data,
    output logic [DATA_WIDTH-1:0] slave_rx_data,
    output logic                  done,
    output logic                  busy
);

    logic sclk, mosi, miso, ss;
    logic slave_done;

    spi_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLK_DIV(CLK_DIV)
    ) MASTER (
        .clk(clk),
        .reset(reset),
        .start(start),
        .tx_data(master_tx_data),
        .miso(miso),
        .sclk(sclk),
        .mosi(mosi),
        .ss(ss),
        .rx_data(master_rx_data),
        .done(done),
        .busy(busy)
    );

    spi_slave #(
        .DATA_WIDTH(DATA_WIDTH)
    ) SLAVE (
        .reset(reset),
        .sclk(sclk),
        .ss(ss),
        .mosi(mosi),
        .tx_data(slave_tx_data),
        .miso(miso),
        .rx_data(slave_rx_data),
        .done(slave_done)
    );

endmodule
