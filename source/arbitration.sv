`timescale 1ns / 10ps

module arbitration (
    input logic clk, n_rst,
    input logic bit_tick,
    input logic bus_rx, //bit from CAN bus: dominant = 0, recessive = 1
    input logic tx_request,
    input logic [10:0] tx_id,
    input logic tx_bit, recovery_done, bus_off_req, 

    output logic is_transmitter, is_receiver, arb_lost, bus_off_o,
    output logic bus_idle, // 1 = bus is idle (11 recessive bits detected)
    output logic arb_active 
);

typedef enum logic [2:0] {
    IDLE = 3'd0,
    ARB_PHASE = 3'd1,
    TRANSMIT = 3'd2,
    RECEIVE = 3'd3,
    BUS_OFF = 3'd4 //error state
} arb_state_t;

arb_state_t state, next_state; 

logic sof_detected, bit_count_en, bit_count_clr, arb_done, idle_count_en;

assign sof_detected = bit_tick && bus_idle && !bus_rx; // SOF is the first 0 after idle
assign arb_lost = (state == ARB_PHASE) && bit_tick && (tx_bit  == 1'b1) && (bus_rx  == 1'b0);
assign arb_active = (state == ARB_PHASE)? 1'b1: 1'b0;

//idle counter - count 11 recessive bits
flex_counter_CDL #(.SIZE(4)) counter_11 (
    .clk (clk),
    .n_rst (n_rst),
    .count_enable (idle_count_en), //only counts recissive bits (1)
    .clear(!bus_rx),
    .rollover_val (4'd11),
    .count_out(),
    .rollover_flag(bus_idle)
);

//bit counter for arb state to transmit state
flex_counter_CDL #(.SIZE(4)) arb_done_count (
    .clk (clk),
    .n_rst (n_rst),
    .count_enable (bit_count_en), //only counts recissive bits (1)
    .clear(bit_count_clr),
    .rollover_val (4'd11),
    .count_out (),
    .rollover_flag(arb_done)
);

always_comb begin
    case(state)
        IDLE: begin
            idle_count_en = bit_tick && bus_rx;
            bit_count_en = 1'b0;
            bus_off_o = 1'b0;
            bit_count_clr = 1'b1;
            is_transmitter = 1'b0;
            is_receiver = 1'b0;
        end
        ARB_PHASE: begin
            idle_count_en = bit_tick && bus_rx;
            bit_count_en = bit_tick;
            bus_off_o = 1'b0;
            bit_count_clr = 1'b0;
            is_transmitter = 1'b0;
            is_receiver = 1'b0;
        end
        TRANSMIT: begin
            idle_count_en = bit_tick && bus_rx;
            bit_count_en = 1'b0;
            bus_off_o = 1'b0;
            bit_count_clr = 1'b0;
            is_transmitter = 1'b1;
            is_receiver = 1'b0;
        end
        RECEIVE: begin
            idle_count_en = bit_tick && bus_rx;
            bit_count_en = 1'b0;
            bus_off_o = 1'b0;
            bit_count_clr = 1'b0;
            is_transmitter = 1'b0;
            is_receiver = 1'b1;
        end
        BUS_OFF: begin
            idle_count_en = bit_tick && bus_rx;
            bit_count_en = 1'b0;
            bus_off_o = 1'b1;
            bit_count_clr = 1'b0;
            is_transmitter = 1'b0;
            is_receiver = 1'b0;
        end
        default: begin
            idle_count_en = bit_tick && bus_rx;
            bit_count_en = 1'b0;
            bus_off_o = 1'b0;
            bit_count_clr = 1'b0;
            is_transmitter = 1'b0;
            is_receiver = 1'b0;
        end
    endcase
end

//fsm
always_ff @(posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        state <=  IDLE;
    end else begin
        state <= next_state;
    end
end

always_comb begin
    case(state)
        IDLE: begin
            if (sof_detected && tx_request) begin
                next_state = ARB_PHASE; 
            end else if (sof_detected && !tx_request) begin
                next_state = RECEIVE;
            end else begin
                next_state = IDLE;
            end
        end
        ARB_PHASE: begin
            if (arb_lost) begin
                next_state = RECEIVE;
            end else if (arb_done) begin
                next_state = TRANSMIT;
            end else begin
                next_state = ARB_PHASE;
            end
        end
        TRANSMIT: begin
            if (bus_off_req) begin
                next_state = BUS_OFF;
            end else if (bus_idle) begin
                next_state = IDLE;
            end else begin
                next_state = TRANSMIT;
            end
        end
        RECEIVE: begin
            if(bus_off_req) begin 
                next_state = BUS_OFF;
            end else if (bus_idle) begin
                next_state = IDLE;
            end else begin
                next_state = RECEIVE;
            end
        end
        BUS_OFF: begin
            if(recovery_done) begin
                next_state = IDLE;
            end else begin
                next_state = BUS_OFF;
            end
        end
        default: begin
            next_state =  IDLE;
        end
    endcase
end

endmodule

