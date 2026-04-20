`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_rx_buffer ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic push;
    logic pop;
    logic [10:0] push_id;
    logic [3:0] push_dlc;
    logic [63:0] push_data;
    logic [10:0] head_id;
    logic [3:0] head_dlc;
    logic [63:0] head_data;
    logic empty;
    logic full;
    logic [3:0] count;

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
        push = 0;
        pop = 0;
        push_id = '0;
        push_dlc = '0;
        push_data = '0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    rx_buffer #() DUT (.*);

    initial begin
        n_rst = 1;

        reset_dut;

        $finish;
    end
endmodule

/* verilator coverage_on */
