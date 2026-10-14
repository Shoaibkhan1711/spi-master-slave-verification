`timescale 1ns/1ps

// SPI Master: Mode 0 (CPOL=0, CPHA=0), full duplex.
module spi_master #(
    parameter DATA_WIDTH = 8,
    parameter CLK_DIV    = 4
) (
    input  logic                   clk,
    input  logic                   reset,
    input  logic                   start,
    input  logic [DATA_WIDTH-1:0]  tx_data,
    input  logic                   miso,
    output logic                   sclk,
    output logic                   mosi,
    output logic                   ss,
    output logic [DATA_WIDTH-1:0]  rx_data,
    output logic                   done,
    output logic                   busy
);

    typedef enum logic [1:0] {IDLE, TRANSFER, DONE_ST} state_t;
    state_t state;

    logic [DATA_WIDTH-1:0] shift_out;
    logic [DATA_WIDTH-1:0] shift_in;
    logic [$clog2(DATA_WIDTH):0] bit_cnt;
    logic [$clog2(CLK_DIV)-1:0] div_cnt;
    logic sclk_en;

    // One tick every CLK_DIV system clocks while transferring.
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            div_cnt <= '0;
            sclk_en <= 1'b0;
        end else if (state == TRANSFER) begin
            if (div_cnt == CLK_DIV-1) begin
                div_cnt <= '0;
                sclk_en <= 1'b1;
            end else begin
                div_cnt <= div_cnt + 1'b1;
                sclk_en <= 1'b0;
            end
        end else begin
            div_cnt <= '0;
            sclk_en <= 1'b0;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= IDLE;
            ss        <= 1'b1;
            sclk      <= 1'b0;
            mosi      <= 1'b0;
            busy      <= 1'b0;
            done      <= 1'b0;
            shift_out <= '0;
            shift_in  <= '0;
            rx_data   <= '0;
            bit_cnt   <= '0;
        end else begin
            done <= 1'b0;

            case (state)
                IDLE: begin
                    ss   <= 1'b1;
                    sclk <= 1'b0;
                    busy <= 1'b0;

                    if (start) begin
                        ss        <= 1'b0;
                        busy      <= 1'b1;
                        shift_out <= tx_data;
                        mosi      <= tx_data[DATA_WIDTH-1];
                        shift_in  <= '0;
                        bit_cnt   <= '0;
                        state     <= TRANSFER;
                    end
                end

                TRANSFER: begin
                    if (sclk_en) begin
                        sclk <= ~sclk;

                        if (sclk) begin
                            // Falling edge: prepare the next MOSI bit.
                            shift_out <= {shift_out[DATA_WIDTH-2:0], 1'b0};
                            mosi      <= shift_out[DATA_WIDTH-2];
                        end else begin
                            // Rising edge: sample MISO.
                            shift_in <= {shift_in[DATA_WIDTH-2:0], miso};

                            if (bit_cnt == DATA_WIDTH-1)
                                state <= DONE_ST;
                            else
                                bit_cnt <= bit_cnt + 1'b1;
                        end
                    end
                end

                DONE_ST: begin
                    ss      <= 1'b1;
                    sclk    <= 1'b0;
                    busy    <= 1'b0;
                    done    <= 1'b1;
                    rx_data <= shift_in;
                    state   <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
