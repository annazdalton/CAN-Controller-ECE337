`timescale 1ns / 10ps

module CAN_top #(
    // parameters
) (
    input logic clk, n_rst,
    input logic bus_rx, tx_request,
);

logic bus_idle, arb_active, error, error_idle,

//error handling
logic error_active, error_passive, error_serial_out, bus_off, bus_off_tec_rec, recovery_done;

//tx and rx datapath
logic is_transmitter, is_receiver;

CAN_fsm protocol_fsm(
    .clk(clk), 
    .n_rst(n_rst),
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
    .error_passive(error_passive),
    .erro_actice(error_active),
    
    .serial_out(error_serial_out), //figure out how to integrate into datapath 
    .error_idle(error_idle)
);

CAN_error_counters tec_rec(
    .clk(clk), 
    .n_rst(n_rst),

    .tx_error(), 
    .tx_success(), 
    .rx_error(),
    .rx_success(),

    .bus_rx(bus_rx),
    .bus_off_i(bus_off),

    .error_active(error_active), 
    .error_passive(error_passive),
    .bus_off(bus_off_tec_rec),
    .recovery_done(recovery_done)
);

arbitration arb (
    .clk(clk), 
    .n_rst(n_rst),
    .bus_rx(bus_rx), 
    .tx_request(tx_request),
    .tx_id(),
    .tx_bit(), 
    .recovery_done(recovery_done),
    .bus_off_req(bus_off_tec_rec),

    .is_transmitter(is_transmitter),
    .is_receiver(is_receiver),
    .arb_lost(), 
    .bus_off_o(bus_off),
    .bus_idle(bus_idle), 
    .arb_active(arb_active)
);


endmodule

