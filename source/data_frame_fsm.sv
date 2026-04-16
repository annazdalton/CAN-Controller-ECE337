`timescale 1ns / 10ps

module data_frame_fsm #(
    // parameters
) (
    input logic clk,
    input logic n_rst,

    input logic new_message,
    input logic [10:0] identifier,
    input logic [3:0] data_len,
    input logic [63:0] data_field,

    output logic [110:0] data_frame,
    output logic [7:0] frame_len,
    output logic [7:0] stuff_len,
    output logic busy,
    output logic data_ready
);

    typedef enum logic [2:0] {
        IDLE,
        CRC_START,
        CRC_WAIT,
        ASSEMBLE,
        DONE
    } state_t;

    state_t state;
    state_t next_state;

    logic crc_start;
    logic crc_done;
    logic [14:0] crc_out;

    logic [10:0] id_reg;
    logic [3:0] len_reg;
    logic [63:0] data_reg;

    logic [6:0] data_bits;
    logic [7:0] payload_bits;
    logic [7:0] total_bits;
    logic [7:0] crc_start_idx;

    logic [6:0] build_idx;
    logic [6:0] next_build_idx;

    logic [110:0] frame_reg;
    logic [110:0] next_frame_reg;

    logic bit_to_write;
    logic next_data_ready;

    assign data_bits = {len_reg, 3'b000};
    assign payload_bits = 8'd34 + {1'b0, data_bits};
    assign total_bits = payload_bits + 8'd10;
    assign crc_start_idx = 8'd19 + {1'b0, data_bits};

    assign data_frame = frame_reg;
    assign frame_len = total_bits;
    assign stuff_len = payload_bits;
    assign busy = (state != IDLE);

    CRC_generator crc_inst (
        .clk(clk),
        .n_rst(n_rst),
        .start(crc_start),
        .sof_bit(1'b0),
        .identifier(id_reg),
        .rtr_bit(1'b0),
        .ide_bit(1'b0),
        .r0_bit(1'b0),
        .dlc(len_reg),
        .data(data_reg),
        .done(crc_done),
        .crc_out(crc_out)
    );

    always_comb begin
        bit_to_write = 1'b1;

        if (build_idx == 7'd0) begin
            bit_to_write = 1'b0;
        end else if ((build_idx >= 7'd1) && (build_idx <= 7'd11)) begin
            bit_to_write = id_reg[11 - build_idx];
        end else if ((build_idx == 7'd12) || (build_idx == 7'd13) || (build_idx == 7'd14)) begin
            bit_to_write = 1'b0;
        end else if ((build_idx >= 7'd15) && (build_idx <= 7'd18)) begin
            bit_to_write = len_reg[18 - build_idx];
        end else if ((build_idx >= 7'd19) && (build_idx < crc_start_idx[6:0])) begin
            bit_to_write = data_reg[63 - (build_idx - 7'd19)];
        end else if ((build_idx >= crc_start_idx[6:0]) && (build_idx < (crc_start_idx[6:0] + 7'd15))) begin
            bit_to_write = crc_out[14 - (build_idx - crc_start_idx[6:0])];
        end else begin
            bit_to_write = 1'b1;
        end
    end

    always_comb begin
        next_state = state;
        next_build_idx = build_idx;
        next_frame_reg = frame_reg;
        next_data_ready = 1'b0;
        crc_start = 1'b0;

        case (state)
            IDLE: begin
                next_build_idx = 7'd0;
                next_frame_reg = '0;
                if (new_message) begin
                    next_state = CRC_START;
                end
            end

            CRC_START: begin
                crc_start = 1'b1;
                next_state = CRC_WAIT;
            end

            CRC_WAIT: begin
                if (crc_done) begin
                    next_state = ASSEMBLE;
                    next_build_idx = 7'd0;
                    next_frame_reg = '0;
                end
            end

            ASSEMBLE: begin
                next_frame_reg[build_idx] = bit_to_write;
                if (build_idx == (total_bits[6:0] - 1'b1)) begin
                    next_state = DONE;
                end else begin
                    next_build_idx = build_idx + 1'b1;
                end
            end

            DONE: begin
                next_data_ready = 1'b1;
                if (!new_message) begin
                    next_state = IDLE;
                end
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            state <= IDLE;
            id_reg <= 11'd0;
            len_reg <= 4'd0;
            data_reg <= 64'd0;
            build_idx <= 7'd0;
            frame_reg <= '0;
            data_ready <= 1'b0;
        end else begin
            state <= next_state;
            build_idx <= next_build_idx;
            frame_reg <= next_frame_reg;
            data_ready <= next_data_ready;

            if ((state == IDLE) && new_message) begin
                id_reg <= identifier;
                len_reg <= data_len;
                data_reg <= data_field;
            end
        end
    end

endmodule
