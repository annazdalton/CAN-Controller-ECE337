`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_host_cfg_top ();

    localparam CLK_PERIOD = 10ns;
    localparam ADDR_W = 4;
    localparam DATA_W = 8;
    localparam IRQ_W = 3;

    localparam logic [ADDR_W-1:0] MODE_ADDR = 4'h0;
    localparam logic [ADDR_W-1:0] BIT_TIMING_ADDR = 4'h1;
    localparam logic [ADDR_W-1:0] FILTER_ADDR = 4'h2;
    localparam logic [ADDR_W-1:0] IRQ_ENABLE_ADDR = 4'h3;
    localparam logic [ADDR_W-1:0] IRQ_STATUS_ADDR = 4'h4;
    localparam logic [ADDR_W-1:0] IRQ_CLEAR_ADDR = 4'h5;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic host_wr_req;
    logic host_rd_req;
    logic [DATA_W - 1: 0] host_wdata;
    logic [ADDR_W - 1: 0] host_addr;

    logic evt_rx_ready;
    logic evt_tx_complete;
    logic evt_error;

    logic [DATA_W-1:0] host_rdata;
    logic host_wr_ack;
    logic host_rd_ack;

    logic [DATA_W-1:0] mode_cfg;
    logic [DATA_W-1:0] bit_timing_cfg;
    logic [DATA_W-1:0] filter_cfg;

    logic irq;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    task reset_dut;
    begin
        n_rst = 0;
        host_wr_req = 0;
        host_rd_req = 0;
        host_wdata = '0;
        host_addr = '0;
        evt_rx_ready = 0;
        evt_tx_complete = 0;
        evt_error = 0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    task check_equal(
        input string name,
        input logic [31:0] actual,
        input logic [31:0] expected
    );
    begin
        if (actual !== expected) begin
            $display("FAIL: %s | actual = 0x%0h expected = 0x%0h", name, actual, expected);
            $finish;
        end
        else begin
            $display("PASS: %s | value = 0x%0h", name, actual);
        end
    end
    endtask
    
    task host_write(
        input logic [ADDR_W-1:0] addr,
        input logic [DATA_W-1:0] data
    );
    begin
        @(negedge clk);
        host_addr = addr;
        host_wdata = data;
        host_wr_req = 1'b1;
        host_rd_req = 1'b0;

        @(posedge clk);
        #1;
        check_equal("host_wr_ack after write", host_wr_ack, 1'b1);

        @(negedge clk);
        host_wr_req = 1'b0;

        @(posedge clk);
        #1;
        check_equal("host_wr_ack clears", host_wr_ack, 1'b0);

    // extra cycle for downstream register update
        @(posedge clk);
        #1;
    end
    endtask

    task host_read(
        input logic [ADDR_W-1:0] addr,
        input logic [DATA_W-1:0] expected_data
    );
    begin
        @(negedge clk);
        host_addr = addr;
        host_rd_req = 1'b1;
        host_wr_req = 1'b0;

        @(posedge clk);
        #1;
        check_equal("host_rd_ack after read", host_rd_ack, 1'b1);
        check_equal("host_rdata after read", host_rdata, expected_data);
        
        @(negedge clk);
        host_rd_req = 1'b0;

        @(posedge clk);
        #1;
        check_equal("host_rd_ack clears", host_rd_ack, 1'b0);
    end
    endtask

    host_cfg_top DUT (
        .clk(clk),
        .n_rst(n_rst),
        .host_wr_req(host_wr_req),
        .host_rd_req(host_rd_req),
        .host_wdata(host_wdata),
        .host_addr(host_addr),
        .host_rdata(host_rdata),
        .host_wr_ack(host_wr_ack),
        .host_rd_ack(host_rd_ack),
        .evt_rx_ready(evt_rx_ready),
        .evt_tx_complete(evt_tx_complete),
        .evt_error(evt_error),
        .mode_cfg(mode_cfg),
        .bit_timing_cfg(bit_timing_cfg),
        .filter_cfg(filter_cfg),
        .irq(irq)
    );

    initial begin
        n_rst = 1;

        $display("\n--- Reset Test ---");
        reset_dut;
        #1;
        
        check_equal("mode_cfg reset", mode_cfg, 8'h00);
        check_equal("bit_timing_cfg reset", bit_timing_cfg, 8'h00);
        check_equal("filter_cfg reset", filter_cfg, 8'h00);
        check_equal("host_rdata reset", host_rdata, 8'h00);
        check_equal("host_wr_ack reset", host_wr_ack, 1'b0);
        check_equal("host_rd_ack reset", host_rd_ack, 1'b0);
        check_equal("irq reset", irq, 1'b0);

        $display("\n--- Write Config Register Tests ---");
        host_write(MODE_ADDR, 8'hA5);
        check_equal("mode_cfg updated", mode_cfg, 8'hA5);

        host_write(BIT_TIMING_ADDR, 8'h3C);
        check_equal("bit_timing_cfg updated", bit_timing_cfg, 8'h3C);

        host_write(FILTER_ADDR, 8'hF0);
        check_equal("filter_cfg updated", filter_cfg, 8'hF0);

        $display("\n--- Read Config Register Tests ---");
        host_read(MODE_ADDR, 8'hA5);
        host_read(BIT_TIMING_ADDR, 8'h3C);
        host_read(FILTER_ADDR, 8'hF0);

        $display("\n--- IRQ Disabled Event Test ---");
        evt_rx_ready = 1'b1;
        @(posedge clk);
        #1;
        
        check_equal("irq stays low when enables are zero", irq, 1'b0);
        evt_rx_ready = 1'b0;

        $display("\n--- Enable IRQ Sources Test ---");
        host_write(IRQ_ENABLE_ADDR, 8'b00000111);

        $display("\n--- RX Event IRQ Test ---");
        evt_rx_ready = 1'b1;
        @(posedge clk);
        #1;
        
        check_equal("irq asserted on RX event", irq, 1'b1);
        evt_rx_ready = 1'b0;

        $display("\n--- Read IRQ Status After RX Event ---");
        host_read(IRQ_STATUS_ADDR, 8'b00000001);

        $display("\n--- Clear RX IRQ Status ---");
        host_write(IRQ_CLEAR_ADDR, 8'b00000001);
        @(posedge clk);
        #1;
        
        check_equal("irq deasserted after clearing RX status", irq, 1'b0);
        host_read(IRQ_STATUS_ADDR, 8'b00000000);

        $display("\n--- TX Complete Event IRQ Test ---");
        evt_tx_complete = 1'b1;
        @(posedge clk);
        #1;
        
        check_equal("irq asserted on TX complete", irq, 1'b1);
        evt_tx_complete = 1'b0;
        host_read(IRQ_STATUS_ADDR, 8'b00000010);

        $display("\n--- Error Event IRQ Test ---");
        host_write(IRQ_CLEAR_ADDR, 8'b00000010);
        @(posedge clk);
        #1;
        
        evt_error = 1'b1;
        @(posedge clk);
        #1;
        
        check_equal("irq asserted on error event", irq, 1'b1);
        evt_error = 1'b0;
        host_read(IRQ_STATUS_ADDR, 8'b00000100);

        $display("\n--- Multiple Events Test ---");
        host_write(IRQ_CLEAR_ADDR, 8'b00000111);
        @(posedge clk);
        #1;
        
        evt_rx_ready = 1'b1;
        evt_tx_complete = 1'b1;
        evt_error = 1'b1;
        @(posedge clk);
        #1;
        
        check_equal("irq asserted on multiple events", irq, 1'b1);
        evt_rx_ready = 1'b0;
        evt_tx_complete = 1'b0;
        evt_error = 1'b0;
        host_read(IRQ_STATUS_ADDR, 8'b00000111);

        $display("\n--- IRQ Masking Test ---");
        host_write(IRQ_CLEAR_ADDR, 8'b00000111);
        @(posedge clk);
        
        host_write(IRQ_ENABLE_ADDR, 8'b00000001);
        evt_error = 1'b1;
        @(posedge clk);
        
        check_equal("irq stays low when error source masked", irq, 1'b0);
        evt_error = 1'b0;
        host_read(IRQ_STATUS_ADDR, 8'b00000100);

        $display("\nAll host_cfg_top tests passed.\n");
        $finish;
    end
endmodule

/* verilator coverage_on */

