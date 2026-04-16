`timescale 1ns / 10ps

module bit_stuff #(
    // parameters
) (
    input logic clk,
    input logic n_rst,
    input logic stuffing_enable,

    input logic in_valid,
    input logic in_bit,
    output logic in_ready,

    output logic out_valid,
    output logic out_bit,
    input logic out_ready
);

    logic last_bit;
    logic [2:0] count;
    logic stuffing;

    logic next_last_bit;
    logic [2:0] next_count;
    logic next_stuffing;

    always_comb begin
        in_ready = 1'b0;
        out_valid = 1'b0;
        out_bit = in_bit;

        if (stuffing_enable) begin
            if (stuffing) begin
                out_valid = 1'b1;
                out_bit = ~last_bit;
                in_ready = 1'b0;
            end else begin
                out_valid = in_valid;
                out_bit = in_bit;
                in_ready = out_ready;
            end
        end else begin
            out_valid = in_valid;
            out_bit = in_bit;
            in_ready = out_ready;
        end
    end

    always_comb begin
        next_last_bit = last_bit;
        next_count = count;
        next_stuffing = stuffing;

        if (!stuffing_enable) begin
            next_last_bit = 1'b0;
            next_count = 3'd0;
            next_stuffing = 1'b0;
        end else begin
            if (stuffing) begin
                if (out_ready) begin
                    next_stuffing = 1'b0;
                    next_last_bit = ~last_bit;
                    next_count = 3'd1;
                end
            end else if (in_valid && in_ready) begin
                if (count == 3'd0) begin
                    next_last_bit = in_bit;
                    next_count = 3'd1;
                end else if (in_bit == last_bit) begin
                    if (count == 3'd4) begin
                        next_count = 3'd5;
                        next_stuffing = 1'b1;
                    end else begin
                        next_count = count + 1'b1;
                    end
                end else begin
                    next_last_bit = in_bit;
                    next_count = 3'd1;
                end
            end
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            last_bit <= 1'b0;
            count <= 3'd0;
            stuffing <= 1'b0;
        end else begin
            last_bit <= next_last_bit;
            count <= next_count;
            stuffing <= next_stuffing;
        end
    end

endmodule
