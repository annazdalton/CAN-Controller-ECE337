`timescale 1ns / 10ps

module CAN_fsm (
    input logic clk,
    input logic n_rst,
    input logic tx_request,
    input logic bus_idle,
    input logic node_off,
    input logic data_done,
    input logic error_done,
    input logic tx_bit,
    input logic arb_field_done,
    input logic eof_done,
    input logic bus_bit,
    input logic error_request,

    output logic sof_en,
    output logic arb_en,
    output logic crc_rst,
    output logic data_en,
    output logic ack_en,
    output logic ack_delim_en,
    output logic eof_en,
    output logic error
);

    logic count_en, count_clear, ifs_count_done;
    //2 bit counter, rollover val = 3
    flex_counter_CDL #(
        .SIZE(2)
    ) counter (
        .clk(clk),
        .n_rst(n_rst),
        .count_enable(count_en),
        .clear(count_clear),
        .rollover_val(2'd3),
        .count_out(),
        .rollover_flag(ifs_count_done)
    );

    typedef enum logic [3:0] {
        IDLE = 4'd0,
        SOF = 4'd1,
        ARB = 4'd2,
        DATA = 4'd3,
        ACK = 4'd4,
        ACK_DELIM = 4'd5,
        EOF = 4'd6,
        IFS = 4'd7,
        ERROR = 4'd8
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        //default
        next_state = state;

        case (state)
            IDLE: begin
                sof_en = 1'b0;
                arb_en = 1'b0;
                crc_rst = 1'b0;
                data_en = 1'b0;
                ack_en = 1'b0;
                ack_delim_en = 1'b0;
                eof_en = 1'b0;
                error = 1'b0;

                count_clear = 1'b1;
                count_en = 1'b0;

                if (error_request) begin
                    next_state = ERROR;
                end else if (tx_request & bus_idle & !node_off) begin
                    next_state = SOF;
                end else begin
                    next_state = IDLE;
                end
            end
            SOF: begin
                sof_en = 1'b1;
                arb_en = 1'b0;
                crc_rst = 1'b1;
                data_en = 1'b0;
                ack_en = 1'b0;
                ack_delim_en = 1'b0;
                eof_en = 1'b0;
                error = 1'b0;

                count_clear = 1'b0;
                count_en = 1'b0;

                if (error_request) begin
                    next_state = ERROR;
                end else if (tx_bit & !bus_bit) begin
                    next_state = ERROR;
                end else begin
                    next_state = ARB;
                end
            end
            ARB: begin
                sof_en = 1'b0;
                arb_en = 1'b1;
                crc_rst = 1'b0;
                data_en = 1'b0;
                ack_en = 1'b0;
                ack_delim_en = 1'b0;
                eof_en = 1'b0;
                error = 1'b0;

                count_en = 1'b0;
                count_clear = 1'b0;

                if (error_request) begin
                    next_state = ERROR;
                end else if (arb_field_done) begin
                    next_state = DATA;
                end else begin
                    next_state = ARB;
                end
            end
            DATA: begin
                sof_en = 1'b0;
                arb_en = 1'b0;
                crc_rst = 1'b0;
                data_en = 1'b1;
                ack_en = 1'b0;
                ack_delim_en = 1'b0;
                eof_en = 1'b0;
                error = 1'b0;

                count_en = 1'b0;
                count_clear = 1'b0;

                if (error_request) begin
                    next_state = ERROR;
                end else if (data_done) begin
                    next_state = ACK;
                end else begin
                    next_state = DATA;
                end
            end
            ACK: begin
                sof_en = 1'b0;
                arb_en = 1'b1;
                crc_rst = 1'b0;
                data_en = 1'b0;
                ack_en = 1'b1;
                ack_delim_en = 1'b0;
                eof_en = 1'b0;
                error = 1'b0;

                count_en = 1'b0;
                count_clear = 1'b0;

                if (error_request) begin
                    next_state = ERROR;
                end else begin
                    next_state = ACK_DELIM;
                end
            end
            ACK_DELIM: begin
                sof_en = 1'b0;
                arb_en = 1'b0;
                crc_rst = 1'b0;
                data_en = 1'b0;
                ack_en = 1'b0;
                ack_delim_en = 1'b1;
                eof_en = 1'b0;
                error = 1'b0;

                count_en = 1'b0;
                count_clear = 1'b0;

                if (error_request) begin
                    next_state = ERROR;
                end else begin
                    next_state = EOF;
                end
            end
            EOF: begin
                sof_en = 1'b0;
                arb_en = 1'b0;
                crc_rst = 1'b0;
                data_en = 1'b0;
                ack_en = 1'b0;
                ack_delim_en = 1'b0;
                eof_en = 1'b1;
                error = 1'b0;

                count_en = 1'b0;
                count_clear = 1'b0;

                if (error_request) begin
                    next_state = ERROR;
                end else if (eof_done) begin
                    next_state = IFS;
                end else begin
                    next_state = EOF;
                end
            end
            IFS: begin
                sof_en = 1'b0;
                arb_en = 1'b0;
                crc_rst = 1'b0;
                data_en = 1'b0;
                ack_en = 1'b0;
                ack_delim_en = 1'b0;
                eof_en = 1'b0;
                error = 1'b0;

                count_en = 1'b1;
                count_clear = 1'b0;

                if (ifs_count_done) begin
                    next_state = IDLE;
                end else begin
                    next_state = IFS;
                end
            end
            ERROR: begin
                sof_en = 1'b0;
                arb_en = 1'b0;
                crc_rst = 1'b0;
                data_en = 1'b0;
                ack_en = 1'b0;
                ack_delim_en = 1'b0;
                eof_en = 1'b0;
                error = 1'b1;

                count_en = 1'b0;
                count_clear = 1'b0;

                if (error_done) begin
                    next_state = IDLE;
                end else begin
                    next_state = ERROR;
                end
            end
            default: begin
                sof_en = 1'b0;
                arb_en = 1'b0;
                crc_rst = 1'b0;
                data_en = 1'b0;
                ack_en = 1'b0;
                ack_delim_en = 1'b0;
                eof_en = 1'b0;
                error = 1'b0;

                count_en = 1'b0;
                count_clear = 1'b0;

                next_state = IDLE;
            end
        endcase
    end

endmodule
