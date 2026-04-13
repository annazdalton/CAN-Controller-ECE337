`timescale 1ns / 10ps

module data_frame_fsm #(
    // parameters
) (
    input logic clk, n_rst

    input logic new_message,
    input logic [3:0] data_len,
    input logic [63:0] data_field,
    
    output logic [110: 0] data_frame,
    output logic data_ready,
);

    localparam logic [10:0] IDENTIFIER = 11'h123;

    typedef enum logic [2:0] {
        IDLE,
        LOAD,
        CRC_START,
        CRC_WAIT,
        ASSEMBLE,
        DONE

    } state_t;

    state_t state, next_state;


    logic crc_start;
    logic crc_done;
    logic [14:0] crc_out;

    CRC_generator crc_inst (
        .clk(clk),
        .n_rst(n_rst),
        .start(crc_start),
        .data(data_field),
        .data_len(data_len[2:0]),
        .done(crc_done),
        .crc_out(crc_out)
    );

    logic [109:0] frame_reg, next_frame;
    logic next_ready;

    always_comb begin
        next_state = state;
        crc_start  = 0;
        next_ready = 0;
        next_frame = frame_reg;

        case (state)

            IDLE: begin
                if (new_message)
                    next_state = LOAD;
            end

            LOAD: begin
                // Start CRC
                crc_start  = 1;
                next_state = CRC_WAIT;
            end

            CRC_WAIT: begin
                if (crc_done)
                    next_state = ASSEMBLE;
            end

            ASSEMBLE: begin
                int bit_ptr;
                bit_ptr = 110;

                // SOF
                next_frame[bit_ptr] = 0;
                bit_ptr--;

                // Identifier
                next_frame[bit_ptr -: 11] = IDENTIFIER;
                bit_ptr -= 11;

                // RTR, IDE, r0
                next_frame[bit_ptr] = 0; bit_ptr--;
                next_frame[bit_ptr] = 0; bit_ptr--;
                next_frame[bit_ptr] = 0; bit_ptr--;

                // DLC
                next_frame[bit_ptr -: 4] = data_len;
                bit_ptr -= 4;

                // DATA
                int data_bits;
                data_bits = data_len * 8;

                next_frame[bit_ptr -: data_bits] = data_field[63 -: data_bits];
                bit_ptr -= data_bits;

                // CRC
                next_frame[bit_ptr -: 15] = crc_out;
                bit_ptr -= 15;

                // CRC delimiter
                next_frame[bit_ptr] = 1;
                bit_ptr--;

                // ACK, tx sends recessive (1)
                next_frame[bit_ptr] = 1;
                bit_ptr--;

                // ACK delimiter
                next_frame[bit_ptr] = 1;
                bit_ptr--;

                // EOF (7 bits)
                next_frame[bit_ptr -: 7] = 7'b1111111;
                bit_ptr -= 7;

                // Interframe space (3 bits)
                next_frame[bit_ptr -: 3] = 3'b111;
                bit_ptr -= 3;
                next_state = DONE;
            end

            DONE: begin
                next_ready = 1;
                if (!new_message)
                    next_state = IDLE;
            end

        endcase
    end


    always_ff @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            state <= IDLE;
            frame_reg <= 0;
            data_ready <= 0;
        end
        else begin
            state <= next_state;
            frame_reg <= next_frame;
            data_ready <= next_ready;
        end
    end

    assign data_frame = frame_reg;
endmodule

