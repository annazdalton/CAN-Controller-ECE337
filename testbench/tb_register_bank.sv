`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_register_bank;

    localparam CLK_PERIOD = 10ns;
    localparam ADDR_W = 6;
    localparam DATA_W = 8;
    localparam IRQ_W = 3;

    localparam logic [ADDR_W-1:0] MODE_ADDR = 5'd0;
    localparam logic [ADDR_W-1:0] BT_BRP_LO_ADDR = 5'd1;
    localparam logic [ADDR_W-1:0] BT_BRP_HI_ADDR = 5'd2;
    localparam logic [ADDR_W-1:0] BT_TQPB_ADDR = 5'd3;
    localparam logic [ADDR_W-1:0] BT_SAMPLE_ADDR = 5'd4;
    localparam logic [ADDR_W-1:0] BT_SJW_ADDR = 5'd5;
    localparam logic [ADDR_W-1:0] BT_FD_ADDR = 5'd6;
    localparam logic [ADDR_W-1:0] IRQ_ENABLE_ADDR = 5'd7;
    localparam logic [ADDR_W-1:0] IRQ_STATUS_ADDR = 5'd8;
    localparam logic [ADDR_W-1:0] IRQ_CLEAR_ADDR = 5'd9;
    localparam logic [ADDR_W-1:0] TX_ID_ADDR = 5'd10;
    localparam logic [ADDR_W-1:0] TX_ID_HI_ADDR = 5'd11;
    localparam logic [ADDR_W-1:0] TX_DLC_ADDR = 5'd12;
    localparam logic [ADDR_W-1:0] TX_DATA0_ADDR = 5'd13;
    localparam logic [ADDR_W-1:0] TX_DATA7_ADDR = 5'd20;
    localparam logic [ADDR_W-1:0] TX_CTRL_ADDR = 5'd21;
    localparam logic [ADDR_W-1:0] RX_POP_ADDR = 5'd22;

    logic clk, n_rst;
    logic reg_wr_en, reg_rd_en;
    logic [DATA_W-1:0] reg_wdata;
    logic [ADDR_W-1:0] reg_addr;
    logic [IRQ_W-1:0] irq_status;
    logic [10:0] rx_head_id;
    logic [3:0] rx_head_dlc;
    logic [63:0] rx_head_data;
    logic rx_buf_empty;
    logic rx_buf_full;
    logic [3:0] rx_count;

    logic [DATA_W-1:0] reg_rdata;
    logic wr_accept, rd_valid;
    logic [IRQ_W-1:0] irq_enable_reg, irq_clear;
    logic bt_enable;
    logic [9:0] bt_brp;
    logic [5:0] bt_tq_per_bit;
    logic [5:0] bt_sample_tq;
    logic [5:0] bt_sjw;
    logic bt_fd;
    logic [10:0] tx_id_cfg;
    logic [3:0] tx_dlc_cfg;
    logic [63:0] tx_data_cfg;
    logic tx_wr_en_pulse, tx_request;
    logic rx_pop_pulse;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    always begin
        clk = 1'b0;
        #(CLK_PERIOD / 2.0);
        clk = 1'b1;
        #(CLK_PERIOD / 2.0);
    end

    task automatic reset_dut;
        begin
            n_rst = 1'b0;
            reg_wr_en = 1'b0;
            reg_rd_en = 1'b0;
            reg_wdata = '0;
            reg_addr = '0;
            irq_status = '0;
            rx_head_id = '0;
            rx_head_dlc = '0;
            rx_head_data = '0;
            rx_buf_empty = 1'b1;
            rx_buf_full = 1'b0;
            rx_count = '0;
            repeat (3) @(posedge clk);
            @(negedge clk);
            n_rst = 1'b1;
            repeat (2) @(posedge clk);
        end
    endtask

    task automatic write_reg(input logic [ADDR_W-1:0] addr, input logic [DATA_W-1:0] data);
        begin
            @(negedge clk);
            reg_addr = addr;
            reg_wdata = data;
            reg_wr_en = 1'b1;
            reg_rd_en = 1'b0;
            @(posedge clk);
            @(negedge clk);
            reg_wr_en = 1'b0;
        end
    endtask

    task automatic read_reg(input logic [ADDR_W-1:0] addr, output logic [DATA_W-1:0] data);
        begin
            @(negedge clk);
            reg_addr = addr;
            reg_rd_en = 1'b1;
            reg_wr_en = 1'b0;
            @(posedge clk);
            data = reg_rdata;
            @(negedge clk);
            reg_rd_en = 1'b0;
        end
    endtask

    register_bank #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),
        .IRQ_W(IRQ_W)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .reg_wr_en(reg_wr_en),
        .reg_rd_en(reg_rd_en),
        .reg_wdata(reg_wdata),
        .reg_addr(reg_addr),
        .irq_status(irq_status),
        .rx_head_id(rx_head_id),
        .rx_head_dlc(rx_head_dlc),
        .rx_head_data(rx_head_data),
        .rx_buf_empty(rx_buf_empty),
        .rx_buf_full(rx_buf_full),
        .rx_count(rx_count),
        .reg_rdata(reg_rdata),
        .wr_accept(wr_accept),
        .rd_valid(rd_valid),
        .irq_enable_reg(irq_enable_reg),
        .irq_clear(irq_clear),
        .bt_enable(bt_enable),
        .bt_brp(bt_brp),
        .bt_tq_per_bit(bt_tq_per_bit),
        .bt_sample_tq(bt_sample_tq),
        .bt_sjw(bt_sjw),
        .bt_fd(bt_fd),
        .tx_id_cfg(tx_id_cfg),
        .tx_dlc_cfg(tx_dlc_cfg),
        .tx_data_cfg(tx_data_cfg),
        .tx_wr_en_pulse(tx_wr_en_pulse),
        .tx_request(tx_request),
        .rx_pop_pulse(rx_pop_pulse)
    );

    logic [7:0] rd_data;

    initial begin
        reset_dut();

        write_reg(MODE_ADDR, 8'b0000_0001);

        write_reg(BT_BRP_LO_ADDR, 8'h34);
        write_reg(BT_BRP_HI_ADDR, 8'h02);
        write_reg(BT_TQPB_ADDR, 8'd16);
        write_reg(BT_SAMPLE_ADDR, 8'd11);
        write_reg(BT_SJW_ADDR, 8'd1);
        write_reg(BT_FD_ADDR, 8'h01);

        write_reg(IRQ_ENABLE_ADDR, 8'b0000_0101);

        irq_status = 3'b110;
        read_reg(IRQ_STATUS_ADDR, rd_data);

        write_reg(IRQ_STATUS_ADDR, 8'hFF);

        @(posedge clk);

        write_reg(IRQ_CLEAR_ADDR, 8'b0000_0011);
        @(posedge clk);
        @(negedge clk);

        write_reg(TX_ID_ADDR, 8'hA5);
        write_reg(TX_ID_HI_ADDR, 8'h03);
        write_reg(TX_DLC_ADDR, 8'h08);
        write_reg(TX_DATA0_ADDR, 8'h11);
        write_reg(TX_DATA7_ADDR, 8'h88);

        @(posedge clk);

        write_reg(TX_CTRL_ADDR, 8'b0000_0011);
        @(posedge clk);
        @(negedge clk);

        write_reg(RX_POP_ADDR, 8'hFF);
        @(posedge clk);
        @(negedge clk);

        read_reg(5'd31, rd_data);

        @(negedge clk);
        reg_addr = MODE_ADDR;
        reg_wdata = 8'h5A;
        reg_wr_en = 1'b1;
        reg_rd_en = 1'b1;
        @(posedge clk);
        @(negedge clk);
        reg_wr_en = 1'b0;
        reg_rd_en = 1'b0;
        read_reg(MODE_ADDR, rd_data);
        $finish;
    end

endmodule

/* verilator coverage_on */
