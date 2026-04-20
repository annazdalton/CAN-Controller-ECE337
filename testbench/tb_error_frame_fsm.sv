`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_error_frame_fsm ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic error, error_passive, error_active, serial_out, error_done;

    error_frame_fsm error_frame(
        .clk(clk), 
        .n_rst(n_rst),
        .error(error),
        .error_passive(error_passive),
        .error_active(error_active),
        
        .serial_out(serial_out), 
        .error_done(error_done)
    );

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
        error = 0;
        error_passive = 1;
        error_active = 0;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    initial begin
        n_rst = 1;

        reset_dut;

        #(20ns);

        error = 1'b1;
        @(negedge clk);

        //load
        @(posedge clk);

        //start shifting 1s
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        //start shifting 0s
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        #(300ns);

        $finish;
    end
endmodule

/* verilator coverage_on */
