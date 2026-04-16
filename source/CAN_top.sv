`timescale 1ns / 10ps

module CAN_top #(
    // parameters
) (
    input logic clk, n_rst,
    input logic bus_rx, tx_request, 

    output logic tx_bit
    //bus_rx is the bit on the bus, tx_bit is the bit that the node is sending to the bus
);

logic bus_idle, arb_active, error, error_idle,

//error handling
logic error_active, error_passive, error_serial_out, bus_off, bus_off_tec_rec, recovery_done;

//tx and rx datapath
logic is_transmitter, is_receiver;
logic sof_en, arb_en, crc_rst, data_en, ack_en, ack_delim_en, eof_en, eof_done, data_done; 

CAN_fsm protocol_fsm(
    .clk(clk), 
    .n_rst(n_rst),
    .tx_request(tx_request), 
    .bus_idle(bus_idle), .
    .node_off(arb_lost), //check this idk if this is right
    .data_done(data_done), 
    .error_idle(error_idle), 
    .tx_bit(tx_bit), 
    .arb_field_done(~arb_active), //maybe change this to a pulse when done
    .eof_done(eof_done), 
    .bus_bit(bus_rx), 

    .sof_en(sof_en), 
    .arb_en(arb_en), 
    .crc_rst(crc_rst), 
    .data_en(data_en), 
    .ack_en(ack_en), 
    .ack_delim_en(ack_delim_en), 
    .eof_en(eof_en), 
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
    .tx_bit(tx_bit), 
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

