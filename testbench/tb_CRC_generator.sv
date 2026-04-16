`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_CRC_generator;

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

    logic start;
    logic sof_bit;
    logic [10:0] identifier;
    logic rtr_bit;
    logic ide_bit;
    logic r0_bit;
    logic [3:0] dlc;
    logic [63:0] data;
    logic done;
    logic [14:0] crc_out;

    always begin
        clk = 1'b0;
        #(CLK_PERIOD / 2.0);
        clk = 1'b1;
        #(CLK_PERIOD / 2.0);
    end

    task reset_dut;
    begin
        n_rst = 1'b0;
        repeat (3) @(posedge clk);
        n_rst = 1'b1;
        repeat (2) @(posedge clk);
    end
    endtask

    task start_crc_frame(
        input logic [10:0] id_i,
        input logic [3:0] dlc_i,
        input logic [63:0] data_i
    );
    begin
        identifier = id_i;
        dlc = dlc_i;
        data = data_i;

        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        wait (done == 1'b1);
        @(posedge clk);
    end
    endtask

    task check_crc(input logic [14:0] expected_crc);
    begin
        if (crc_out == expected_crc) begin
            pass_count = pass_count + 1;
            $display("[%0t] [PASS] %s: crc_out=0x%0h", $time, testcase, crc_out);
        end else begin
            fail_count = fail_count + 1;
            $display("[%0t] [FAIL] %s: expected=0x%0h got=0x%0h", $time, testcase, expected_crc, crc_out);
        end
    end
    endtask

    CRC_generator DUT (
        .clk(clk),
        .n_rst(n_rst),
        .start(start),
        .sof_bit(sof_bit),
        .identifier(identifier),
        .rtr_bit(rtr_bit),
        .ide_bit(ide_bit),
        .r0_bit(r0_bit),
        .dlc(dlc),
        .data(data),
        .done(done),
        .crc_out(crc_out)
    );

    initial begin
        n_rst = 1'b1;
        start = 1'b0;
        sof_bit = 1'b0;
        rtr_bit = 1'b0;
        ide_bit = 1'b0;
        r0_bit = 1'b0;
        identifier = 11'd0;
        dlc = 4'd0;
        data = 64'd0;

        pass_count = 0;
        fail_count = 0;

        reset_dut();

        testcase = "DLC=2 frame";
        start_crc_frame(11'h123, 4'd2, 64'hA5F0_0000_0000_0000);
        check_crc(15'h0ACD);

        testcase = "DLC=8 frame";
        start_crc_frame(11'h7AA, 4'd8, 64'hDEAD_BEEF_CAFE_BABE);
        check_crc(15'h51E5);

        testcase = "DLC=1 frame";
        start_crc_frame(11'h055, 4'd1, 64'hB300_0000_0000_0000);
        check_crc(15'h5687);

        testcase = "DLC=0 frame";
        start_crc_frame(11'h000, 4'd0, 64'h0000_0000_0000_0000);
        check_crc(15'h0000);

        $display("[SUMMARY] tb_CRC_generator pass=%0d fail=%0d", pass_count, fail_count);

        repeat (10) @(posedge clk);

        $finish;
    end

endmodule

/* verilator coverage_on */
