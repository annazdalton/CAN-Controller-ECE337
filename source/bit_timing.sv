module bit_timing (
    input logic clk,
    input logic n_rst,

    // Control
    input logic enable,
    input logic rx_active, // asserted while receiving a frame
    input logic bus_idle, // high when bus is idle/intermission
    input logic resync_enable,

    // Bit timing configuration
    input logic [9:0] brp, // baud rate prescaler: tq tick every (brp+1) clocks
    input logic [5:0] tq_per_bit, // total time quanta per bit
    input logic [5:0] sample_tq, // sample point location within bit
    input logic [5:0] sjw, // synchronization jump width in tq
    input logic fd, // Flexible Datarate flag

    input logic can_rx,

    output logic tq_tick,
    output logic sample_tick,
    output logic bit_tick,
    output logic hard_sync_pulse,
    output logic resync_pulse,
    output logic early_edge,
    output logic late_edge,
    output logic timing_error,
    output logic sampled_bit
);

    // RX synchronizer and edge detector
    logic rx_meta, rx_sync, rx_prev;
    logic rx_edge;
    logic rx_falling_edge;

    logic [9:0] active_brp;
    logic [9:0] brp_count;
    logic [5:0] tq_count;

    // Double bitrate in FD mode by halving BRP
    always_comb begin
        if (fd) begin
            if (brp > 10'd0)
                active_brp = brp >> 1;
            else
                active_brp = 10'd0;
        end else begin
            active_brp = brp;
        end
    end

    always_ff @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
            rx_prev <= 1'b1;
        end else begin
            rx_meta <= can_rx;
            rx_sync <= rx_meta;
            rx_prev <= rx_sync;
        end
    end

    assign rx_edge = (rx_sync != rx_prev);
    assign rx_falling_edge = (rx_prev == 1'b1) && (rx_sync == 1'b0);

    // Time quantum prescaler
    always_ff @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            brp_count <= '0;
            tq_tick <= 1'b0;
        end else begin
            tq_tick <= 1'b0;

            if (!enable) begin
                brp_count <= '0;
            end else if (brp_count >= active_brp) begin
                brp_count <= '0;
                tq_tick <= 1'b1;
            end else begin
                brp_count <= brp_count + 10'd1;
            end
        end
    end

    // Bit timing state
    // tq_count counts 0 .. tq_per_bit-1
    // sample_tick when tq_count == sample_tq
    // bit_tick when tq_count == tq_per_bit-1
    //
    // Resync policy:
    // - hard sync on SOF while idle
    // - if an edge occurs before sample point -> early edge -> advance timing
    // - if an edge occurs after sample point  -> late edge  -> slow timing
    logic resync_done_this_bit;
    logic edge_pending;
    logic [5:0] edge_tq_snapshot;
    logic resync_edge_valid;
    logic [5:0] resync_tq_ref;
    logic [5:0] phase_error;
    logic [5:0] phase_adjust;

    always_comb begin
        phase_error = '0;
        phase_adjust = '0;

        resync_edge_valid = (rx_edge || edge_pending) && rx_active && resync_enable && !resync_done_this_bit;
        if (edge_pending) resync_tq_ref = edge_tq_snapshot;
        else resync_tq_ref = tq_count;

        if (resync_edge_valid) begin
            if (resync_tq_ref < sample_tq) begin
                // early edge
                phase_error = sample_tq - resync_tq_ref;
            end else begin
                // late edge
                phase_error = resync_tq_ref - sample_tq;
            end

            if (phase_error > sjw) phase_adjust = sjw;
            else phase_adjust = phase_error;
        end
    end

    always_ff @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            tq_count <= '0;
            sample_tick <= 1'b0;
            bit_tick <= 1'b0;
            hard_sync_pulse <= 1'b0;
            resync_pulse <= 1'b0;
            early_edge <= 1'b0;
            late_edge <= 1'b0;
            timing_error <= 1'b0;
            sampled_bit <= 1'b1;
            resync_done_this_bit <= 1'b0;
            edge_pending <= 1'b0;
            edge_tq_snapshot <= '0;
        end else begin
            sample_tick <= 1'b0;
            bit_tick <= 1'b0;
            hard_sync_pulse <= 1'b0;
            resync_pulse <= 1'b0;
            early_edge <= 1'b0;
            late_edge <= 1'b0;
            timing_error <= 1'b0;

            // Capture edge timing even when it doesn't land exactly on tq_tick
            if (enable && rx_edge && rx_active && resync_enable && !resync_done_this_bit && !edge_pending) begin
                edge_pending <= 1'b1;
                edge_tq_snapshot <= tq_count;
            end

            // Hard synchronization on SOF while bus is idle
            if (enable && bus_idle && rx_falling_edge) begin
                tq_count <= 6'd0;
                hard_sync_pulse <= 1'b1;
                resync_done_this_bit <= 1'b0;
                edge_pending <= 1'b0;
            end else if (enable && tq_tick) begin
                // Optional sample event
                if (tq_count == sample_tq) begin
                    sample_tick <= 1'b1;
                    sampled_bit <= rx_sync;
                end

                // Bit boundary
                if (tq_count == (tq_per_bit - 6'd1)) begin
                    tq_count <= 6'd0;
                    bit_tick <= 1'b1;
                    resync_done_this_bit <= 1'b0;
                end else begin
                    tq_count <= tq_count + 6'd1;
                end

                // Edge-based resynchronization during RX
                // Only allow one resync action per bit
                if (resync_edge_valid) begin
                    if (resync_tq_ref < sample_tq) begin
                        // Early edge: advance local timing
                        early_edge <= 1'b1;
                        if (phase_adjust != 0) begin
                            // Move forward in the current bit
                            tq_count <= tq_count + phase_adjust;
                            resync_pulse <= 1'b1;
                        end
                    end else if (resync_tq_ref > sample_tq) begin
                        // Late edge: slow local timing
                        late_edge <= 1'b1;
                        if (phase_adjust != 0) begin
                            // Move backward in the current bit
                            // Prevent underflow just in case
                            if (tq_count >= phase_adjust) tq_count <= tq_count - phase_adjust;
                            else tq_count <= 6'd0;
                            resync_pulse <= 1'b1;
                        end
                    end

                    resync_done_this_bit <= 1'b1;
                    edge_pending <= 1'b0;
                end
            end
        end
    end

endmodule
