`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_CRC_check ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;

    localparam logic [14:0] POLY = 15'b110001011001100;

    logic clk, n_rst;
    logic start;
    logic [63:0] data;
    logic [2:0] data_len;
    logic [14:0] crc_in;
    logic done;
    logic error;

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

    CRC_check DUT (
        .clk(clk),
        .n_rst(n_rst),
        .start(start),
        .data(data),
        .data_len(data_len),
        .crc_in(crc_in),
        .done(done),
        .error(error)
    );
    function logic [14:0] crc_ref(input logic [63:0] d, input int len);
        logic [14:0] crc;
        int b, i;
        logic bit_in, fb;
        begin
            crc = '0;

            for (b = 0; b < len; b++) begin
                for (i = 0; i < 8; i++) begin
                    bit_in = d[63 - (b*8 + i)];
                    fb = crc[14] ^ bit_in;
                    crc = crc << 1;
                    if (fb) crc ^= POLY;
                end
            end

            return crc;
        end
    endfunction

    task run_test(input logic [63:0] d, input int len, input bit inject_error);
        logic [14:0] expected;
    begin
        data = d;
        data_len = len;

        expected = crc_ref(d, len);

        // optionally corrupt CRC
        crc_in = inject_error ? (expected ^ 15'h1) : expected;

        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;

        wait (done);

        if (error !== inject_error)
            $display("FAIL: inject=%0b error=%0b expected=%0h got=%0h",
                      inject_error, error, expected, crc_in);
        else
            $display("PASS: inject=%0b error=%0b", inject_error, error);

        @(posedge clk);
    end
    endtask

    initial begin
        n_rst = 1;
        start = 0;
        
        reset_dut;

        run_test(64'h1234_5678_9ABC_DEF0, 8, 0);
        run_test(64'h1234_5678_9ABC_DEF0, 8, 1);
        run_test(64'hFFFF_FFFF_FFFF_FFFF, 8, 0);
        run_test(64'h0000_0000_0000_00FF, 1, 0);
        $finish;
    end
endmodule

/* verilator coverage_on */