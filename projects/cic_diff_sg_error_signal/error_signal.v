`timescale 1ns / 1ps

module error_signal #
(
    parameter DATA_WIDTH = 26,
    parameter START_BIT = 11    // Generate 12,11,10,9,8 ... and switch in RP to see which one is better
)
(
   (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
   // input data from divider, 8+24 bit but AXIS need 16 bit
   input [31:0]                      S_AXIS_in_tdata,  
   input                             S_AXIS_in_tvalid,
   input                             clk,
   input                             rst,
   input                             trigger_enable, // from neg edge triggerring from function generator
   input [31:0]                      gpio_setpoint,

   (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
   output [16-1:0]                   M_AXIS_out_tdata, // output error_signal to Red pitaya DAC , 10 bit but AXIS need 16
   output                            M_AXIS_out_tvalid 
);
   wire signed  [ DATA_WIDTH-1: 0]   divider_data ;
   wire signed  [ DATA_WIDTH-1: 0]   setpoint ;

   reg  signed  [ DATA_WIDTH-1: 0]   error ;
   reg  signed  [ DATA_WIDTH-1: 0]   difference ;
   reg  signed  [ DATA_WIDTH-1: 0]   error_new = 26'h0 ;
   reg  signed  [ DATA_WIDTH-1: 0]   upper_overload_threshold = 26'b00000000000000000010100011 ; //  350 mV = 163 roughly
   reg  signed  [ DATA_WIDTH-1: 0]   lower_overload_threshold = 26'b11111111111111111101011101 ; // -350 mV = -163 roughly

   assign  setpoint     = gpio_setpoint[DATA_WIDTH-1:0] ; // there is a default gpio value
   assign  divider_data = S_AXIS_in_tdata[DATA_WIDTH-1:0] ; // 2-bit integer + 24-bit fraction

   always @(posedge clk) 
   begin
      if (~rst) 
         begin
         error <= 26'h0 ;
         end
      else 
      begin
         if (trigger_enable == 1'b1) 
         begin
         error <= error_new ; 
         end
      end
   end 

   always @*            // logic for error_new
   begin
      difference = setpoint - divider_data - error  ; 

      if (( (difference > upper_overload_threshold) || (difference < lower_overload_threshold) ) == 1'b0) 
         begin
            error_new = setpoint - divider_data  ;
         end
   end

   assign M_AXIS_out_tdata  = { 6'b000000, error[START_BIT+9:START_BIT] } ; // only 10-bit error_signal goes to DAC
   assign M_AXIS_out_tvalid = S_AXIS_in_tvalid;

endmodule
