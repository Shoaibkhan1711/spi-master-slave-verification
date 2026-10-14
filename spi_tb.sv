`timescale 1ns/1ps

module spi_tb;

    localparam DATA_WIDTH = 8;
    localparam CLK_DIV    = 4;

    logic clk;
    logic reset;
    logic start;
    logic [DATA_WIDTH-1:0] master_tx_data, slave_tx_data;
    logic [DATA_WIDTH-1:0] master_rx_data, slave_rx_data;
    logic done, busy;
    integer pass_count, fail_count;
    logic [DATA_WIDTH-1:0] m_rand, s_rand;
    logic done_prev;

    spi_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLK_DIV(CLK_DIV)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .master_tx_data(master_tx_data),
        .slave_tx_data(slave_tx_data),
        .master_rx_data(master_rx_data),
        .slave_rx_data(slave_rx_data),
        .done(done),
        .busy(busy)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("spi.vcd");
        $dumpvars(0, spi_tb);
    end

    task automatic apply_reset;
        begin
            reset = 1'b1;
            start = 1'b0;
            master_tx_data = '0;
            slave_tx_data = '0;
            repeat (5) @(posedge clk);
            @(negedge clk);
            reset = 1'b0;
            repeat (2) @(posedge clk);
        end
    endtask

    task automatic do_transfer(
        input logic [DATA_WIDTH-1:0] m_data,
        input logic [DATA_WIDTH-1:0] s_data
    );
        begin
            @(negedge clk);
            master_tx_data = m_data;
            slave_tx_data = s_data;
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            wait (done === 1'b1);
            @(negedge clk);
        end
    endtask

    task automatic check_result(
        input logic [DATA_WIDTH-1:0] exp_master_rx,
        input logic [DATA_WIDTH-1:0] exp_slave_rx
    );
        begin
            if ((master_rx_data === exp_master_rx) &&
                (slave_rx_data === exp_slave_rx)) begin
                pass_count = pass_count + 1;
                $display("PASS: master_rx=%02h slave_rx=%02h",
                         master_rx_data, slave_rx_data);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: expected master_rx=%02h slave_rx=%02h; got master_rx=%02h slave_rx=%02h",
                         exp_master_rx, exp_slave_rx, master_rx_data, slave_rx_data);
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        done_prev = 1'b0;

        apply_reset();

        $display("\n== DIRECTED TEST: basic transfer ==");
        do_transfer(8'hA5, 8'h3C);
        check_result(8'h3C, 8'hA5);

        $display("\n== DIRECTED TEST: corner values ==");
        do_transfer(8'h00, 8'hFF);
        check_result(8'hFF, 8'h00);

        do_transfer(8'hFF, 8'h00);
        check_result(8'h00, 8'hFF);

        $display("\n== RANDOM TESTS ==");
        for (int i = 0; i < 20; i++) begin
            m_rand = $urandom;
            s_rand = $urandom;
            do_transfer(m_rand, s_rand);
            check_result(s_rand, m_rand);
        end

        $display("\n==============================");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        #20;
        $finish;
    end

    // Immediate protocol assertions. They are intended to catch common
    // control and unknown-value issues during active transfers.
    always @(posedge clk) begin
        if (reset) begin
            done_prev <= 1'b0;
        end else begin
            assert (!busy || !dut.ss)
                else $error("ASSERTION FAIL: SS de-asserted while busy");
            assert (!(done_prev && dut.done))
                else $error("ASSERTION FAIL: DONE held for more than one cycle");
            assert (!dut.ss || !dut.MASTER.sclk_en)
                else $error("ASSERTION FAIL: SCLK enable active while SS is high");
            assert (!busy || (!$isunknown(dut.mosi) && !$isunknown(dut.miso)))
                else $error("ASSERTION FAIL: X detected on MOSI/MISO during transfer");
            done_prev <= dut.done;
        end
    end

endmodule
