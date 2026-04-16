`timescale 1ns / 10ps

module CRC_generator #(
    // parameters
) (
    input logic clk,
    input logic n_rst,

    input logic start,

    input logic sof_bit,
    input logic [10:0] identifier,
    input logic rtr_bit,
    input logic ide_bit,
    input logic r0_bit,
    input logic [3:0] dlc,
    input logic [63:0] data,

    output logic done,
    output logic [14:0] crc_out
);

    // CAN CRC-15 polynomial: x^15 + x^14 + x^10 + x^8 + x^7 + x^4 + x^3 + 1
    // without x^15 term in register XOR mask => 0x4599
    localparam logic [14:0] POLY = 15'b100010110011001;

    logic [14:0] crc_reg;
    logic [14:0] next_crc;

    logic [6:0] bit_idx;
    logic [6:0] next_bit_idx;
    logic [6:0] data_bits;
    logic [6:0] total_bits;

    logic busy;
    logic next_busy;

    logic next_done;

    logic current_bit;
    logic feedback;

    assign data_bits = {dlc, 3'b000};
    assign total_bits = 7'd19 + data_bits;
    assign crc_out = crc_reg;

    always_comb begin
        current_bit = 1'b0;

        if (bit_idx == 7'd0) begin
            current_bit = sof_bit;
        end else if ((bit_idx >= 7'd1) && (bit_idx <= 7'd11)) begin
            current_bit = identifier[11 - bit_idx];
        end else if (bit_idx == 7'd12) begin
            current_bit = rtr_bit;
        end else if (bit_idx == 7'd13) begin
            current_bit = ide_bit;
        end else if (bit_idx == 7'd14) begin
            current_bit = r0_bit;
        end else if ((bit_idx >= 7'd15) && (bit_idx <= 7'd18)) begin
            current_bit = dlc[18 - bit_idx];
        end else begin
            current_bit = data[63 - (bit_idx - 7'd19)];
        end
    end

    always_comb begin
        next_crc = crc_reg;
        next_bit_idx = bit_idx;
        next_busy = busy;
        next_done = 1'b0;

        feedback = 1'b0;

        if (!busy) begin
            if (start) begin
                next_crc = 15'd0;
                next_bit_idx = 7'd0;
                next_busy = 1'b1;
            end
        end else begin
            if (bit_idx < total_bits) begin
                feedback = crc_reg[14] ^ current_bit;

                next_crc = {crc_reg[13:0], 1'b0};
                if (feedback) begin
                    next_crc = next_crc ^ POLY;
                end

                next_bit_idx = bit_idx + 1'b1;
            end else begin
                next_busy = 1'b0;
                next_done = 1'b1;
            end
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            crc_reg <= 15'd0;
            bit_idx <= 7'd0;
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            crc_reg <= next_crc;
            bit_idx <= next_bit_idx;
            busy <= next_busy;
            done <= next_done;
        end
    end

endmodule
