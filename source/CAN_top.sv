`timescale 1ns / 10ps

module CAN_top #(
    // parameters
) (
    input logic clk,
    input logic n_rst,

    input logic bus_rx,

    //ports for host interface
    input logic host_wr_req,
    input logic host_rd_req,
    input logic [7:0] host_wdata,
    input logic [5:0] host_addr,

    output logic tx_bit,
    output logic tx_buf_valid,
    output logic tx_complete,
    output logic arb_lost,

    output logic [10:0] rx_head_id,
    output logic [3:0] rx_head_dlc,
    output logic [63:0] rx_head_data,
    output logic rx_buf_empty,
    output logic rx_buf_full,
    output logic [3:0] rx_count,

    output logic rx_ready,
    output logic crc_err,
    output logic stf_err,

    //ports for host interface
    output logic [7:0] host_rdata,
    output logic host_wr_ack,
    output logic host_rd_ack,
    output logic irq
);

    logic bit_tick;
    logic sample_tick;
    logic hard_sync_pulse;
    logic sampled_bit;
    logic rx_fd;
    logic tx_fd_phase;
    logic timing_fd;

    logic tx_en;
    logic tx_buf_clr;

    logic bus_idle;

    logic [10:0] tx_buf_id;
    logic [3:0] tx_buf_dlc;
    logic [63:0] tx_buf_data;

    logic rx_push;
    logic [10:0] rx_push_id;
    logic [3:0] rx_push_dlc;
    logic [63:0] rx_push_data;
    logic rx_en;

    logic tx_wr_en;
    logic [10:0] tx_wr_id;
    logic [3:0] tx_wr_dlc;
    logic [63:0] tx_wr_data;
    logic tx_request;
    logic rx_pop;

    logic bt_enable;
    logic [9:0] bt_brp;
    logic [5:0] bt_tq_per_bit;
    logic [5:0] bt_sample_tq;
    logic [5:0] bt_sjw;
    logic bt_fd;

    logic error_passive;
    logic error_active;
    logic bus_off;
    logic bus_off_tec_rec;

    logic data_done;
    logic eof_done;

    //error signals
    logic rx_crc_err;
    logic rx_stf_err;
    logic rx_error_flag;
    logic proto_error_req;  //protocol fsm error input
    logic send_error_frame;
    logic error_done;
    logic tx_error;

    // debug taps for otherwise-unconnected internal module outputs
    logic dbg_bt_tq_tick;
    logic dbg_bt_resync_pulse;
    logic dbg_bt_early_edge;
    logic dbg_bt_late_edge;
    logic dbg_bt_timing_error;
    logic dbg_tx_msg_due_tx;
    logic dbg_tx_listen_after_arb;
    logic dbg_fsm_sof_en;
    logic dbg_fsm_arb_en;
    logic dbg_fsm_crc_rst;
    logic dbg_fsm_data_en;
    logic dbg_fsm_ack_en;
    logic dbg_fsm_ack_delim_en;
    logic dbg_fsm_eof_en;
    logic dbg_tec_recovery_done;

    assign proto_error_req = rx_stf_err | rx_crc_err | rx_error_flag;
    assign bus_idle = bus_rx && !tx_en;
    assign tx_error = tx_bit != bus_rx;
    assign bus_off = bus_off_tec_rec;
    assign crc_err = rx_crc_err;
    assign stf_err = rx_stf_err;
    assign data_done = tx_complete;
    assign eof_done = tx_complete;
    assign timing_fd = tx_fd_phase ? 1'b1 : rx_fd;


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
        .fd(timing_fd),
        .can_rx(bus_rx),
        .tq_tick(dbg_bt_tq_tick),
        .sample_tick(sample_tick),
        .bit_tick(bit_tick),
        .hard_sync_pulse(hard_sync_pulse),
        .resync_pulse(dbg_bt_resync_pulse),
        .early_edge(dbg_bt_early_edge),
        .late_edge(dbg_bt_late_edge),
        .timing_error(dbg_bt_timing_error),
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
        .tx_fd_cfg(bt_fd),
        .can_tx(tx_bit),
        .tx_en(tx_en),
        .tx_complete(tx_complete),
        .arb_lost(arb_lost),
        .msg_due_tx(dbg_tx_msg_due_tx),
        .tx_buf_clr(tx_buf_clr),
        .listen_after_arb(dbg_tx_listen_after_arb),
        .tx_fd_phase(tx_fd_phase),
        .error(send_error_frame),
        .error_passive(error_passive),
        .error_active(error_active),
        .error_done(error_done)
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
        .fd(rx_fd),
        .rx_push(rx_push),
        .rx_push_id(rx_push_id),
        .rx_push_dlc(rx_push_dlc),
        .rx_push_data(rx_push_data),
        .rx_ready(rx_ready),
        .crc_err(rx_crc_err),
        .stf_err(rx_stf_err),
        .error_flag(rx_error_flag)
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

    CAN_fsm protocol_fsm (
        .clk(clk),
        .n_rst(n_rst),
        .tx_request(tx_request),
        .bus_idle(bus_idle),
        .node_off(bus_off),
        .data_done(data_done),
        .error_done(error_done),
        .tx_bit(tx_bit),
        .arb_field_done(1'b1),
        .eof_done(eof_done),
        .bus_bit(bus_rx),
        .error_request(proto_error_req),

        .sof_en(dbg_fsm_sof_en),
        .arb_en(dbg_fsm_arb_en),
        .crc_rst(dbg_fsm_crc_rst),
        .data_en(dbg_fsm_data_en),
        .ack_en(dbg_fsm_ack_en),
        .ack_delim_en(dbg_fsm_ack_delim_en),
        .eof_en(dbg_fsm_eof_en),
        .error(send_error_frame)
    );

    CAN_error_counters tec_rec (
        .clk(clk),
        .n_rst(n_rst),

        //this might be wrong, maybe try changing error singals to pulse
        .tx_error(tx_error),
        .tx_success(tx_complete),
        .rx_error(proto_error_req),
        .rx_success(rx_ready),

        .bus_rx(bus_rx),
        .bus_off_i(bus_off),

        .error_active(error_active),
        .error_passive(error_passive),
        .bus_off(bus_off_tec_rec),
        .recovery_done(dbg_tec_recovery_done)
    );

    host_cfg_top #(
        .DATA_W(8),
        .ADDR_W(6),
        .IRQ_W(3)
    ) host_cfg (
        .clk(clk),
        .n_rst(n_rst),

        .host_wr_req(host_wr_req),
        .host_rd_req(host_rd_req),
        .host_wdata(host_wdata),
        .host_addr(host_addr),
        .host_rdata(host_rdata),
        .host_wr_ack(host_wr_ack),
        .host_rd_ack(host_rd_ack),

        .evt_rx_ready(rx_ready),
        .evt_tx_complete(tx_complete),
        .evt_error(proto_error_req),

        .tx_id_cfg(tx_wr_id),
        .tx_dlc_cfg(tx_wr_dlc),
        .tx_data_cfg(tx_wr_data),
        .tx_wr_en_pulse(tx_wr_en),
        .tx_request(tx_request),
        .rx_pop_pulse(rx_pop),
        .irq(irq),

        .bt_enable(bt_enable),
        .bt_brp(bt_brp),
        .bt_tq_per_bit(bt_tq_per_bit),
        .bt_sample_tq(bt_sample_tq),
        .bt_sjw(bt_sjw),
        .bt_fd(bt_fd),

        .rx_head_id(rx_head_id),
        .rx_head_dlc(rx_head_dlc),
        .rx_head_data(rx_head_data),
        .rx_buf_empty(rx_buf_empty),
        .rx_buf_full(rx_buf_full),
        .rx_count(rx_count)
    );

endmodule
