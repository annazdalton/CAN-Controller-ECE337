`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_register_bank ();

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

    // DUT inputs
    logic reg_wr_en;
    logic reg_rd_en;
    logic [DATA_W-1:0] reg_wdata;
    logic [ADDR_W-1:0] reg_addr;
    logic [IRQ_W-1:0] irq_status;

    // DUT outputs
    logic [DATA_W-1:0] reg_rdata;
    logic wr_accept;
    logic rd_valid;
    logic [IRQ_W-1:0] irq_enable_reg;
    logic [IRQ_W-1:0] irq_clear;
    logic [DATA_W-1:0] mode_cfg;
    logic [DATA_W-1:0] bit_timing_cfg;
    logic [DATA_W-1:0] filter_cfg;

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
        reg_wr_en = 0;
        reg_rd_en = 0;
        reg_wdata = '0;
        reg_addr = '0;
        irq_status = '0;

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

    register_bank DUT (
        .clk(clk),
        .n_rst(n_rst),
        .reg_wr_en(reg_wr_en),
        .reg_rd_en(reg_rd_en),
        .reg_wdata(reg_wdata),
        .reg_addr(reg_addr),
        .irq_status(irq_status),
        .reg_rdata(reg_rdata),
        .wr_accept(wr_accept),
        .rd_valid(rd_valid),
        .irq_enable_reg(irq_enable_reg),
        .irq_clear(irq_clear),
        .mode_cfg(mode_cfg),
        .bit_timing_cfg(bit_timing_cfg),
        .filter_cfg(filter_cfg)
    );

    initial begin
        n_rst = 1;

        $display("\n--- Reset Test ---");
        reset_dut;
        #1;
        check_equal("mode_cfg reset", mode_cfg, 8'h00);
        check_equal("bit_timing_cfg reset", bit_timing_cfg, 8'h00);
        check_equal("filter_cfg reset", filter_cfg, 8'h00);
        check_equal("irq_enable_reg reset", irq_enable_reg, 3'b000);
        check_equal("reg_rdata reset", reg_rdata, 8'h00);
        check_equal("wr_accept reset", wr_accept, 1'b0);
        check_equal("rd_valid reset", rd_valid, 1'b0);
        check_equal("irq_clear reset", irq_clear, 3'b000);

        $display("\n--- Write MODE Register Test ---");
        reg_wr_en = 1'b1;
        reg_rd_en = 1'b0;
        reg_addr = MODE_ADDR;
        reg_wdata = 8'hA5;
        #1;
        check_equal("wr_accept asserted on MODE write", wr_accept, 1'b1);
        @(posedge clk);
        #1;
        check_equal("mode_cfg updated after MODE write", mode_cfg, 8'hA5);

        reg_wr_en = 1'b0;
        @(posedge clk);
        #1;
        check_equal("wr_accept clears after write", wr_accept, 1'b0);

        $display("\n--- Write BIT_TIMING Register Test ---");
        reg_wr_en = 1'b1;
        reg_addr = BIT_TIMING_ADDR;
        reg_wdata = 8'h3C;
        #1;
        check_equal("wr_accept asserted on BIT_TIMING write", wr_accept, 1'b1);
        @(posedge clk);
        #1;
        check_equal("bit_timing_cfg updated after write", bit_timing_cfg, 8'h3C);

        reg_wr_en = 1'b0;
        @(posedge clk);

        $display("\n--- Write FILTER Register Test ---");
        reg_wr_en = 1'b1;
        reg_addr = FILTER_ADDR;
        reg_wdata = 8'hF0;
        #1;
        check_equal("wr_accept asserted on FILTER write", wr_accept, 1'b1);
        @(posedge clk);
        #1;
        check_equal("filter_cfg updated after write", filter_cfg, 8'hF0);

        reg_wr_en = 1'b0;
        @(posedge clk);

        $display("\n--- Write IRQ_ENABLE Register Test ---");
        reg_wr_en = 1'b1;
        reg_addr = IRQ_ENABLE_ADDR;
        reg_wdata = 8'b00000101;
        #1;
        check_equal("wr_accept asserted on IRQ_ENABLE write", wr_accept, 1'b1);
        @(posedge clk);
        #1;
        check_equal("irq_enable_reg updated after write", irq_enable_reg, 3'b101);

        reg_wr_en = 1'b0;
        @(posedge clk);

        $display("\n--- IRQ_CLEAR Pulse Test ---");
        reg_wr_en = 1'b1;
        reg_addr = IRQ_CLEAR_ADDR;
        reg_wdata = 8'b00000011;
        #1;
        check_equal("irq_clear asserted during IRQ_CLEAR write", irq_clear, 3'b011);
        check_equal("wr_accept asserted on IRQ_CLEAR write", wr_accept, 1'b1);
        @(posedge clk);
        reg_wr_en = 1'b0;
        #1;
        check_equal("irq_clear returns low after write removed", irq_clear, 3'b000);

        $display("\n--- Read MODE Register Test ---");
        reg_rd_en = 1'b1;
        reg_addr = MODE_ADDR;
        #1;
        check_equal("rd_valid asserted on MODE read", rd_valid, 1'b1);
        @(posedge clk);
        #1;
        check_equal("reg_rdata returns MODE value", reg_rdata, 8'hA5);

        reg_rd_en = 1'b0;
        @(posedge clk);
        #1;
        check_equal("rd_valid clears after read", rd_valid, 1'b0);

        $display("\n--- Read BIT_TIMING Register Test ---");
        reg_rd_en = 1'b1;
        reg_addr = BIT_TIMING_ADDR;
        #1;
        check_equal("rd_valid asserted on BIT_TIMING read", rd_valid, 1'b1);
        @(posedge clk);
        #1;
        check_equal("reg_rdata returns BIT_TIMING value", reg_rdata, 8'h3C);

        reg_rd_en = 1'b0;
        @(posedge clk);

        $display("\n--- Read FILTER Register Test ---");
        reg_rd_en = 1'b1;
        reg_addr = FILTER_ADDR;
        #1;
        check_equal("rd_valid asserted on FILTER read", rd_valid, 1'b1);
        @(posedge clk);
        #1;
        check_equal("reg_rdata returns FILTER value", reg_rdata, 8'hF0);

        reg_rd_en = 1'b0;
        @(posedge clk);

        $display("\n--- Read IRQ_ENABLE Register Test ---");
        reg_rd_en = 1'b1;
        reg_addr = IRQ_ENABLE_ADDR;
        #1;
        check_equal("rd_valid asserted on IRQ_ENABLE read", rd_valid, 1'b1);
        @(posedge clk);
        #1;
        check_equal("reg_rdata returns zero-extended IRQ_ENABLE", reg_rdata, 8'b00000101);

        reg_rd_en = 1'b0;
        @(posedge clk);

        $display("\n--- Read IRQ_STATUS Register Test ---");
        irq_status = 3'b110;
        reg_rd_en = 1'b1;
        reg_addr = IRQ_STATUS_ADDR;
        #1;
        check_equal("rd_valid asserted on IRQ_STATUS read", rd_valid, 1'b1);
        @(posedge clk);
        #1;
        check_equal("reg_rdata returns zero-extended IRQ_STATUS", reg_rdata, 8'b00000110);

        reg_rd_en = 1'b0;
        @(posedge clk);

        $display("\n--- Read Invalid Address Test ---");
        reg_rd_en = 1'b1;
        reg_addr = 4'hF;
        #1;
        check_equal("rd_valid asserted on invalid read", rd_valid, 1'b1);
        @(posedge clk);
        #1;
        check_equal("invalid address read returns zero", reg_rdata, 8'h00);

        reg_rd_en = 1'b0;
        @(posedge clk);

        $display("\n--- Write Priority Over Read Test ---");
        reg_wr_en = 1'b1;
        reg_rd_en = 1'b1;
        reg_addr = MODE_ADDR;
        reg_wdata = 8'h5A;
        #1;
        check_equal("wr_accept asserted when both write/read high", wr_accept, 1'b1);
        check_equal("rd_valid not asserted when write has priority", rd_valid, 1'b0);
        @(posedge clk);
        #1;
        check_equal("MODE updated in write-priority case", mode_cfg, 8'h5A);

        reg_wr_en = 1'b0;
        reg_rd_en = 1'b0;
        @(posedge clk);

        $display("\nAll register_bank tests passed.\n");
        $finish;
    end
endmodule

/* verilator coverage_on */

