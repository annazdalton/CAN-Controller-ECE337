`timescale 1ns / 10ps

module CAN_top #(
    // parameters
) (
    input logic clk,
    input logic n_rst,

    input logic bus_rx,
    input logic tx_request,
    input logic tx_wr_en,
    input logic [10:0] tx_wr_id,
    input logic [3:0] tx_wr_dlc,
    input logic [63:0] tx_wr_data,

    input logic rx_pop,

    input logic bt_enable,
    input logic [9:0] bt_brp,
    input logic [5:0] bt_tq_per_bit,
    input logic [5:0] bt_sample_tq,
    input logic [5:0] bt_sjw,
    input logic bt_fd,

    output logic tx_bit,
    output logic tx_buf_valid,
    output logic tx_complete,
    output logic arb_lost,

    output logic [10:0] rx_head_id,
    output logic [3:0] rx_head_dlc,
    output logic [63:0] rx_head_data,
    output logic rx_buf_empty,
    output logic rx_buf_full,
    output logic [$clog2(4+1)-1:0] rx_count,

    output logic rx_ready,
    output logic crc_err,
    output logic stf_err,
    output logic error_flag
);

    logic bit_tick;
    logic sample_tick;
    logic hard_sync_pulse;
    logic sampled_bit;

    logic tx_en;
    logic msg_due_tx;
    logic tx_buf_clr;
    logic listen_after_arb;

    logic bus_idle;

    logic [10:0] tx_buf_id;
    logic [3:0] tx_buf_dlc;
    logic [63:0] tx_buf_data;

    logic rx_push;
    logic [10:0] rx_push_id;
    logic [3:0] rx_push_dlc;
    logic [63:0] rx_push_data;
    logic rx_en;

    assign bus_idle = bus_rx && !tx_en;

    tx_buffer u_tx_buffer (
        .clk(clk),
        .n_rst(n_rst),
        .wr_en(tx_wr_en),
        .clr_valid(tx_buf_clr),
        .wr_id(tx_wr_id),
        .wr_dlc(tx_wr_dlc),
        .wr_data(tx_wr_data),
        .valid(tx_buf_valid),
        .id_out(tx_buf_id),
        .dlc_out(tx_buf_dlc),
        .data_out(tx_buf_data)
    );

    bit_timing u_bit_timing (
        .clk(clk),
        .n_rst(n_rst),
        .enable(bt_enable),
        .rx_active(rx_en),
        .bus_idle(bus_idle),
        .resync_enable(1'b1),
        .brp(bt_brp),
        .tq_per_bit(bt_tq_per_bit),
        .sample_tq(bt_sample_tq),
        .sjw(bt_sjw),
        .fd(bt_fd),
        .can_rx(bus_rx),
        .tq_tick(),
        .sample_tick(sample_tick),
        .bit_tick(bit_tick),
        .hard_sync_pulse(hard_sync_pulse),
        .resync_pulse(),
        .early_edge(),
        .late_edge(),
        .timing_error(),
        .sampled_bit(sampled_bit)
    );

    can_tx_path u_can_tx_path (
        .clk(clk),
        .n_rst(n_rst),
        .can_rx(bus_rx),
        .bit_tick(bit_tick),
        .bus_idle(bus_idle),
        .tx_buf_valid(tx_buf_valid),
        .tx_buf_id(tx_buf_id),
        .tx_buf_dlc(tx_buf_dlc),
        .tx_buf_data(tx_buf_data),
        .tx_request(tx_request),
        .can_tx(tx_bit),
        .tx_en(tx_en),
        .tx_complete(tx_complete),
        .arb_lost(arb_lost),
        .msg_due_tx(msg_due_tx),
        .tx_buf_clr(tx_buf_clr),
        .listen_after_arb(listen_after_arb)
    );

    can_rx_path u_can_rx_path (
        .clk(clk),
        .n_rst(n_rst),
        .sample_tick(sample_tick),
        .sampled_bit(sampled_bit),
        .hard_sync_pulse(hard_sync_pulse),
        .tx_en(tx_en),
        .rx_buf_full(rx_buf_full),
        .rx_en(rx_en),
        .rx_push(rx_push),
        .rx_push_id(rx_push_id),
        .rx_push_dlc(rx_push_dlc),
        .rx_push_data(rx_push_data),
        .rx_ready(rx_ready),
        .crc_err(crc_err),
        .stf_err(stf_err),
        .error_flag(error_flag)
    );

    rx_buffer #(
        .DEPTH(4)
    ) u_rx_buffer (
        .clk(clk),
        .n_rst(n_rst),
        .push(rx_push),
        .pop(rx_pop),
        .push_id(rx_push_id),
        .push_dlc(rx_push_dlc),
        .push_data(rx_push_data),
        .head_id(rx_head_id),
        .head_dlc(rx_head_dlc),
        .head_data(rx_head_data),
        .empty(rx_buf_empty),
        .full(rx_buf_full),
        .count(rx_count)
    );

endmodule
