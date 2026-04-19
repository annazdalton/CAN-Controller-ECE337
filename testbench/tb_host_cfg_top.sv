`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_host_cfg_top;

    localparam CLK_PERIOD = 10ns;
    localparam ADDR_W = 5;
    localparam DATA_W = 8;
    localparam IRQ_W = 3;

    localparam logic [ADDR_W-1:0] ADDR_MODE = 5'd0;
    localparam logic [ADDR_W-1:0] ADDR_BT_BRP_LO = 5'd1;
    localparam logic [ADDR_W-1:0] ADDR_BT_BRP_HI = 5'd2;
    localparam logic [ADDR_W-1:0] ADDR_BT_TQPB = 5'd3;
    localparam logic [ADDR_W-1:0] ADDR_BT_SAMPLE = 5'd4;
    localparam logic [ADDR_W-1:0] ADDR_BT_SJW = 5'd5;
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

    task automatic check_equal(input string name, input logic [63:0] actual,
                               input logic [63:0] expected);
        begin
            if (actual !== expected) begin
                $display("FAIL: %s | actual=0x%0h expected=0x%0h", name, actual, expected);
                $finish;
            end else begin
                $display("PASS: %s", name);
            end
        end
    endtask

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
            repeat (3) @(posedge clk);
            @(negedge clk);
            n_rst = 1'b1;
            repeat (2) @(posedge clk);
        end
    endtask

    task automatic host_write(input logic [ADDR_W-1:0] addr, input logic [DATA_W-1:0] data);
        integer timeout;
        begin
            @(negedge clk);
            host_addr = addr;
            host_wdata = data;
            host_wr_req = 1'b1;
            host_rd_req = 1'b0;

            timeout = 0;
            @(posedge clk);
            while (!host_wr_ack && timeout < 10) begin
                @(posedge clk);
                timeout++;
            end
            if (!host_wr_ack) begin
                $display("FAIL: write timeout addr=0x%0h", addr);
                $finish;
            end

            host_wr_req = 1'b0;
            host_wdata = '0;
        end
    endtask

    task automatic host_read(input logic [ADDR_W-1:0] addr, output logic [DATA_W-1:0] data);
        integer timeout;
        begin
            @(negedge clk);
            host_addr = addr;
            host_rd_req = 1'b1;
            host_wr_req = 1'b0;

            timeout = 0;
            @(posedge clk);
            while (!host_rd_ack && timeout < 10) begin
                @(posedge clk);
                timeout++;
            end
            if (!host_rd_ack) begin
                $display("FAIL: read timeout addr=0x%0h", addr);
                $finish;
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
        .rx_pop_pulse(rx_pop_pulse),
        .irq(irq)
    );

    logic [7:0] rd_data;

    initial begin
        reset_dut();

        check_equal("reset host_wr_ack", host_wr_ack, 1'b0);
        check_equal("reset host_rd_ack", host_rd_ack, 1'b0);
        check_equal("reset bt_enable", bt_enable, 1'b0);
        check_equal("reset irq", irq, 1'b0);

        host_write(ADDR_MODE, 8'h01);
        check_equal("mode enables bit-timing", bt_enable, 1'b1);

        host_write(ADDR_BT_BRP_LO, 8'h34);
        host_write(ADDR_BT_BRP_HI, 8'h01);
        host_write(ADDR_BT_TQPB, 8'd16);
        host_write(ADDR_BT_SAMPLE, 8'd11);
        host_write(ADDR_BT_SJW, 8'd1);
        check_equal("bt_brp programmed", bt_brp, 10'h134);
        check_equal("bt_tq_per_bit programmed", bt_tq_per_bit, 6'd16);
        check_equal("bt_sample_tq programmed", bt_sample_tq, 6'd11);
        check_equal("bt_sjw programmed", bt_sjw, 6'd1);

        host_write(ADDR_TX_ID_LO, 8'hC3);
        host_write(ADDR_TX_ID_HI, 8'h02);
        host_write(ADDR_TX_DLC, 8'h08);
        host_write(ADDR_TX_DATA0, 8'hAA);
        host_write(ADDR_TX_DATA7, 8'h55);
        host_write(ADDR_TX_CTRL, 8'b0000_0011);
        check_equal("tx_id configured", tx_id_cfg, 11'h2C3);
        check_equal("tx_dlc configured", tx_dlc_cfg, 4'h8);
        check_equal("tx_data byte0 configured", tx_data_cfg[7:0], 8'hAA);
        check_equal("tx_data byte7 configured", tx_data_cfg[63:56], 8'h55);
        check_equal("tx_request set", tx_request, 1'b1);
        check_equal("tx_wr_en pulse high", tx_wr_en_pulse, 1'b1);
        @(posedge clk);
        check_equal("tx_wr_en pulse clears", tx_wr_en_pulse, 1'b0);

        host_write(ADDR_RX_POP, 8'hFF);
        check_equal("rx_pop pulse high", rx_pop_pulse, 1'b1);
        @(posedge clk);
        check_equal("rx_pop pulse clears", rx_pop_pulse, 1'b0);

        host_write(ADDR_IRQ_ENABLE, 8'b0000_0111);

        evt_rx_ready = 1'b1;
        @(posedge clk);
        evt_rx_ready = 1'b0;
        @(posedge clk);
        check_equal("irq asserted on rx event", irq, 1'b1);
        host_read(ADDR_IRQ_STATUS, rd_data);
        check_equal("irq status rx bit set", rd_data[0], 1'b1);

        host_write(ADDR_IRQ_CLEAR, 8'b0000_0001);
        @(posedge clk);
        check_equal("irq deasserted after clear", irq, 1'b0);

        host_write(ADDR_IRQ_ENABLE, 8'b0000_0001);
        evt_error = 1'b1;
        @(posedge clk);
        evt_error = 1'b0;
        @(posedge clk);
        check_equal("irq masked error does not assert", irq, 1'b0);
        host_read(ADDR_IRQ_STATUS, rd_data);
        check_equal("masked error still latches status", rd_data[2], 1'b1);

        host_write(ADDR_IRQ_STATUS, 8'hFF);
        host_read(ADDR_IRQ_STATUS, rd_data);
        check_equal("write to irq_status is no-op", rd_data[2], 1'b1);
        $finish;
    end

endmodule

/* verilator coverage_on */
