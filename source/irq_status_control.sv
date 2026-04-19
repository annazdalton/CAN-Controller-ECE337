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

    always_comb begin
        next_irq_status = irq_status & ~irq_clear;

        if (evt_rx_ready) begin
            next_irq_status[0] = 1'b1;
        end

        if (evt_tx_complete) begin
            next_irq_status[1] = 1'b1;
        end

        if (evt_error) begin
            next_irq_status[2] = 1'b1;
        end

        next_irq = |(next_irq_status & irq_enable_reg);
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            irq_status <= '0;
            irq <= 1'b0;
        end else begin
            irq_status <= next_irq_status;
            irq <= next_irq;
        end
    end

endmodule
