`timescale 1ns / 10ps

module tx_buffer #(
    parameter ID_W = 11,
    parameter DLC_W = 4,
    parameter DATA_W = 64
) (
    input  logic              clk,
    input  logic              n_rst,
    input  logic              wr_en,
    input  logic              clr_valid,
    input  logic [ID_W-1:0]   wr_id,
    input  logic [DLC_W-1:0]  wr_dlc,
    input  logic [DATA_W-1:0] wr_data,

    output logic              valid,
    output logic [ID_W-1:0]   id_out,
    output logic [DLC_W-1:0]  dlc_out,
    output logic [DATA_W-1:0] data_out
);

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            valid <= 1'b0;
            id_out <= '0;
            dlc_out <= '0;
            data_out <= '0;
        end else begin
            if (wr_en) begin
                valid <= 1'b1;
                id_out <= wr_id;
                dlc_out <= wr_dlc;
                data_out <= wr_data;
            end else if (clr_valid) begin
                valid <= 1'b0;
            end
        end
    end

endmodule
