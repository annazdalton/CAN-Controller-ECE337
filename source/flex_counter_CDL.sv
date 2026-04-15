`timescale 1ns / 10ps

module flex_counter_CDL #(parameter SIZE = 8) (
    input logic clk, n_rst, count_enable, clear, 
    input logic [SIZE - 1:0] rollover_val,
    output logic [SIZE - 1:0] count_out,
    output logic rollover_flag
);
    logic [SIZE - 1:0] count_next;

    logic reg_flag_next;

    always_ff @(posedge clk, negedge n_rst) begin 
        if (~n_rst) begin
            count_out <= '0;
            rollover_flag <= '0;
        end else begin
            count_out <= count_next;
            rollover_flag <= reg_flag_next;
        end
    end

    always_comb begin
        if(clear) begin
            count_next = '0;
        end else if (count_enable) begin
            if(count_out == rollover_val | count_out > rollover_val) begin
                count_next = 'b1;
            end else begin
                count_next = count_out + 'b1;
            end
        end else begin
            count_next = count_out;
        end

        if (count_next == rollover_val | count_out > rollover_val) begin
            reg_flag_next = 1'b1;
        end else begin
            reg_flag_next = 1'b0;
        end
    end

endmodule

