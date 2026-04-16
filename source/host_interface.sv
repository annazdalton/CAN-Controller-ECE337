`timescale 1ns / 10ps

module host_interface #(
    parameter ADDR_W = 4,
    parameter DATA_W = 8
) (
    input logic clk, n_rst,

    // From Host
    input logic host_wr_req,
    input logic host_rd_req,
    input logic [DATA_W-1:0] host_wdata,
    input logic [ADDR_W-1:0] host_addr,

    // From register_bank
    input logic [DATA_W-1:0] reg_rdata,
    input logic wr_accept,
    input logic rd_valid,

    // Registered Outputs
    output logic [DATA_W-1:0] host_rdata,
    output logic host_wr_ack,
    output logic host_rd_ack,

    // To register bank
    output logic reg_wr_en,
    output logic reg_rd_en,
    output logic [DATA_W-1:0] reg_wdata,
    output logic [ADDR_W-1:0] reg_addr
);

    logic [DATA_W-1:0] next_host_rdata;
    logic next_host_wr_ack;
    logic next_host_rd_ack;

    always_comb begin
        next_host_rdata = host_rdata;
        next_host_wr_ack = 1'b0;
        next_host_rd_ack = 1'b0;
        reg_wr_en = 1'b0;
        reg_rd_en = 1'b0;
        reg_wdata = host_wdata;
        reg_addr = host_addr;

        if (host_wr_req) begin
            reg_wr_en = 1'b1;
            reg_rd_en = 1'b0;
            reg_wdata = host_wdata;
            reg_addr = host_addr;

            if (wr_accept) begin
                next_host_wr_ack = 1'b1;
            end
        end else if (host_rd_req) begin
            reg_wr_en = 1'b0;
            reg_rd_en = 1'b1;
            reg_addr = host_addr;

            if(rd_valid) begin
                next_host_rdata = reg_rdata;
                next_host_rd_ack = 1'b1;
            end
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            host_rdata <= '0;
            host_wr_ack <= 1'b0;
            host_rd_ack <= 1'b0;
        end else begin
            host_rdata <= next_host_rdata;
            host_wr_ack <= next_host_wr_ack;
            host_rd_ack <= next_host_rd_ack;
        end
    end

endmodule

