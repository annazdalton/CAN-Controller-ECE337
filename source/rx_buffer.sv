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
    output logic [$clog2(DEPTH+1)-1:0] count
);

    localparam PTR_W = (DEPTH <= 2) ? 1 : $clog2(DEPTH);

    logic [ID_W-1:0] id_mem [0:DEPTH-1];
    logic [DLC_W-1:0] dlc_mem [0:DEPTH-1];
    logic [DATA_W-1:0] data_mem [0:DEPTH-1];

    logic [PTR_W-1:0] wr_ptr;
    logic [PTR_W-1:0] rd_ptr;

    logic do_push;
    logic do_pop;

    assign empty = (count == '0);
    assign full = (count == DEPTH[$clog2(DEPTH+1)-1:0]);

    assign do_push = push && !full;
    assign do_pop = pop && !empty;

    assign head_id = id_mem[rd_ptr];
    assign head_dlc = dlc_mem[rd_ptr];
    assign head_data = data_mem[rd_ptr];

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            count <= '0;
        end else begin
            if (do_push) begin
                id_mem[wr_ptr] <= push_id;
                dlc_mem[wr_ptr] <= push_dlc;
                data_mem[wr_ptr] <= push_data;

                if (wr_ptr == PTR_W'(DEPTH - 1)) begin
                    wr_ptr <= '0;
                end else begin
                    wr_ptr <= wr_ptr + 1'b1;
                end
            end

            if (do_pop) begin
                if (rd_ptr == PTR_W'(DEPTH - 1)) begin
                    rd_ptr <= '0;
                end else begin
                    rd_ptr <= rd_ptr + 1'b1;
                end
            end

            case ({do_push, do_pop})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
