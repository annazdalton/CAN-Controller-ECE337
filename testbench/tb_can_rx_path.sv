`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_can_rx_path;

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk;
    logic n_rst;

    logic bit_tick;
    logic sample_tick;

    logic can_rx;
    logic hard_sync_pulse;

    logic tx_buf_valid;
    logic [10:0] tx_buf_id;
    logic [3:0] tx_buf_dlc;
    logic [63:0] tx_buf_data;
    logic tx_request;
    logic error;
    logic error_passive;
    logic error_active;

    logic tx_can_tx;
    logic tx_en;
    logic tx_complete;
    logic arb_lost;
    logic msg_due_tx;
    logic tx_buf_clr;
    logic listen_after_arb;

    logic rx_en;
    logic fd;
    logic rx_push;
    logic [10:0] rx_push_id;
    logic [3:0] rx_push_dlc;
    logic [63:0] rx_push_data;
    logic rx_ready;
    logic crc_err;
    logic stf_err;
    logic error_flag;

    logic [10:0] rx_head_id;
    logic [3:0] rx_head_dlc;
    logic [63:0] rx_head_data;
    logic rx_empty;
    logic rx_full;
    logic [3:0] rx_count;

    logic [2:0] tick_div;
    logic tx_en_d;

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
            sample_tick <= 1'b0;
            tx_en_d <= 1'b0;
            hard_sync_pulse <= 1'b0;
        end else begin
            if (tick_div == 3'd3) begin
                tick_div <= 3'd0;
                bit_tick <= 1'b1;
            end else begin
                tick_div <= tick_div + 1'b1;
                bit_tick <= 1'b0;
            end

            if (tick_div == 3'd1) begin
                sample_tick <= 1'b1;
            end else begin
                sample_tick <= 1'b0;
            end

            tx_en_d <= tx_en;
            hard_sync_pulse <= tx_en && !tx_en_d;
        end
    end

    task reset_dut;
    begin
        n_rst = 1'b0;
        repeat (5) @(posedge clk);
        n_rst = 1'b1;
        repeat (3) @(posedge clk);
    end
    endtask

    assign can_rx = tx_can_tx;

    can_tx_path TX_DUT (
        .clk(clk),
        .n_rst(n_rst),
        .can_rx(can_rx),
        .bit_tick(bit_tick),
        .bus_idle(1'b1),
        .tx_buf_valid(tx_buf_valid),
        .tx_buf_id(tx_buf_id),
        .tx_buf_dlc(tx_buf_dlc),
        .tx_buf_data(tx_buf_data),
        .tx_request(tx_request),
        .error(error),
        .error_passive(error_passive),
        .error_active(error_active),
        .error_done(),
        .can_tx(tx_can_tx),
        .tx_en(tx_en),
        .tx_complete(tx_complete),
        .arb_lost(arb_lost),
        .msg_due_tx(msg_due_tx),
        .tx_buf_clr(tx_buf_clr),
        .listen_after_arb(listen_after_arb)
    );

    can_rx_path RX_DUT (
        .clk(clk),
        .n_rst(n_rst),
        .sample_tick(sample_tick),
        .sampled_bit(can_rx),
        .hard_sync_pulse(hard_sync_pulse),
        .tx_en(1'b0),
        .rx_buf_full(rx_full),
        .rx_en(rx_en),
        .fd(fd),
        .rx_push(rx_push),
        .rx_push_id(rx_push_id),
        .rx_push_dlc(rx_push_dlc),
        .rx_push_data(rx_push_data),
        .rx_ready(rx_ready),
        .crc_err(crc_err),
        .stf_err(stf_err),
        .error_flag(error_flag)
    );

    rx_buffer #(.DEPTH(4)) RX_BUF (
        .clk(clk),
        .n_rst(n_rst),
        .push(rx_push),
        .pop(1'b0),
        .push_id(rx_push_id),
        .push_dlc(rx_push_dlc),
        .push_data(rx_push_data),
        .head_id(rx_head_id),
        .head_dlc(rx_head_dlc),
        .head_data(rx_head_data),
        .empty(rx_empty),
        .full(rx_full),
        .count(rx_count)
    );

    initial begin
        n_rst = 1'b1;
        tx_buf_valid = 1'b0;
        tx_buf_id = 11'd0;
        tx_buf_dlc = 4'd0;
        tx_buf_data = 64'd0;
        tx_request = 1'b0;
        error = 1'b0;
        error_passive = 1'b0;
        error_active = 1'b1;

        reset_dut();

        tx_buf_valid = 1'b1;
        tx_buf_id = 11'h2AA;
        tx_buf_dlc = 4'd1;
        tx_buf_data = 64'hB300_0000_0000_0000;

        @(posedge clk);
        tx_request = 1'b1;
        @(posedge clk);
        tx_request = 1'b0;

        repeat (30000) @(posedge clk);

        tx_buf_valid = 1'b1;
        tx_buf_id = 11'h155;
        tx_buf_dlc = 4'd8;
        tx_buf_data = 64'h1122_3344_5566_7788;

        @(posedge clk);
        tx_request = 1'b1;
        @(posedge clk);
        tx_request = 1'b0;

        repeat (45000) @(posedge clk);

        tx_buf_valid = 1'b0;
        repeat (1000) @(posedge clk);

        $finish;
    end

endmodule

/* verilator coverage_on */
