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
    output logic stuff_error,
    input logic out_ready
);

    logic last_bit;
    logic [2:0] count;
    logic cut;

    always_comb begin
        out_bit = in_bit;

        if (!destuff_enable) begin
            out_valid = in_valid;
            in_ready = out_ready;
        end else begin
            if (cut) begin
                // Consume stuffed bit regardless of downstream readiness.
                out_valid = 1'b0;
                in_ready = 1'b1;
            end else begin
                out_valid = in_valid;
                in_ready = out_ready;
            end
        end
    end

    logic next_last_bit;
    logic [2:0] next_count;
    logic next_cut;
    logic next_stuff_error;

    always_comb begin
        next_last_bit = last_bit;
        next_count = count;
        next_cut = cut;
        next_stuff_error = 1'b0;

        if (!destuff_enable) begin
            next_last_bit = 0;
            next_count = 0;
            next_cut = 0;
        end

        else begin
            if (in_valid && in_ready) begin
                // drop bit
                if (cut) begin
                    next_cut = 0;

                    if (in_bit == last_bit) begin
                        next_stuff_error = 1'b1;
                    end

                    next_count = 3'd0;
                end
                else begin
                    if (count == 0) begin
                        next_last_bit = in_bit;
                        next_count = 1;
                    end
                    else if (in_bit == last_bit) begin
                        if (count == 3'd4) begin
                            next_count = 3'd5;
                            next_cut = 1;
                        end else begin
                            next_count = count + 1'b1;
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
            stuff_error <= 1'b0;
        end
        else begin
            last_bit <= next_last_bit;
            count <= next_count;
            cut <= next_cut;
            stuff_error <= next_stuff_error;
        end
    end



endmodule
