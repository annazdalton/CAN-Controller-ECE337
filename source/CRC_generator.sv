`timescale 1ns / 10ps

module CRC_generator #(
    // parameters
) (
    input logic clk, n_rst,

    input logic start,
    input logic [63:0] data,
    input logic [2:0] data_len,

    output logic done,
    output logic [14:0] crc_out
);

    // generator polynomial
    localparam logic [14:0] POLY = 15'b110001011001100;

    logic [14:0] crc_reg;
    logic [2:0] byte_idx;
    logic [2:0] bit_idx;
    logic busy;
    assign crc_out = crc_reg;
    assign done = (busy && byte_idx == data_len && bit_idx == 0);
    // question above first

    logic [14:0] next_crc;
    logic [2:0] next_byte_idx;
    logic [2:0] next_bit_idx;
    logic next_busy;

    always_comb begin
        next_crc = crc_reg;
        next_byte_idx = byte_idx;
        next_bit_idx = bit_idx;
        next_busy = busy;

        if (!busy) begin
            if (start) begin
                next_crc = 15'd0;
                next_byte_idx = 0;
                next_bit_idx = 0;
                next_busy = 1;
            end
        end
        else begin
            if (byte_idx < data_len) begin
                // extract current bit (msb)
                logic current_bit;
                logic feedback;

                current_bit = data[63 - (byte_idx * 8 + bit_idx)];

                //crc step
                feedback = current_bit ^ crc_reg[14];

                next_crc = {crc_reg[13:0], 1'b0};
                if (feedback) begin
                    next_crc = next_crc ^ POLY;
                end

                if (bit_idx == 3'd7) begin
                    next_bit_idx = 0;
                    next_byte_idx = byte_idx + 1;
                end

                else begin
                    next_bit_idx = bit_idx + 1;
                end
            end
            else begin
                if (byte_idx == data_len && bit_idx == 0) begin
                    next_busy = 0;
                end
            end
        end
    end
    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            crc_reg  <= 0;
            byte_idx <= 0;
            bit_idx  <= 0;
            busy     <= 0;
        end
        else begin
            crc_reg  <= next_crc;
            byte_idx <= next_byte_idx;
            bit_idx  <= next_bit_idx;
            busy     <= next_busy;
        end
    end

endmodule

