`timescale 1ns / 10ps

module FIFO #(
    parameter SIZE = 8,
    parameter DEPTH = 10
) (
    input logic clk,
    input logic n_rst,
    input logic WEN,
    input logic REN,
    input logic clear,
    input logic [SIZE - 1:0] wdata,

    output logic full,
    output logic empty,
    output logic underrun,
    output logic overrun,
    output logic [3:0] count,
    output logic [SIZE - 1:0] rdata
);

    localparam int ADDR_SIZE = $clog2(DEPTH);
    localparam int COUNT_W = $bits(count);

    logic [SIZE - 1:0] rdata_next;

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            rdata <= '0;
        end else begin
            rdata <= rdata_next;
        end
    end

    logic underrun_next, overrun_next;
    logic [ADDR_SIZE - 1:0] write_loc, write_loc_next, read_loc, read_loc_next;
    logic [COUNT_W - 1:0] count_next;
    logic [SIZE - 1:0] fifo[DEPTH - 1];
    logic [SIZE - 1:0] fifo_next[DEPTH - 1];
    logic write_fire, read_fire;
    logic [COUNT_W - 1:0] count_inc, count_dec;

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            overrun <= '0;
            underrun <= '0;
            write_loc <= '0;
            read_loc <= '0;
            count <= '0;
            fifo <= '{default: '0};
        end else begin
            overrun <= overrun_next;
            underrun <= underrun_next;
            write_loc <= write_loc_next;
            read_loc <= read_loc_next;
            count <= count_next;
            fifo <= fifo_next;
        end
    end

    assign full = (count == COUNT_W'(DEPTH)) ? 1'b1 : 1'b0;
    assign empty = (count == '0) ? 1'b1 : 1'b0;
    assign rdata_next = fifo[read_loc];
    assign write_fire = WEN && !full && !(empty && REN);
    assign read_fire = REN && !empty && !(full && WEN);
    assign count_inc = {{(COUNT_W - 1) {1'b0}}, write_fire};
    assign count_dec = {{(COUNT_W - 1) {1'b0}}, read_fire};

    always_comb begin
        //defaults
        write_loc_next = write_loc;
        read_loc_next = read_loc;
        overrun_next = overrun;
        underrun_next = underrun;
        count_next = count;
        fifo_next = fifo;

        if (clear) begin
            read_loc_next = '0;
            write_loc_next = '0;
            overrun_next = '0;
            underrun_next = '0;
            count_next = '0;
            fifo_next = fifo;
        end else begin
            if (write_fire) begin
                write_loc_next = write_loc + {{(ADDR_SIZE - 1) {1'b0}}, 1'b1};
                fifo_next[write_loc] = wdata;
            end

            if (read_fire) begin
                read_loc_next = read_loc + {{(ADDR_SIZE - 1) {1'b0}}, 1'b1};
            end

            //errors
            if (WEN && full) begin  //overrun error
                overrun_next = 1'b1;
            end
            if (REN && empty) begin
                underrun_next = 1'b1;
            end

            count_next = count + count_inc - count_dec;
        end

    end
endmodule
