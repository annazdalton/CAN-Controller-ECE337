`timescale 1ns / 10ps

module tx_buffer #(
    parameter DEPTH = 4,
    parameter ID_W = 11,
    parameter DLC_W = 4,
    parameter DATA_W = 64
) (
    input logic clk,
    input logic n_rst,
    input logic wr_en,
    input logic clr_valid,
    input logic [ID_W-1:0] wr_id,
    input logic [DLC_W-1:0] wr_dlc,
    input logic [DATA_W-1:0] wr_data,

    output logic valid,
    output logic [ID_W-1:0] id_out,
    output logic [DLC_W-1:0] dlc_out,
    output logic [DATA_W-1:0] data_out
);

    localparam int FIFO_W = ID_W + DLC_W + DATA_W;

    logic fifo_wen;
    logic fifo_ren;
    logic fifo_full;
    logic fifo_empty;
    logic [FIFO_W-1:0] fifo_wdata;
    logic [FIFO_W-1:0] fifo_rdata;

    assign fifo_wen = wr_en && !fifo_full;
    assign fifo_ren = clr_valid && !fifo_empty;

    assign fifo_wdata = {wr_id, wr_dlc, wr_data};
    assign {id_out, dlc_out, data_out} = fifo_rdata;
    assign valid = !fifo_empty;

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
        .full(fifo_full),
        .empty(fifo_empty),
        .underrun(),
        .overrun(),
        .count(),
        .rdata(fifo_rdata)
    );

endmodule
