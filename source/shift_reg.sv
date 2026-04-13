`timescale 1ns / 10ps

module shift_reg #(
    parameter SIZE = 8,
    parameter MSB_FIRST = 0
) (
    input logic clk, n_rst, shift_enable, serial_in, load_enable,
    input logic [SIZE-1 :0] parallel_in,
    output logic serial_out,
    output logic [SIZE-1 :0] parallel_out
);

    logic next_serial_out;
    logic [SIZE-1:0] next_parallel_out; 

    always_ff @(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            parallel_out <= '1;
        end else begin
            parallel_out <= next_parallel_out;
        end
    end

    always_comb begin 
        if (load_enable) begin
            next_parallel_out = parallel_in;
        end else if (shift_enable) begin
            if (MSB_FIRST == 0) begin //lsb first
                next_parallel_out = {serial_in, parallel_out[SIZE - 1:1]};
            end else begin //msb first
                next_parallel_out = {parallel_out[SIZE - 1:0], serial_in};
            end
        end else begin // hold old values
            next_parallel_out = parallel_out;
        end
    end

    always_comb begin
        if (MSB_FIRST) begin
            serial_out = parallel_out[SIZE-1];
        end else begin
            serial_out = parallel_out[0];
        end
    end
endmodule
