`timescale 1ns / 10ps

module host_cfg_top #(
    // parameters
    parameter DATA_W = 8,
    parameter ADDR_W = 5,
    parameter IRQ_W = 3
) (
    input logic clk, n_rst,

    //Host interface inputs
    input logic host_wr_req,
    input logic host_rd_req,
    input logic [DATA_W - 1: 0] host_wdata,
    input logic [ADDR_W - 1: 0] host_addr,

    //Event controlled inputs from rest of CAN controller
    input logic evt_rx_ready,
    input logic evt_tx_complete,
    input logic evt_error,

    //Host interface outputs
    output logic [DATA_W-1:0] host_rdata,
    output logic host_wr_ack,
    output logic host_rd_ack,

    // TX datapath outputs
    output logic [10:0] tx_id_cfg,
    output logic [3:0] tx_dlc_cfg,
    output logic [63:0] tx_data_cfg,
    output logic tx_wr_en_pulse,
    output logic tx_request,

    //rx datapath outputs
    output logic rx_pop_pulse,

    //irq output
    output logic irq
);

//internal host_interface <-> register_bank
logic reg_wr_en;
logic reg_rd_en;
logic [DATA_W - 1:0] reg_wdata;
logic [ADDR_W - 1:0] reg_addr;
logic [DATA_W - 1:0] reg_rdata;
logic wr_accept;
logic rd_valid;

//internal register_bank <-> irq_status_control
logic [IRQ_W - 1:0] irq_enable_reg;
logic [IRQ_W - 1:0] irq_clear;
logic [IRQ_W - 1:0] irq_status;


host_interface #(.DATA_W(DATA_W), .ADDR_W(ADDR_W)) top_hi (
    .clk(clk),
    .n_rst(n_rst),
    .host_wr_req(host_wr_req),
    .host_rd_req(host_rd_req),
    .host_wdata(host_wdata),
    .host_addr(host_addr),
    .reg_rdata(reg_rdata),
    .wr_accept(wr_accept),
    .rd_valid(rd_valid),
    .host_rdata(host_rdata),
    .host_wr_ack(host_wr_ack),
    .host_rd_ack(host_rd_ack),
    .reg_wr_en(reg_wr_en),
    .reg_rd_en(reg_rd_en),
    .reg_wdata(reg_wdata),
    .reg_addr(reg_addr)
);

register_bank #(.DATA_W(DATA_W), .ADDR_W(ADDR_W), .IRQ_W(IRQ_W)) top_rb (
    .clk(clk),
    .n_rst(n_rst),
    .reg_wr_en(reg_wr_en),
    .reg_rd_en(reg_rd_en),
    .reg_wdata(reg_wdata),
    .reg_addr(reg_addr),
    .irq_status(irq_status),
    .reg_rdata(reg_rdata),
    .wr_accept(wr_accept),
    .rd_valid(rd_valid),
    .irq_enable_reg(irq_enable_reg),
    .irq_clear(irq_clear),   
    .tx_id_cfg (tx_id_cfg),
    .tx_dlc_cfg (tx_dlc_cfg),
    .tx_data_cfg (tx_data_cfg),
    .tx_wr_en_pulse (tx_wr_en_pulse),
    .tx_request (tx_request),
    .rx_pop_pulse (rx_pop_pulse)
);

irq_status_control #(.IRQ_W(IRQ_W)) top_irq_sc (
    .clk(clk),
    .n_rst(n_rst),
    .irq_clear(irq_clear),
    .irq_enable_reg(irq_enable_reg),
    .evt_rx_ready(evt_rx_ready),
    .evt_tx_complete(evt_tx_complete),
    .evt_error(evt_error),
    .irq_status(irq_status),
    .irq(irq)
);

endmodule

