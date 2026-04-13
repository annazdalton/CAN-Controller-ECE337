`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_CRC_check ();

    localparam CLK_PERIOD = 10ns;

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
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    CRC_check DUT (

    );

    localparam logic [14:0] POLY = 15'b110001011001100;

    initial begin
        n_rst = 1;
        start = 0;
        data = 0;
        data_len = 0;

        reset_dut;

        $finish;
    end
endmodule

/* verilator coverage_on */