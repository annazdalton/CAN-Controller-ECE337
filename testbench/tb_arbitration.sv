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
    logic is_transmitter, is_receiver, arb_lost, bus_idle, arb_active, bus_off_o, recovery_done; 

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
        recovery_done = '0;

        @(posedge clk);
        @(posedge clk);
    end
    endtask

    logic check_pulse; 
    task check_outputs(
        input logic exp_bus_idle,
        input logic exp_arb_active,
        input logic exp_arb_lost,
        input logic exp_tx,
        input logic exp_rx,
        input logic exp_bus_off,
        input string test_name
    );
    begin
        @(negedge clk);
        check_pulse = 1;
        #(0.1ns);
        if (bus_idle !== exp_bus_idle) begin
            $error("[%s] bus_idle mismatch. Expected=%0b Got=%0b", test_name, exp_bus_idle, bus_idle);
        end else begin
            $display("[%s] bus_idle match. Expected=%0b Got=%0b", test_name, exp_bus_idle, bus_idle);
        end

        if (arb_active !== exp_arb_active) begin
            $error("[%s] arb_active mismatch. Expected=%0b Got=%0b", test_name, exp_arb_active, arb_active);
        end else begin
            $display("[%s] arb_active match. Expected=%0b Got=%0b", test_name, exp_arb_active, arb_active);
        end

        if (arb_lost !== exp_arb_lost) begin 
            $error("[%s] arb_lost mismatch. Expected=%0b Got=%0b", test_name, exp_arb_lost, arb_lost);
        end else begin
            $display("[%s] arb_lost match. Expected=%0b Got=%0b", test_name, exp_arb_lost, arb_lost);
        end

        if (is_transmitter !== exp_tx) begin
            $error("[%s] is_transmitter mismatch. Expected=%0b Got=%0b", test_name, exp_tx, is_transmitter);
        end else begin 
            $display("[%s] is_transmitter match. Expected=%0b Got=%0b", test_name, exp_tx, is_transmitter);
        end

        if (is_receiver !== exp_rx) begin
            $error("[%s] is_receiver mismatch. Expected=%0b Got=%0b", test_name, exp_rx, is_receiver);
        end else begin
            $display("[%s] is_receiver match. Expected=%0b Got=%0b", test_name, exp_rx, is_receiver);
        end            
        
        if (bus_off_o !== exp_bus_off) begin
            $error("[%s] bus_off_o mismatch. Expected=%0b Got=%0b", test_name, exp_bus_off, bus_off_o);
        end else begin
            $display("[%s] bus_off_o match. Expected=%0b Got=%0b", test_name, exp_bus_off, bus_off_o);
        end

        check_pulse = 0;
        $display("[%0t] Test done: %s", $time, test_name);
    end
    endtask

    task drive_bus_bit(input logic bit_val);
    begin
        bus_rx = bit_val;
        @(posedge clk);
    end
    endtask

    //send 11 bits
    task make_bus_idle;
        integer i;
    begin
        for (i = 0; i < 11; i++) begin
            drive_bus_bit(1'b1);
        end
    end
    endtask

    task send_sof;
    begin
        drive_bus_bit(1'b0);
    end
    endtask

    initial begin
        n_rst = 1;

        reset_dut;
        check_outputs(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "Reset state");

        make_bus_idle();
        check_outputs(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "Bus idle after 11 recessive bits");
        
        tx_request = 1'b0;
        send_sof();
        @(posedge clk); // allow state update
        check_outputs(1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, "SOF with no tx_request goes to RECEIVE");

        bus_off_req = 1'b1;
        @(posedge clk);
        bus_off_req = 1'b0;
        check_outputs(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "BUS_OFF entered from RECEIVE");

        recovery_done = 1'b1;
        @(posedge clk);
        recovery_done = 1'b0;
        check_outputs(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "Recovery returns to IDLE");

        make_bus_idle();
        tx_request = 1'b1;
        tx_bit = 1'b1;
        send_sof();
        @(posedge clk);
        check_outputs(1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, "SOF with tx_request enters ARB_PHASE");

        //test arbitration loss
        tx_bit = 1'b1;
        bus_rx = 1'b0;
        @(posedge clk);
        @(posedge clk); // one cycle for state transition
        check_outputs(1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, "Arbitration loss goes to RECEIVE");

        reset_dut();
        $finish;
    end
endmodule

/* verilator coverage_on */

