`timescale 1ns / 10ps

module CAN_error_counters (
    input logic clk,
    input logic n_rst,
    input logic tx_error,
    input logic tx_success,
    input logic rx_error,
    input logic rx_success,
    input logic bus_off_i,
    input logic bus_rx,

    output logic error_active,
    output logic error_passive,
    output logic bus_off,
    output logic recovery_done
);

    logic bus_off_reg, idle_rollover, dominant_bit, rec_seq_en;

    //TEC
    logic [8:0] tec_count, next_tec;
    logic [7:0] rec_count, next_rec;

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            tec_count <= '0;
        end else begin
            tec_count <= next_tec;
        end
    end

    always_comb begin
        if (bus_off_reg) begin
            next_tec = '0;
        end else if (tx_error) begin
            if (tec_count >= 9'd247) begin
                next_tec = 9'd255;
            end else begin
                next_tec = tec_count + 9'd8;
            end
        end else if (tx_success) begin
            if (tec_count == 9'd0) begin
                next_tec = 9'd0;
            end else begin
                next_tec = tec_count - 9'd1;
            end
        end else begin
            next_tec = tec_count;
        end
    end

    //REC
    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            rec_count <= '0;
        end else begin
            rec_count <= next_rec;
        end
    end

    always_comb begin
        if (bus_off_reg) begin
            next_rec = '0;
        end else if (rx_error) begin
            if (rec_count == 8'd255) begin
                next_rec = 8'd255;
            end else begin
                next_rec = rec_count + 8'd1;
            end
        end else if (rx_success) begin
            if (rec_count == 8'd0) begin
                next_rec = 8'd0;
            end else begin
                next_rec = rec_count - 8'd1;
            end
        end else begin
            next_rec = rec_count;
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) bus_off <= 1'b0;
        else begin
            bus_off <= bus_off_reg;
        end
    end

    assign error_passive = ~bus_off && ((tec_count >= 9'd128) || (rec_count >= 8'd128));
    assign error_active = ~bus_off && (tec_count < 9'd128) && (rec_count < 8'd128);

    //bus off state (from arbitration module) recovery counter

    assign dominant_bit = bus_off_i && (bus_rx == 1'b0);
    assign rec_seq_en = bus_off_i && (bus_rx == 1'b1);
    assign bus_off_reg = (tec_count >= 9'd255) || (rec_count >= 8'd255);

    flex_counter_CDL #(
        .SIZE(4)
    ) counter_11 (
        .clk(clk),
        .n_rst(n_rst),
        .count_enable(rec_seq_en),  //only counts recissive bits (1)
        .clear(dominant_bit),
        .rollover_val(4'd11),
        .count_out(),
        .rollover_flag(idle_rollover)
    );

    //count 128 occurences of 11-bit recissive sequence
    flex_counter_CDL #(
        .SIZE(8)
    ) recover_seq_count (
        .clk(clk),
        .n_rst(n_rst),
        .count_enable(idle_rollover),
        .clear(~bus_off_reg),  //reset of not is bus off state
        .rollover_val(8'd128),
        .count_out(),
        .rollover_flag(recovery_done)
    );

endmodule
