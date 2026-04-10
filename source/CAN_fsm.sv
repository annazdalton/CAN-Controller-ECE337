`timescale 1ns / 10ps

module CAN_fsm (
    input logic clk, n_rst,
    input logic tx_request, bus_idle, node_off, data_done, error_idle,

    output logic sof_en, arb_en, crc_rst, data_en, ack_en, ack_delim_en, eof_en, error
);

logic count_en, count_clear, ifs_count_done;
//2 bit counter, rollover val = 3
flex_counter #(parameter SIZE = 2) (
    .clk(clk),
    .n_rst(n_rst), 
    .count_enable(count_en), 
    .clear(count_clear), 
    .rollover_val(2'd3),
    .count_out(),
    .rollover_flag(ifs_count_done)
endmodule

typedef enum logic [2:0] {
    IDLE = 3'd0,
    SOF = 3'd1,
    ARB = 3'd2,
    DATA = 3'd3,
    ACK = 3'd4,
    ACK_DELIM = 3'd5,
    EOF = 3'd6,
    IFS = 3'd7
    ERROR = 3'd8
} state_t;

state_t state, next_state;

always_ff @(posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always_comb begin
    //default
    state <= next_state; 

    case(state) 
        IDLE: begin
            sof_en = 1'b0;
            arb_en = 1'b0;
            crc_rst = 1'b0;
            data_en = 1'b0;
            ack_en = 1'b0;
            ack_delim_en = 1'b0;
            eof_en = 1'b0;
            error = 1'b0;

            count_en = 1'b0;

            if(tx_request & bus_idle & !node_off) begin
                state_next = SOF;
            end else begin
                state_next = IDLE;
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

            count_en = 1'b0;

            if(tx_bit & !bus_bit) begin
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

            if(tx_bit & !bus_bit) begin
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

            if(data_done) begin
                next_state = ERROR;
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

            next_state = ACK_DELIM;
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

            next_state = EOF;
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

            if(eof_done) begin
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

            if(error_idle) begin
                next_state = IDLE;
            end else begin
                next_state = ERROR;
            end
        end
    endcase
end