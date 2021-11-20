`timescale 1ns / 1ps

// Discriminator_1 for LV input (+- 1V)

module discriminator #
(
    parameter ADC_WIDTH = 12,
    parameter AXIS_TDATA_WIDTH = 32
)
(
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    input [AXIS_TDATA_WIDTH-1:0]      S_AXIS_IN_tdata,
    input                             S_AXIS_IN_tvalid,
    input                             clk,
    input                             rst,
    output                            state_out
);
    
    wire signed [ADC_WIDTH-1:0]       data;

    reg                               state, state_next;
    reg  signed [ADC_WIDTH-1:0]       HIGH_THRESHOLD = 12'b0000_0101_1101 ;  
    reg  signed [ADC_WIDTH-1:0]       LOW_THRESHOLD  = 12'b0000_0101_1001 ; 
  
    // Extract only the 12-bits of CIC-ed Ch1 data

    assign  data = S_AXIS_IN_tdata[27:16];
  
    // Handling of the state buffer for finding signal transition at the threshold
    always @(posedge clk) 
    begin
        if (~rst) 
            state <= 1'b0;
        else
            state <= state_next;
    end
    
    always @*            // logic for state buffer
    begin
        if (data > HIGH_THRESHOLD)
            state_next = 1;
        else if (data < LOW_THRESHOLD)
            state_next = 0;
        else
            state_next = state;
    end
    
    assign state_out = state ;

endmodule
