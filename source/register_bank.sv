`timescale 1ns / 10ps

module register_bank #(
    // parameters
    parameter int ADDR_W = 5,
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

    //for transmit datapath
    output logic [10:0] tx_id_cfg,
    output logic [3:0] tx_dlc_cfg,
    output logic [63:0] tx_data_cfg,
    output logic tx_wr_en_pulse,
    output logic tx_request,

    // New RX ports
    output logic rx_pop_pulse
);
    localparam logic [ADDR_W-1:0] MODE_ADDR = 5'd0;
    localparam logic [ADDR_W-1:0] BIT_TIMING_ADDR = 5'd1;
    localparam logic [ADDR_W-1:0] FILTER_ADDR = 5'd2;
    localparam logic [ADDR_W-1:0] IRQ_ENABLE_ADDR = 5'd3;
    localparam logic [ADDR_W-1:0] IRQ_STATUS_ADDR = 5'd4;
    localparam logic [ADDR_W-1:0] IRQ_CLEAR_ADDR = 5'd5;

    // tx registers
    localparam logic [ADDR_W-1:0] TX_ID_ADDR = 5'd6; // [7:0] of ID
    localparam logic [ADDR_W-1:0] TX_ID_HIGH_ADDR = 5'd7; // [10:8] of ID
    localparam logic [ADDR_W-1:0] TX_DLC_ADDR = 5'd8; // [3:0] DLC
    localparam logic [ADDR_W-1:0] TX_DATA0_ADDR = 5'd9; // data[7:0]
    localparam logic [ADDR_W-1:0] TX_DATA1_ADDR = 5'd10; // data[15:8]
    localparam logic [ADDR_W-1:0] TX_DATA2_ADDR = 5'd11; // data[23:16]
    localparam logic [ADDR_W-1:0] TX_DATA3_ADDR = 5'd12; // data[31:24]
    localparam logic [ADDR_W-1:0] TX_DATA4_ADDR = 5'd13; // data[39:32]
    localparam logic [ADDR_W-1:0] TX_DATA5_ADDR = 5'd14; // data[47:40]

    localparam logic [ADDR_W-1:0] TX_DATA6_ADDR = 5'h10  //data[55:48]
    localparam logic [ADDR_W-1:0] TX_DATA7_ADDR  = 5'h11  //data[63:56]
    localparam logic [ADDR_W-1:0] TX_CTRL_ADDR= 5'h12  //bit[0] = tx_request, bit[1] = tx_wr_en pulse
    localparam logic [ADDR_W-1:0] RX_POP_ADDR = 5'h13  //write any value to pop RX FIFO

    logic [10:0] next_tx_id_cfg;
    logic [3:0] next_tx_dlc_cfg;
    logic [63:0] next_tx_data_cfg;
    logic next_tx_request;
    logic next_tx_wr_en_pulse;
    logic next_rx_pop_pulse;

    logic [DATA_W-1:0] next_mode_reg;
    logic [DATA_W-1:0] next_bit_timing_reg;
    logic [DATA_W-1:0] next_filter_reg;
    logic [IRQ_W-1:0] next_irq_enable_reg;
    // logic [DATA_W-1:0] next_reg_rdata;

    logic [IRQ_W-1:0] irq_clear_reg;
    logic [IRQ_W-1:0] next_irq_clear;

    //iqr status addr is read only
    logic valid_wr_addr;

    always_comb begin
        next_mode_reg = mode_cfg;
        next_bit_timing_reg = bit_timing_cfg;
        next_filter_reg = filter_cfg;
        next_irq_enable_reg = irq_enable_reg;
        irq_clear_reg = irq_clear;

        valid_wr_addr = 1'b1;

        wr_accept = 1'b0;
        rd_valid = 1'b0;
        reg_rdata = '0; // change

        next_tx_id_cfg = tx_id_cfg;
        next_tx_dlc_cfg = tx_dlc_cfg;
        next_tx_data_cfg = tx_data_cfg;
        next_tx_request = tx_request;
        next_tx_wr_en_pulse = 1'b0;
        next_rx_pop_pulse = 1'b0;

        assign wr_accept = valid_wr_addr;

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

                IRQ_STATUS_ADDR : begin
                    valid_wr_addr = 1'b0;
                end

                IRQ_CLEAR_ADDR: begin
                    irq_clear_reg  = reg_wdata[IRQ_W-1:0];
                end

                TX_ID_ADDR: begin next_tx_id_cfg[7:0] = reg_wdata; end
                TX_ID_HIGH_ADDR: begin next_tx_id_cfg[10:8] = reg_wdata[2:0]; end
                TX_DLC_ADDR: begin next_tx_dlc_cfg = reg_wdata[3:0]; end
                TX_DATA0_ADDR: begin next_tx_data_cfg[7:0] = reg_wdata; end
                TX_DATA1_ADDR: begin next_tx_data_cfg[15:8] = reg_wdata; end
                TX_DATA2_ADDR: begin next_tx_data_cfg[23:16] = reg_wdata; end
                TX_DATA3_ADDR: begin next_tx_data_cfg[31:24] = reg_wdata; end
                TX_DATA4_ADDR: begin next_tx_data_cfg[39:32] = reg_wdata; end
                TX_DATA5_ADDR: begin next_tx_data_cfg[47:40] = reg_wdata; end 
                TX_DATA6_ADDR: begin next_tx_data_cfg[55:48] = reg_wdata; end
                TX_DATA7_ADDR: begin next_tx_data_cfg[63:56] = reg_wdata; end 

                TX_CTRL_ADDR: begin
                    next_tx_request = reg_wdata[0];
                    next_tx_wr_en_pulse = reg_wdata[1]; // single cycle pulse
                end
            
                RX_POP_ADDR: begin
                    next_rx_pop_pulse = 1'b1;
                end

                default: begin
                    valid_wr_addr = 1'b1;
                end
            endcase
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

                TX_ID_ADDR: begin reg_rdata = tx_id_cfg[7:0]; end
                TX_ID_HIGH_ADDR: begin reg_rdata = {{5{1'b0}}, tx_id_cfg[10:8]}; end
                TX_DLC_ADDR: begin reg_rdata = {{(DATA_W-4){1'b0}}, tx_dlc_cfg}; end
                TX_DATA0_ADDR: begin reg_rdata = tx_data_cfg[7:0]; end
                TX_DATA1_ADDR: begin reg_rdata = tx_data_cfg[15:8]; end 
                TX_DATA2_ADDR: begin reg_rdata = tx_data_cfg[23:16]; end
                TX_DATA3_ADDR: begin reg_rdata = tx_data_cfg[31:24]; end 
                TX_DATA4_ADDR: begin reg_rdata = tx_data_cfg[39:32]; end
                TX_DATA5_ADDR: begin reg_rdata = tx_data_cfg[47:40]; end
                TX_DATA6_ADDR: begin reg_rdata = tx_data_cfg[55:48]; end 
                TX_DATA7_ADDR: begin reg_rdata = tx_data_cfg[63:56]; end
                TX_CTRL_ADDR: begin reg_rdata = {{(DATA_W-2){1'b0}},tx_wr_en_pulse, tx_request}; end

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
            //tx registers
            tx_id_cfg <= '0;
            tx_dlc_cfg <= '0;
            tx_data_cfg <= '0;
            tx_request <= '0;
            tx_wr_en_pulse <= '0;
            rx_pop_pulse <= '0;
        end else begin
            mode_cfg <= next_mode_reg;
            bit_timing_cfg <= next_bit_timing_reg;
            filter_cfg <= next_filter_reg;
            irq_enable_reg <= next_irq_enable_reg;
            irq_clear <= irq_clear_reg;
            //tx request
            tx_id_cfg <= next_tx_id_cfg;
            tx_dlc_cfg <= next_tx_dlc_cfg;
            tx_data_cfg <= next_tx_data_cfg;
            tx_request <= next_tx_request;
            tx_wr_en_pulse <= next_tx_wr_en_pulse;
            rx_pop_pulse <= next_rx_pop_pulse;
        end
    end

endmodule

