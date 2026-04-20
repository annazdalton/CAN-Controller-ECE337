`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_can_tx_path;

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk;
    logic n_rst;

    logic can_rx;
    logic bit_tick;
    logic bus_idle;

    logic tx_buf_valid;
    logic [10:0] tx_buf_id;
    logic [3:0] tx_buf_dlc;
    logic [63:0] tx_buf_data;
    logic tx_request;
    logic tx_fd_cfg;
    logic error;
    logic error_passive;
    logic error_active;

    logic can_tx;
    logic tx_en;
    logic tx_complete;
    logic arb_lost;
    logic msg_due_tx;
    logic tx_buf_clr;
    logic listen_after_arb;
    logic tx_fd_phase;

    logic [2:0] tick_div;

    always begin
        clk = 1'b0;
        #(CLK_PERIOD/2.0);
        clk = 1'b1;
        #(CLK_PERIOD/2.0);
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            tick_div <= 3'd0;
            bit_tick <= 1'b0;
        end else begin
            if (tick_div == 3'd3) begin
                tick_div <= 3'd0;
                bit_tick <= 1'b1;
            end else begin
                tick_div <= tick_div + 1'b1;
                bit_tick <= 1'b0;
            end
        end
    end

    task reset_dut;
    begin
        n_rst = 1'b0;
        repeat (4) @(posedge clk);
        n_rst = 1'b1;
        repeat (2) @(posedge clk);
    end
    endtask

    task request_tx(
        input logic [10:0] id_i,
        input logic [3:0] dlc_i,
        input logic [63:0] data_i
    );
    begin
        tx_buf_valid = 1'b1;
        tx_buf_id = id_i;
        tx_buf_dlc = dlc_i;
        tx_buf_data = data_i;

        @(posedge clk);
        tx_request = 1'b1;
        @(posedge clk);
        tx_request = 1'b0;
    end
    endtask

    can_tx_path DUT (
        .clk(clk),
        .n_rst(n_rst),
        .can_rx(can_rx),
        .bit_tick(bit_tick),
        .bus_idle(bus_idle),
        .tx_buf_valid(tx_buf_valid),
        .tx_buf_id(tx_buf_id),
        .tx_buf_dlc(tx_buf_dlc),
        .tx_buf_data(tx_buf_data),
        .tx_request(tx_request),
        .tx_fd_cfg(tx_fd_cfg),
        .error(error),
        .error_passive(error_passive),
        .error_active(error_active),
        .error_done(),
        .can_tx(can_tx),
        .tx_en(tx_en),
        .tx_complete(tx_complete),
        .arb_lost(arb_lost),
        .msg_due_tx(msg_due_tx),
        .tx_buf_clr(tx_buf_clr),
        .listen_after_arb(listen_after_arb),
        .tx_fd_phase(tx_fd_phase)
    );

    initial begin
        n_rst = 1'b1;
        can_rx = 1'b1;
        bus_idle = 1'b1;
        tx_buf_valid = 1'b0;
        tx_buf_id = 11'd0;
        tx_buf_dlc = 4'd0;
        tx_buf_data = 64'd0;
        tx_request = 1'b0;
        tx_fd_cfg = 1'b0;
        error = 1'b0;
        error_passive = 1'b0;
        error_active = 1'b1;

        reset_dut();

        bus_idle = 1'b1;
        can_rx = 1'b1;
        request_tx(11'h123, 4'd2, 64'hA5F0_0000_0000_0000);
        repeat (30000) @(posedge clk);

        bus_idle = 1'b1;
        can_rx = 1'b1;
        request_tx(11'h321, 4'd1, 64'hC300_0000_0000_0000);

        wait (tx_en == 1'b1);
        repeat (12) begin
            @(posedge clk);
            if (bit_tick) begin
                can_rx = 1'b0;
            end
        end
        can_rx = 1'b1;

        repeat (5000) @(posedge clk);

        bus_idle = 1'b1;
        can_rx = 1'b1;
        request_tx(11'h055, 4'd8, 64'hDEAD_BEEF_CAFE_BABE);
        repeat (35000) @(posedge clk);

        $finish;
    end

endmodule

/* verilator coverage_on */
