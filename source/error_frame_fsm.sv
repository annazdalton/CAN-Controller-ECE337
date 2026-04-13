`timescale 1ns / 10ps

module error_frame_fsm (
    input logic clk, n_rst,
    input logic error,
    output logic serial_out, error_idle
);

logic [13:0] error_frame;
logic shift_en, count_en, count_clear, wait_done, par_load_en;

//counter for inter->idle
flex_counter #(.SIZE(2)) count3 (
    .clk(clk),
    .n_rst(n_rst), 
    .count_enable(count_en), 
    .clear(count_clear), 
    .rollover_val(2'd3),
    .count_out(),
    .rollover_flag(wait_done)
);

//counter that counts bits shifted out
flex_counter #(.SIZE(4)) count14 (
    .clk(clk),
    .n_rst(n_rst), 
    .count_enable(shift_en), 
    .clear(count_clear), 
    .rollover_val(4'd14),
    .count_out(),
    .rollover_flag(error_done)
);

shift_reg #(.SIZE(14), .MSB_FIRST(0)
) shift_register (
    .clk(clk), 
    .n_rst(n_rst), 
    .shift_enable(shift_en), 
    .serial_in(1'b0), 
    .load_enable(par_load_en),
    .parallel_in(error_frame),
    .serial_out(serial_out),
    .parallel_out()
);

typedef enum logic [2:0] { 
    IDLE = 3'd0,
    ERR_LOAD = 3'd1,
    ERR_FRAME = 3'd2,
    INTER = 3'd3
} state_t0;

state_t0 state, next_state;

always_ff @(posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always_comb begin 
case(state)
    IDLE: begin
        error_frame =  14'b0;
        shift_en = 1'b0;
        error_idle = 1'b1;
        count_en = 1'b0;
        count_clear = 1'b1;
        par_load_en = 1'b0;

        if(error) begin
            next_state = ERR_LOAD;
        end else begin
            next_state = IDLE;
        end
    end
    ERR_LOAD: begin
        error_frame = 14'b000000_1111_1111;
        shift_en  = 1'b0;
        error_idle = 1'b0;
        count_en = 1'b0;
        count_clear = 1'b0;
        par_load_en = 1'b1;

        next_state = ERR_FRAME;
    end
    ERR_FRAME: begin
        error_frame = 14'b000000_1111_1111;
        shift_en  = 1'b1;
        error_idle = 1'b0;
        count_en = 1'b0;
        count_clear = 1'b0;
        par_load_en = 1'b0;

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
        count_clear = 1'b0;
        par_load_en = 1'b0;

        if(wait_done) begin
            next_state = IDLE;
        end else begin
            next_state = INTER;
        end
    end
    default: begin
        error_frame = 14'b0;
        shift_en  = 1'b0;
        error_idle = 1'b0;
        count_en = 1'b0;
        count_clear = 1'b0;
        par_load_en = 1'b0;

        next_state = IDLE;
    end
endcase
end

endmodule

