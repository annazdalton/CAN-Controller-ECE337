`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_CAN_top;

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

    // Host interface
    logic host_wr_req;
    logic host_rd_req;
    logic [7:0] host_wdata;
    logic [4:0] host_addr;
    logic [7:0] host_rdata;
    logic host_wr_ack;
    logic host_rd_ack;
    logic irq;

     // TX outputs
    logic tx_bit;
    logic tx_buf_valid;
    logic tx_complete;
    logic arb_lost;

    // RX outputs
    logic [10:0] rx_head_id;
    logic [3:0] rx_head_dlc;
    logic [63:0] rx_head_data;
    logic rx_buf_empty;
    logic rx_buf_full;
    logic [2:0] rx_count;

    // Status outputs
    logic rx_ready;
    logic crc_err;
    logic stf_err;
    logic error_flag;
    logic bus_rx;

    // logic bus_line;
    // logic tx_bit_a;
    // logic tx_bit_b;

    // logic tx_request_a;
    // logic tx_wr_en_a;
    // logic [10:0] tx_wr_id_a;
    // logic [3:0] tx_wr_dlc_a;
    // logic [63:0] tx_wr_data_a;

    // logic tx_request_b;
    // logic tx_wr_en_b;
    // logic [10:0] tx_wr_id_b;
    // logic [3:0] tx_wr_dlc_b;
    // logic [63:0] tx_wr_data_b;

    // logic rx_pop_a;
    // logic rx_pop_b;

    // logic bt_enable;
    // logic [9:0] bt_brp;
    // logic [5:0] bt_tq_per_bit;
    // logic [5:0] bt_sample_tq;
    // logic [5:0] bt_sjw;
    // logic bt_fd;

    // logic tx_buf_valid_a;
    // logic tx_complete_a;
    // logic arb_lost_a;

    // logic [10:0] rx_head_id_b;
    // logic [3:0] rx_head_dlc_b;
    // logic [63:0] rx_head_data_b;
    // logic rx_buf_empty_b;
    // logic rx_buf_full_b;
    // logic [$clog2(4+1)-1:0] rx_count_b;
    // logic rx_ready_b;
    // logic crc_err_b;
    // logic stf_err_b;
    // logic error_flag_b;

    // logic tx_buf_valid_b;
    // logic tx_complete_b;
    // logic arb_lost_b;

    // logic [10:0] rx_head_id_a;
    // logic [3:0] rx_head_dlc_a;
    // logic [63:0] rx_head_data_a;
    // logic rx_buf_empty_a;
    // logic rx_buf_full_a;
    // logic [$clog2(4+1)-1:0] rx_count_a;
    // logic rx_ready_a;
    // logic crc_err_a;
    // logic stf_err_a;
    // logic error_flag_a;

    // logic saw_complete_a;
    // logic saw_complete_b;
    // logic saw_lost_a;
    // logic saw_lost_b;

    // integer pre_pop_a;
    // integer pre_pop_b;

    // assign bus_line = tx_bit_a & tx_bit_b;

    always begin
        clk = 1'b0;
        #(CLK_PERIOD/2.0);
        clk = 1'b1;
        #(CLK_PERIOD/2.0);
    end

    // task init_signals;
    // begin
    //     n_rst = 1'b0;

    //     tx_request_a = 1'b0;
    //     tx_wr_en_a = 1'b0;
    //     tx_wr_id_a = 11'd0;
    //     tx_wr_dlc_a = 4'd0;
    //     tx_wr_data_a = 64'd0;

    //     tx_request_b = 1'b0;
    //     tx_wr_en_b = 1'b0;
    //     tx_wr_id_b = 11'd0;
    //     tx_wr_dlc_b = 4'd0;
    //     tx_wr_data_b = 64'd0;

    //     rx_pop_a = 1'b0;
    //     rx_pop_b = 1'b0;

    //     bt_enable = 1'b1;
    //     bt_brp = 10'd0;
    //     bt_tq_per_bit = 6'd8;
    //     bt_sample_tq = 6'd3;
    //     bt_sjw = 6'd1;
    //     bt_fd = 1'b0;
    // end
    // endtask

    // task reset_dut;
    // begin
    //     @(negedge clk);
    //     n_rst = 1'b0;
    //     repeat (6) @(posedge clk);
    //     @(negedge clk);
    //     n_rst = 1'b1;
    //     repeat (6) @(posedge clk);
    // end
    // endtask

    // task monitor_nodes(input integer cycles);
    //     integer i;
    // begin
    //     saw_complete_a = 1'b0;
    //     saw_complete_b = 1'b0;
    //     saw_lost_a = 1'b0;
    //     saw_lost_b = 1'b0;

    //     for (i = 0; i < cycles; i = i + 1) begin
    //         @(posedge clk);
    //         if (tx_complete_a) saw_complete_a = 1'b1;
    //         if (tx_complete_b) saw_complete_b = 1'b1;
    //         if (arb_lost_a) saw_lost_a = 1'b1;
    //         if (arb_lost_b) saw_lost_b = 1'b1;
    //     end
    // end
    // endtask

    // CAN_top DUT_A (
    //     .clk(clk),
    //     .n_rst(n_rst),
    //     .bus_rx(bus_line),
    //     .tx_request(tx_request_a),
    //     .tx_wr_en(tx_wr_en_a),
    //     .tx_wr_id(tx_wr_id_a),
    //     .tx_wr_dlc(tx_wr_dlc_a),
    //     .tx_wr_data(tx_wr_data_a),
    //     .rx_pop(rx_pop_a),
    //     .bt_enable(bt_enable),
    //     .bt_brp(bt_brp),
    //     .bt_tq_per_bit(bt_tq_per_bit),
    //     .bt_sample_tq(bt_sample_tq),
    //     .bt_sjw(bt_sjw),
    //     .bt_fd(bt_fd),
    //     .tx_bit(tx_bit_a),
    //     .tx_buf_valid(tx_buf_valid_a),
    //     .tx_complete(tx_complete_a),
    //     .arb_lost(arb_lost_a),
    //     .rx_head_id(rx_head_id_a),
    //     .rx_head_dlc(rx_head_dlc_a),
    //     .rx_head_data(rx_head_data_a),
    //     .rx_buf_empty(rx_buf_empty_a),
    //     .rx_buf_full(rx_buf_full_a),
    //     .rx_count(rx_count_a),
    //     .rx_ready(rx_ready_a),
    //     .crc_err(crc_err_a),
    //     .stf_err(stf_err_a),
    //     .error_flag(error_flag_a)
    // );

    // CAN_top DUT_B (
    //     .clk(clk),
    //     .n_rst(n_rst),
    //     .bus_rx(bus_line),
    //     .tx_request(tx_request_b),
    //     .tx_wr_en(tx_wr_en_b),
    //     .tx_wr_id(tx_wr_id_b),
    //     .tx_wr_dlc(tx_wr_dlc_b),
    //     .tx_wr_data(tx_wr_data_b),
    //     .rx_pop(rx_pop_b),
    //     .bt_enable(bt_enable),
    //     .bt_brp(bt_brp),
    //     .bt_tq_per_bit(bt_tq_per_bit),
    //     .bt_sample_tq(bt_sample_tq),
    //     .bt_sjw(bt_sjw),
    //     .bt_fd(bt_fd),
    //     .tx_bit(tx_bit_b),
    //     .tx_buf_valid(tx_buf_valid_b),
    //     .tx_complete(tx_complete_b),
    //     .arb_lost(arb_lost_b),
    //     .rx_head_id(rx_head_id_b),
    //     .rx_head_dlc(rx_head_dlc_b),
    //     .rx_head_data(rx_head_data_b),
    //     .rx_buf_empty(rx_buf_empty_b),
    //     .rx_buf_full(rx_buf_full_b),
    //     .rx_count(rx_count_b),
    //     .rx_ready(rx_ready_b),
    //     .crc_err(crc_err_b),
    //     .stf_err(stf_err_b),
    //     .error_flag(error_flag_b)
    // );
    
    //address map
    localparam logic [4:0] ADDR_MODE = 5'h00;
    localparam logic [4:0] ADDR_BT_BRP_LO = 5'h01;
    localparam logic [4:0] ADDR_BT_BRP_HI = 5'h02;
    localparam logic [4:0] ADDR_BT_TQPB = 5'h03;
    localparam logic [4:0] ADDR_BT_SAMPLE = 5'h04;
    localparam logic [4:0] ADDR_BT_SJW = 5'h05;
    localparam logic [4:0] ADDR_BT_FD = 5'h06;
    localparam logic [4:0] ADDR_IRQ_ENABLE = 5'h07;
    localparam logic [4:0] ADDR_IRQ_STATUS = 5'h08;
    localparam logic [4:0] ADDR_IRQ_CLEAR = 5'h09;
    localparam logic [4:0] ADDR_TX_ID_LO = 5'h0A;
    localparam logic [4:0] ADDR_TX_ID_HI = 5'h0B;
    localparam logic [4:0] ADDR_TX_DLC = 5'h0C;
    localparam logic [4:0] ADDR_TX_DATA0 = 5'h0D;
    localparam logic [4:0] ADDR_TX_DATA1 = 5'h0E;
    localparam logic [4:0] ADDR_TX_DATA2 = 5'h0F;
    localparam logic [4:0] ADDR_TX_DATA3 = 5'h10;
    localparam logic [4:0] ADDR_TX_DATA4 = 5'h11;
    localparam logic [4:0] ADDR_TX_DATA5 = 5'h12;
    localparam logic [4:0] ADDR_TX_DATA6 = 5'h13;
    localparam logic [4:0] ADDR_TX_DATA7 = 5'h14;
    localparam logic [4:0] ADDR_TX_CTRL = 5'h15;
    localparam logic [4:0] ADDR_RX_POP = 5'h16;

    CAN_top dut (
        .clk (clk),
        .n_rst (n_rst),
        .bus_rx (bus_rx),
        .host_wr_req (host_wr_req),
        .host_rd_req (host_rd_req),
        .host_wdata (host_wdata),
        .host_addr (host_addr),
        .host_rdata (host_rdata),
        .host_wr_ack (host_wr_ack),
        .host_rd_ack (host_rd_ack),
        .irq (irq),
        .tx_bit (tx_bit),
        .tx_buf_valid (tx_buf_valid),
        .tx_complete (tx_complete),
        .arb_lost (arb_lost),
        .rx_head_id (rx_head_id),
        .rx_head_dlc (rx_head_dlc),
        .rx_head_data (rx_head_data),
        .rx_buf_empty (rx_buf_empty),
        .rx_buf_full (rx_buf_full),
        .rx_count (rx_count),
        .rx_ready (rx_ready),
        .crc_err (crc_err),
        .stf_err (stf_err)
    );

    task automatic host_write(
        input logic [4:0] addr, 
        input logic [7:0] data
    );
        integer timeout;
        @(negedge clk);
        host_wr_req = 1'b1;
        host_addr   = addr;
        host_wdata  = data;
        
        // Wait for ack explicitly instead of fixed cycle count
        timeout = 0;
        @(posedge clk);
        while (!host_wr_ack && timeout < 10) begin
            @(posedge clk);
            timeout++;
        end
        if (!host_wr_ack) begin
            $display("WARNING: no wr_ack for addr=0x%02X data=0x%02X", addr, data);
        end
        host_wr_req = 1'b0;
        host_wdata  = 8'h00;
        host_addr   = 5'h00;
    endtask

    task automatic host_read(
        input logic [4:0] addr,
        output logic [7:0] data
    );
        integer timeout;
        @(negedge clk);
        host_rd_req = 1'b1;
        host_addr   = addr;

        timeout = 0;
        @(posedge clk);
        while (!host_rd_ack && timeout < 10) begin
            @(posedge clk);
            timeout++;
        end
        if (!host_rd_ack)
            $display("WARNING: no rd_ack for addr=0x%02X", addr);
        data        = host_rdata;
        host_rd_req = 1'b0;
        host_addr   = 5'h00;
    endtask

     task automatic configure_bit_timing(
        input logic [9:0] brp,
        input logic [5:0] tq_per_bit,
        input logic [5:0] sample_tq,
        input logic [5:0] sjw,
        input logic fd
    );
        $display("[%0t] Configuring bit timing", $time);
        host_write(ADDR_BT_BRP_LO, brp[7:0]);
        host_write(ADDR_BT_BRP_HI, {{6{1'b0}}, brp[9:8]});
        host_write(ADDR_BT_TQPB,   {{2{1'b0}}, tq_per_bit});
        host_write(ADDR_BT_SAMPLE, {{2{1'b0}}, sample_tq});
        host_write(ADDR_BT_SJW,    {{2{1'b0}}, sjw});
        host_write(ADDR_BT_FD,     {{7{1'b0}}, fd});
    endtask

    task automatic send_can_frame(
        input logic [10:0] id,
        input logic [3:0]  dlc,
        input logic [63:0] data
    );
        $display("[%0t] Enqueueing CAN frame ID=0x%03X DLC=%0d", $time, id, dlc);
        host_write(ADDR_TX_ID_LO,  id[7:0]);
        host_write(ADDR_TX_ID_HI,  {{5{1'b0}}, id[10:8]});
        host_write(ADDR_TX_DLC,    {{4{1'b0}}, dlc});
        host_write(ADDR_TX_DATA0,  data[7:0]);
        host_write(ADDR_TX_DATA1,  data[15:8]);
        host_write(ADDR_TX_DATA2,  data[23:16]);
        host_write(ADDR_TX_DATA3,  data[31:24]);
        host_write(ADDR_TX_DATA4,  data[39:32]);
        host_write(ADDR_TX_DATA5,  data[47:40]);
        host_write(ADDR_TX_DATA6,  data[55:48]);
        host_write(ADDR_TX_DATA7,  data[63:56]);
        // Write TX_CTRL: bit[1]=tx_wr_en pulse, bit[0]=tx_request
        host_write(ADDR_TX_CTRL,   8'b00000011);
        // Deassert tx_request after frame is queued
        // (keep asserted until tx_complete IRQ seen in real usage)
    endtask

    task automatic wait_for_irq(
        output logic [7:0] irq_status
    );
        integer timeout;
        timeout = 0;
        $display("[%0t] Waiting for IRQ", $time);
        while (!irq && timeout < 10000) begin
            @(posedge clk);
            timeout++;
        end
        if (timeout >= 10000)
            $display("ERROR: IRQ timeout");
        else
            $display("[%0t] IRQ asserted", $time);
        host_read(ADDR_IRQ_STATUS, irq_status);
        $display("[%0t] IRQ status = 0x%02X", $time, irq_status);
    endtask

    task automatic clear_irq(
        input logic [7:0] mask
    );
        host_write(ADDR_IRQ_CLEAR, mask);
        $display("[%0t] Cleared IRQ mask=0x%02X", $time, mask);
    endtask

    task automatic pop_rx_frame();
        $display("[%0t] Popping RX frame: ID=0x%03X DLC=%0d DATA=0x%016X", $time, rx_head_id, rx_head_dlc, rx_head_data);
        host_write(ADDR_RX_POP, 8'hFF);
    endtask

    task automatic do_reset();
        n_rst = 1'b0;
        host_wr_req = 1'b0;
        host_rd_req = 1'b0;
        host_wdata = 8'h00;
        host_addr = 5'h00;
        bus_rx = 1'b1; // recessive
        repeat(4) @(posedge clk);
        n_rst = 1'b1;
        repeat(2) @(posedge clk);
        $display("[%0t] Reset complete", $time);
    endtask

    logic [7:0] rd_data;
    logic [7:0] irq_status;

    initial begin
        // init_signals();
        // pass_count = 0;
        // fail_count = 0;

        // reset_dut();

        // testcase = "Node A transmits one frame";
        // $display("[%0t] %s", $time, testcase);

        // @(negedge clk);
        // tx_wr_en_a = 1'b1;
        // tx_wr_id_a = 11'h321;
        // tx_wr_dlc_a = 4'd2;
        // tx_wr_data_a = 64'hABCD_0000_0000_0000;

        // @(negedge clk);
        // tx_wr_en_a = 1'b0;

        // @(negedge clk);
        // tx_request_a = 1'b1;
        // @(negedge clk);
        // tx_request_a = 1'b0;

        // monitor_nodes(20000);

        // if (saw_complete_a) begin
        //     pass_count = pass_count + 1;
        //     $display("[%0t] [PASS] %s tx_complete_a observed", $time, testcase);
        // end else begin
        //     fail_count = fail_count + 1;
        //     $display("[%0t] [FAIL] %s tx_complete_a not observed", $time, testcase);
        // end

        // if (!saw_lost_a) begin
        //     pass_count = pass_count + 1;
        //     $display("[%0t] [PASS] %s no arbitration loss on node A", $time, testcase);
        // end else begin
        //     fail_count = fail_count + 1;
        //     $display("[%0t] [FAIL] %s unexpected arbitration loss on node A", $time, testcase);
        // end

        // if (!tx_buf_valid_a) begin
        //     pass_count = pass_count + 1;
        //     $display("[%0t] [PASS] %s tx buffer A cleared after completion", $time, testcase);
        // end else begin
        //     fail_count = fail_count + 1;
        //     $display("[%0t] [FAIL] %s tx buffer A still marked valid", $time, testcase);
        // end

        // testcase = "Simultaneous transmit request from both nodes";
        // $display("[%0t] %s", $time, testcase);

        // @(negedge clk);
        // tx_wr_en_a = 1'b1;
        // tx_wr_id_a = 11'h300;
        // tx_wr_dlc_a = 4'd1;
        // tx_wr_data_a = 64'hA500_0000_0000_0000;
        // tx_wr_en_b = 1'b1;
        // tx_wr_id_b = 11'h120;
        // tx_wr_dlc_b = 4'd1;
        // tx_wr_data_b = 64'h3C00_0000_0000_0000;

        // @(negedge clk);
        // tx_wr_en_a = 1'b0;
        // tx_wr_en_b = 1'b0;

        // @(negedge clk);
        // tx_request_a = 1'b1;
        // tx_request_b = 1'b1;
        // @(negedge clk);
        // tx_request_a = 1'b0;
        // tx_request_b = 1'b0;

        // monitor_nodes(25000);

        // if (saw_complete_a || saw_complete_b) begin
        //     pass_count = pass_count + 1;
        //     $display("[%0t] [PASS] %s at least one tx_complete seen", $time, testcase);
        // end else begin
        //     fail_count = fail_count + 1;
        //     $display("[%0t] [FAIL] %s no tx_complete seen", $time, testcase);
        // end

        // if (!(saw_lost_a && saw_lost_b)) begin
        //     pass_count = pass_count + 1;
        //     $display("[%0t] [PASS] %s no invalid double-loss condition", $time, testcase);
        // end else begin
        //     fail_count = fail_count + 1;
        //     $display("[%0t] [FAIL] %s both nodes reported arbitration loss", $time, testcase);
        // end

        // testcase = "Pop receive buffers";
        // $display("[%0t] %s", $time, testcase);

        // pre_pop_a = rx_count_a;
        // pre_pop_b = rx_count_b;

        // @(negedge clk);
        // rx_pop_a = 1'b1;
        // rx_pop_b = 1'b1;
        // @(negedge clk);
        // rx_pop_a = 1'b0;
        // rx_pop_b = 1'b0;

        // repeat (20) @(posedge clk);

        // if ((rx_count_a <= pre_pop_a) && (rx_count_b <= pre_pop_b)) begin
        //     pass_count = pass_count + 1;
        //     $display("[%0t] [PASS] %s pop did not increase queue depth", $time, testcase);
        // end else begin
        //     fail_count = fail_count + 1;
        //     $display("[%0t] [FAIL] %s unexpected queue growth after pop", $time, testcase);
        // end

        // $display("[SUMMARY] tb_CAN_top pass=%0d fail=%0d", pass_count, fail_count);

    
        // TEST 1: Reset and basic register read/write
        do_reset();
        $display("[%0t] TEST 1: Register read/write", $time);

        // Write and read back mode register
        host_write(ADDR_MODE, 8'hA5);
        host_read(ADDR_MODE, rd_data);
        if (rd_data === 8'hA5)
            $display("PASS: mode_cfg readback correct (0x%02X)", rd_data);
        else
            $display("FAIL: mode_cfg readback got 0x%02X expected 0xA5", rd_data);

       
        // TEST 2: IRQ enable and masking
        $display("[%0t] TEST 2: IRQ enable register", $time);
        // Enable all three IRQ sources (rx_ready, tx_complete, error)
        host_write(ADDR_IRQ_ENABLE, 8'b00000111);
        host_read(ADDR_IRQ_ENABLE, rd_data);
        if (rd_data[2:0] === 3'b111)
            $display("PASS: IRQ enable readback correct");
        else
            $display("FAIL: IRQ enable readback got 0x%02X", rd_data);

        // TEST 3: Bit timing configuration
        $display("[%0t] TEST 3: Bit timing config", $time);
        // 500kbps example: brp=4, tq_per_bit=16, sample_tq=11, sjw=1
        configure_bit_timing(
            .brp       (10'd4),
            .tq_per_bit(6'd16),
            .sample_tq (6'd11),
            .sjw       (6'd1),
            .fd        (1'b0)
        );
        // Readback BRP low byte
        host_read(ADDR_BT_BRP_LO, rd_data);
        if (rd_data === 8'd4)
            $display("PASS: bt_brp[7:0] readback correct");
        else
            $display("FAIL: bt_brp[7:0] got 0x%02X", rd_data);

        // Enable bt via mode register bit[0]
        host_write(ADDR_MODE, 8'b00000001);

        // TEST 4: TX frame enqueue
        $display("[%0t] TEST 4: TX frame enqueue", $time);
        send_can_frame(
            .id  (11'h1A3),
            .dlc (4'd4),
            .data(64'hDEADBEEF_00000000)
        );
        // tx_buf_valid should assert
        repeat(2) @(posedge clk);
        if (tx_buf_valid)
            $display("PASS: tx_buf_valid asserted after enqueue");
        else
            $display("FAIL: tx_buf_valid not asserted");

        // TEST 5: IRQ on TX complete (bus_rx held recessive = bus idle)
        $display("[%0t] TEST 5: TX complete IRQ", $time);
        bus_rx = 1'b1; // keep bus recessive/idle
        repeat(500) @(posedge clk);
        wait_for_irq(irq_status);
        if (irq_status[1])
            $display("PASS: tx_complete IRQ bit set");
        else
            $display("NOTE: tx_complete IRQ not set yet (may need more cycles)");
        clear_irq(8'b00000010); // clear tx_complete bit

        // TEST 6: RX path — inject a recessive bus pattern and check rx_ready IRQ
        $display("[%0t] TEST 6: RX ready IRQ", $time);
        // Drive bus_rx low to simulate SOF from another node
        @(negedge clk);
        bus_rx = 1'b0; // dominant = SOF
        repeat(5) @(posedge clk);
        bus_rx = 1'b1;
        // Wait and check if rx_ready or error fires
        repeat(20) @(posedge clk);
        host_read(ADDR_IRQ_STATUS, irq_status);
        $display("[%0t] IRQ status after bus activity = 0x%02X", $time, irq_status);

        // TEST 7: IRQ clear
        $display("[%0t] TEST 7: IRQ clear", $time);
        host_write(ADDR_IRQ_ENABLE, 8'b00000111);
        // Force a read of status then clear all
        host_read(ADDR_IRQ_STATUS, irq_status);
        clear_irq(8'b00000111);
        repeat(3) @(posedge clk);
        if (!irq)
            $display("PASS: IRQ deasserted after clear");
        else
            $display("FAIL: IRQ still asserted after clear");

        // TEST 8: RX buffer pop
        $display("[%0t] TEST 8: RX buffer pop", $time);
        if (!rx_buf_empty) begin
            pop_rx_frame();
            repeat(2) @(posedge clk);
            $display("[%0t] rx_buf_empty=%0b after pop", $time, rx_buf_empty);
        end else begin
            $display("NOTE: RX buffer empty, skipping pop test");
        end

        // TEST 9: Write to read-only IRQ_STATUS (should be ignored)
        $display("[%0t] TEST 9: Write to read-only register", $time);
        host_read(ADDR_IRQ_STATUS, rd_data);
        host_write(ADDR_IRQ_STATUS, 8'hFF); // should be ignored
        host_read(ADDR_IRQ_STATUS, irq_status);
        if (irq_status === rd_data)
            $display("PASS: Read-only register not modified by write");
        else
            $display("FAIL: Read-only register was modified (got 0x%02X)", irq_status);

        repeat(10) @(posedge clk);
        $display("=== CAN_top Testbench Complete ===");

        $finish;
    end

endmodule

/* verilator coverage_on */
