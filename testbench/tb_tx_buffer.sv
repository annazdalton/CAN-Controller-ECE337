`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_tx_buffer ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic wr_en;
    logic clr_valid;
    logic [10:0] wr_id;
    logic [3:0] wr_dlc;
    logic [63:0] wr_data;
    logic valid;
    logic [10:0] id_out;
    logic [3:0] dlc_out;
    logic [63:0] data_out;

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
        wr_en = 0;
        clr_valid = 0;
        wr_id = '0;
        wr_dlc = '0;
        wr_data = '0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    tx_buffer #() DUT (.*);

    initial begin
        n_rst = 1;

        reset_dut;

        $finish;
    end
endmodule

/* verilator coverage_on */
