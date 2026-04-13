`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_FIFO ();

    localparam CLK_PERIOD = 10ns;
    localparam SIZE = 8;
    localparam DEPTH = 10;

    logic WEN, REN, clear;
    logic [SIZE-1:0] wdata;

    logic full, empty, underrun, overrun;
    logic [$clog2(DEPTH+1)-1:0] count;
    logic [SIZE-1:0] rdata;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;

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
        WEN = 0;
        REN = 0;
        clear = 0;
        wdata = '0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    task check_equal(
        input string name,
        input logic [31:0] actual,
        input logic [31:0] expected
    );
    begin
        if (actual !== expected) begin
            $display("FAIL: %s | actual = 0x%0h expected = 0x%0h", name, actual, expected);
            $finish;
        end else begin
            $display("PASS: %s | value = 0x%0h", name, actual);
        end
    end
    endtask

    FIFO DUT (.clk(clk),
        .n_rst(n_rst),
        .WEN(WEN),
        .REN(REN),
        .clear(clear),
        .wdata(wdata),
        .full(full),
        .empty(empty),
        .underrun(underrun),
        .overrun(overrun),
        .count(count),
        .rdata(rdata));

    initial begin
        n_rst = 1;

        $display("\n--- Reset Test ---");
        reset_dut;
        @(posedge clk);
        @(posedge clk);
        check_equal("count reset", count, 0);
        check_equal("empty reset", empty, 1);
        check_equal("full reset", full, 0);
        check_equal("underrun reset", underrun, 0);
        check_equal("overrun reset", overrun, 0);
        check_equal("rdata reset", rdata, 8'h00);

        $display("\n--- Single Write Test ---");
        WEN = 1;
        REN = 0;
        clear = 0;
        wdata = 8'hA5;
        @(posedge clk);
        WEN = 0;
        @(posedge clk);
        @(posedge clk);
        check_equal("count after single write", count, 1);
        check_equal("empty low after single write", empty, 0);
        check_equal("full low after single write", full, 0);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        $display("\n--- Single Read Test ---");
        REN = 1;
        @(posedge clk);
        REN = 0;
        check_equal("rdata after single read", rdata, 8'hA5);
        @(posedge clk);
        check_equal("count after single read", count, 0);
        check_equal("empty high after single read", empty, 1);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        $display("\n--- Multiple Write/Read FIFO Order Test ---");
        WEN = 1;
        wdata = 8'h11;
        @(posedge clk);
        wdata = 8'h22;
        @(posedge clk);
        wdata = 8'h33;
        @(posedge clk);
        WEN = 0;
        @(posedge clk);
        @(posedge clk);
        check_equal("count after three writes", count, 3);

        WEN = 0;
        REN = 1;
        @(posedge clk);
        check_equal("first read data", rdata, 8'h11);
        @(posedge clk)
        check_equal("count after first read", count, 2);

        @(posedge clk);
        check_equal("second read data", rdata, 8'h22);
        check_equal("count after second read", count, 1);

        @(posedge clk);
        check_equal("third read data", rdata, 8'h33);
        check_equal("count after third read", count, 0);
        check_equal("empty asserted after draining FIFO", empty, 1);

        REN = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        $display("\n--- Fill To Full Test ---");
        WEN = 1;
        for (int i = 0; i < DEPTH; i++) begin
            wdata = i[7:0];
            @(posedge clk);
        end
        WEN = 0;
        @(posedge clk);
        @(posedge clk);
        check_equal("count at full depth", count, DEPTH);
        check_equal("full asserted", full, 1);
        check_equal("empty deasserted at full", empty, 0);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        $display("\n--- Overrun Test ---");
        WEN = 1;
        wdata = 8'hFF;
        @(posedge clk);
        WEN = 0;
        @(posedge clk);
        @(posedge clk);
        check_equal("overrun asserted on write when full", overrun, 1);
        check_equal("count unchanged on overrun", count, DEPTH);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        $display("\n--- Clear Test ---");
        clear = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        check_equal("count cleared", count, 0);
        check_equal("empty asserted after clear", empty, 1);
        check_equal("full deasserted after clear", full, 0);
        check_equal("overrun cleared after clear", overrun, 0);
        check_equal("underrun cleared after clear", underrun, 0);

        clear = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        $display("\n--- Underrun Test ---");
        REN = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        check_equal("underrun asserted on read when empty", underrun, 1);
        check_equal("count unchanged on underrun", count, 0);
        check_equal("empty remains asserted on underrun", empty, 1);

        REN = 0;
        @(posedge clk);
        @(posedge clk)
        @(posedge clk);

        $display("\n--- Simultaneous Read/Write Test ---");
        clear = 1;
        @(posedge clk);
        clear = 0;
        @(posedge clk);

        WEN = 1;
        REN = 0;
        wdata = 8'h55;
        @(posedge clk);
        WEN = 0;
        @(posedge clk);
        @(posedge clk);
        check_equal("count after preload write", count, 1);

        WEN = 1;
        REN = 1;
        wdata = 8'h66;
        @(posedge clk);
        WEN = 0;
        REN = 0;
        @(posedge clk);
        @(posedge clk);
        check_equal("count after simultaneous read/write", count, 1);

        WEN = 0;
        REN = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        check_equal("remaining data after simultaneous read/write", rdata, 8'h66);
        check_equal("count after final read", count, 0);

        REN = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        $display("\nAll FIFO tests passed.\n");
        $finish;
    end
endmodule

/* verilator coverage_on */

