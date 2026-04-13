`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_CAN_fsm ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic tx_request, bus_idle, node_off, data_done, error_idle, tx_bit, arb_field_done, eof_done, bus_bit;
    logic sof_en, arb_en, crc_rst, data_en, ack_en, ack_delim_en, eof_en, error;

    CAN_fsm DUT(
    .clk(clk), 
    .n_rst(n_rst),
    .tx_request(tx_request), 
    .bus_idle(bus_idle),
    .node_off(node_off), 
    .data_done(data_done), 
    .error_idle(error_idle), 
    .tx_bit(tx_bit), 
    .arb_field_done(~arb_active), //maybe change this to a pulse when done
    .eof_done(eof_done), 
    .bus_bit(bus_bit), 

    .sof_en(sof_en), 
    .arb_en(arb_en), 
    .crc_rst(crc_rst), 
    .data_en(data_en), 
    .ack_en(ack_en), 
    .ack_delim_en(ack_delim_en), 
    .eof_en(eof_en), 
    .error(error)
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
        @(posedge clk);
        @(posedge clk);
        tx_request = '0;
        bus_idle = '0;
        node_off = '1;
        data_done = '0;
        error_idle = '0;
        tx_bit = '0;
        arb_field_done = '0;
        eof_done = '0;
        bus_bit = '0;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    logic check_pulse;
    logic check_mismatch;

    task check_output;
        input logic expected_output;
        input logic actual_output;
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

        //idle state
        check_output(1'b0, sof_en, "check sof_en is low, idle state");
        @(posedge clk);

        node_off = 0;
        bus_bit = 0;
        tx_bit = 0;
        tx_request = 1;
        bus_idle = 1;
        @(negedge clk);
        
        //sof state
        check_output(1'b1, sof_en, "check sof_en is high, sof state");
        @(posedge clk);

        check_output(1'b1, arb_en, "check arb_en is high, arb state");
        @(posedge clk);

        arb_field_done = 1;
        @(negedge clk);

        check_output(1'b1, data_en, "check data_en is high, data state");
        @(posedge clk);

        data_done = 1;
        @(negedge clk);

        check_output(1'b1, ack_en, "check ack_en is high, ack state");
        @(posedge clk);

        check_output(1'b1, ack_delim_en, "check ack_delim_en is high, ack_delim state");
        @(posedge clk);

        check_output(1'b1, eof_en, "check eof_en is high, eof state");
        @(posedge clk);

        eof_done = 1;
        @(negedge clk);

        check_output(1'b0, eof_en, "check eof_en is low, ifs state");
        @(posedge clk);

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        check_output(1'b0, eof_en, "check eof_en is low, idle state");


        $finish;
    end
endmodule

/* verilator coverage_on */

