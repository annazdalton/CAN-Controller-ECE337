`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_arbitration ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst, bus_rx, tx_request, tx_bit, bus_off_req;
    logic [10:0] tx_id;
    logic is_transmitter, is_receiver, arb_lost, bus_idle, arb_active; 

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end


    arbitration DUT (
        .clk(clk), 
        .n_rst(n_rst),
        .bus_rx(bus_rx), //sampled bit from CAN bus: dominant = 0, recessive = 1
        .tx_request(tx_request),
        .tx_id(tx_id),
        .tx_bit(tx_bit), 
        .bus_off_req(bus_off_req),

        .is_transmitter(is_transmitter),
        .is_receiver(is_receiver),
        .arb_lost(arb_lost), 
        .bus_idle(bus_idle), // 1 = bus is idle (11 recessive bits detected)
        .arb_active(arb_active) //1 is arb phase is ongoing 
    );

    task reset_dut;
    begin
        n_rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        bus_rx = 0;
        tx_request = 0;
        tx_id = 11'b11111_11111_1;
        tx_bit = 0;
        bus_off_req = 0;

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

        //IDLE
        check_output(1'b0, is_transmitter, "check is_transmitter is low, idle state");
        check_output(1'b0, is_receiver, "check is_reciever is low, idle state");


        $finish;
    end
endmodule

/* verilator coverage_on */

