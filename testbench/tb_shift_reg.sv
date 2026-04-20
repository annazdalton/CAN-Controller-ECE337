`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_shift_reg ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic shift_enable;
    logic serial_in;
    logic load_enable;
    logic [7:0] parallel_in;
    logic serial_out;
    logic [7:0] parallel_out;

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
        shift_enable = 0;
        serial_in = 0;
        load_enable = 0;
        parallel_in = '0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    shift_reg #() DUT (.*);

    initial begin
        n_rst = 1;

        reset_dut;

        $finish;
    end
endmodule

/* verilator coverage_on */
