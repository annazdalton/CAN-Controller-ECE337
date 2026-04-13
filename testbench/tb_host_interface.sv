`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_host_interface ();

    localparam CLK_PERIOD = 10ns;
    localparam ADDR_W = 4;
    localparam DATA_W = 8;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;

    // DUT inputs
    logic host_wr_req;
    logic host_rd_req;
    logic [DATA_W-1:0] host_wdata;
    logic [ADDR_W-1:0] host_addr;
    logic [DATA_W-1:0] reg_rdata;
    logic wr_accept;
    logic rd_valid;

    // DUT outputs
    logic [DATA_W-1:0] host_rdata;
    logic host_wr_ack;
    logic host_rd_ack;
    logic reg_wr_en;
    logic reg_rd_en;
    logic [DATA_W-1:0] reg_wdata;
    logic [ADDR_W-1:0] reg_addr;

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
        host_wr_req = 0;
        host_rd_req = 0;
        host_wdata = '0;
        host_addr = '0;
        reg_rdata = '0;
        wr_accept = 0;
        rd_valid = 0;

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
        end
        else begin
            $display("PASS: %s | value = 0x%0h", name, actual);
        end
    end
    endtask

    host_interface DUT (.clk(clk),
                        .n_rst(n_rst),
                        .host_wr_req(host_wr_req),
                        .host_rd_req(host_rd_req),
                        .host_wdata(host_wdata),
                        .host_addr(host_addr),
                        .reg_rdata(reg_rdata),
                        .wr_accept(wr_accept),
                        .rd_valid(rd_valid),
                        .host_rdata(host_rdata),
                        .host_wr_ack(host_wr_ack),
                        .host_rd_ack(host_rd_ack),
                        .reg_wr_en(reg_wr_en),
                        .reg_rd_en(reg_rd_en),
                        .reg_wdata(reg_wdata),
                        .reg_addr(reg_addr));

    initial begin
        n_rst = 1;

        $display("\n--- Reset Test ---");
        reset_dut;

        check_equal("host_rdata reset", host_rdata, 8'h00);
        check_equal("host_wr_ack reset", host_wr_ack, 1'b0);
        check_equal("host_rd_ack reset", host_rd_ack, 1'b0);
        check_equal("reg_wdata reset", reg_wdata, 8'h00);

        $display("\n--- Write Test ---");
        host_addr = 4'h3;
        host_wdata = 8'hA5;
        host_wr_req = 1'b1;
        host_rd_req = 1'b0;
        wr_accept = 1'b1;
        rd_valid = 1'b0;

        #1;
        check_equal("reg_wr_en asserted during write", reg_wr_en, 1'b1);
        check_equal("reg_rd_en deasserted during write", reg_rd_en, 1'b0);
        check_equal("reg_addr matches host_addr on write", reg_addr, 4'h3);

        @(posedge clk);
        #1;
        check_equal("reg_wdata captured on write", reg_wdata, 8'hA5);
        check_equal("host_wr_ack asserted after write accept", host_wr_ack, 1'b1);
        check_equal("host_rd_ack remains low during write", host_rd_ack, 1'b0);

        host_wr_req = 1'b0;
        wr_accept = 1'b0;
        @(posedge clk);
        #1;
        check_equal("host_wr_ack clears after pulse", host_wr_ack, 1'b0);

        $display("\n--- Read Test ---");
        host_addr = 4'h4;
        host_rd_req = 1'b1;
        host_wr_req = 1'b0;
        reg_rdata = 8'h3C;
        rd_valid = 1'b1;
        wr_accept = 1'b0;

        #1;
        check_equal("reg_rd_en asserted during read", reg_rd_en, 1'b1);
        check_equal("reg_wr_en deasserted during read", reg_wr_en, 1'b0);
        check_equal("reg_addr matches host_addr on read", reg_addr, 4'h4);

        @(posedge clk);
        #1;
        check_equal("host_rdata captured on read", host_rdata, 8'h3C);
        check_equal("host_rd_ack asserted after valid read", host_rd_ack, 1'b1);
        check_equal("host_wr_ack remains low during read", host_wr_ack, 1'b0);

        host_rd_req = 1'b0;
        rd_valid = 1'b0;
        @(posedge clk);
        #1;
        check_equal("host_rd_ack clears after pulse", host_rd_ack, 1'b0);

        $display("\n--- Write Priority Test ---");
        host_wr_req = 1'b1;
        host_rd_req = 1'b1;
        host_addr = 4'h2;
        host_wdata = 8'h55;
        reg_rdata = 8'hEE;
        wr_accept = 1'b1;
        rd_valid = 1'b1;

        #1;
        check_equal("write wins when both reqs are high: reg_wr_en", reg_wr_en, 1'b1);
        check_equal("write wins when both reqs are high: reg_rd_en", reg_rd_en, 1'b0);
        check_equal("write path address selected", reg_addr, 4'h2);

        @(posedge clk);
        #1;
        check_equal("write path data selected", reg_wdata, 8'h55);
        check_equal("write ack asserted in priority case", host_wr_ack, 1'b1);
        check_equal("read ack not asserted in priority case", host_rd_ack, 1'b0);

        host_wr_req = 1'b0;
        host_rd_req = 1'b0;
        wr_accept   = 1'b0;
        rd_valid    = 1'b0;
        @(posedge clk);

        $display("\n--- Idle Test ---");
        host_wr_req = 1'b0;
        host_rd_req = 1'b0;
        host_wdata = 8'h0F;
        host_addr = 4'h7;
        reg_rdata = 8'hF0;
        wr_accept = 1'b0;
        rd_valid = 1'b0;

        #1;
        check_equal("reg_wr_en low in idle", reg_wr_en, 1'b0);
        check_equal("reg_rd_en low in idle", reg_rd_en, 1'b0);

        @(posedge clk);
        #1;
        check_equal("host_wr_ack low in idle", host_wr_ack, 1'b0);
        check_equal("host_rd_ack low in idle", host_rd_ack, 1'b0);

        $display("\nAll host_interface tests passed.\n");
        $finish;
    end
endmodule

/* verilator coverage_on */

