`timescale 1ns / 10ps

module rx_buffer #(
    parameter DEPTH = 4,
    parameter ID_W = 11,
    parameter DLC_W = 4,
    parameter DATA_W = 64
) (
    input logic clk,
    input logic n_rst,
    input logic push,
    input logic pop,
    input logic [ID_W-1:0] push_id,
    input logic [DLC_W-1:0] push_dlc,
    input logic [DATA_W-1:0] push_data,

    output logic [ID_W-1:0] head_id,
    output logic [DLC_W-1:0] head_dlc,
    output logic [DATA_W-1:0] head_data,
    output logic empty,
    output logic full,
    output logic [3:0] count
);

    localparam int FIFO_W = ID_W + DLC_W + DATA_W;

    logic fifo_wen;
    logic fifo_ren;
    logic [FIFO_W-1:0] fifo_wdata;
    logic [FIFO_W-1:0] fifo_rdata;

    assign fifo_wen = push && !full;
    assign fifo_ren = pop && !empty;

    assign fifo_wdata = {push_id, push_dlc, push_data};
    assign {head_id, head_dlc, head_data} = fifo_rdata;

    FIFO #(
        .SIZE(FIFO_W),
        .DEPTH(DEPTH)
    ) u_fifo (
        .clk(clk),
        .n_rst(n_rst),
        .WEN(fifo_wen),
        .REN(fifo_ren),
        .clear(1'b0),
        .wdata(fifo_wdata),
        .full(full),
        .empty(empty),
        .underrun(),
        .overrun(),
        .count(count),
        .rdata(fifo_rdata)
    );

endmodule
