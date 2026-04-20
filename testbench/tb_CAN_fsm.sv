`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_CAN_fsm ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic tx_request, bus_idle, node_off, data_done, error_done, tx_bit, arb_field_done, eof_done, bus_bit, error_request;
    logic sof_en, arb_en, crc_rst, data_en, ack_en, ack_delim_en, eof_en, error;

    CAN_fsm DUT(
    .clk(clk), 
    .n_rst(n_rst),
    .tx_request(tx_request), 
    .bus_idle(bus_idle),
    .node_off(node_off), 
    .data_done(data_done), 
    .error_done(error_done), 
    .tx_bit(tx_bit), 
    .arb_field_done(arb_field_done), //maybe change this to a pulse when done
    .eof_done(eof_done), 
    .bus_bit(bus_bit), 
    .error_request(error_request), 

    .sof_en(sof_en), 
    .arb_en(arb_en), 
    .crc_rst(crc_rst), 
    .data_en(data_en), 
    .ack_en(ack_en), 
    .ack_delim_en(ack_delim_en), 
    .eof_en(eof_en), 
    .error(error)
);

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
        tx_request = '0;
        bus_idle = '0;
        node_off = '1;
        data_done = '0;
        error_done = '0;
        tx_bit = '0;
        arb_field_done = '0;
        eof_done = '0;
        bus_bit = '0;
        error_request = '0;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    initial begin
        n_rst = 1;

        reset_dut;

        //idle state
        @(posedge clk);

        node_off = 0;
        bus_bit = 0;
        tx_bit = 0;
        tx_request = 1;
        bus_idle = 1;
        @(negedge clk);
        
        //sof state
        @(posedge clk);
        @(posedge clk);

        arb_field_done = 1;
        @(negedge clk);
        @(posedge clk);

        data_done = 1;
        @(negedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        eof_done = 1;
        @(negedge clk);
        @(posedge clk);

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        //normal state transitions done

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        //cause error:

        //sof state
        @(posedge clk);
        @(posedge clk);

        tx_bit = 1;
        bus_bit = 0;
        error_done = '0;
        @(negedge clk);
        @(posedge clk);

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        error_done = 1;
        @(negedge clk);
        @(posedge clk);

        #300ns;

        $finish;
    end
endmodule

/* verilator coverage_on */
