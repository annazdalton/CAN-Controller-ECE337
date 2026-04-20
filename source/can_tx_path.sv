`timescale 1ns / 10ps

module can_tx_path #(
    parameter MAX_FRAME_BITS = 111,
    parameter MAX_STUFFED_BITS = 160
) (
    input logic clk,
    input logic n_rst,
    input logic can_rx,
    input logic bit_tick,
    input logic bus_idle,

    input logic tx_buf_valid,
    input logic [10:0] tx_buf_id,
    input logic [3:0] tx_buf_dlc,
    input logic [63:0] tx_buf_data,
    input logic tx_request,
    input logic tx_fd_cfg,

    //ports for error frame fsm
    input  logic error,
    input  logic error_passive,
    input  logic error_active,
    output logic error_done,

    output logic can_tx,
    output logic tx_en,
    output logic tx_complete,
    output logic arb_lost,
    output logic msg_due_tx,
    output logic tx_buf_clr,
    output logic listen_after_arb,
    output logic tx_fd_phase
);

    typedef enum logic [2:0] {
        TX_IDLE,
        TX_BUILD_START,
        TX_BUILD_WAIT,
        TX_STUFF,
        TX_WAIT_BIT,
        TX_SEND
    } tx_state_t;

    tx_state_t state;
    tx_state_t next_state;

    logic frame_start;
    logic frame_ready;
    logic frame_busy;
    logic [110:0] frame_bits;
    logic [7:0] frame_len;
    logic [7:0] stuff_len;

    logic [110:0] frame_bits_reg;
    logic [110:0] next_frame_bits_reg;
    logic [7:0] frame_len_reg;
    logic [7:0] next_frame_len_reg;
    logic [7:0] stuff_len_reg;
    logic [7:0] next_stuff_len_reg;

    logic [MAX_STUFFED_BITS-1:0] stuffed_bits;
    logic [MAX_STUFFED_BITS-1:0] next_stuffed_bits;
    logic [7:0] stuffed_len;
    logic [7:0] next_stuffed_len;

    logic [6:0] stuff_src_idx;
    logic [6:0] next_stuff_src_idx;
    logic [7:0] tx_idx;
    logic [7:0] next_tx_idx;

    logic tx_fd_reg;
    logic next_tx_fd_reg;
    logic [7:0] fd_start_idx_reg;
    logic [7:0] next_fd_start_idx_reg;
    logic [7:0] fd_end_idx_reg;
    logic [7:0] next_fd_end_idx_reg;
    logic fd_start_seen;
    logic next_fd_start_seen;
    logic fd_end_seen;
    logic next_fd_end_seen;

    logic bs_enable;
    logic bs_in_valid;
    logic bs_in_bit;
    logic bs_in_ready;
    logic bs_out_valid;
    logic bs_out_bit;

    logic next_tx_complete;
    logic next_arb_lost;
    logic next_msg_due_tx;
    logic next_tx_buf_clr;
    logic next_listen_after_arb;
    logic next_tx_en;

    logic arb_is_transmitter;
    logic arb_is_receiver;
    logic arb_lost_det;
    logic arb_bus_off;
    logic arb_bus_idle;
    logic arb_active;
    logic arb_tx_bit;
    logic arb_loss_now;

    assign bs_in_valid = (state == TX_STUFF) && ({1'b0, stuff_src_idx} < frame_len_reg);
    assign bs_in_bit = frame_bits_reg[stuff_src_idx];
    assign bs_enable = (state == TX_STUFF) && ({1'b0, stuff_src_idx} < stuff_len_reg);

    assign arb_tx_bit = ((state == TX_SEND) && (tx_idx < stuffed_len)) ? stuffed_bits[tx_idx] : 1'b1;
    assign arb_loss_now = (state == TX_SEND) && (tx_idx < stuffed_len) && (tx_idx < 8'd12) && (stuffed_bits[tx_idx] == 1'b1) && (can_rx == 1'b0);
    assign tx_fd_phase = (state == TX_SEND) && tx_en && tx_fd_reg && (tx_idx >= fd_start_idx_reg) && (tx_idx < fd_end_idx_reg);

    logic error_serial_out;
    logic error_frame_done;
    logic error_active_sig, error_passive_sig;

    error_frame_fsm u_error_frame_fsm (
        .clk (clk),
        .n_rst (n_rst),
        .error (error),
        .error_passive(error_passive),
        .error_active (error_active),
        .serial_out (error_serial_out),
        .error_done (error_frame_done)
    );

    assign error_done = error_frame_done;

    data_frame_fsm u_data_frame_fsm (
        .clk(clk),
        .n_rst(n_rst),
        .new_message(frame_start),
        .identifier(tx_buf_id),
        .data_len(tx_buf_dlc),
        .data_field(tx_buf_data),
        .fd_enable(tx_fd_reg),
        .data_frame(frame_bits),
        .frame_len(frame_len),
        .stuff_len(stuff_len),
        .busy(frame_busy),
        .data_ready(frame_ready)
    );

    bit_stuff u_bit_stuff (
        .clk(clk),
        .n_rst(n_rst),
        .stuffing_enable(bs_enable),
        .in_valid(bs_in_valid),
        .in_bit(bs_in_bit),
        .in_ready(bs_in_ready),
        .out_valid(bs_out_valid),
        .out_bit(bs_out_bit),
        .out_ready(1'b1)
    );

    arbitration u_arbitration (
        .clk(clk),
        .n_rst(n_rst),
        .bit_tick(bit_tick),
        .bus_rx(can_rx),
        .tx_request(msg_due_tx),
        .tx_id(tx_buf_id),
        .tx_bit(arb_tx_bit),
        .recovery_done(1'b0),
        .bus_off_req(1'b0),
        .is_transmitter(arb_is_transmitter),
        .is_receiver(arb_is_receiver),
        .arb_lost(arb_lost_det),
        .bus_off_o(arb_bus_off),
        .bus_idle(arb_bus_idle),
        .arb_active(arb_active)
    );

    always_comb begin
        if (!error_frame_done) begin
            // error frame has priority
            can_tx = error_serial_out;
        end else if ((state == TX_SEND) && (tx_idx < stuffed_len)) begin
            can_tx = stuffed_bits[tx_idx];
        end else begin
            can_tx = 1'b1; //default
        end  
    end

    always_comb begin
        next_state = state;

        next_frame_bits_reg = frame_bits_reg;
        next_frame_len_reg = frame_len_reg;
        next_stuff_len_reg = stuff_len_reg;

        next_stuffed_bits = stuffed_bits;
        next_stuffed_len = stuffed_len;
        next_stuff_src_idx = stuff_src_idx;
        next_tx_idx = tx_idx;
        next_tx_fd_reg = tx_fd_reg;
        next_fd_start_idx_reg = fd_start_idx_reg;
        next_fd_end_idx_reg = fd_end_idx_reg;
        next_fd_start_seen = fd_start_seen;
        next_fd_end_seen = fd_end_seen;

        frame_start = 1'b0;

        next_tx_complete = 1'b0;
        next_arb_lost = 1'b0;
        next_tx_buf_clr = 1'b0;
        next_msg_due_tx = msg_due_tx;
        next_listen_after_arb = listen_after_arb;
        next_tx_en = tx_en;

        case (state)
            TX_IDLE: begin
                next_tx_en = 1'b0;

                if (tx_buf_valid && tx_request) begin
                    next_msg_due_tx = 1'b1;
                end

                if (next_msg_due_tx && tx_buf_valid && bus_idle && arb_bus_idle) begin
                    next_tx_fd_reg = tx_fd_cfg;
                    next_state = TX_BUILD_START;
                end
            end

            TX_BUILD_START: begin
                frame_start = 1'b1;
                next_state = TX_BUILD_WAIT;
            end

            TX_BUILD_WAIT: begin
                if (frame_ready) begin
                    next_frame_bits_reg = frame_bits;
                    next_frame_len_reg = frame_len;
                    next_stuff_len_reg = stuff_len;
                    next_stuffed_bits = '0;
                    next_stuffed_len = 8'd0;
                    next_stuff_src_idx = 7'd0;
                    next_fd_start_idx_reg = 8'd0;
                    next_fd_end_idx_reg = 8'd0;
                    next_fd_start_seen = 1'b0;
                    next_fd_end_seen = 1'b0;
                    next_state = TX_STUFF;
                end
            end

            TX_STUFF: begin
                if (bs_out_valid && (stuffed_len < MAX_STUFFED_BITS[7:0])) begin
                    next_stuffed_bits[stuffed_len] = bs_out_bit;
                    next_stuffed_len = stuffed_len + 1'b1;

                    if (tx_fd_reg) begin
                        if (!fd_start_seen && bs_in_valid && bs_in_ready && ({1'b0, stuff_src_idx} >= 8'd19)) begin
                            next_fd_start_idx_reg = stuffed_len;
                            next_fd_start_seen = 1'b1;
                        end
                        if (!fd_end_seen && bs_in_valid && bs_in_ready && ({1'b0, stuff_src_idx} >= stuff_len_reg)) begin
                            next_fd_end_idx_reg = stuffed_len;
                            next_fd_end_seen = 1'b1;
                        end
                    end
                end

                if (bs_in_valid && bs_in_ready) begin
                    next_stuff_src_idx = stuff_src_idx + 1'b1;
                end

                if (({1'b0, stuff_src_idx} >= frame_len_reg) && !bs_out_valid) begin
                    next_state = TX_WAIT_BIT;
                    next_tx_idx = 8'd0;
                    next_tx_en = 1'b0;
                    next_listen_after_arb = 1'b0;

                    if (tx_fd_reg) begin
                        if (!fd_start_seen) begin
                            next_fd_start_idx_reg = 8'd0;
                            next_fd_start_seen = 1'b1;
                        end
                        if (!fd_end_seen) begin
                            next_fd_end_idx_reg = stuffed_len;
                            next_fd_end_seen = 1'b1;
                        end
                    end else begin
                        next_fd_start_idx_reg = 8'd0;
                        next_fd_end_idx_reg = 8'd0;
                        next_fd_start_seen = 1'b0;
                        next_fd_end_seen = 1'b0;
                    end
                end
            end

            TX_WAIT_BIT: begin
                next_tx_en = 1'b0;
                if (bit_tick) begin
                    next_state = TX_SEND;
                    next_tx_en = 1'b1;
                end
            end

            TX_SEND: begin
                next_tx_en = 1'b1;

                if (bit_tick && error_frame_done) begin
                    if (arb_loss_now) begin
                        next_state = TX_IDLE;
                        next_tx_en = 1'b0;
                        next_arb_lost = 1'b1;
                        next_listen_after_arb = 1'b1;
                    end else if (tx_idx == (stuffed_len - 1'b1)) begin
                        next_state = TX_IDLE;
                        next_tx_en = 1'b0;
                        next_tx_complete = 1'b1;
                        next_tx_buf_clr = 1'b1;
                        next_msg_due_tx = 1'b0;
                        next_listen_after_arb = 1'b0;
                    end else begin
                        next_tx_idx = tx_idx + 1'b1;
                    end
                end
            end

            default: begin
                next_state = TX_IDLE;
                next_tx_en = 1'b0;
            end
        endcase
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            state <= TX_IDLE;
            frame_bits_reg <= '0;
            frame_len_reg <= 8'd0;
            stuff_len_reg <= 8'd0;
            stuffed_bits <= '0;
            stuffed_len <= 8'd0;
            stuff_src_idx <= 7'd0;
            tx_idx <= 8'd0;
            tx_fd_reg <= 1'b0;
            fd_start_idx_reg <= 8'd0;
            fd_end_idx_reg <= 8'd0;
            fd_start_seen <= 1'b0;
            fd_end_seen <= 1'b0;
            tx_en <= 1'b0;
            tx_complete <= 1'b0;
            arb_lost <= 1'b0;
            msg_due_tx <= 1'b0;
            tx_buf_clr <= 1'b0;
            listen_after_arb <= 1'b0;
        end else begin
            state <= next_state;
            frame_bits_reg <= next_frame_bits_reg;
            frame_len_reg <= next_frame_len_reg;
            stuff_len_reg <= next_stuff_len_reg;
            stuffed_bits <= next_stuffed_bits;
            stuffed_len <= next_stuffed_len;
            stuff_src_idx <= next_stuff_src_idx;
            tx_idx <= next_tx_idx;
            tx_fd_reg <= next_tx_fd_reg;
            fd_start_idx_reg <= next_fd_start_idx_reg;
            fd_end_idx_reg <= next_fd_end_idx_reg;
            fd_start_seen <= next_fd_start_seen;
            fd_end_seen <= next_fd_end_seen;
            tx_en <= next_tx_en;
            tx_complete <= next_tx_complete;
            arb_lost <= next_arb_lost;
            msg_due_tx <= next_msg_due_tx;
            tx_buf_clr <= next_tx_buf_clr;
            listen_after_arb <= next_listen_after_arb;
        end
    end

endmodule
