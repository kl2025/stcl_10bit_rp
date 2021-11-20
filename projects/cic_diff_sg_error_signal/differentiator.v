`timescale 1ns / 1ps

// Savitzky–Golay first order differentiator for LV input (+- 1V)
// apply shift register => find gradient => discriminator to detect zero crossing => set to 1'b1 when negative gradient

module differentiator #
(
    parameter ADC_WIDTH = 16,  
    parameter START_BIT = 5,
    parameter AXIS_TDATA_WIDTH = 32
)
(
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000, TDATA_NUM_BYTES 4" *)
    input [AXIS_TDATA_WIDTH-1:0]      S_AXIS_IN_tdata,
    input                             S_AXIS_IN_tvalid,
    input                             clk,
    input                             rst,
    output                            diff_state_out
);
    
    wire signed [ADC_WIDTH-1:0]       data_in; 

    reg  signed [ADC_WIDTH-1:0]       x_t_m1 = 16'd0; 
    reg  signed [ADC_WIDTH-1:0]       x_t_m2 = 16'd0; 
    reg  signed [ADC_WIDTH-1:0]       x_t_m3 = 16'd0; 
    reg  signed [ADC_WIDTH-1:0]       x_t_m4 = 16'd0; 
    reg                               state, state_next;
    reg  signed [ADC_WIDTH-1:0]       sum = 16'd0; 
    reg  signed [ADC_WIDTH-1:0]       gradient; 

    reg  signed [ADC_WIDTH-1:0]       zero_THRESHOLD   = 16'b0000_0000_0000_0000 ; 
    reg  signed [ADC_WIDTH-1:0]       upper_THRESHOLD  = 16'b0000_0000_0000_0011 ; // 3 is around 6mV
  
    // Extract only the 16-bits of CIC output

    assign  data_in = S_AXIS_IN_tdata[START_BIT+15:START_BIT];

    // Handling of data_in shift register 
    always @(posedge clk) 
    begin
        if (~rst) 
        begin
            x_t_m1 <= {ADC_WIDTH{1'b0}};  
            x_t_m2 <= {ADC_WIDTH{1'b0}};  
            x_t_m3 <= {ADC_WIDTH{1'b0}};  
            x_t_m4 <= {ADC_WIDTH{1'b0}};  
            sum    <= {ADC_WIDTH{1'b0}};  
        end
        else
        begin
        x_t_m1  <= data_in ;
        x_t_m2  <= x_t_m1 ;
        x_t_m3  <= x_t_m2 ;
        x_t_m4  <= x_t_m3 ;
        sum     <= (data_in <<< 1) + x_t_m1 - x_t_m3 - (x_t_m4 <<< 1) ; // SG filter for 1st derivative with 2 clk cycle delay
        end
    end

    // https://en.wikipedia.org/wiki/Savitzky%E2%80%93Golay_filter
    // SG 1st derivative equation is `gradient = sum/10` 
    // for zero crossing detection, optionally we can just use factor=1 
    always @* 
    begin
    gradient = sum ;   
    end


//  Schmitt trigger discriminator part

    always @(posedge clk) 
    begin
        if (~rst) 
            state <= 1'b0;
        else
            state <= state_next;
    end
    
    
    always @*       
    begin
        if (gradient <= zero_THRESHOLD)
            state_next = 1;
        else if (gradient > upper_THRESHOLD)
            state_next = 0;
        else
            state_next = state;
    end

    assign  diff_state_out = state ;

    
endmodule
