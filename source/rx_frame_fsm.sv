`timescale 1ns / 10ps

module rx_frame_fsm #(
    // parameters
) (
    input logic clk,
    input logic n_rst,
    input logic start,
    input logic bit_valid,
    input logic bit_in,

    output logic busy,
    output logic payload_len_valid,
    output logic [7:0] payload_len,
    output logic [7:0] frame_len,
    output logic payload_done,
    output logic done,
    output logic crc_error,
    output logic format_error,
    output logic [10:0] frame_id,
    output logic [3:0] frame_dlc,
    output logic [63:0] frame_data
);

    localparam logic [14:0] CRC_POLY = 15'b100010110011001;

    logic [7:0] bit_count;
    logic [6:0] data_bits;
    logic [7:0] crc_start_idx;
    logic [14:0] calc_crc;
    logic [14:0] recv_crc;

    logic crc_feedback;
    logic [14:0] calc_crc_next;

    assign data_bits = {frame_dlc, 3'b000};
    assign crc_start_idx = 8'd18 + {1'b0, data_bits};
    assign busy = (bit_count != 8'd0) || payload_len_valid;

    always_comb begin
        crc_feedback = calc_crc[14] ^ bit_in;
        calc_crc_next = {calc_crc[13:0], 1'b0};
        if (crc_feedback) begin
            calc_crc_next = calc_crc_next ^ CRC_POLY;
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            bit_count <= 8'd0;
            payload_len_valid <= 1'b0;
            payload_len <= 8'd0;
            frame_len <= 8'd0;
            payload_done <= 1'b0;
            done <= 1'b0;
            crc_error <= 1'b0;
            format_error <= 1'b0;
            frame_id <= 11'd0;
            frame_dlc <= 4'd0;
            frame_data <= 64'd0;
            calc_crc <= 15'd0;
            recv_crc <= 15'd0;
        end else begin
            payload_done <= 1'b0;
            done <= 1'b0;

            if (start) begin
                bit_count <= 8'd0;
                payload_len_valid <= 1'b0;
                payload_len <= 8'd0;
                frame_len <= 8'd0;
                crc_error <= 1'b0;
                format_error <= 1'b0;
                frame_id <= 11'd0;
                frame_dlc <= 4'd0;
                frame_data <= 64'd0;
                calc_crc <= 15'd0;
                recv_crc <= 15'd0;
            end else if (bit_valid) begin
                if (bit_count < crc_start_idx) begin
                    calc_crc <= calc_crc_next;
                end

                if (bit_count == 8'd0) frame_id[10] <= bit_in;
                if (bit_count == 8'd1) frame_id[9] <= bit_in;
                if (bit_count == 8'd2) frame_id[8] <= bit_in;
                if (bit_count == 8'd3) frame_id[7] <= bit_in;
                if (bit_count == 8'd4) frame_id[6] <= bit_in;
                if (bit_count == 8'd5) frame_id[5] <= bit_in;
                if (bit_count == 8'd6) frame_id[4] <= bit_in;
                if (bit_count == 8'd7) frame_id[3] <= bit_in;
                if (bit_count == 8'd8) frame_id[2] <= bit_in;
                if (bit_count == 8'd9) frame_id[1] <= bit_in;
                if (bit_count == 8'd10) frame_id[0] <= bit_in;

                if ((bit_count == 8'd11) || (bit_count == 8'd12) || (bit_count == 8'd13)) begin
                    if (bit_in != 1'b0) begin
                        format_error <= 1'b1;
                    end
                end

                if (bit_count == 8'd14) frame_dlc[3] <= bit_in;
                if (bit_count == 8'd15) frame_dlc[2] <= bit_in;
                if (bit_count == 8'd16) frame_dlc[1] <= bit_in;

                if (bit_count == 8'd17) begin
                    frame_dlc[0] <= bit_in;
                    payload_len_valid <= 1'b1;
                    payload_len <= 8'd33 + {frame_dlc[3:1], bit_in, 3'b000};
                    frame_len <= 8'd43 + {frame_dlc[3:1], bit_in, 3'b000};
                    if ({frame_dlc[3:1], bit_in} > 4'd8) begin
                        format_error <= 1'b1;
                    end
                end

                if (payload_len_valid && (bit_count >= 8'd18) && (bit_count < crc_start_idx)) begin
                    frame_data[63 - (bit_count - 8'd18)] <= bit_in;
                end

                if (payload_len_valid && (bit_count >= crc_start_idx) && (bit_count < (crc_start_idx + 8'd15))) begin
                    recv_crc[14 - (bit_count - crc_start_idx)] <= bit_in;
                end

                if (payload_len_valid && (bit_count == (payload_len - 1'b1))) begin
                    payload_done <= 1'b1;
                end

                if (payload_len_valid && (bit_count == (crc_start_idx + 8'd15))) begin
                    if (bit_in != 1'b1) begin
                        format_error <= 1'b1;
                    end
                end

                if (payload_len_valid && (bit_count == (crc_start_idx + 8'd17))) begin
                    if (bit_in != 1'b1) begin
                        format_error <= 1'b1;
                    end
                end

                if (payload_len_valid && (bit_count >= (crc_start_idx + 8'd18)) && (bit_count <= (crc_start_idx + 8'd24))) begin
                    if (bit_in != 1'b1) begin
                        format_error <= 1'b1;
                    end
                end

                if (payload_len_valid && (bit_count == (frame_len - 1'b1))) begin
                    done <= 1'b1;
                    if (recv_crc != calc_crc) begin
                        crc_error <= 1'b1;
                    end
                    bit_count <= 8'd0;
                    payload_len_valid <= 1'b0;
                end else begin
                    bit_count <= bit_count + 1'b1;
                end
            end
        end
    end

endmodule
