`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_data_frame_fsm;

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk;
    logic n_rst;

    logic new_message;
    logic [10:0] identifier;
    logic [3:0] data_len;
    logic [63:0] data_field;
    logic fd_enable;

    logic [110:0] data_frame;
    logic [7:0] frame_len;
    logic [7:0] stuff_len;
    logic busy;
    logic data_ready;

    always begin
        clk = 1'b0;
        #(CLK_PERIOD/2.0);
        clk = 1'b1;
        #(CLK_PERIOD/2.0);
    end

    task reset_dut;
    begin
        n_rst = 1'b0;
        repeat (3) @(posedge clk);
        n_rst = 1'b1;
        repeat (2) @(posedge clk);
    end
    endtask

    task send_message(
        input logic [10:0] id_i,
        input logic [3:0] dlc_i,
        input logic [63:0] data_i
    );
    begin
        identifier = id_i;
        data_len = dlc_i;
        data_field = data_i;

        @(posedge clk);
        new_message = 1'b1;
        @(posedge clk);
        new_message = 1'b0;

        wait (data_ready == 1'b1);
        @(posedge clk);
    end
    endtask

    data_frame_fsm DUT (
        .clk(clk),
        .n_rst(n_rst),
        .new_message(new_message),
        .identifier(identifier),
        .data_len(data_len),
        .data_field(data_field),
        .fd_enable(fd_enable),
        .data_frame(data_frame),
        .frame_len(frame_len),
        .stuff_len(stuff_len),
        .busy(busy),
        .data_ready(data_ready)
    );

    initial begin
        new_message = 1'b0;
        identifier = 11'd0;
        data_len = 4'd0;
        data_field = 64'd0;
        fd_enable = 1'b0;

        reset_dut();
        send_message(11'h123, 4'd1, 64'hA500_0000_0000_0000);
        send_message(11'h055, 4'd4, 64'h1122_3344_0000_0000);
        send_message(11'h7AA, 4'd8, 64'hDEAD_BEEF_CAFE_BABE);
        fd_enable = 1'b1;
        send_message(11'h011, 4'd2, 64'hABCD_0000_0000_0000);
        fd_enable = 1'b0;

        repeat (10) @(posedge clk);

        $finish;
    end

endmodule

/* verilator coverage_on */
