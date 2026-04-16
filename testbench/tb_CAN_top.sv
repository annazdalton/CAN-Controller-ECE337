`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_CAN_top;

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

    logic bus_line;
    logic tx_bit_a;
    logic tx_bit_b;

    logic tx_request_a;
    logic tx_wr_en_a;
    logic [10:0] tx_wr_id_a;
    logic [3:0] tx_wr_dlc_a;
    logic [63:0] tx_wr_data_a;

    logic tx_request_b;
    logic tx_wr_en_b;
    logic [10:0] tx_wr_id_b;
    logic [3:0] tx_wr_dlc_b;
    logic [63:0] tx_wr_data_b;

    logic rx_pop_a;
    logic rx_pop_b;

    logic bt_enable;
    logic [9:0] bt_brp;
    logic [5:0] bt_tq_per_bit;
    logic [5:0] bt_sample_tq;
    logic [5:0] bt_sjw;
    logic bt_fd;

    logic tx_buf_valid_a;
    logic tx_complete_a;
    logic arb_lost_a;

    logic [10:0] rx_head_id_b;
    logic [3:0] rx_head_dlc_b;
    logic [63:0] rx_head_data_b;
    logic rx_buf_empty_b;
    logic rx_buf_full_b;
    logic [$clog2(4+1)-1:0] rx_count_b;
    logic rx_ready_b;
    logic crc_err_b;
    logic stf_err_b;
    logic error_flag_b;

    logic tx_buf_valid_b;
    logic tx_complete_b;
    logic arb_lost_b;

    logic [10:0] rx_head_id_a;
    logic [3:0] rx_head_dlc_a;
    logic [63:0] rx_head_data_a;
    logic rx_buf_empty_a;
    logic rx_buf_full_a;
    logic [$clog2(4+1)-1:0] rx_count_a;
    logic rx_ready_a;
    logic crc_err_a;
    logic stf_err_a;
    logic error_flag_a;

    logic saw_complete_a;
    logic saw_complete_b;
    logic saw_lost_a;
    logic saw_lost_b;

    integer pre_pop_a;
    integer pre_pop_b;

    assign bus_line = tx_bit_a & tx_bit_b;

    always begin
        clk = 1'b0;
        #(CLK_PERIOD/2.0);
        clk = 1'b1;
        #(CLK_PERIOD/2.0);
    end

    task init_signals;
    begin
        n_rst = 1'b1;

        tx_request_a = 1'b0;
        tx_wr_en_a = 1'b0;
        tx_wr_id_a = 11'd0;
        tx_wr_dlc_a = 4'd0;
        tx_wr_data_a = 64'd0;

        tx_request_b = 1'b0;
        tx_wr_en_b = 1'b0;
        tx_wr_id_b = 11'd0;
        tx_wr_dlc_b = 4'd0;
        tx_wr_data_b = 64'd0;

        rx_pop_a = 1'b0;
        rx_pop_b = 1'b0;

        bt_enable = 1'b1;
        bt_brp = 10'd0;
        bt_tq_per_bit = 6'd8;
        bt_sample_tq = 6'd3;
        bt_sjw = 6'd1;
        bt_fd = 1'b0;
    end
    endtask

    task reset_dut;
    begin
        @(negedge clk);
        n_rst = 1'b0;
        repeat (6) @(posedge clk);
        @(negedge clk);
        n_rst = 1'b1;
        repeat (6) @(posedge clk);
    end
    endtask

    task monitor_nodes(input integer cycles);
        integer i;
    begin
        saw_complete_a = 1'b0;
        saw_complete_b = 1'b0;
        saw_lost_a = 1'b0;
        saw_lost_b = 1'b0;

        for (i = 0; i < cycles; i = i + 1) begin
            @(posedge clk);
            if (tx_complete_a) saw_complete_a = 1'b1;
            if (tx_complete_b) saw_complete_b = 1'b1;
            if (arb_lost_a) saw_lost_a = 1'b1;
            if (arb_lost_b) saw_lost_b = 1'b1;
        end
    end
    endtask

    CAN_top DUT_A (
        .clk(clk),
        .n_rst(n_rst),
        .bus_rx(bus_line),
        .tx_request(tx_request_a),
        .tx_wr_en(tx_wr_en_a),
        .tx_wr_id(tx_wr_id_a),
        .tx_wr_dlc(tx_wr_dlc_a),
        .tx_wr_data(tx_wr_data_a),
        .rx_pop(rx_pop_a),
        .bt_enable(bt_enable),
        .bt_brp(bt_brp),
        .bt_tq_per_bit(bt_tq_per_bit),
        .bt_sample_tq(bt_sample_tq),
        .bt_sjw(bt_sjw),
        .bt_fd(bt_fd),
        .tx_bit(tx_bit_a),
        .tx_buf_valid(tx_buf_valid_a),
        .tx_complete(tx_complete_a),
        .arb_lost(arb_lost_a),
        .rx_head_id(rx_head_id_a),
        .rx_head_dlc(rx_head_dlc_a),
        .rx_head_data(rx_head_data_a),
        .rx_buf_empty(rx_buf_empty_a),
        .rx_buf_full(rx_buf_full_a),
        .rx_count(rx_count_a),
        .rx_ready(rx_ready_a),
        .crc_err(crc_err_a),
        .stf_err(stf_err_a),
        .error_flag(error_flag_a)
    );

    CAN_top DUT_B (
        .clk(clk),
        .n_rst(n_rst),
        .bus_rx(bus_line),
        .tx_request(tx_request_b),
        .tx_wr_en(tx_wr_en_b),
        .tx_wr_id(tx_wr_id_b),
        .tx_wr_dlc(tx_wr_dlc_b),
        .tx_wr_data(tx_wr_data_b),
        .rx_pop(rx_pop_b),
        .bt_enable(bt_enable),
        .bt_brp(bt_brp),
        .bt_tq_per_bit(bt_tq_per_bit),
        .bt_sample_tq(bt_sample_tq),
        .bt_sjw(bt_sjw),
        .bt_fd(bt_fd),
        .tx_bit(tx_bit_b),
        .tx_buf_valid(tx_buf_valid_b),
        .tx_complete(tx_complete_b),
        .arb_lost(arb_lost_b),
        .rx_head_id(rx_head_id_b),
        .rx_head_dlc(rx_head_dlc_b),
        .rx_head_data(rx_head_data_b),
        .rx_buf_empty(rx_buf_empty_b),
        .rx_buf_full(rx_buf_full_b),
        .rx_count(rx_count_b),
        .rx_ready(rx_ready_b),
        .crc_err(crc_err_b),
        .stf_err(stf_err_b),
        .error_flag(error_flag_b)
    );

    initial begin
        init_signals();
        pass_count = 0;
        fail_count = 0;

        reset_dut();

        testcase = "Node A transmits one frame";
        $display("[%0t] %s", $time, testcase);

        @(negedge clk);
        tx_wr_en_a = 1'b1;
        tx_wr_id_a = 11'h321;
        tx_wr_dlc_a = 4'd2;
        tx_wr_data_a = 64'hABCD_0000_0000_0000;

        @(negedge clk);
        tx_wr_en_a = 1'b0;

        @(negedge clk);
        tx_request_a = 1'b1;
        @(negedge clk);
        tx_request_a = 1'b0;

        monitor_nodes(20000);

        if (saw_complete_a) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s tx_complete_a observed", $time, testcase);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s tx_complete_a not observed", $time, testcase);
        end

        if (!saw_lost_a) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s no arbitration loss on node A", $time, testcase);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s unexpected arbitration loss on node A", $time, testcase);
        end

        if (!tx_buf_valid_a) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s tx buffer A cleared after completion", $time, testcase);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s tx buffer A still marked valid", $time, testcase);
        end

        testcase = "Simultaneous transmit request from both nodes";
        $display("[%0t] %s", $time, testcase);

        @(negedge clk);
        tx_wr_en_a = 1'b1;
        tx_wr_id_a = 11'h300;
        tx_wr_dlc_a = 4'd1;
        tx_wr_data_a = 64'hA500_0000_0000_0000;
        tx_wr_en_b = 1'b1;
        tx_wr_id_b = 11'h120;
        tx_wr_dlc_b = 4'd1;
        tx_wr_data_b = 64'h3C00_0000_0000_0000;

        @(negedge clk);
        tx_wr_en_a = 1'b0;
        tx_wr_en_b = 1'b0;

        @(negedge clk);
        tx_request_a = 1'b1;
        tx_request_b = 1'b1;
        @(negedge clk);
        tx_request_a = 1'b0;
        tx_request_b = 1'b0;

        monitor_nodes(25000);

        if (saw_complete_a || saw_complete_b) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s at least one tx_complete seen", $time, testcase);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s no tx_complete seen", $time, testcase);
        end

        if (!(saw_lost_a && saw_lost_b)) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s no invalid double-loss condition", $time, testcase);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s both nodes reported arbitration loss", $time, testcase);
        end

        testcase = "Pop receive buffers";
        $display("[%0t] %s", $time, testcase);

        pre_pop_a = rx_count_a;
        pre_pop_b = rx_count_b;

        @(negedge clk);
        rx_pop_a = 1'b1;
        rx_pop_b = 1'b1;
        @(negedge clk);
        rx_pop_a = 1'b0;
        rx_pop_b = 1'b0;

        repeat (20) @(posedge clk);

        if ((rx_count_a <= pre_pop_a) && (rx_count_b <= pre_pop_b)) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s pop did not increase queue depth", $time, testcase);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s unexpected queue growth after pop", $time, testcase);
        end

        $display("[SUMMARY] tb_CAN_top pass=%0d fail=%0d", pass_count, fail_count);

        $finish;
    end

endmodule

/* verilator coverage_on */
