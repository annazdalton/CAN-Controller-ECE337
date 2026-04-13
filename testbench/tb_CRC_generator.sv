`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_CRC_generator ();

    localparam CLK_PERIOD = 10ns;

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


    logic start;
    logic [63:0] data;
    logic [2:0] data_len;
    logic done;
    logic [14:0] crc_out;

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

    CRC_generator DUT (
        .clk(clk),
        .n_rst(n_rst),
        .start(start),
        .data(data),
        .data_len(data_len),
        .done(done),
        .crc_out(crc_out)
    );


    localparam logic [14:0] POLY = 15'b110001011001100;

    function logic [14:0] crc_ref(
        input logic [63:0] d,
        input int len_bytes
    );
        logic [14:0] crc;
        int i, b;
        logic bit_in;
        logic fb;

        begin
            crc = '0;

            // process byte by byte
            for (b = 0; b < len_bytes; b++) begin
                // process each byte MSB-first
                for (i = 0; i < 8; i++) begin

                    // pick bit from correct byte position
                    bit_in = d[63 - (b*8 + i)];

                    // feedback = MSB XOR input
                    fb = crc[14] ^ bit_in;

                    crc = crc << 1;

                    if (fb)
                        crc ^= POLY;
                end
            end

            return crc;
        end
    endfunction



    task run_test(input logic [63:0] d, input logic [2:0] len);
        logic [14:0] expected;
    begin
        data = d;
        data_len = len;

        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;

        // wait for done
        wait (done == 1);

        /*
        expected = crc_ref(d, len);

        if (crc_out !== expected) begin
            $display("FAIL: data=%h len=%0d expected=%h got=%h",
                      d, len, expected, crc_out);
        end else begin
            $display("PASS: data=%h len=%0d crc=%h",
                      d, len, crc_out);
        end
        */
        @(posedge clk);
    end
    endtask

    initial begin
        n_rst = 1;
        start = 0;
        data = 0;
        data_len = 8;

        reset_dut;

        // Test vectors
        run_test(64'h0000_0000_0000_0001, 3'd1);
        run_test(64'hFFFF_FFFF_FFFF_FFFF, 3'd7);
        run_test(64'h1234_5678_9ABC_DEF0, 3'd7);
        run_test(64'h0000_0000_0000_00FF, 3'd2);

        $finish;
    end
endmodule

/* verilator coverage_on */

