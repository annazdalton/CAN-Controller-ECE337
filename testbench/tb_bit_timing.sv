`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_bit_timing ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;

    // DUT inputs and outputs
    logic enable;
    logic rx_active;
    logic bus_idle;
    logic resync_enable;
    logic [9:0] brp;
    logic [5:0] tq_per_bit;
    logic [5:0] sample_tq;
    logic [5:0] sjw;
    logic fd;
    logic can_rx;

    logic tq_tick;
    logic sample_tick;
    logic bit_tick;
    logic hard_sync_pulse;
    logic resync_pulse;
    logic early_edge;
    logic late_edge;
    logic timing_error;
    logic sampled_bit;

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

    task init_signals;
        begin
            enable = 1'b0;
            rx_active = 1'b0;
            bus_idle = 1'b1;
            resync_enable = 1'b0;
            brp = 10'd3; // tq every 4 clocks
            tq_per_bit = 6'd8; // 8 tq per bit
            sample_tq = 6'd3; // sample around middle
            sjw = 6'd1;
            fd = 1'b0;
            can_rx = 1'b1; // recessive idle
        end
    endtask

    task wait_tq_ticks(input integer num_ticks);
        integer i;
        begin
            for (i = 0; i < num_ticks; i = i + 1) begin
                @(posedge clk);
                while (tq_tick !== 1'b1) begin
                    @(posedge clk);
                end
            end
        end
    endtask

    bit_timing DUT (.*);

    initial begin
        init_signals();
        n_rst = 1'b1;

        reset_dut();

        // 1: enable timing unit and observe tq_tick
        enable = 1'b1;
        repeat (20) @(posedge clk);

        // 2: hard sync on SOF
        // bus is idle, then falling edge on can_rx should trigger hard sync
        bus_idle = 1'b1;
        rx_active = 1'b0;
        resync_enable = 1'b0;
        can_rx = 1'b1;

        @(negedge clk);
        can_rx = 1'b0;

        // 3: active reception, sample and bit ticks
        bus_idle = 1'b0;
        rx_active = 1'b1;
        resync_enable = 1'b1;

        // Hold bus low for a few bits
        wait_tq_ticks(12);

        // Change bus before next sample point
        can_rx = 1'b1;
        wait_tq_ticks(12);

        // 4: early edge (edge before sample_tq)
        while (bit_tick !== 1'b1) @(posedge clk);
        @(posedge clk);
        wait_tq_ticks(1);
        can_rx = ~can_rx;

        // 5: late edge (edge after sample_tq)
        while (bit_tick !== 1'b1) @(posedge clk);
        @(posedge clk);
        wait_tq_ticks(5);
        can_rx = ~can_rx;

        // 6: enable FD mode and observe faster tq_tick rate
        fd = 1'b1;
        repeat (60) @(posedge clk);

        $finish;
    end

endmodule
