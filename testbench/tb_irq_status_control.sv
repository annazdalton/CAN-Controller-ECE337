`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_irq_status_control ();

    localparam CLK_PERIOD = 10ns;
    localparam IRQ_W = 3;

    // DUT inputs
    logic [IRQ_W-1:0] irq_clear;
    logic [IRQ_W-1:0] irq_enable_reg;
    logic evt_rx_ready;
    logic evt_tx_complete;
    logic evt_error;

    // DUT outputs
    logic [IRQ_W-1:0] irq_status;
    logic irq;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;

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
        irq_clear = '0;
        irq_enable_reg = '0;
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

    irq_status_control DUT (.clk(clk),
        .n_rst(n_rst),
        .irq_clear(irq_clear),
        .irq_enable_reg(irq_enable_reg),
        .evt_rx_ready(evt_rx_ready),
        .evt_tx_complete(evt_tx_complete),
        .evt_error(evt_error),
        .irq_status(irq_status),
        .irq(irq));

    initial begin
        n_rst = 1;

        $display("\n--- Reset Test ---");
        reset_dut;
        #1;
        check_equal("irq_status reset", irq_status, 3'b000);
        check_equal("irq reset", irq, 1'b0);

        $display("\n--- RX Event With IRQ Disabled Test ---");
        irq_enable_reg = 3'b000;
        evt_rx_ready = 1'b1;
        @(posedge clk);
        #1;
        check_equal("irq_status[0] set by RX event", irq_status, 3'b001);
        check_equal("irq remains low when disabled", irq, 1'b0);
        evt_rx_ready = 1'b0;

        $display("\n--- Clear RX Status Test ---");
        irq_clear = 3'b001;
        @(posedge clk);
        #1;
        check_equal("irq_status cleared by irq_clear", irq_status, 3'b000);
        check_equal("irq low after clear", irq, 1'b0);
        irq_clear = 3'b000;

        $display("\n--- TX Event With IRQ Enabled Test ---");
        irq_enable_reg = 3'b010;
        evt_tx_complete = 1'b1;
        @(posedge clk);
        #1;
        check_equal("irq_status[1] set by TX complete", irq_status, 3'b010);
        check_equal("irq asserted when enabled source is set", irq, 1'b1);
        evt_tx_complete = 1'b0;

        $display("\n--- Sticky Status Test ---");
        @(posedge clk);
        #1;
        check_equal("irq_status remains set until cleared", irq_status, 3'b010);
        check_equal("irq remains asserted while enabled status stays set", irq, 1'b1);

        $display("\n--- Clear TX Status Test ---");
        irq_clear = 3'b010;
        @(posedge clk);
        #1;
        check_equal("irq_status cleared after TX clear", irq_status, 3'b000);
        check_equal("irq deasserted after clear", irq, 1'b0);
        irq_clear = 3'b000;

        $display("\n--- Error Event Test ---");
        irq_enable_reg = 3'b100;
        evt_error = 1'b1;
        @(posedge clk);
        #1;
        check_equal("irq_status[2] set by error event", irq_status, 3'b100);
        check_equal("irq asserted for enabled error event", irq, 1'b1);
        evt_error = 1'b0;

        $display("\n--- Simultaneous Events Test ---");
        irq_clear = 3'b100;
        @(posedge clk);
        #1;
        irq_clear = 3'b000;
        irq_enable_reg = 3'b111;
        evt_rx_ready = 1'b1;
        evt_tx_complete = 1'b1;
        evt_error = 1'b1;
        @(posedge clk);
        #1;
        check_equal("all irq_status bits set by simultaneous events", irq_status, 3'b111);
        check_equal("irq asserted when any enabled bits are set", irq, 1'b1);
        evt_rx_ready = 1'b0;
        evt_tx_complete = 1'b0;
        evt_error = 1'b0;

        $display("\n--- Partial Clear Test ---");
        irq_clear = 3'b101;
        @(posedge clk);
        #1;
        check_equal("partial clear leaves only TX complete set", irq_status, 3'b010);
        check_equal("irq still high because remaining enabled bit is set", irq, 1'b1);
        irq_clear = 3'b000;

        $display("\n--- Masking Test ---");
        irq_enable_reg = 3'b001;
        @(posedge clk);
        #1;
        check_equal("irq low when only disabled status bit remains set", irq, 1'b0);

        $display("\nAll irq_status_control tests passed.\n");
        $finish;
    end
endmodule

/* verilator coverage_on */

