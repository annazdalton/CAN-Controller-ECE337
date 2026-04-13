`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_bit_stuff ();

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

    logic stuffing_enable;
    logic in_valid;
    logic in_bit;
    logic in_ready;

    logic out_valid;
    logic out_bit;
    logic out_ready;
    bit_stuff DUT (
        .clk(clk),
        .n_rst(n_rst),
        .stuffing_enable(stuffing_enable),
        .in_valid(in_valid),
        .in_bit(in_bit),
        .in_ready(in_ready),
        .out_valid(out_valid),
        .out_bit(out_bit),
        .out_ready(out_ready)
    );

    task send_bit(input logic bit_val);
    begin
        @(posedge clk);
        in_valid = 1;
        in_bit   = bit_val;

        // wait until DUT accepts it
        while (!in_ready) begin
            @(posedge clk);
        end

        @(posedge clk);
        in_valid = 0;
    end
    endtask

    task send_sequence(input logic [31:0] data, input int length);
    begin
        for (int i = length-1; i >= 0; i--) begin
            send_bit(data[i]);
        end
    end
    endtask


    initial begin
        n_rst = 1;
        out_ready = 1;

        reset_dut;

        send_sequence(8'b10101010, 8);
        
        // should insert
        send_sequence(8'b11111011, 8);

        send_sequence(16'b1111111111111111, 16);

        $finish;
    end
endmodule

/* verilator coverage_on */

