`timescale 1ns / 10ps

module bit_destuff #(
    // parameters
) (
    input logic clk, n_rst,

    input logic destuff_enable,
    input logic in_valid,
    input logic in_bit,
    output logic in_ready,

    output logic out_valid,
    output logic out_bit,
    input logic out_ready
);

    logic last_bit;
    logic [2:0] count;
    logic cut;

    always_comb begin
        in_ready = 0;
        out_valid = 0;
        out_bit = in_bit;

        if (destuff_enable) begin
            in_ready = out_ready;
            
            if (cut) begin
                out_valid = 0;
            end
            else begin
                out_valid = in_valid;
                out_bit = in_bit;
            end
        end
        else begin
            out_valid = in_valid;
            out_bit = in_bit;
            in_ready = out_ready;
        end
    end

    logic next_last_bit;
    logic [2:0] next_count;
    logic next_cut;

    always_comb begin
        next_last_bit = last_bit;
        next_count = count;
        next_cut = cut;

        if (!destuff_enable) begin
            next_count = 0;
            next_cut = 0;
        end

        else begin
            if (in_valid && in_ready) begin
                // drop bit
                if (cut) begin
                    next_cut = 0;
                    next_last_bit = in_bit;
                    next_count = 1;
                end
                else begin
                    if (count == 0) begin
                        next_last_bit = in_bit;
                        next_count = 1;
                    end
                    else if (in_bit == last_bit) begin
                        next_count = count + 1;

                        if (count + 1 == 5) begin
                            next_cut = 1;
                        end
                    end
                    else begin
                        next_last_bit = in_bit;
                        next_count = 1;
                    end
                end
            end
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            last_bit <= 0;
            count <= 0;
            cut <= 0;
        end
        else begin
            last_bit <= next_last_bit;
            count <= next_count;
            cut <= next_cut;
        end
    end



endmodule

