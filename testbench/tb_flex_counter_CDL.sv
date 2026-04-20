`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_flex_counter_CDL ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic count_enable;
    logic clear;
    logic [7:0] rollover_val;
    logic [7:0] count_out;
    logic rollover_flag;

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
        count_enable = 0;
        clear = 0;
        rollover_val = 8'd3;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    flex_counter_CDL #() DUT (.*);

    initial begin
        n_rst = 1;

        reset_dut;

        $finish;
    end
endmodule

/* verilator coverage_on */
