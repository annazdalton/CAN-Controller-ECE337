`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_error_frame_fsm ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic error, serial_out, error_idle;

    error_frame_fsm error_frame(
        .clk(clk), 
        .n_rst(n_rst),
        .error(error),
        
        .serial_out(serial_out), 
        .error_idle(error_idle)
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
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    logic check_pulse;
    logic check_mismatch;

    task check_output;
        input logic actual_output;
        input logic expected_output;
        input string test_name;
    begin
        check_mismatch = 0;
        check_pulse = 1;
        #(0.1);
        if(expected_output != actual_output) begin
            check_mismatch = 1;
            $display("Test Case FAILED for the %s check. Expected %d, Actual %d", test_name, expected_output, actual_output);
        end else begin
            check_mismatch = 0;
            $display("Test Case PASSED for the %s check. Expected %d, Actual %d", test_name, expected_output, actual_output);
        end
        check_pulse = 0;
    end
    endtask

    initial begin
        n_rst = 1;

        reset_dut;

        #(20ns);

        check_output(1'b0 ,serial_out, "serial out is 0 - idle");

        error = 1'b1;
        @(negedge clk);

        //load
        check_output(1'b0 ,serial_out, "serial out is 0 - load");
        @(posedge clk);

        //start shifting 1s
        check_output(1'b1 ,serial_out, "serial out is 1 - err frame shifting out");
        @(posedge clk);
        check_output(1'b1 ,serial_out, "serial out is 1 - err frame shifting out");
        @(posedge clk);
        check_output(1'b1 ,serial_out, "serial out is 1 - err frame shifting out");
        @(posedge clk);
        check_output(1'b1 ,serial_out, "serial out is 1 - err frame shifting out");
        @(posedge clk);
        check_output(1'b1 ,serial_out, "serial out is 1 - err frame shifting out");
        @(posedge clk);
        check_output(1'b1 ,serial_out, "serial out is 1 - err frame shifting out");
        @(posedge clk);
        check_output(1'b1 ,serial_out, "serial out is 1 - err frame shifting out");
        @(posedge clk);
        check_output(1'b1 ,serial_out, "serial out is 1 - err frame shifting out");
        @(posedge clk);

        //start shifting 0s
        check_output(1'b0 ,serial_out, "serial out is 0 - err frame shifting out");
        @(posedge clk);
        check_output(1'b0 ,serial_out, "serial out is 0 - err frame shifting out");
        @(posedge clk);
        check_output(1'b0 ,serial_out, "serial out is 0 - err frame shifting out");
        @(posedge clk);
        check_output(1'b0 ,serial_out, "serial out is 0 - err frame shifting out");
        @(posedge clk);
        check_output(1'b0 ,serial_out, "serial out is 0 - err frame shifting out");
        @(posedge clk);
        check_output(1'b0 ,serial_out, "serial out is 0 - err frame shifting out");
        @(posedge clk);

        #(300ns);

        $finish;
    end
endmodule

/* verilator coverage_on */

