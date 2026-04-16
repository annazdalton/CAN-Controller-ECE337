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

    string testcase;
    integer pass_count;
    integer fail_count;

    logic new_message;
    logic [10:0] identifier;
    logic [3:0] data_len;
    logic [63:0] data_field;

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

    task check_frame(input logic [3:0] dlc_i);
        logic [7:0] expected_frame_len;
        logic [7:0] expected_stuff_len;
    begin
        expected_frame_len = 8'd44 + {dlc_i, 3'b000};
        expected_stuff_len = 8'd34 + {dlc_i, 3'b000};

        if (frame_len == expected_frame_len) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s frame_len=%0d", $time, testcase, frame_len);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s frame_len exp=%0d got=%0d", $time, testcase, expected_frame_len, frame_len);
        end

        if (stuff_len == expected_stuff_len) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s stuff_len=%0d", $time, testcase, stuff_len);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s stuff_len exp=%0d got=%0d", $time, testcase, expected_stuff_len, stuff_len);
        end

        if (data_frame[0] == 1'b0) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s SOF bit is dominant", $time, testcase);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s SOF bit expected 0 got %0b", $time, testcase, data_frame[0]);
        end

        if (data_frame[frame_len - 1'b1] == 1'b1) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s EOF bit is recessive", $time, testcase);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s EOF bit expected 1 got %0b", $time, testcase, data_frame[frame_len - 1'b1]);
        end
    end
    endtask

    data_frame_fsm DUT (
        .clk(clk),
        .n_rst(n_rst),
        .new_message(new_message),
        .identifier(identifier),
        .data_len(data_len),
        .data_field(data_field),
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

        pass_count = 0;
        fail_count = 0;

        reset_dut();

        testcase = "one-byte payload";
        send_message(11'h123, 4'd1, 64'hA500_0000_0000_0000);
        check_frame(4'd1);

        testcase = "four-byte payload";
        send_message(11'h055, 4'd4, 64'h1122_3344_0000_0000);
        check_frame(4'd4);

        testcase = "eight-byte payload";
        send_message(11'h7AA, 4'd8, 64'hDEAD_BEEF_CAFE_BABE);
        check_frame(4'd8);

        $display("[SUMMARY] tb_data_frame_fsm pass=%0d fail=%0d", pass_count, fail_count);

        repeat (10) @(posedge clk);

        $finish;
    end

endmodule

/* verilator coverage_on */
