`timescale 1ns / 10ps

module irq_status_control #(
    // parameters
    parameter int IRQ_W = 3
) (
    input logic clk, n_rst,
    input logic [IRQ_W-1:0] irq_clear,
    input logic [IRQ_W-1:0] irq_enable_reg,

    input logic evt_rx_ready,
    input logic evt_tx_complete,
    input logic evt_error,

    output logic [IRQ_W-1:0] irq_status,
    output logic irq
);
    logic [IRQ_W-1:0] next_irq_status;
    logic next_irq;
    logic evt_rx_ready_d;
    logic evt_tx_complete_d;
    logic evt_error_d;
    logic evt_rx_ready_pulse;
    logic evt_tx_complete_pulse;
    logic evt_error_pulse;

    assign evt_rx_ready_pulse = evt_rx_ready && !evt_rx_ready_d;
    assign evt_tx_complete_pulse = evt_tx_complete && !evt_tx_complete_d;
    assign evt_error_pulse = evt_error && !evt_error_d;

    always_comb begin
        next_irq_status = irq_status;

        if (evt_rx_ready_pulse) begin
            next_irq_status[0] = 1'b1;
        end

        if (evt_tx_complete_pulse) begin
            next_irq_status[1] = 1'b1;
        end

        if (evt_error_pulse) begin
            next_irq_status[2] = 1'b1;
        end

        next_irq_status = next_irq_status & ~irq_clear;

        next_irq = |(next_irq_status & irq_enable_reg);
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            irq_status <= '0;
            irq <= 1'b0;
            evt_rx_ready_d <= 1'b0;
            evt_tx_complete_d <= 1'b0;
            evt_error_d <= 1'b0;
        end else begin
            irq_status <= next_irq_status;
            irq <= next_irq;
            evt_rx_ready_d <= evt_rx_ready;
            evt_tx_complete_d <= evt_tx_complete;
            evt_error_d <= evt_error;
        end
    end

endmodule
