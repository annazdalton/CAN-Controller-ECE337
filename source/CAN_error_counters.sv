`timescale 1ns / 10ps

module CAN_error_counters (
    input logic clk, n_rst,

    input  logic tx_error, tx_success, rx_error_plus8, rx_error_plus1, rx_success,

    //inputs from arbitration module
    input  logic bus_rx,
    input  logic in_bus_off,

    output logic error_active, // TEC < 128 && REC < 128
    output logic error_passive, // TEC >= 128 || REC >= 128 (but not bus off)
    output logic bus_off, // TEC >= 256
    output logic [8:0] tec_out, // Current TEC value
    output logic [7:0] rec_out // Current REC value
);

logic bus_off_reg;

always_ff @(posedge clk, negedge n_rst) begin
    if (~n_rst)
        bus_off_reg <= 1'b0;
    else if (tec >= 9'd256)
        bus_off_reg <= 1'b1;
    else if (recovery_done)
        bus_off_reg <= 1'b0;
end

assign bus_off = bus_off_reg;

//TEC
logic [8:0] tec, next_tec;

always_ff @(posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        tec <= '0;
    end else begin
        tec <= next_tec; 
    end
end

always_comb begin
    //default
    next_tec = tec;

    if(bus_off_reg) begin
        next_tec = '0;
    end else if(tx_error) begin
        next_tec = (tec + 9'd8 >= 9'd256) ? 9'd256 : tec + 9'd8; //add 8
    end else if (tx_success) begin
        next_tec = (tec == 9'd0) ? 9'd0 : tec - 9'd1; //subtract 1
    end
end

//REC
logic [7:0] rec, next_rec; 
always_ff @(posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        rec <= '0;
    end else begin
        rec <= next_rec; 
    end
end

always_comb begin
    //default
    next_rec = rec;

    if (rx_error_plus8) begin
        next_rec = (rec + 8'd8 >= 8'd127) ? 8'd127 : rec + 8'd8;
    end else if (rx_error_plus8) begin
        next_rec = (rec + 8'd8 >= 8'd127) ? 8'd127 : rec + 8'd8;
    end else if (rx_error_plus1) begin
        next_rec = (rec + 8'd1 >= 8'd127) ? 8'd127 : rec + 8'd1;
    end else if (rx_success) begin
        next_rec = (rec == 8'd0) ? 8'd0 : rec - 8'd1;
    end
end

//bus off state (arbitration module) recovery counter
logic [3:0] idle_count_out;
logic idle_rollover, dominant_seen,recovery_done;
logic [7:0] seq_count_out;

assign dominant_seen = (in_bus_off && bus_rx == 1'b0);

flex_counter_CDL #(.SIZE(4)) recessive_run_count (
    .clk (clk),
    .n_rst (n_rst),
    .count_enable (in_bus_off && bus_rx == 1'b1),//only counts recissive bits (1)
    .clear (dominant_seen),
    .rollover_val (4'd11),
    .count_out (idle_count_out),
    .rollover_flag (idle_rollover)
);

 flex_counter_CDL #(.SIZE(8)) recover_seq_countt (
    .clk (clk),
    .n_rst (n_rst),
    .count_enable (idle_rollover),
    .clear (~bus_off_reg), //reset of not is bus off state
    .rollover_val (8'd128),
    .count_out (seq_count_out),
    .rollover_flag  (recovery_done)
);

assign bus_off = (tec >= 9'd256);
assign error_passive = ~bus_off && (tec >= 9'd128 || rec >= 8'd128);
assign error_active  = ~bus_off && ~error_passive;

assign tec_out = tec;
assign rec_out = rec;

endmodule

