`timescale 1ns / 10ps

module error_frame_fsm (
    input logic clk, n_rst,
    input logic error, error_passive, error_active,
    output logic serial_out, error_done
);

logic [13:0] error_frame_passive;
logic [5:0] error_frame_active;
logic wait_done, count_en, count_clear;
logic pas_shift_en, pas_count_clear, pas_par_load_en, pas_error_done;
logic act_shift_en, act_count_clear, act_par_load_en, act_error_done;

logic serial_out_act, serial_out_pas;

assign error_frame_passive = 14'b000000_1111_1111;
assign error_frame_active = 6'b000000;

always_comb begin
    if(error_passive) begin
        serial_out = serial_out_pas;
    end else begin
        serial_out = serial_out_act;
    end
end

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

//counts passive bits shifted out
flex_counter #(.SIZE(4)) count_passive (
    .clk(clk),
    .n_rst(n_rst), 
    .count_enable(pas_shift_en), 
    .clear(pas_count_clear), 
    .rollover_val(4'd14),
    .count_out(),
    .rollover_flag(pas_error_done)
);

//passive error shift reg
shift_reg #(.SIZE(14), .MSB_FIRST(0)
) shift_register_passive (
    .clk(clk), 
    .n_rst(n_rst), 
    .shift_enable(pas_shift_en), 
    .serial_in(1'b0), 
    .load_enable(pas_par_load_en),
    .parallel_in(error_frame_passive),
    .serial_out(serial_out_pas),
    .parallel_out()
);

//counts active bits shifted out
flex_counter #(.SIZE(4)) count_active (
    .clk(clk),
    .n_rst(n_rst), 
    .count_enable(act_shift_en), 
    .clear(act_count_clear), 
    .rollover_val(4'd6),
    .count_out(),
    .rollover_flag(act_error_done)
);

//active error shift reg
shift_reg #(.SIZE(6), .MSB_FIRST(0)
) shift_register_active (
    .clk(clk), 
    .n_rst(n_rst), 
    .shift_enable(act_shift_en), 
    .serial_in(1'b0), 
    .load_enable(act_par_load_en),
    .parallel_in(error_frame_active),
    .serial_out(serial_out_act),
    .parallel_out()
);

typedef enum logic [2:0] { 
    IDLE = 3'd0,
    ERR_LOAD_ACTIVE = 3'd1,
    ERR_LOAD_PASSIVE = 3'd2,
    ERR_FRAME_PASSIVE = 3'd3,
    ERR_FRAME_ACTIVE = 3'd4,
    INTER = 3'd5
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
        pas_shift_en = 1'b0;
        act_shift_en = 1'b0;

        pas_par_load_en = 1'b0;
        act_par_load_en = 1'b0;

        act_count_clear = 1'b1;
        pas_count_clear = 1'b1;

        error_done = 1'b1;
        count_en = 1'b0;
        count_clear = 1'b1;

        if(error && error_passive) begin
            next_state = ERR_LOAD_PASSIVE;
        end if (error && error_active) begin
            next_state = ERR_LOAD_ACTIVE;
        end else begin
            next_state = IDLE;
        end
    end
    ERR_LOAD_ACTIVE: begin
        pas_shift_en = 1'b0;
        act_shift_en = 1'b0;

        pas_par_load_en = 1'b0;
        act_par_load_en = 1'b1;

        act_count_clear = 1'b0;
        pas_count_clear = 1'b0;

        error_done = 1'b0;
        count_en = 1'b0;
        count_clear = 1'b0;

        next_state = ERR_FRAME_ACTIVE;
    end
    ERR_LOAD_PASSIVE: begin
        pas_shift_en = 1'b0;
        act_shift_en = 1'b0;

        pas_par_load_en = 1'b0;
        act_par_load_en = 1'b1;

        act_count_clear = 1'b0;
        pas_count_clear = 1'b0;

        error_done = 1'b0;
        count_en = 1'b0;
        count_clear = 1'b0;

        next_state = ERR_FRAME_PASSIVE;
    end
    ERR_FRAME_PASSIVE: begin
        pas_shift_en = 1'b1;
        act_shift_en = 1'b0;

        pas_par_load_en = 1'b0;
        act_par_load_en = 1'b1;

        act_count_clear = 1'b0;
        pas_count_clear = 1'b0;

        error_done = 1'b0;
        count_en = 1'b0;
        count_clear = 1'b0;

        if(pas_error_done) begin
            next_state = INTER;
        end else begin
            next_state = ERR_FRAME_PASSIVE;
        end
    end
    ERR_FRAME_ACTIVE: begin
        pas_shift_en = 1'b0;
        act_shift_en = 1'b1;

        pas_par_load_en = 1'b0;
        act_par_load_en = 1'b0;

        act_count_clear = 1'b0;
        pas_count_clear = 1'b0;

        error_done = 1'b0;
        count_en = 1'b0;
        count_clear = 1'b0;

        if(act_error_done) begin
            next_state = INTER;
        end else begin
            next_state = ERR_FRAME_ACTIVE;
        end
    end
    INTER: begin
        pas_shift_en = 1'b0;
        act_shift_en = 1'b0;

        pas_par_load_en = 1'b0;
        act_par_load_en = 1'b0;

        act_count_clear = 1'b0;
        pas_count_clear = 1'b0;

        error_done = 1'b0;
        count_en = 1'b1;
        count_clear = 1'b0;

        if(wait_done) begin
            next_state = IDLE;
        end else begin
            next_state = INTER;
        end
    end
    default: begin
        pas_shift_en = 1'b0;
        act_shift_en = 1'b0;

        pas_par_load_en = 1'b0;
        act_par_load_en = 1'b0;

        act_count_clear = 1'b0;
        pas_count_clear = 1'b0;

        error_done = 1'b0;
        count_en = 1'b0;
        count_clear = 1'b0;

        next_state = IDLE;
    end
endcase
end

endmodule

