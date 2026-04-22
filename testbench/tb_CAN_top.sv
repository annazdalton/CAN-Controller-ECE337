`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_CAN_top;

    // Testbench convention used by the top-level scenarios below:
    // - Node A is the primary receiver / observer
    // - Node B is the primary transmitter / source
    localparam CLK_PERIOD = 10ns;
    localparam int MAX_BITS = 512;

    localparam logic [5:0] ADDR_MODE = 6'h00;
    localparam logic [5:0] ADDR_BT_BRP_LO = 6'h01;
    localparam logic [5:0] ADDR_BT_BRP_HI = 6'h02;
    localparam logic [5:0] ADDR_BT_TQPB = 6'h03;
    localparam logic [5:0] ADDR_BT_SAMPLE = 6'h04;
    localparam logic [5:0] ADDR_BT_SJW = 6'h05;
    localparam logic [5:0] ADDR_BT_FD = 6'h06;
    localparam logic [5:0] ADDR_IRQ_ENABLE = 6'h07;
    localparam logic [5:0] ADDR_IRQ_STATUS = 6'h08;
    localparam logic [5:0] ADDR_IRQ_CLEAR = 6'h09;
    localparam logic [5:0] ADDR_TX_ID_LO = 6'h0A;
    localparam logic [5:0] ADDR_TX_ID_HI = 6'h0B;
    localparam logic [5:0] ADDR_TX_DLC = 6'h0C;
    localparam logic [5:0] ADDR_TX_DATA0 = 6'h0D;
    localparam logic [5:0] ADDR_TX_DATA1 = 6'h0E;
    localparam logic [5:0] ADDR_TX_DATA2 = 6'h0F;
    localparam logic [5:0] ADDR_TX_DATA3 = 6'h10;
    localparam logic [5:0] ADDR_TX_DATA4 = 6'h11;
    localparam logic [5:0] ADDR_TX_DATA5 = 6'h12;
    localparam logic [5:0] ADDR_TX_DATA6 = 6'h13;
    localparam logic [5:0] ADDR_TX_DATA7 = 6'h14;
    localparam logic [5:0] ADDR_TX_CTRL = 6'h15;
    localparam logic [5:0] ADDR_RX_POP = 6'h16;

    logic clk;
    logic n_rst;

    logic force_bus_en;
    logic force_bus_bit;
    logic bus_line;

    logic host_wr_req_a;
    logic host_rd_req_a;
    logic [7:0] host_wdata_a;
    logic [5:0] host_addr_a;
    logic [7:0] host_rdata_a;
    logic host_wr_ack_a;
    logic host_rd_ack_a;
    logic irq_a;

    logic tx_bit_a;
    logic tx_buf_valid_a;
    logic tx_complete_a;
    logic arb_lost_a;
    logic arb_lost_seen_a;
    logic [10:0] rx_head_id_a;
    logic [3:0] rx_head_dlc_a;
    logic [63:0] rx_head_data_a;
    logic rx_buf_empty_a;
    logic rx_buf_full_a;
    logic [3:0] rx_count_a;
    logic rx_ready_a;
    logic crc_err_a;
    logic stf_err_a;

    logic host_wr_req_b;
    logic host_rd_req_b;
    logic [7:0] host_wdata_b;
    logic [5:0] host_addr_b;
    logic [7:0] host_rdata_b;
    logic host_wr_ack_b;
    logic host_rd_ack_b;
    logic irq_b;

    logic tx_bit_b;
    logic tx_buf_valid_b;
    logic tx_complete_b;
    logic arb_lost_b;
    logic arb_lost_seen_b;
    logic [10:0] rx_head_id_b;
    logic [3:0] rx_head_dlc_b;
    logic [63:0] rx_head_data_b;
    logic rx_buf_empty_b;
    logic rx_buf_full_b;
    logic [3:0] rx_count_b;
    logic rx_ready_b;
    logic crc_err_b;
    logic stf_err_b;

    logic [7:0] rd_data;
    logic [MAX_BITS-1:0] frame_bits;
    int frame_len;
    int edge_idx;

    string TEST_NAME;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    always begin
        clk = 1'b0;
        #(CLK_PERIOD/2.0);
        clk = 1'b1;
        #(CLK_PERIOD/2.0);
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            arb_lost_seen_a <= 1'b0;
            arb_lost_seen_b <= 1'b0;
        end else begin
            if (arb_lost_a) arb_lost_seen_a <= 1'b1;
            if (arb_lost_b) arb_lost_seen_b <= 1'b1;
        end
    end

    assign bus_line = tx_bit_a & tx_bit_b & (force_bus_en ? force_bus_bit : 1'b1);

    CAN_top dut_a (
        .clk(clk),
        .n_rst(n_rst),
        .bus_rx(bus_line),
        .host_wr_req(host_wr_req_a),
        .host_rd_req(host_rd_req_a),
        .host_wdata(host_wdata_a),
        .host_addr(host_addr_a),
        .tx_bit(tx_bit_a),
        .tx_buf_valid(tx_buf_valid_a),
        .tx_complete(tx_complete_a),
        .arb_lost(arb_lost_a),
        .rx_head_id(rx_head_id_a),
        .rx_head_dlc(rx_head_dlc_a),
        .rx_head_data(rx_head_data_a),
        .rx_buf_empty(rx_buf_empty_a),
        .rx_buf_full(rx_buf_full_a),
        .rx_count(rx_count_a),
        .rx_ready(rx_ready_a),
        .crc_err(crc_err_a),
        .stf_err(stf_err_a),
        .host_rdata(host_rdata_a),
        .host_wr_ack(host_wr_ack_a),
        .host_rd_ack(host_rd_ack_a),
        .irq(irq_a)
    );

    CAN_top dut_b (
        .clk(clk),
        .n_rst(n_rst),
        .bus_rx(bus_line),
        .host_wr_req(host_wr_req_b),
        .host_rd_req(host_rd_req_b),
        .host_wdata(host_wdata_b),
        .host_addr(host_addr_b),
        .tx_bit(tx_bit_b),
        .tx_buf_valid(tx_buf_valid_b),
        .tx_complete(tx_complete_b),
        .arb_lost(arb_lost_b),
        .rx_head_id(rx_head_id_b),
        .rx_head_dlc(rx_head_dlc_b),
        .rx_head_data(rx_head_data_b),
        .rx_buf_empty(rx_buf_empty_b),
        .rx_buf_full(rx_buf_full_b),
        .rx_count(rx_count_b),
        .rx_ready(rx_ready_b),
        .crc_err(crc_err_b),
        .stf_err(stf_err_b),
        .host_rdata(host_rdata_b),
        .host_wr_ack(host_wr_ack_b),
        .host_rd_ack(host_rd_ack_b),
        .irq(irq_b)
    );


    task automatic host_write_a(input logic [5:0] addr, input logic [7:0] data);
    begin
        @(negedge clk);
        host_wr_req_a = 1'b1;
        host_addr_a = addr;
        host_wdata_a = data;

        @(posedge clk);
        while (!host_wr_ack_a) begin
            @(posedge clk);
        end

        @(negedge clk);
        host_wr_req_a = 1'b0;
        host_addr_a = '0;
        host_wdata_a = '0;
    end
    endtask

    task automatic host_write_b(input logic [5:0] addr, input logic [7:0] data);
    begin
        @(negedge clk);
        host_wr_req_b = 1'b1;
        host_addr_b = addr;
        host_wdata_b = data;

        @(posedge clk);
        while (!host_wr_ack_b) begin
            @(posedge clk);
        end

        @(negedge clk);
        host_wr_req_b = 1'b0;
        host_addr_b = '0;
        host_wdata_b = '0;
    end
    endtask

    task automatic host_read_a(input logic [5:0] addr, output logic [7:0] data);
    begin
        @(negedge clk);
        host_rd_req_a = 1'b1;
        host_addr_a = addr;

        @(posedge clk);
        while (!host_rd_ack_a) begin
            @(posedge clk);
        end

        data = host_rdata_a;

        @(negedge clk);
        host_rd_req_a = 1'b0;
        host_addr_a = '0;
    end
    endtask

    task automatic host_read_b(input logic [5:0] addr, output logic [7:0] data);
    begin
        @(negedge clk);
        host_rd_req_b = 1'b1;
        host_addr_b = addr;

        @(posedge clk);
        while (!host_rd_ack_b) begin
            @(posedge clk);
        end

        data = host_rdata_b;

        @(negedge clk);
        host_rd_req_b = 1'b0;
        host_addr_b = '0;
    end
    endtask

    task automatic clear_irq_a(input logic [7:0] mask);
    begin
        host_write_a(ADDR_IRQ_CLEAR, mask);
    end
    endtask

    task automatic clear_irq_b(input logic [7:0] mask);
    begin
        host_write_b(ADDR_IRQ_CLEAR, mask);
    end
    endtask

    task automatic configure_node_a_custom(
        input logic [2:0] irq_mask,
        input logic [9:0] brp,
        input logic fd_en
    );
    begin
        host_write_a(ADDR_MODE, 8'h00);
        host_write_a(ADDR_BT_BRP_LO, brp[7:0]);
        host_write_a(ADDR_BT_BRP_HI, {{6{1'b0}}, brp[9:8]});
        host_write_a(ADDR_BT_TQPB, 8'd8);
        host_write_a(ADDR_BT_SAMPLE, 8'd3);
        host_write_a(ADDR_BT_SJW, 8'd1);
        host_write_a(ADDR_BT_FD, {{7{1'b0}}, fd_en});
        host_write_a(ADDR_MODE, 8'h01);
        host_write_a(ADDR_IRQ_ENABLE, {{5{1'b0}}, irq_mask});
        host_write_a(ADDR_TX_CTRL, 8'h00);
        clear_irq_a(8'h07);
    end
    endtask

    task automatic configure_node_b_custom(
        input logic [2:0] irq_mask,
        input logic [9:0] brp,
        input logic fd_en
    );
    begin
        host_write_b(ADDR_MODE, 8'h00);
        host_write_b(ADDR_BT_BRP_LO, brp[7:0]);
        host_write_b(ADDR_BT_BRP_HI, {{6{1'b0}}, brp[9:8]});
        host_write_b(ADDR_BT_TQPB, 8'd8);
        host_write_b(ADDR_BT_SAMPLE, 8'd3);
        host_write_b(ADDR_BT_SJW, 8'd1);
        host_write_b(ADDR_BT_FD, {{7{1'b0}}, fd_en});
        host_write_b(ADDR_MODE, 8'h01);
        host_write_b(ADDR_IRQ_ENABLE, {{5{1'b0}}, irq_mask});
        host_write_b(ADDR_TX_CTRL, 8'h00);
        clear_irq_b(8'h07);
    end
    endtask

    task automatic configure_node_a(input logic [2:0] irq_mask);
    begin
        configure_node_a_custom(irq_mask, 10'd0, 1'b0);
    end
    endtask

    task automatic configure_node_b(input logic [2:0] irq_mask);
    begin
        configure_node_b_custom(irq_mask, 10'd0, 1'b0);
    end
    endtask

    task automatic load_frame_a(
        input logic [10:0] id,
        input logic [3:0] dlc,
        input logic [63:0] data
    );
    begin
        host_write_a(ADDR_TX_ID_LO, id[7:0]);
        host_write_a(ADDR_TX_ID_HI, {{5{1'b0}}, id[10:8]});
        host_write_a(ADDR_TX_DLC, {{4{1'b0}}, dlc});
        host_write_a(ADDR_TX_DATA0, data[7:0]);
        host_write_a(ADDR_TX_DATA1, data[15:8]);
        host_write_a(ADDR_TX_DATA2, data[23:16]);
        host_write_a(ADDR_TX_DATA3, data[31:24]);
        host_write_a(ADDR_TX_DATA4, data[39:32]);
        host_write_a(ADDR_TX_DATA5, data[47:40]);
        host_write_a(ADDR_TX_DATA6, data[55:48]);
        host_write_a(ADDR_TX_DATA7, data[63:56]);
        host_write_a(ADDR_TX_CTRL, 8'h02);
    end
    endtask

    task automatic load_frame_b(
        input logic [10:0] id,
        input logic [3:0] dlc,
        input logic [63:0] data
    );
    begin
        host_write_b(ADDR_TX_ID_LO, id[7:0]);
        host_write_b(ADDR_TX_ID_HI, {{5{1'b0}}, id[10:8]});
        host_write_b(ADDR_TX_DLC, {{4{1'b0}}, dlc});
        host_write_b(ADDR_TX_DATA0, data[7:0]);
        host_write_b(ADDR_TX_DATA1, data[15:8]);
        host_write_b(ADDR_TX_DATA2, data[23:16]);
        host_write_b(ADDR_TX_DATA3, data[31:24]);
        host_write_b(ADDR_TX_DATA4, data[39:32]);
        host_write_b(ADDR_TX_DATA5, data[47:40]);
        host_write_b(ADDR_TX_DATA6, data[55:48]);
        host_write_b(ADDR_TX_DATA7, data[63:56]);
        host_write_b(ADDR_TX_CTRL, 8'h02);
    end
    endtask

    task automatic request_tx_a;
    begin
        host_write_a(ADDR_TX_CTRL, 8'h01);
    end
    endtask

    task automatic request_tx_b;
    begin
        host_write_b(ADDR_TX_CTRL, 8'h01);
    end
    endtask

    task automatic request_tx_both;
        logic got_a;
        logic got_b;
    begin
        @(negedge clk);
        host_wr_req_a = 1'b1;
        host_addr_a = ADDR_TX_CTRL;
        host_wdata_a = 8'h01;
        host_wr_req_b = 1'b1;
        host_addr_b = ADDR_TX_CTRL;
        host_wdata_b = 8'h01;

        got_a = 1'b0;
        got_b = 1'b0;
        while (!(got_a && got_b)) begin
            @(posedge clk);
            if (host_wr_ack_a) got_a = 1'b1;
            if (host_wr_ack_b) got_b = 1'b1;
        end

        @(negedge clk);
        host_wr_req_a = 1'b0;
        host_addr_a = '0;
        host_wdata_a = '0;
        host_wr_req_b = 1'b0;
        host_addr_b = '0;
        host_wdata_b = '0;
    end
    endtask

    task automatic send_frame_a(
        input logic [10:0] id,
        input logic [3:0] dlc,
        input logic [63:0] data
    );
    begin
        load_frame_a(id, dlc, data);
        request_tx_a();
    end
    endtask

    task automatic send_frame_b(
        input logic [10:0] id,
        input logic [3:0] dlc,
        input logic [63:0] data
    );
    begin
        load_frame_b(id, dlc, data);
        request_tx_b();
    end
    endtask

    task automatic pop_rx_a;
    begin
        host_write_a(ADDR_RX_POP, 8'h01);
    end
    endtask

    function automatic [14:0] crc15_calc(
        input logic [10:0] id,
        input logic [3:0] dlc,
        input logic [63:0] data,
        input logic fd_frame
    );
        logic [14:0] crc;
        logic bit_in;
        logic feedback;
        int data_bits;
        int idx;
    begin
        crc = 15'd0;
        data_bits = dlc * 8;

        for (idx = 0; idx < (19 + data_bits); idx = idx + 1) begin
            if (idx == 0) begin
                bit_in = 1'b0;
            end else if (idx <= 11) begin
                bit_in = id[11 - idx];
            end else if (idx <= 13) begin
                bit_in = 1'b0;
            end else if (idx == 14) begin
                bit_in = fd_frame;
            end else if (idx <= 18) begin
                bit_in = dlc[18 - idx];
            end else begin
                bit_in = data[63 - (idx - 19)];
            end

            feedback = crc[14] ^ bit_in;
            crc = {crc[13:0], 1'b0};
            if (feedback) begin
                crc = crc ^ 15'b100010110011001;
            end
        end

        crc15_calc = crc;
    end
    endfunction

    task automatic build_frame_stream(
        input logic [10:0] id,
        input logic [3:0] dlc,
        input logic [63:0] data,
        input logic fd_frame,
        input logic corrupt_crc,
        input logic apply_stuff,
        output logic [MAX_BITS-1:0] bits,
        output int nbits
    );
        logic [MAX_BITS-1:0] raw;
        logic [14:0] crc;
        logic raw_bit;
        logic last_bit;
        int data_bits;
        int pre_len;
        int raw_len;
        int idx;
        int out_idx;
        int run_count;
    begin
        bits = '0;
        raw = '0;

        data_bits = dlc * 8;
        pre_len = 34 + data_bits;
        raw_len = pre_len + 10;

        crc = crc15_calc(id, dlc, data, fd_frame);
        if (corrupt_crc) begin
            crc[2] = ~crc[2];
        end

        raw[0] = 1'b0;
        for (idx = 1; idx <= 11; idx = idx + 1) begin
            raw[idx] = id[11 - idx];
        end
        raw[12] = 1'b0;
        raw[13] = 1'b0;
        raw[14] = fd_frame;
        raw[15] = dlc[3];
        raw[16] = dlc[2];
        raw[17] = dlc[1];
        raw[18] = dlc[0];

        for (idx = 0; idx < data_bits; idx = idx + 1) begin
            raw[19 + idx] = data[63 - idx];
        end

        for (idx = 0; idx < 15; idx = idx + 1) begin
            raw[19 + data_bits + idx] = crc[14 - idx];
        end

        for (idx = 0; idx < 10; idx = idx + 1) begin
            raw[pre_len + idx] = 1'b1;
        end

        if (!apply_stuff) begin
            bits = raw;
            nbits = raw_len;
        end else begin
            out_idx = 0;
            run_count = 0;
            last_bit = 1'b0;

            for (idx = 0; idx < pre_len; idx = idx + 1) begin
                raw_bit = raw[idx];
                bits[out_idx] = raw_bit;
                out_idx = out_idx + 1;

                if (run_count == 0) begin
                    last_bit = raw_bit;
                    run_count = 1;
                end else if (raw_bit == last_bit) begin
                    run_count = run_count + 1;
                    if (run_count == 5) begin
                        bits[out_idx] = ~last_bit;
                        out_idx = out_idx + 1;
                        last_bit = ~last_bit;
                        run_count = 1;
                    end
                end else begin
                    last_bit = raw_bit;
                    run_count = 1;
                end
            end

            for (idx = pre_len; idx < raw_len; idx = idx + 1) begin
                bits[out_idx] = raw[idx];
                out_idx = out_idx + 1;
            end

            nbits = out_idx;
        end
    end
    endtask

    task automatic drive_external_bits(input logic [MAX_BITS-1:0] bits, input int nbits);
        int idx;
    begin
        force_bus_en = 1'b1;
        force_bus_bit = 1'b1;

        repeat (16) @(posedge dut_a.bit_tick);

        for (idx = 0; idx < nbits; idx = idx + 1) begin
            force_bus_bit = bits[idx];
            @(posedge dut_a.bit_tick);
        end

        force_bus_bit = 1'b1;
        repeat (16) @(posedge dut_a.bit_tick);
        force_bus_en = 1'b0;
    end
    endtask

    task automatic find_transition_pair_index(
        input logic [MAX_BITS-1:0] bits,
        input int nbits,
        input int start_idx,
        output int idx_out
    );
        int idx;
    begin
        idx_out = -1;
        for (idx = start_idx; idx < (nbits - 2); idx = idx + 1) begin
            if ((bits[idx] != bits[idx + 1]) && (bits[idx + 1] != bits[idx + 2])) begin
                idx_out = idx;
                break;
            end
        end
    end
    endtask

    task automatic drive_external_bits_with_phase_bump(
        input logic [MAX_BITS-1:0] bits,
        input int nbits,
        input int bump_idx,
        input int bump_tq
    );
        int idx;
        int nominal_tq;
        int wait_tq;
        int shift_tq;
    begin
        nominal_tq = 8;
        force_bus_en = 1'b1;
        force_bus_bit = 1'b1;

        repeat (16) @(posedge dut_a.bit_tick);
        force_bus_bit = bits[0];

        for (idx = 0; idx < (nbits - 1); idx = idx + 1) begin
            shift_tq = 0;
            if (idx == bump_idx) begin
                shift_tq = bump_tq;
            end else if (idx == (bump_idx + 1)) begin
                shift_tq = -bump_tq;
            end

            wait_tq = nominal_tq + shift_tq;
            if (wait_tq < 1) begin
                wait_tq = 1;
            end

            repeat (wait_tq) @(posedge dut_a.u_bit_timing.tq_tick);
            force_bus_bit = bits[idx + 1];
        end

        repeat (nominal_tq) @(posedge dut_a.u_bit_timing.tq_tick);
        force_bus_bit = 1'b1;
        repeat (16) @(posedge dut_a.bit_tick);
        force_bus_en = 1'b0;
    end
    endtask

    task automatic do_reset;
    begin
        n_rst = 1'b0;
        host_wr_req_a = 1'b0;
        host_rd_req_a = 1'b0;
        host_wdata_a = '0;
        host_addr_a = '0;
        host_wr_req_b = 1'b0;
        host_rd_req_b = 1'b0;
        host_wdata_b = '0;
        host_addr_b = '0;
        force_bus_en = 1'b0;
        force_bus_bit = 1'b1;
        repeat (8) @(posedge clk);
        n_rst = 1'b1;
        repeat (8) @(posedge clk);
    end
    endtask

    initial begin
        TEST_NAME = "RESET";
        n_rst = 1'b1;
        host_wr_req_a = 1'b0;
        host_rd_req_a = 1'b0;
        host_wdata_a = '0;
        host_addr_a = '0;
        host_wr_req_b = 1'b0;
        host_rd_req_b = 1'b0;
        host_wdata_b = '0;
        host_addr_b = '0;
        force_bus_en = 1'b0;
        force_bus_bit = 1'b1;

        // BASIC_TX_NODE_B_TO_NODE_A
        TEST_NAME = "BASIC_TX_NODE_B_TO_NODE_A";
        do_reset();
        configure_node_a(3'b111);
        configure_node_b(3'b111);
        build_frame_stream(11'h1A3, 4'd4, 64'hDEADBEEF_00000000, 1'b0, 1'b0, 1'b1, frame_bits, frame_len);
        send_frame_b(11'h1A3, 4'd4, 64'hDEADBEEF_00000000);
        repeat (1500) @(posedge clk);
        host_read_a(ADDR_IRQ_STATUS, rd_data);
        clear_irq_a(8'h01);
        host_read_b(ADDR_IRQ_STATUS, rd_data);
        clear_irq_b(8'h02);

        // BASIC_RX_NODE_A_EXTERNAL_FRAME
        TEST_NAME = "BASIC_RX_NODE_A_EXTERNAL_FRAME";
        do_reset();
        configure_node_a(3'b111);
        configure_node_b(3'b000);
        build_frame_stream(11'h255, 4'd2, 64'hABCD_000000000000, 1'b0, 1'b0, 1'b1, frame_bits, frame_len);
        drive_external_bits(frame_bits, frame_len);
        repeat (1500) @(posedge clk);
        host_read_a(ADDR_IRQ_STATUS, rd_data);
        clear_irq_a(8'h01);

        // ARBITRATION_LOSS_THEN_NODE_A_RETRANSMITS
        TEST_NAME = "ARBITRATION_LOSS_THEN_NODE_A_RETRANSMITS";
        do_reset();
        configure_node_a(3'b111);
        configure_node_b(3'b111);
        force_bus_en = 1'b1;
        force_bus_bit = 1'b0;
        load_frame_a(11'h6A5, 4'd1, 64'hAA00_000000000000);
        load_frame_b(11'h123, 4'd1, 64'h5500_000000000000);
        request_tx_both();
        wait ((dut_a.u_can_tx_path.state == 3'd4) && (dut_b.u_can_tx_path.state == 3'd4));
        force_bus_bit = 1'b1;
        wait (tx_complete_b == 1'b1);
        repeat (40) @(posedge clk);
        force_bus_en = 1'b0;

        // CRC_ERROR_DETECTION_NODE_A_RX
        TEST_NAME = "CRC_ERROR_DETECTION_NODE_A_RX";
        do_reset();
        configure_node_a(3'b100);
        configure_node_b(3'b000);
        build_frame_stream(11'h2C3, 4'd2, 64'h1234_000000000000, 1'b0, 1'b1, 1'b1, frame_bits, frame_len);
        drive_external_bits(frame_bits, frame_len);
        repeat (40) @(posedge clk);
        host_read_a(ADDR_IRQ_STATUS, rd_data);
        clear_irq_a(8'h04);

        // BIT_STUFF_ERROR_DETECTION_NODE_A_RX
        TEST_NAME = "BIT_STUFF_ERROR_DETECTION_NODE_A_RX";
        do_reset();
        configure_node_a(3'b100);
        configure_node_b(3'b000);
        build_frame_stream(11'h000, 4'd0, 64'h0000_000000000000, 1'b0, 1'b0, 1'b0, frame_bits, frame_len);
        drive_external_bits(frame_bits, frame_len);
        repeat (40) @(posedge clk);
        host_read_a(ADDR_IRQ_STATUS, rd_data);
        clear_irq_a(8'h04);

        // BACK_TO_BACK_FRAME_HANDLING_NODE_A_RX
        TEST_NAME = "BACK_TO_BACK_FRAME_HANDLING_NODE_A_RX";
        do_reset();
        configure_node_a(3'b001);
        configure_node_b(3'b000);
        build_frame_stream(11'h111, 4'd2, 64'hA1B2_000000000000, 1'b0, 1'b0, 1'b1, frame_bits, frame_len);
        drive_external_bits(frame_bits, frame_len);
        build_frame_stream(11'h222, 4'd2, 64'hC3D4_000000000000, 1'b0, 1'b0, 1'b1, frame_bits, frame_len);
        drive_external_bits(frame_bits, frame_len);
        repeat (5000) @(posedge clk);
        pop_rx_a();
        repeat (20) @(posedge clk);
        pop_rx_a();
        repeat (4) @(posedge clk);

        // INTERRUPT_HANDLING_A_RX_B_TX
        TEST_NAME = "INTERRUPT_HANDLING_A_RX_B_TX";
        do_reset();
        configure_node_a(3'b000);
        configure_node_b(3'b000);
        send_frame_b(11'h155, 4'd1, 64'hAA00_000000000000);
        repeat (5000) @(posedge clk);
        host_read_a(ADDR_IRQ_STATUS, rd_data);
        clear_irq_a(8'h01);

        host_write_a(ADDR_IRQ_ENABLE, 8'h01);
        send_frame_b(11'h166, 4'd1, 64'hBB00_000000000000);
        repeat (5000) @(posedge clk);
        host_read_a(ADDR_IRQ_STATUS, rd_data);
        clear_irq_a(8'h01);
        repeat (6) @(posedge clk);

        host_write_b(ADDR_IRQ_ENABLE, 8'h02);
        send_frame_b(11'h077, 4'd1, 64'hCC00_000000000000);
        repeat (5000) @(posedge clk);
        host_read_b(ADDR_IRQ_STATUS, rd_data);
        clear_irq_b(8'h02);
        repeat (6) @(posedge clk);

        host_write_a(ADDR_IRQ_ENABLE, 8'h04);
        build_frame_stream(11'h299, 4'd1, 64'hDD00_000000000000, 1'b0, 1'b1, 1'b1, frame_bits, frame_len);
        drive_external_bits(frame_bits, frame_len);
        repeat (40) @(posedge clk);
        host_read_a(ADDR_IRQ_STATUS, rd_data);
        clear_irq_a(8'h04);
        repeat (6) @(posedge clk);

        // NORMAL_RATE_THEN_FD_RATE_B_TO_A
        TEST_NAME = "NORMAL_RATE_THEN_FD_RATE_B_TO_A";
        do_reset();
        configure_node_a_custom(3'b111, 10'd3, 1'b0);
        configure_node_b_custom(3'b111, 10'd3, 1'b0);
        send_frame_b(11'h33A, 4'd4, 64'h01234567_00000000);
        repeat (5000) @(posedge clk);
        configure_node_a_custom(3'b111, 10'd3, 1'b1);
        configure_node_b_custom(3'b111, 10'd3, 1'b1);
        send_frame_b(11'h33B, 4'd4, 64'h89ABCDEF_00000000);
        repeat (5000) @(posedge clk);

        // PHASE_BUFFER_COMPENSATION_REFINEMENT_NODE_A_RX
        TEST_NAME = "PHASE_BUFFER_COMPENSATION_REFINEMENT_NODE_A_RX";
        do_reset();
        configure_node_a_custom(3'b001, 10'd3, 1'b0);
        configure_node_b_custom(3'b000, 10'd3, 1'b0);
        build_frame_stream(11'h2A5, 4'd4, 64'hA5A55AA5_00000000, 1'b0, 1'b0, 1'b1, frame_bits, frame_len);
        find_transition_pair_index(frame_bits, frame_len, 24, edge_idx);
        if (edge_idx >= 0) begin
            drive_external_bits_with_phase_bump(frame_bits, frame_len, edge_idx, -2);
        end else begin
            drive_external_bits(frame_bits, frame_len);
        end
        repeat (5000) @(posedge clk);

        $finish;
    end

endmodule

/* verilator coverage_on */
