`timescale 1ns / 10ps

module register_bank #(
    // parameters
    parameter int ADDR_W = 4,
    parameter int DATA_W = 8,
    parameter int IRQ_W  = 3
    
) (
    input logic clk, n_rst,

     // From host_interface
    input  logic reg_wr_en,
    input  logic reg_rd_en,
    input  logic [DATA_W-1:0] reg_wdata,
    input  logic [ADDR_W-1:0] reg_addr,

    // From irq_status_ctrl
    input  logic [IRQ_W-1:0] irq_status,

    // To host_interface
    output logic [DATA_W-1:0] reg_rdata,
    output logic wr_accept,
    output logic rd_valid,

    // To irq_status_ctrl
    output logic [IRQ_W-1:0] irq_enable_reg,
    output logic [IRQ_W-1:0] irq_clear,

    // To other modules
    output logic [DATA_W-1:0] mode_cfg,
    output logic [DATA_W-1:0] bit_timing_cfg,
    output logic [DATA_W-1:0] filter_cfg
);
    localparam logic [ADDR_W-1:0] MODE_ADDR = 4'h0;
    localparam logic [ADDR_W-1:0] BIT_TIMING_ADDR = 4'h1;
    localparam logic [ADDR_W-1:0] FILTER_ADDR = 4'h2;
    localparam logic [ADDR_W-1:0] IRQ_ENABLE_ADDR = 4'h3;
    localparam logic [ADDR_W-1:0] IRQ_STATUS_ADDR = 4'h4;
    localparam logic [ADDR_W-1:0] IRQ_CLEAR_ADDR = 4'h5;

    logic [DATA_W-1:0] next_mode_reg;
    logic [DATA_W-1:0] next_bit_timing_reg;
    logic [DATA_W-1:0] next_filter_reg;
    logic [IRQ_W-1:0] next_irq_enable_reg;
    // logic [DATA_W-1:0] next_reg_rdata;

    logic [IRQ_W-1:0] irq_clear_reg;
    logic [IRQ_W-1:0] next_irq_clear;

    always_comb begin
        next_mode_reg = mode_cfg;
        next_bit_timing_reg = bit_timing_cfg;
        next_filter_reg = filter_cfg;
        next_irq_enable_reg = irq_enable_reg;
        irq_clear_reg = irq_clear;

        wr_accept = 1'b0;
        rd_valid = 1'b0;
        reg_rdata = '0; // change

        if (reg_wr_en) begin
            case (reg_addr)
                MODE_ADDR: begin
                    next_mode_reg = reg_wdata;
                end

                BIT_TIMING_ADDR: begin
                    next_bit_timing_reg = reg_wdata;
                end

                FILTER_ADDR: begin
                    next_filter_reg = reg_wdata;
                end

                IRQ_ENABLE_ADDR: begin
                    next_irq_enable_reg = reg_wdata[IRQ_W-1:0];
                end

                IRQ_CLEAR_ADDR: begin
                    irq_clear_reg  = reg_wdata[IRQ_W-1:0];
                end

                default: begin
                end
            endcase

            wr_accept = 1'b1;
        end else if (reg_rd_en) begin
            case (reg_addr)
                MODE_ADDR: begin
                    reg_rdata = mode_cfg;
                end

                BIT_TIMING_ADDR: begin
                    reg_rdata = bit_timing_cfg;
                end

                FILTER_ADDR: begin
                    reg_rdata = filter_cfg;
                end

                IRQ_ENABLE_ADDR: begin
                    reg_rdata = {{(DATA_W-IRQ_W){1'b0}}, irq_enable_reg};
                end

                IRQ_STATUS_ADDR: begin
                    reg_rdata = {{(DATA_W-IRQ_W){1'b0}}, irq_status};
                end

                IRQ_CLEAR_ADDR: begin
                    reg_rdata = '0;
                end

                default: begin
                    reg_rdata = '0;
                end
            endcase

            rd_valid = 1'b1;
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            mode_cfg <= '0;
            bit_timing_cfg <= '0;
            filter_cfg <= '0;
            irq_enable_reg <= '0;
            irq_clear <= '0;
        end else begin
            mode_cfg <= next_mode_reg;
            bit_timing_cfg <= next_bit_timing_reg;
            filter_cfg <= next_filter_reg;
            irq_enable_reg <= next_irq_enable_reg;
            irq_clear <= irq_clear_reg;
        end
    end

endmodule

