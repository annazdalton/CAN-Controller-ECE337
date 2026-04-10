`timescale 1ns / 10ps

module error_frame_fsm (
    input logic clk, n_rst,
    input logic error,
    output logic serial_out, error_idle
);

logic [13:0] error_frame;
logic shift_en, count_en, count_clear, wait_done;

flex_counter #(parameter SIZE = 2) (
    .clk(clk),
    .n_rst(n_rst), 
    .count_enable(count_en), 
    .clear(count_clear), 
    .rollover_val(2'd3),
    .count_out(),
    .rollover_flag(wait_done)
);

typedef enum logic [1:0] { 
    IDLE = 1'd0,
    ERR_FRAME = 1'd1,
    INTER = 1'd2
} state_t;

state_t state, next_state;

always_ff @(posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        state <= '0;
    end else begin
        state <= next_state;
    end
end

always_comb begin 
    IDLE: begin
        error_frame =  14'b0;
        shift_en = 1'b0;
        error_idle = 1'b1;
        count_en = 1'b0;

        if(error) begin
            next_state = ERR_FRAME;
        end else begin
            next_state = IDLE;
        end
    end
    ERR_FRAME: begin
        error_frame = 14'b000000_1111_1111;
        shift_en  = 1'b1;
        error_idle = 1'b0;
        count_en = 1'b0;

        if(error_done) begin
            next_state = INTER;
        end else begin
            next_state = ERR_FRAME;
        end
    end
    INTER: begin
        error_frame = 14'b0;
        shift_en  = 1'b0;
        error_idle = 1'b0;
        count_en = 1'b1;

        if(wait_done) begin
            next_state = IDLE;
        end else begin
            next_state = ERR_FRAME;
        end
    end
end

endmodule

