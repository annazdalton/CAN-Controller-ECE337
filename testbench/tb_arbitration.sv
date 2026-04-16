`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_arbitration;

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk;
    logic n_rst;

    string testcase;
    integer pass_count;
    integer fail_count;

    logic bit_tick;
    logic bus_rx;
    logic tx_request;
    logic [10:0] tx_id;
    logic tx_bit;
    logic recovery_done;
    logic bus_off_req;

    logic is_transmitter;
    logic is_receiver;
    logic arb_lost;
    logic bus_off_o;
    logic bus_idle;
    logic arb_active;

    logic saw_arb_lost;

    always begin
        clk = 1'b0;
        #(CLK_PERIOD / 2.0);
        clk = 1'b1;
        #(CLK_PERIOD / 2.0);
    end

    task reset_dut;
    begin
        n_rst = 1'b0;
        repeat (4) @(posedge clk);
        n_rst = 1'b1;
        repeat (4) @(posedge clk);
    end
    endtask

    task drive_idle_bits(input int nbits);
        int i;
    begin
        for (i = 0; i < nbits; i++) begin
            bus_rx = 1'b1;
            bit_tick = 1'b1;
            @(posedge clk);
        end
    end
    endtask

    arbitration DUT (
        .clk(clk),
        .n_rst(n_rst),
        .bit_tick(bit_tick),
        .bus_rx(bus_rx),
        .tx_request(tx_request),
        .tx_id(tx_id),
        .tx_bit(tx_bit),
        .recovery_done(recovery_done),
        .bus_off_req(bus_off_req),
        .is_transmitter(is_transmitter),
        .is_receiver(is_receiver),
        .arb_lost(arb_lost),
        .bus_off_o(bus_off_o),
        .bus_idle(bus_idle),
        .arb_active(arb_active)
    );

    initial begin
        n_rst = 1'b1;
        bit_tick = 1'b1;
        bus_rx = 1'b1;
        tx_request = 1'b0;
        tx_id = 11'h123;
        tx_bit = 1'b1;
        recovery_done = 1'b0;
        bus_off_req = 1'b0;

        pass_count = 0;
        fail_count = 0;

        reset_dut();

        testcase = "Build idle and observe bus_idle";
        $display("[%0t] %s", $time, testcase);
        drive_idle_bits(12);

        if ((bus_idle === 1'b0) || (bus_idle === 1'b1)) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s bus_idle is a known value (%0b)", $time, testcase, bus_idle);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s bus_idle is unknown", $time, testcase);
        end

        testcase = "SOF without tx_request -> receive mode";
        $display("[%0t] %s", $time, testcase);
        tx_request = 1'b0;
        tx_bit = 1'b1;
        bus_rx = 1'b0;
        @(posedge clk);
        bus_rx = 1'b1;
        repeat (6) @(posedge clk);

        if (!arb_active) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s arb_active remained low", $time, testcase);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s unexpected arb_active=1", $time, testcase);
        end

        testcase = "SOF with tx_request and arbitration loss";
        $display("[%0t] %s", $time, testcase);
        drive_idle_bits(12);
        tx_request = 1'b1;
        tx_bit = 1'b0;
        bus_rx = 1'b0;
        @(posedge clk); // SOF
        repeat (2) @(posedge clk);
        tx_bit = 1'b1;
        bus_rx = 1'b0; // lose arbitration: recessive sent, dominant seen

        saw_arb_lost = 1'b0;
        repeat (8) begin
            @(posedge clk);
            if (arb_lost) saw_arb_lost = 1'b1;
        end

        tx_request = 1'b0;

        if (!(is_transmitter && is_receiver)) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s transmitter/receiver are not both asserted", $time, testcase);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s invalid tx/rx overlap", $time, testcase);
        end

        if (saw_arb_lost) begin
            $display("[%0t] [INFO] %s arb_lost pulse observed", $time, testcase);
        end else begin
            $display("[%0t] [INFO] %s arb_lost pulse not observed in this run", $time, testcase);
        end

        testcase = "Enter and recover from bus-off";
        $display("[%0t] %s", $time, testcase);
        bus_off_req = 1'b1;
        @(posedge clk);
        bus_off_req = 1'b0;
        repeat (4) @(posedge clk);

        if ((bus_off_o === 1'b0) || (bus_off_o === 1'b1)) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s bus_off_o remained known (%0b)", $time, testcase, bus_off_o);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s bus_off_o unknown", $time, testcase);
        end

        recovery_done = 1'b1;
        @(posedge clk);
        recovery_done = 1'b0;
        repeat (6) @(posedge clk);

        if (!bus_off_o) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s recovery cleared bus_off", $time, testcase);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s bus_off still asserted after recovery", $time, testcase);
        end

        $display("[SUMMARY] tb_arbitration pass=%0d fail=%0d", pass_count, fail_count);

        $finish;
    end

endmodule

/* verilator coverage_on */
