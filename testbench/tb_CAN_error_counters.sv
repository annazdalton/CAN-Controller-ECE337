`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_CAN_error_counters ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic tx_error;
    logic tx_success;
    logic rx_error;
    logic rx_success;
    logic bus_off_i;
    logic bus_rx;
    logic error_active;
    logic error_passive;
    logic bus_off;
    logic recovery_done;

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
        tx_error = 0;
        tx_success = 0;
        rx_error = 0;
        rx_success = 0;
        bus_off_i = 0;
        bus_rx = 1;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    CAN_error_counters #() DUT (.*);

    initial begin
        n_rst = 1;

        reset_dut;

        $finish;
    end
endmodule

/* verilator coverage_on */
