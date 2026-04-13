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
        input string test_name;
        input logic actual_output;
        input logic expected_output;
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

    // tx_bit_vec: whats being transmitted (MSB first)
    // bus_rx_vec: what appears on the bus (MSB first)
    task automatic drive_arb_phase (
        input int n,
        input logic [10:0] tx_bit_vec,
        input logic [10:0] bus_rx_vec
    );
        for (int i = n-1; i >= 0; i--) begin
            tx_bit = tx_bit_vec[i];
            bus_rx = bus_rx_vec[i];
            @(posedge clk); #1;
        end
    endtask

    //send 11 resessive bits
    task automatic wait_bus_idle();
        bus_rx = 1'b1;
        repeat (12) @(posedge clk);
        #1;
    endtask

    initial begin
        n_rst = 1;

        reset_dut;
        //reset/idle checks
        check_output("is_transmitter = 0 after reset", is_transmitter, 1'b0);
        check_output("is_receiver = 0 after reset",    is_receiver,    1'b0);
        check_output("arb_lost = 0 after reset",       arb_lost,       1'b0);
        check_output("arb_active = 0 after reset",     arb_active,     1'b0);

        // bus_rx starts at 1 - send 10 more 1s
        bus_rx = 1'b1;
        repeat (10) begin
            @(posedge clk); 
            #1;
        end
        check_output("bus_idle goes high after 11 recessive bits", bus_idle, 1'b1);
 
        // add one dominant bit, idle_count should reset
        bus_rx = 1'b0;
        @(posedge clk); 
        #1;
        check_output("bus_idle goes low after dominant bit", bus_idle, 1'b0);

        // check sof works
        wait_bus_idle();
        check_output("bus_idle before SOF", bus_idle, 1'b1);
 
        // SOF: first dominant bit after idle
        bus_rx = 1'b0;
        tx_request = 1'b0;
        @(posedge clk); 
        #1;
        @(posedge clk); 
        #1;

        check_output("is_receiver = 1, SOF", is_receiver, 1'b1);
        check_output("is_transmitter = 0", is_transmitter, 1'b0);
        check_output("arb_active= 0, RECEIVE", arb_active, 1'b0);

        bus_rx = 1'b1;
        repeat (10) begin
            @(posedge clk); 
            #1;
        end
        check_output("bus_idle goes high after 11 recessive bits", bus_idle, 1'b1);

        
        @(negedge clk); //back to idle
        check_output("is_receiver = 0, IDLE", is_receiver, 1'b0);
        tx_request = 1; 

        bus_rx = 1'b1;
        repeat (10) begin
            @(posedge clk); 
            #1;
        end
        check_output("bus_idle goes high after 11 recessive bits", bus_idle, 1'b1);

        #300ns;
        $finish;
    end
endmodule

/* verilator coverage_on */

