`timescale 1ns / 10ps

module can_rx_path #(
    parameter MAX_FRAME_BITS = 160
) (
    input logic clk,
    input logic n_rst,
    input logic sample_tick,
    input logic sampled_bit,
    input logic hard_sync_pulse,
    input logic tx_en,
    input logic rx_buf_full,

    output logic rx_en,
    output logic fd,
    output logic rx_push,
    output logic [10:0] rx_push_id,
    output logic [3:0] rx_push_dlc,
    output logic [63:0] rx_push_data,

    output logic rx_ready,
    output logic crc_err,
    output logic stf_err,
    output logic error_flag
);

    typedef enum logic [0:0] {
        RX_IDLE,
        RX_ACTIVE
    } rx_state_t;

    rx_state_t state;
    rx_state_t next_state;

    logic destuff_enable;
    logic next_destuff_enable;

    logic destuff_out_valid;
    logic destuff_out_bit;
    logic destuff_stuff_error;

    logic parser_start;
    logic parser_done;
    logic parser_crc_error;
    logic parser_format_error;
    logic parser_payload_done;
    logic parser_fd;
    logic parser_payload_len_valid;
    logic [7:0] parser_payload_len;
    logic [7:0] parser_frame_len;
    logic [10:0] parser_id;
    logic [3:0] parser_dlc;
    logic [63:0] parser_data;

    logic stuff_have_last;
    logic stuff_last_bit;
    logic [2:0] stuff_run_count;
    logic stuff_expect;

    logic next_stuff_have_last;
    logic next_stuff_last_bit;
    logic [2:0] next_stuff_run_count;
    logic next_stuff_expect;
    logic pending_disable;
    logic next_pending_disable;

    logic next_rx_en;
    logic next_fd;
    logic next_rx_push;
    logic [10:0] next_rx_push_id;
    logic [3:0] next_rx_push_dlc;
    logic [63:0] next_rx_push_data;
    logic next_rx_ready;
    logic next_crc_err;
    logic next_stf_err;
    logic next_error_flag;

    bit_destuff u_bit_destuff (
        .clk(clk),
        .n_rst(n_rst),
        .destuff_enable(destuff_enable),
        .in_valid(sample_tick && (state == RX_ACTIVE)),
        .in_bit(sampled_bit),
        .in_ready(),
        .out_valid(destuff_out_valid),
        .out_bit(destuff_out_bit),
        .stuff_error(destuff_stuff_error),
        .out_ready(1'b1)
    );

    rx_frame_fsm u_rx_frame_fsm (
        .clk(clk),
        .n_rst(n_rst),
        .start(parser_start),
        .bit_valid(destuff_out_valid && (state == RX_ACTIVE)),
        .bit_in(destuff_out_bit),
        .busy(),
        .payload_len_valid(parser_payload_len_valid),
        .payload_len(parser_payload_len),
        .frame_len(parser_frame_len),
        .payload_done(parser_payload_done),
        .fd(parser_fd),
        .done(parser_done),
        .crc_error(parser_crc_error),
        .format_error(parser_format_error),
        .frame_id(parser_id),
        .frame_dlc(parser_dlc),
        .frame_data(parser_data)
    );

    always_comb begin
        next_state = state;
        parser_start = 1'b0;

        next_destuff_enable = destuff_enable;

        next_stuff_have_last = stuff_have_last;
        next_stuff_last_bit = stuff_last_bit;
        next_stuff_run_count = stuff_run_count;
        next_stuff_expect = stuff_expect;
        next_pending_disable = pending_disable;

        next_rx_en = rx_en;
        next_fd = fd;
        next_rx_push = 1'b0;
        next_rx_push_id = rx_push_id;
        next_rx_push_dlc = rx_push_dlc;
        next_rx_push_data = rx_push_data;
        next_rx_ready = 1'b0;
        next_crc_err = 1'b0;
        next_stf_err = 1'b0;
        next_error_flag = 1'b0;

        case (state)
            RX_IDLE: begin
                next_rx_en = 1'b0;
                next_fd = 1'b0;
                next_destuff_enable = 1'b0;
                next_stuff_have_last = 1'b0;
                next_stuff_last_bit = 1'b0;
                next_stuff_run_count = 3'd0;
                next_stuff_expect = 1'b0;
                next_pending_disable = 1'b0;

                if (!tx_en && hard_sync_pulse) begin
                    next_state = RX_ACTIVE;
                    next_rx_en = 1'b1;
                    next_destuff_enable = 1'b1;
                    parser_start = 1'b1;
                end
            end

            RX_ACTIVE: begin
                next_rx_en = 1'b1;
                next_fd = parser_fd;

                if (destuff_stuff_error) begin
                    next_stf_err = 1'b1;
                    next_error_flag = 1'b1;
                end

                if (sample_tick && destuff_enable) begin
                    if (stuff_expect) begin
                        if (sampled_bit == stuff_last_bit) begin
                            next_stf_err = 1'b1;
                            next_error_flag = 1'b1;
                        end else begin
                            next_stuff_expect = 1'b0;
                            next_stuff_have_last = 1'b1;
                            next_stuff_last_bit = sampled_bit;
                            next_stuff_run_count = 3'd1;
                            if (pending_disable) begin
                                next_destuff_enable = 1'b0;
                                next_pending_disable = 1'b0;
                            end
                        end
                    end else begin
                        if (!stuff_have_last) begin
                            next_stuff_have_last = 1'b1;
                            next_stuff_last_bit = sampled_bit;
                            next_stuff_run_count = 3'd1;
                        end else if (sampled_bit == stuff_last_bit) begin
                            if (stuff_run_count == 3'd4) begin
                                next_stuff_run_count = 3'd5;
                                next_stuff_expect = 1'b1;
                            end else begin
                                next_stuff_run_count = stuff_run_count + 1'b1;
                            end
                        end else begin
                            next_stuff_last_bit = sampled_bit;
                            next_stuff_run_count = 3'd1;
                        end
                    end
                end

                if (parser_payload_done) begin
                    next_destuff_enable = 1'b0;
                    next_pending_disable = 1'b0;
                end

                if (parser_done) begin
                    next_state = RX_IDLE;
                    next_rx_en = 1'b0;
                    next_fd = 1'b0;

                    if (parser_format_error) begin
                        next_error_flag = 1'b1;
                    end else begin
                        if (parser_crc_error) begin
                            next_crc_err = 1'b1;
                        end else if (!rx_buf_full) begin
                            next_rx_push = 1'b1;
                            next_rx_push_id = parser_id;
                            next_rx_push_dlc = parser_dlc;
                            next_rx_push_data = parser_data;
                            next_rx_ready = 1'b1;
                        end
                    end
                end
            end

            default: begin
                next_state = RX_IDLE;
                next_rx_en = 1'b0;
                next_fd = 1'b0;
            end
        endcase
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            state <= RX_IDLE;
            destuff_enable <= 1'b0;
            stuff_have_last <= 1'b0;
            stuff_last_bit <= 1'b0;
            stuff_run_count <= 3'd0;
            stuff_expect <= 1'b0;
            pending_disable <= 1'b0;
            rx_en <= 1'b0;
            fd <= 1'b0;
            rx_push <= 1'b0;
            rx_push_id <= 11'd0;
            rx_push_dlc <= 4'd0;
            rx_push_data <= 64'd0;
            rx_ready <= 1'b0;
            crc_err <= 1'b0;
            stf_err <= 1'b0;
            error_flag <= 1'b0;
        end else begin
            state <= next_state;
            destuff_enable <= next_destuff_enable;
            stuff_have_last <= next_stuff_have_last;
            stuff_last_bit <= next_stuff_last_bit;
            stuff_run_count <= next_stuff_run_count;
            stuff_expect <= next_stuff_expect;
            pending_disable <= next_pending_disable;
            rx_en <= next_rx_en;
            fd <= next_fd;
            rx_push <= next_rx_push;
            rx_push_id <= next_rx_push_id;
            rx_push_dlc <= next_rx_push_dlc;
            rx_push_data <= next_rx_push_data;
            rx_ready <= next_rx_ready;
            crc_err <= next_crc_err;
            stf_err <= next_stf_err;
            error_flag <= next_error_flag;
        end
    end

endmodule
