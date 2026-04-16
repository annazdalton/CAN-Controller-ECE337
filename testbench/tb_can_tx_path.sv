`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_can_tx_path;

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk;
    logic n_rst;

    string testcase;
    integer pass_count;
    integer fail_count;

    logic can_rx;
    logic bit_tick;
    logic bus_idle;

    logic tx_buf_valid;
    logic [10:0] tx_buf_id;
    logic [3:0] tx_buf_dlc;
    logic [63:0] tx_buf_data;
    logic tx_request;

    logic can_tx;
    logic tx_en;
    logic tx_complete;
    logic arb_lost;
    logic msg_due_tx;
    logic tx_buf_clr;
    logic listen_after_arb;

    logic [2:0] tick_div;

    logic saw_complete;
    logic saw_lost;
    logic saw_clr;

    always begin
        clk = 1'b0;
        #(CLK_PERIOD/2.0);
        clk = 1'b1;
        #(CLK_PERIOD/2.0);
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            tick_div <= 3'd0;
            bit_tick <= 1'b0;
        end else begin
            if (tick_div == 3'd3) begin
                tick_div <= 3'd0;
                bit_tick <= 1'b1;
            end else begin
                tick_div <= tick_div + 1'b1;
                bit_tick <= 1'b0;
            end
        end
    end

    task reset_dut;
    begin
        n_rst = 1'b0;
        repeat (4) @(posedge clk);
        n_rst = 1'b1;
        repeat (2) @(posedge clk);
    end
    endtask

    task request_tx(
        input logic [10:0] id_i,
        input logic [3:0] dlc_i,
        input logic [63:0] data_i
    );
    begin
        tx_buf_valid = 1'b1;
        tx_buf_id = id_i;
        tx_buf_dlc = dlc_i;
        tx_buf_data = data_i;

        @(posedge clk);
        tx_request = 1'b1;
        @(posedge clk);
        tx_request = 1'b0;
    end
    endtask

    task monitor_tx(input integer cycles);
        integer i;
    begin
        saw_complete = 1'b0;
        saw_lost = 1'b0;
        saw_clr = 1'b0;

        for (i = 0; i < cycles; i = i + 1) begin
            @(posedge clk);
            if (tx_complete) saw_complete = 1'b1;
            if (arb_lost) saw_lost = 1'b1;
            if (tx_buf_clr) saw_clr = 1'b1;
        end
    end
    endtask

    can_tx_path DUT (
        .clk(clk),
        .n_rst(n_rst),
        .can_rx(can_rx),
        .bit_tick(bit_tick),
        .bus_idle(bus_idle),
        .tx_buf_valid(tx_buf_valid),
        .tx_buf_id(tx_buf_id),
        .tx_buf_dlc(tx_buf_dlc),
        .tx_buf_data(tx_buf_data),
        .tx_request(tx_request),
        .can_tx(can_tx),
        .tx_en(tx_en),
        .tx_complete(tx_complete),
        .arb_lost(arb_lost),
        .msg_due_tx(msg_due_tx),
        .tx_buf_clr(tx_buf_clr),
        .listen_after_arb(listen_after_arb)
    );

    initial begin
        n_rst = 1'b1;
        can_rx = 1'b1;
        bus_idle = 1'b1;
        tx_buf_valid = 1'b0;
        tx_buf_id = 11'd0;
        tx_buf_dlc = 4'd0;
        tx_buf_data = 64'd0;
        tx_request = 1'b0;

        pass_count = 0;
        fail_count = 0;

        reset_dut();

        testcase = "Standard transmit";
        $display("[%0t] %s", $time, testcase);

        bus_idle = 1'b1;
        can_rx = 1'b1;
        request_tx(11'h123, 4'd2, 64'hA5F0_0000_0000_0000);
        monitor_tx(30000);

        if (saw_complete && !saw_lost) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s completed without arbitration loss", $time, testcase);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s expected complete=1/lost=0 saw complete=%0b lost=%0b", $time, testcase, saw_complete, saw_lost);
        end

        if (saw_clr) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s tx_buf_clr observed", $time, testcase);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s tx_buf_clr not observed", $time, testcase);
        end

        testcase = "Disturb bus during transmission";
        $display("[%0t] %s", $time, testcase);

        bus_idle = 1'b1;
        can_rx = 1'b1;
        request_tx(11'h321, 4'd1, 64'hC300_0000_0000_0000);

        saw_complete = 1'b0;
        saw_lost = 1'b0;
        saw_clr = 1'b0;

        wait (tx_en == 1'b1);
        repeat (12) begin
            @(posedge clk);
            if (bit_tick) begin
                can_rx = 1'b0;
            end
            if (tx_complete) saw_complete = 1'b1;
            if (arb_lost) saw_lost = 1'b1;
        end
        can_rx = 1'b1;

        repeat (5000) begin
            @(posedge clk);
            if (tx_complete) saw_complete = 1'b1;
            if (arb_lost) saw_lost = 1'b1;
        end

        if (saw_lost || saw_complete) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s transmitter reacted (lost=%0b complete=%0b)", $time, testcase, saw_lost, saw_complete);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s no tx reaction observed", $time, testcase);
        end

        testcase = "Back-to-back transmit request";
        $display("[%0t] %s", $time, testcase);

        bus_idle = 1'b1;
        can_rx = 1'b1;
        request_tx(11'h055, 4'd8, 64'hDEAD_BEEF_CAFE_BABE);
        monitor_tx(35000);

        if (saw_complete) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s tx_complete observed", $time, testcase);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s tx_complete not observed", $time, testcase);
        end

        $display("[SUMMARY] tb_can_tx_path pass=%0d fail=%0d", pass_count, fail_count);

        $finish;
    end

endmodule

/* verilator coverage_on */
