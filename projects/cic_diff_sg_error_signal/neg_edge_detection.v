`timescale 1ns / 1ps

module neg_edge_detection #
(
    parameter ADC_WIDTH = 12,
    parameter AXIS_TDATA_WIDTH = 16
)
(
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    input [AXIS_TDATA_WIDTH-1:0]   S_AXIS_IN_tdata,
    input                          S_AXIS_IN_tvalid,
    input                          clk,
    input                          rst,
    output                         trigger
);
    
    wire signed [11:0]             ch2_data;
    reg                            state, state_next, trigger_reg ;
    reg  signed [11:0]             upper_threshold = 12'd54 ;  // 80 for 5V TTL, 54 for 3.4V TTL trigger
    reg  signed [11:0]             lower_threshold = 12'd50 ;  // 75 for 5V TTL, 50 for 3.4V TTL trigger
    
    // For 10-bit Red Pitaya, Extract only the first 12-bits of ch2 ADC data 
    assign  ch2_data = S_AXIS_IN_tdata[15:4];
 
    // Handling of the state buffer for finding signal transition at the threshold
    always @(posedge clk) 
    begin
        if (~rst) 
        begin
            state <= 1'b0;
            trigger_reg <= 1'b0;
        end
        else
        begin
            state <= state_next ;
            trigger_reg <= state & (!state_next) ;  // so that the trigger signal will be one clock cycle long
        end
    end
    
    always @*            
    begin
        if (ch2_data > upper_threshold)
            state_next = 1;
        else if (ch2_data < lower_threshold)
            state_next = 0;
        else
            state_next = state;
    end

    assign trigger = trigger_reg;
    
endmodule
