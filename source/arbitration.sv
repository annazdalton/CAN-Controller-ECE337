`timescale 1ns / 10ps

module arbitration (
    input logic clk, n_rst,
    input logic bus_rx, //sampled bit from CAN bus: dominant = 0, recessive = 1
    input logic tx_request,
    input logic [10:0] tx_id,
    input logic tx_bit, bus_off_req,

    output logic is_transmitter,
    output logic is_receiver,
    output logic arb_lost, 
    output logic bus_idle, // 1 = bus is idle (11 recessive bits detected)
    output logic arb_active //1 is arb phase is ongoing 
);

typedef enum logic [2:0] {
    IDLE = 3'd0,
    ARB_PHASE = 3'd1,
    TRANSMIT = 3'd2,
    RECEIVE = 3'd3,
    BUS_OFF = 3'd4 //error state
} arb_state_t;

arb_state_t state, next_state; 

logic [4:0] idle_count, idle_count_next;
logic [5:0] bit_count, bit_count_next;
logic arb_lost_internal, sof_detected;

assign bus_idle = (idle_count >= 5'd11)? 1'b1: 1'b0;
assign sof_detected = (bus_idle && bus_rx == 1'b0)? 1'b1: 1'0; // SOF is the first 0 after idle
assign arb_lost_internal = (state == ARB_PHASE) && (tx_bit  == 1'b1) && (bus_rx  == 1'b0); 
assign arb_active = (state == ARB_PHASE)? 1'b1: 1'b0;

//counts 11 ressesive bits
always_ff @(posedge clk, negedge rst_n) begin
    if (~n_rst) begin
        idle_count <= '0;
    end else begin
        idle_count <= idle_count_next;
    end
end

always_comb begin
    if (bus_rx == 1'b0) begin //reset if theres a dominant bit
        idle_count_next = '0;
    end else if (idle_count < 5'd11) begin
        idle_count_next <= idle_count + 1'b1;
    end else begin
        idle_count_next <= idle_count;
    end
end

//counts bits in arb field
always_ff @(posedge clk, negedge rst_n) begin
    if (~n_rst) begin
        bit_count <= '0;
    end else begin
        bit_count = bit_count_next;
    end
end

always_comb begin
    case(state)
        IDLE: bit_count_next = '0;
        ARB_PHASE: bit_count_next = bit_count + 1'b1;
        default: bit_count_next = bit_count;
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
            if (arb_lost_internal) begin
                next_state = RECEIVE;
            end else if (bit_cnt == (ARB_BITS - 1)) begin
                next_state = TRANSMIT;
            end else begin
                next_state = ARB_PHASE;
            end
        end
        TRANSMIT: begin
            if (bus_idle) begin
                next_state = IDLE;
            end else begin
                next_state = TRANSMIT;
            end
        end
        RECEIVE: begin
            if(bus_off_req) begin //tec counter is greater than 256
                next_state = BUS_OFF;
            end else if (bus_idle) begin
                next_state = IDLE;
            end else begin
                next_state = RECEIVE;
            end
        end
        BUS_OFF: begin
            if(!bus_off) begin
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

//output logic 
always_ff @(posedge clk, negedge rst_n) begin
    if (~n_rst) begin
        is_transmitter <= '0;
        is_receiver <= '0;
        arb_lost <= '0;
    end else begin
        is_transmitter <= (next_state == TRANSMIT);
        is_receiver <= (next_state == RECEIVE);
        arb_lost <= arb_lost_internal; //pulse
    end
end

endmodule

