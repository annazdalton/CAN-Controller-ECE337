`timescale 1ns / 10ps

module CRC_check #(
    // parameters
) (
    input logic clk, n_rst,

    input logic start,
    input logic [63:0] data,
    input logic [2:0] data_len,
    input logic [14:0] crc_in,

    output logic done,
    output logic error
);

    localparam logic [14:0] POLY = 15'b110001011001100;

    logic [14:0] crc_reg;
    logic [6:0]  bit_count;
    logic        busy;

    logic [6:0] total_bits;
    assign total_bits = data_len * 8 + 15;

    assign done  = (busy && bit_count == total_bits);
    assign error = (done && (crc_reg != 0));


    logic [14:0] next_crc;
    logic [6:0]  next_bit_count;
    logic        next_busy;

    always_comb begin
        next_crc       = crc_reg;
        next_bit_count = bit_count;
        next_busy      = busy;

        if (!busy) begin
            if (start) begin
                next_crc       = 15'd0;
                next_bit_count = 0;
                next_busy      = 1;
            end
        end
        else begin
            if (bit_count < total_bits) begin

                logic current_bit;
                logic feedback;

                if (bit_count < data_len * 8) begin
                    // DATA region
                    current_bit = data[63 - bit_count];
                end
                else begin
                    // CRC region
                    current_bit = crc_in[14 - (bit_count - data_len * 8)];
                end

                feedback = current_bit ^ crc_reg[14];

                next_crc = {crc_reg[13:0], 1'b0};

                if (feedback) begin
                    next_crc ^= POLY;
                end

                next_bit_count = bit_count + 1;
            end
            else begin
                next_busy = 0;
            end
        end
    end


    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            crc_reg   <= 0;
            bit_count <= 0;
            busy      <= 0;
        end
        else begin
            crc_reg   <= next_crc;
            bit_count <= next_bit_count;
            busy      <= next_busy;
        end
    end
endmodule
