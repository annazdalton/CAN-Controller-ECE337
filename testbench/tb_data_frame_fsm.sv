`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_data_frame_fsm ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;

    logic new_message;
    logic [3:0] data_len;
    logic [63:0] data_field;

    logic [110:0] data_frame;
    logic data_ready;


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

    data_frame_fsm DUT (
        .clk(clk),
        .n_rst(n_rst),
        .data_len(data_len),
        .data_field(data_field),
        .data_frame(data_frame),
        .data_ready(data_ready)
    );


    task run_test(input logic [63:0] d, input int len);
        logic [110:0] expected;
    begin
        data_field = d;
        data_len   = len;

        // trigger
        @(negedge clk);
        new_message = 1;
        @(negedge clk);
        new_message = 0;

        // wait for completion
        wait (data_ready);


        @(posedge clk);
    end
    endtask
    initial begin
        n_rst = 1;

        reset_dut;

        run_test(64'h1234_5678_9ABC_DEF0, 8);
        run_test(64'hFFFF_FFFF_FFFF_FFFF, 8);
        run_test(64'h0000_0000_0000_00FF, 1);
        run_test(64'hA5A5_A5A5_A5A5_A5A5, 4);
        
        $finish;
    end
endmodule

/* verilator coverage_on */

