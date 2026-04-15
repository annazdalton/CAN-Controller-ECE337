`timescale 1ns / 10ps

module CAN_top #(
    // parameters
) (
    input logic clk, n_rst,
    input logic bus_rx, tx_request,
);

logic bus_idle, arb_active, error, error_idle,

arbitration arb (
    .clk(clk), 
    .n_rst(n_rst),
    .bus_rx(bus_rx), //sampled bit from CAN bus: dominant = 0, recessive = 1
    .tx_request(tx_request),
    .tx_id(),
    .tx_bit(), 
    .bus_off_req(),

    .is_transmitter(),
    .is_receiver(),
    .arb_lost(), 
    .bus_idle(bus_idle), // 1 = bus is idle (11 recessive bits detected)
    .arb_active() //1 is arb phase is ongoing 
);

CAN_fsm protocol_fsm(
    .clk(clk), 
    .n_rst(),
    .tx_request(tx_request), 
    .bus_idle(bus_idle), .
    .node_off(), 
    .data_done(), 
    .error_idle(error_idle), 
    .tx_bit(), 
    .arb_field_done(~arb_active), //maybe change this to a pulse when done
    .eof_done(), 
    .bus_bit(), 

    .sof_en(), 
    .arb_en(), 
    .crc_rst(), 
    .data_en(), 
    .ack_en(), 
    .ack_delim_en(), 
    .eof_en(), 
    .error(error)
);

error_frame_fsm error_frame(
    .clk(clk), 
    .n_rst(n_rst),
    .error(error),
    
    .serial_out(), 
    .error_idle(error_idle)
);

CAN_error_counters tec_rec(
    .clk(), 
    .n_rst(),

    .tx_error(), 
    .tx_success(), 
    .rx_error(),
    .rx_success(),

    .bus_rx(bus_rx),
    .bus_off_i(),

    .error_active(), 
    .error_passive(),
    .bus_off(),
    .recovery_done()
);


endmodule

