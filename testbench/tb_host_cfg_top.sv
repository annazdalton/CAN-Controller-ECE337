`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_host_cfg_top;

    localparam CLK_PERIOD = 10ns;
    localparam ADDR_W = 6;
    localparam DATA_W = 8;
    localparam IRQ_W = 3;

    localparam logic [ADDR_W-1:0] ADDR_MODE = 5'd0;
    localparam logic [ADDR_W-1:0] ADDR_BT_BRP_LO = 5'd1;
    localparam logic [ADDR_W-1:0] ADDR_BT_BRP_HI = 5'd2;
    localparam logic [ADDR_W-1:0] ADDR_BT_TQPB = 5'd3;
    localparam logic [ADDR_W-1:0] ADDR_BT_SAMPLE = 5'd4;
    localparam logic [ADDR_W-1:0] ADDR_BT_SJW = 5'd5;
    localparam logic [ADDR_W-1:0] ADDR_BT_FD = 5'd6;
    localparam logic [ADDR_W-1:0] ADDR_IRQ_ENABLE = 5'd7;
    localparam logic [ADDR_W-1:0] ADDR_IRQ_STATUS = 5'd8;
    localparam logic [ADDR_W-1:0] ADDR_IRQ_CLEAR = 5'd9;
    localparam logic [ADDR_W-1:0] ADDR_TX_ID_LO = 5'd10;
    localparam logic [ADDR_W-1:0] ADDR_TX_ID_HI = 5'd11;
    localparam logic [ADDR_W-1:0] ADDR_TX_DLC = 5'd12;
    localparam logic [ADDR_W-1:0] ADDR_TX_DATA0 = 5'd13;
    localparam logic [ADDR_W-1:0] ADDR_TX_DATA7 = 5'd20;
    localparam logic [ADDR_W-1:0] ADDR_TX_CTRL = 5'd21;
    localparam logic [ADDR_W-1:0] ADDR_RX_POP = 5'd22;

    logic clk, n_rst;
    logic host_wr_req, host_rd_req;
    logic [DATA_W-1:0] host_wdata;
    logic [ADDR_W-1:0] host_addr;

    logic evt_rx_ready, evt_tx_complete, evt_error;
    logic [10:0] rx_head_id;
    logic [3:0] rx_head_dlc;
    logic [63:0] rx_head_data;
    logic rx_buf_empty;
    logic rx_buf_full;
    logic [3:0] rx_count;

    logic [DATA_W-1:0] host_rdata;
    logic host_wr_ack, host_rd_ack;

    logic [10:0] tx_id_cfg;
    logic [3:0] tx_dlc_cfg;
    logic [63:0] tx_data_cfg;
    logic tx_wr_en_pulse;
    logic tx_request;

    logic bt_enable;
    logic [9:0] bt_brp;
    logic [5:0] bt_tq_per_bit;
    logic [5:0] bt_sample_tq;
    logic [5:0] bt_sjw;
    logic bt_fd;

    logic rx_pop_pulse;
    logic irq;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    always begin
        clk = 1'b0;
        #(CLK_PERIOD / 2.0);
        clk = 1'b1;
        #(CLK_PERIOD / 2.0);
    end

    task automatic reset_dut;
        begin
            n_rst = 1'b0;
            host_wr_req = 1'b0;
            host_rd_req = 1'b0;
            host_wdata = '0;
            host_addr = '0;
            evt_rx_ready = 1'b0;
            evt_tx_complete = 1'b0;
            evt_error = 1'b0;
            rx_head_id = '0;
            rx_head_dlc = '0;
            rx_head_data = '0;
            rx_buf_empty = 1'b1;
            rx_buf_full = 1'b0;
            rx_count = '0;
            repeat (3) @(posedge clk);
            @(negedge clk);
            n_rst = 1'b1;
            repeat (2) @(posedge clk);
        end
    endtask

    task automatic host_write(input logic [ADDR_W-1:0] addr, input logic [DATA_W-1:0] data);
        begin
            @(negedge clk);
            host_addr = addr;
            host_wdata = data;
            host_wr_req = 1'b1;
            host_rd_req = 1'b0;

            @(posedge clk);
            while (!host_wr_ack) begin
                @(posedge clk);
            end

            host_wr_req = 1'b0;
            host_wdata = '0;
        end
    endtask

    task automatic host_read(input logic [ADDR_W-1:0] addr, output logic [DATA_W-1:0] data);
        begin
            @(negedge clk);
            host_addr = addr;
            host_rd_req = 1'b1;
            host_wr_req = 1'b0;

            @(posedge clk);
            while (!host_rd_ack) begin
                @(posedge clk);
            end

            data = host_rdata;
            host_rd_req = 1'b0;
        end
    endtask

    host_cfg_top #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W),
        .IRQ_W(IRQ_W)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .host_wr_req(host_wr_req),
        .host_rd_req(host_rd_req),
        .host_wdata(host_wdata),
        .host_addr(host_addr),
        .evt_rx_ready(evt_rx_ready),
        .evt_tx_complete(evt_tx_complete),
        .evt_error(evt_error),
        .rx_head_id(rx_head_id),
        .rx_head_dlc(rx_head_dlc),
        .rx_head_data(rx_head_data),
        .rx_buf_empty(rx_buf_empty),
        .rx_buf_full(rx_buf_full),
        .rx_count(rx_count),
        .host_rdata(host_rdata),
        .host_wr_ack(host_wr_ack),
        .host_rd_ack(host_rd_ack),
        .tx_id_cfg(tx_id_cfg),
        .tx_dlc_cfg(tx_dlc_cfg),
        .tx_data_cfg(tx_data_cfg),
        .tx_wr_en_pulse(tx_wr_en_pulse),
        .tx_request(tx_request),
        .bt_enable(bt_enable),
        .bt_brp(bt_brp),
        .bt_tq_per_bit(bt_tq_per_bit),
        .bt_sample_tq(bt_sample_tq),
        .bt_sjw(bt_sjw),
        .bt_fd(bt_fd),
        .rx_pop_pulse(rx_pop_pulse),
        .irq(irq)
    );

    logic [7:0] rd_data;

    initial begin
        reset_dut();

        host_write(ADDR_MODE, 8'h01);

        host_write(ADDR_BT_BRP_LO, 8'h34);
        host_write(ADDR_BT_BRP_HI, 8'h01);
        host_write(ADDR_BT_TQPB, 8'd16);
        host_write(ADDR_BT_SAMPLE, 8'd11);
        host_write(ADDR_BT_SJW, 8'd1);
        host_write(ADDR_BT_FD, 8'h01);

        host_write(ADDR_TX_ID_LO, 8'hC3);
        host_write(ADDR_TX_ID_HI, 8'h02);
        host_write(ADDR_TX_DLC, 8'h08);
        host_write(ADDR_TX_DATA0, 8'hAA);
        host_write(ADDR_TX_DATA7, 8'h55);
        host_write(ADDR_TX_CTRL, 8'b0000_0011);
        @(posedge clk);

        host_write(ADDR_RX_POP, 8'hFF);
        @(posedge clk);

        host_write(ADDR_IRQ_ENABLE, 8'b0000_0111);

        evt_rx_ready = 1'b1;
        @(posedge clk);
        evt_rx_ready = 1'b0;
        @(posedge clk);
        host_read(ADDR_IRQ_STATUS, rd_data);

        host_write(ADDR_IRQ_CLEAR, 8'b0000_0001);
        @(posedge clk);

        host_write(ADDR_IRQ_ENABLE, 8'b0000_0001);
        evt_error = 1'b1;
        @(posedge clk);
        evt_error = 1'b0;
        @(posedge clk);
        host_read(ADDR_IRQ_STATUS, rd_data);

        host_write(ADDR_IRQ_STATUS, 8'hFF);
        host_read(ADDR_IRQ_STATUS, rd_data);
        $finish;
    end

endmodule

/* verilator coverage_on */
