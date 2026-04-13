`timescale 1ns / 10ps

module bit_stuff #(
    // parameters
) (
    input logic clk, n_rst,
    input logic stuffing_enable,
    // host and module
    input logic in_valid,
    input logic in_bit,
    // module ready to receive new bit
    output logic in_ready
    ,
   // module and receiver
    output logic out_valid,
    output logic out_bit,
    // receiver ready to receive new bit
    input logic out_ready
);

    logic last_bit;
    logic [2:0] count;
    logic stuffing;

    always_comb begin
        in_ready = 0;
        out_valid = 0;
        out_bit = 0;
        if (stuffing_enable) begin
            if (stuffing) begin
                out_valid = 1;
                out_bit = ~last_bit;
                // tells host not ready to receive new bit
                in_ready = 0;

            end
            else begin
                out_valid = in_valid;
                out_bit = in_bit;
                // module ready but downstream RX may not be ready
                in_ready = out_ready;
            end
        end
        else begin
            out_bit = in_bit;
            out_valid = in_valid;
            in_ready = out_ready;
        end
    end

    logic next_last_bit;
    logic [2:0] next_count;
    logic next_stuffing;

    always_comb begin
        next_last_bit = last_bit;
        next_count = count;
        next_stuffing = stuffing;

        if (stuffing_enable) begin
            if (stuffing) begin
                if (out_ready) begin
                    next_stuffing = 0;
                    next_count = 1;
                    next_last_bit = ~last_bit;
                end
            end

            else if (in_valid && in_ready) begin
                if (count == 0) begin
                    next_last_bit = in_bit;
                    next_count = 1;
                end
                else if (in_bit == last_bit) begin
                    if (count == 5) begin
                        next_stuffing = 1;
                    end
                    else begin
                        next_count = count + 1;
                    end       
                end
                else begin
                    next_last_bit = in_bit;
                    next_count = 1;
                end
            end 
        end
        else begin
            next_count = 0;
            next_stuffing = 0;
        end
    end 
    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            last_bit <= 0;
            count <= 0;
            stuffing <= 0;
        end
        else begin
            last_bit <= next_last_bit;
            count <= next_count;
            stuffing <= next_stuffing;
        end
    
    end


endmodule

