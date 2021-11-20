`timescale 1ns / 1ps

// positive edge detection

module pos_edge_detection #
(
    parameter ADC_WIDTH = 12,
    parameter AXIS_TDATA_WIDTH = 16
)
(
    input                  state_in,
    input                  clk,
    input                  rst,
    output                 trigger
);
    
    reg                    state, state_next, trigger_reg ;
 
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
            trigger_reg <= state_next & (!state) ;
        end
    end
    
    always @*            
    begin
         state_next = state_in ;
    end

    assign trigger = trigger_reg;
    
endmodule
