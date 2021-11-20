
`timescale 1 ns / 1 ps

module axis_constant #
(
  parameter integer AXIS_TDATA_WIDTH = 32
)
(
  // System signals
  input  wire                        aclk,
  input  wire                        state_data,

  // Master side
  // (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
  output wire [AXIS_TDATA_WIDTH-1:0] m_axis_tdata,
  output wire                        m_axis_tvalid
);

  // roughly 100mV = 46.45 in 10-bit version
  // {32{1'b1}} = -1 in 2's complement 
 
  assign m_axis_tdata = (state_data == 1'b1 ) ? {{16{1'b1}},16'b0000_0010_1111_1111} : {AXIS_TDATA_WIDTH{1'b1}} ;

  assign m_axis_tvalid = 1'b1;

endmodule
