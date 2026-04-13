`timescale 1ns / 10ps

module FIFO #(
    parameter SIZE = 8, 
    parameter DEPTH = 10
) (
    input logic clk, n_rst,
    input logic WEN, REN, clear, 
    input logic [SIZE - 1:0] wdata,

    output logic full, empty, underrun, overrun,
    output logic [$clog2(DEPTH+1) - 1 :0] count,
    output logic [SIZE - 1:0] rdata
);

localparam int ADDR_SIZE = $clog2(DEPTH);

logic [SIZE - 1:0] rdata_next;

always_ff @(posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        rdata <= '0;
    end else begin
        rdata <= rdata_next;
    end
end

logic underrun_next, overrun_next;
logic [ADDR_SIZE - 1:0] write_loc, write_loc_next, read_loc, read_loc_next;
logic [$clog2(DEPTH+1) - 1 :0] count_next;
logic [SIZE - 1:0][DEPTH - 1:0] fifo, fifo_next;

always_ff @(posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        overrun <= '0;
        underrun <= '0;
        write_loc <= '0;
        read_loc <= '0;
        count <= '0;
        fifo <= '0;
    end else begin
        overrun <= overrun_next;
        underrun <= underrun_next;
        write_loc <= write_loc_next;
        read_loc <= read_loc_next;
        count <= count_next;
        fifo <= fifo_next;
    end
end

assign full = (count == DEPTH)? 1'b1: 1'b0;
assign empty = (count == 0)? 1'b1: 1'b0;
assign rdata_next = fifo[read_loc];

always_comb begin
    //defaults
    write_loc_next = write_loc;
    read_loc_next = read_loc;
    overrun_next = overrun;
    underrun_next = underrun;
    count_next = count;
    fifo_next = fifo;

    if(clear) begin
        read_loc_next = '0;
        write_loc_next = '0;
        overrun_next = '0;
        underrun_next = '0;
        count_next = '0;
        fifo_next = fifo;
    end else begin
        if(WEN && !full && !(empty && REN)) begin //write to fifo
            write_loc_next = write_loc + 'd1;
            fifo_next[write_loc] = wdata;
        end else if (REN && !empty && !(full & WEN)) begin
            read_loc_next = read_loc + 'd1;
        end

        //errors
        if (WEN && full) begin //overrun error
            overrun_next = 1'b1;
        end
        if (REN && empty) begin
            underrun_next = 1'b1;
        end

        if(count == DEPTH) begin
            if((REN && WEN) | WEN) begin
                count_next = count;
            end else if (REN) begin
                count_next = count - 'd1;
            end
        end else if(count == 0 && REN) begin //cant read from empty fifo
            count_next = count; 
        end else begin
            count_next = count + WEN - REN;
        end
    end

end
endmodule

