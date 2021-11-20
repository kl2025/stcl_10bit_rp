
# create basic cores from examples
# ==================================================================================================
# block_design.tcl - Create Vivado Project - basic red pitaya block design
#
# This script should be run from the base redpitaya-guides/ folder inside Vivado tcl console.
#
# This script is modification of Pavel Demin's project.tcl and block_design.tcl files
# by Anton Potocnik, 29.11.2016
# Tested with Vivado 2016.3
# ==================================================================================================


### this implementation is for 10-bit Red Pitaya using 14-bit version code with the lowest 4-bits set as grounded 

#set project_name
set part_name xc7z010clg400-1
set bd_path tmp/$project_name/$project_name.srcs/sources_1/bd/system

file delete -force tmp/$project_name

create_project $project_name tmp/$project_name -part $part_name

create_bd_design system
# open_bd_design {$bd_path/system.bd}

# Load RedPitaya ports
source cfg/ports.tcl

# Set Path for the custom IP cores
set_property IP_REPO_PATHS tmp/cores [current_project]
update_ip_catalog


# Load any additional Verilog files in the project folder
set files [glob -nocomplain projects/$project_name/*.v projects/$project_name/*.sv]
if {[llength $files] > 0} {
  add_files -norecurse $files
}
#update_compile_order -fileset sources_1


# ====================================================================================
# IP cores

# Create clk_wiz
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz pll_0
set_property -dict [list CONFIG.PRIMITIVE {PLL}] [get_bd_cells pll_0]
set_property -dict [list CONFIG.PRIM_IN_FREQ.VALUE_SRC USER] [get_bd_cells pll_0]
set_property -dict [list \
   CONFIG.PRIM_IN_FREQ {125.0} \
   CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
   CONFIG.CLKOUT1_USED {true} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {125.0} \
   CONFIG.CLKOUT2_USED {true} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {250.0} \
   CONFIG.CLKOUT2_REQUESTED_PHASE {-90.0} \
   CONFIG.USE_RESET {false} \
   ] [get_bd_cells pll_0]
endgroup


# Zynq processing system with RedPitaya specific preset
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7 processing_system7_0
set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1}] [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_IMPORT_BOARD_PRESET {cfg/red_pitaya.xml}] [get_bd_cells processing_system7_0]
endgroup

# Buffers for differential IOs - Daisychain
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf_1
set_property -dict [list CONFIG.C_SIZE {2}] [get_bd_cells util_ds_buf_1]

create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf_2
set_property -dict [list CONFIG.C_SIZE {2}] [get_bd_cells util_ds_buf_2]
set_property -dict [list CONFIG.C_BUF_TYPE {OBUFDS}] [get_bd_cells util_ds_buf_2]
endgroup

# AXI GPIO IP core
# set default setpoint as 3429 in decimal and D65 in hex
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0
set_property -dict [list CONFIG.C_IS_DUAL {1} CONFIG.C_ALL_INPUTS_2 {1} CONFIG.C_GPIO_WIDTH {32} CONFIG.C_GPIO2_WIDTH {32} CONFIG.C_DOUT_DEFAULT {0x0062F60E}] [get_bd_cells axi_gpio_0]
endgroup


# Add IP core: axis_red_pitaya_adc
startgroup
create_bd_cell -type ip -vlnv pavel-demin:user:axis_red_pitaya_adc axis_red_pitaya_adc_0
endgroup

# Add IP core: axis_red_pitaya_dac
startgroup
create_bd_cell -type ip -vlnv pavel-demin:user:axis_red_pitaya_dac axis_red_pitaya_dac_0
endgroup

# Constant for AXIS aresetn constant = xlc_reset <= always 1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlc_reset
endgroup


# AND gate
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 and_0
set_property -dict [list CONFIG.C_size {1} CONFIG.C_OPERATION {and}] [get_bd_cells and_0]
endgroup


# AXIS Constant from Pavel Demin for testing
#create_bd_cell -type ip -vlnv pavel-demin:user:axis_constant axis_constant_0

# my_discriminator module
create_bd_cell -type module -reference discriminator discriminator_0

# my_differentiator module
create_bd_cell -type module -reference differentiator differentiator_0

# pos-edge-detection module
create_bd_cell -type module -reference pos_edge_detection pos_edge_0

# neg-edge-detection module
create_bd_cell -type module -reference neg_edge_detection neg_edge_0


# Create proc_sys_reset
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_0
endgroup


# Create axis_broadcaster_0 for ADC
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster bcast_0
set_property -dict [list CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells bcast_0]
set_property -dict [list CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells bcast_0]
set_property -dict [list \
   CONFIG.S_TDATA_NUM_BYTES {4} \
   CONFIG.M_TDATA_NUM_BYTES {2} \
   CONFIG.NUM_MI {2} \
   CONFIG.M00_TDATA_REMAP {tdata[15:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[31:16]} \
   ] [get_bd_cells bcast_0]
endgroup


# Create axis_broadcaster_1 after cic_1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster bcast_1
set_property -dict [list CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells bcast_1]
set_property -dict [list CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells bcast_1]
set_property -dict [list \
   CONFIG.S_TDATA_NUM_BYTES {4} \
   CONFIG.M_TDATA_NUM_BYTES {4} \
   CONFIG.NUM_MI {2} \
   CONFIG.M00_TDATA_REMAP {tdata[31:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[31:0]} \
   ] [get_bd_cells bcast_1]
endgroup


# Create axis_broadcaster_2 for divider result
# M00. go to PID_input's subset_converter
# M01. go to GPIO_2
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster bcast_2
set_property -dict [list CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells bcast_2]
set_property -dict [list CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells bcast_2]
set_property -dict [list \
   CONFIG.S_TDATA_NUM_BYTES {4} \
   CONFIG.M_TDATA_NUM_BYTES {4} \
   CONFIG.NUM_MI {2} \
   CONFIG.M00_TDATA_REMAP {tdata[31:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[31:0]} \
   ] [get_bd_cells bcast_2]
endgroup



# timer module
create_bd_cell -type module -reference my_timer timer_0


# Create divider_generator
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:div_gen div_gen_0
set_property -dict [list \
   CONFIG.dividend_and_quotient_width {24} \
   CONFIG.divisor_width {24} \
   CONFIG.remainder_type {Fractional} \
   CONFIG.fractional_width {24} \
   CONFIG.operand_sign {Unsigned} \
   ] [get_bd_cells div_gen_0]
endgroup


# CIC_decimation_0
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:cic_compiler cic_0
set_property -dict [list CONFIG.INPUT_DATA_WIDTH.VALUE_SRC USER] [get_bd_cells cic_0]
set_property -dict [list \
   CONFIG.FILTER_TYPE {Decimation} \
   CONFIG.NUMBER_OF_STAGES {6} \
   CONFIG.SAMPLE_RATE_CHANGES {Fixed} \
   CONFIG.FIXED_OR_INITIAL_RATE {512} \
   CONFIG.INPUT_SAMPLE_FREQUENCY {125} \
   CONFIG.CLOCK_FREQUENCY {125} \
   CONFIG.INPUT_DATA_WIDTH {16} \
   CONFIG.QUANTIZATION {Truncation} \
   CONFIG.OUTPUT_DATA_WIDTH {32} \
   CONFIG.USE_XTREME_DSP_SLICE {false} \
   CONFIG.HAS_ARESETN {true} \
   ] [get_bd_cells cic_0]
endgroup


# CIC_decimation_1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:cic_compiler cic_1
set_property -dict [list CONFIG.INPUT_DATA_WIDTH.VALUE_SRC USER] [get_bd_cells cic_1]
set_property -dict [list \
   CONFIG.FILTER_TYPE {Interpolation} \
   CONFIG.NUMBER_OF_STAGES {6} \
   CONFIG.SAMPLE_RATE_CHANGES {Fixed} \
   CONFIG.FIXED_OR_INITIAL_RATE {512} \
   CONFIG.INPUT_SAMPLE_FREQUENCY {0.244140625} \
   CONFIG.CLOCK_FREQUENCY {125} \
   CONFIG.INPUT_DATA_WIDTH {32} \
   CONFIG.QUANTIZATION {Truncation} \
   CONFIG.OUTPUT_DATA_WIDTH {32} \
   CONFIG.USE_XTREME_DSP_SLICE {false} \
   CONFIG.HAS_ARESETN {true} \
   ] [get_bd_cells cic_1]
endgroup


# subset_converter_0 for Divider_output , cutting 48 bit (24,24) into 32 bit
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter subset_0
set_property -dict [list CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells subset_0]
set_property -dict [list CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells subset_0]
set_property -dict [list \
   CONFIG.S_TDATA_NUM_BYTES {6} \
   CONFIG.M_TDATA_NUM_BYTES {4} \
   CONFIG.TDATA_REMAP {tdata[31:0]} \
   ] [get_bd_cells subset_0]
endgroup


# subset_converter_1 for GPIO_2 , 32 bit to 32 bit
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter subset_1
set_property -dict [list CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells subset_1]
set_property -dict [list CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells subset_1]
set_property -dict [list \
   CONFIG.S_TDATA_NUM_BYTES {4} \
   CONFIG.M_TDATA_NUM_BYTES {4} \
   CONFIG.TDATA_REMAP {tdata[31:0]} \
   ] [get_bd_cells subset_1]
endgroup


# subset_converter_3 for PID_output go to DAC
# out_ch2 is zero, out_ch1 is error signal
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter subset_3
set_property -dict [list CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells subset_3]
set_property -dict [list CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells subset_3]
set_property -dict [list \
   CONFIG.S_TDATA_NUM_BYTES {2} \
   CONFIG.M_TDATA_NUM_BYTES {4} \
   CONFIG.TDATA_REMAP {16'b1111111111111111,tdata[9],tdata[9],tdata[9:0],4'b1111} \
   ] [get_bd_cells subset_3]
endgroup


# subset_converter_4 for before cic
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter subset_4
set_property -dict [list CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells subset_4]
set_property -dict [list CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells subset_4]
set_property -dict [list \
   CONFIG.S_TDATA_NUM_BYTES {2} \
   CONFIG.M_TDATA_NUM_BYTES {2} \
   CONFIG.TDATA_REMAP {tdata[15],tdata[15],tdata[15],tdata[15],tdata[15:4]} \
   ] [get_bd_cells subset_4]
endgroup


# error_signal module
create_bd_cell -type module -reference error_signal error_signal_0


##### optional PID after error_signal module 

# PID module
#create_bd_cell -type module -reference red_pitaya_pid_block pid_0

# Constant for 14bit PID set_point = 0.418579
#startgroup
#create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_set_point
#set_property -dict [list CONFIG.CONST_VAL {b00110101100101} CONFIG.CONST_WIDTH {14}] [get_bd_cells const_set_point]
#endgroup

# Constant for 14bit PID K_p = 0.25
#startgroup
#create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_k_p
#set_property -dict [list CONFIG.CONST_VAL {b00010000000000} CONFIG.CONST_WIDTH {14}] [get_bd_cells const_k_p]
#endgroup

# Constant for 14bit PID K_i = 0
#startgroup
#create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_k_i
#set_property -dict [list CONFIG.CONST_VAL {b00000000000000} CONFIG.CONST_WIDTH {14}] [get_bd_cells const_k_i]
#endgroup

# Constant for 14bit PID K_d = 0
#startgroup
#create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_k_d
#set_property -dict [list CONFIG.CONST_VAL {b00000000000000} CONFIG.CONST_WIDTH {14}] [get_bd_cells const_k_d]
#endgroup

# subset_converter_2 for PID_output go to GPIO_1 , expand 16 bit to 32 bit 
# startgroup
# create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter subset_2
# set_property -dict [list CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells subset_2]
# set_property -dict [list CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells subset_2]
# set_property -dict [list \
# CONFIG.S_TDATA_NUM_BYTES {2} \
# CONFIG.M_TDATA_NUM_BYTES {4} \
# CONFIG.TDATA_REMAP {16'b0000000000000000,tdata[15:0]} \
# ] [get_bd_cells subset_2]
# endgroup

# Create axis_broadcaster_3 for PID output
# 1. go to GPIO_2's subset converter
# 2. go to DAC's subset converter
# startgroup
# create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster bcast_3
# set_property -dict [list CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells bcast_3]
# set_property -dict [list CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells bcast_3]
# set_property -dict [list \
#    CONFIG.S_TDATA_NUM_BYTES {2} \
#    CONFIG.M_TDATA_NUM_BYTES {2} \
#    CONFIG.NUM_MI {2} \
#    CONFIG.M00_TDATA_REMAP {tdata[15:0]} \
#    CONFIG.M01_TDATA_REMAP {tdata[15:0]} \
#    ] [get_bd_cells bcast_3]
# endgroup




# ====================================================================================
# Connections 

connect_bd_net [get_bd_ports daisy_p_i] [get_bd_pins util_ds_buf_1/IBUF_DS_P]
connect_bd_net [get_bd_ports daisy_n_i] [get_bd_pins util_ds_buf_1/IBUF_DS_N]
connect_bd_net [get_bd_ports daisy_p_o] [get_bd_pins util_ds_buf_2/OBUF_DS_P]
connect_bd_net [get_bd_ports daisy_n_o] [get_bd_pins util_ds_buf_2/OBUF_DS_N]
connect_bd_net [get_bd_pins util_ds_buf_1/IBUF_OUT] [get_bd_pins util_ds_buf_2/OBUF_IN]

apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

connect_bd_net [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins pll_0/clk_out1]
connect_bd_net [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] [get_bd_pins pll_0/clk_out1]



# connections for clk_wiz (pll_0) and ADC IP core
connect_bd_net [get_bd_ports adc_clk_p_i] [get_bd_pins pll_0/clk_in1_p]
connect_bd_net [get_bd_ports adc_clk_n_i] [get_bd_pins pll_0/clk_in1_n]
connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins axis_red_pitaya_adc_0/aclk]

connect_bd_net [get_bd_ports adc_dat_a_i] [get_bd_pins axis_red_pitaya_adc_0/adc_dat_a]
connect_bd_net [get_bd_ports adc_dat_b_i] [get_bd_pins axis_red_pitaya_adc_0/adc_dat_b]
connect_bd_net [get_bd_ports adc_csn_o] [get_bd_pins axis_red_pitaya_adc_0/adc_csn]



# connections for DAC IP core and more
connect_bd_net [get_bd_ports dac_clk_o] [get_bd_pins axis_red_pitaya_dac_0/dac_clk]
connect_bd_net [get_bd_ports dac_rst_o] [get_bd_pins axis_red_pitaya_dac_0/dac_rst]
connect_bd_net [get_bd_ports dac_sel_o] [get_bd_pins axis_red_pitaya_dac_0/dac_sel]
connect_bd_net [get_bd_ports dac_wrt_o] [get_bd_pins axis_red_pitaya_dac_0/dac_wrt]
connect_bd_net [get_bd_ports dac_dat_o] [get_bd_pins axis_red_pitaya_dac_0/dac_dat]

connect_bd_net [get_bd_pins pll_0/locked] [get_bd_pins axis_red_pitaya_dac_0/locked]
connect_bd_net [get_bd_pins pll_0/clk_out2] [get_bd_pins axis_red_pitaya_dac_0/ddr_clk]
connect_bd_net [get_bd_pins axis_red_pitaya_dac_0/aclk] [get_bd_pins pll_0/clk_out1]


# Discriminator & Differentiator connection

#connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins axis_constant_0/aclk]

connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins differentiator_0/clk]
connect_bd_net [get_bd_pins differentiator_0/rst] [get_bd_pins xlc_reset/dout]

connect_bd_net [get_bd_pins discriminator_0/rst] [get_bd_pins xlc_reset/dout]
connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins discriminator_0/clk]



# FLOW_CHART
connect_bd_intf_net [get_bd_intf_pins axis_red_pitaya_adc_0/M_AXIS] [get_bd_intf_pins bcast_0/S_AXIS] 
connect_bd_intf_net [get_bd_intf_pins bcast_0/M00_AXIS] [get_bd_intf_pins subset_4/S_AXIS] 
connect_bd_intf_net [get_bd_intf_pins subset_4/M_AXIS] [get_bd_intf_pins cic_0/S_AXIS_DATA] 
connect_bd_intf_net [get_bd_intf_pins cic_0/M_AXIS_DATA] [get_bd_intf_pins cic_1/S_AXIS_DATA]
connect_bd_intf_net [get_bd_intf_pins cic_1/M_AXIS_DATA] [get_bd_intf_pins bcast_1/S_AXIS]

connect_bd_intf_net [get_bd_intf_pins bcast_1/M00_AXIS] [get_bd_intf_pins discriminator_0/S_AXIS_IN]
connect_bd_intf_net [get_bd_intf_pins bcast_1/M01_AXIS] [get_bd_intf_pins differentiator_0/S_AXIS_IN]

connect_bd_net [get_bd_pins discriminator_0/state_out] [get_bd_pins and_0/Op1]
connect_bd_net [get_bd_pins differentiator_0/diff_state_out] [get_bd_pins and_0/Op2]

connect_bd_net [get_bd_pins and_0/Res] [get_bd_pins pos_edge_0/state_in]
connect_bd_intf_net [get_bd_intf_pins bcast_0/M01_AXIS] [get_bd_intf_pins neg_edge_0/S_AXIS_IN] 

connect_bd_net [get_bd_pins pos_edge_0/trigger] [get_bd_pins timer_0/peak_trigger]
connect_bd_net [get_bd_pins neg_edge_0/trigger] [get_bd_pins timer_0/piezo_ramp_trigger]



connect_bd_intf_net [get_bd_intf_pins timer_0/m_axis_sm_cycle] [get_bd_intf_pins div_gen_0/s_axis_dividend] 
connect_bd_intf_net [get_bd_intf_pins timer_0/m_axis_Mm_cycle] [get_bd_intf_pins div_gen_0/s_axis_divisor] 

connect_bd_intf_net [get_bd_intf_pins div_gen_0/M_AXIS_DOUT] [get_bd_intf_pins subset_0/S_AXIS] 
connect_bd_intf_net [get_bd_intf_pins subset_0/M_AXIS] [get_bd_intf_pins bcast_2/S_AXIS] 

connect_bd_intf_net [get_bd_intf_pins bcast_2/M00_AXIS] [get_bd_intf_pins subset_1/S_AXIS] 
connect_bd_intf_net [get_bd_intf_pins bcast_2/M01_AXIS] [get_bd_intf_pins error_signal_0/S_AXIS_in]
connect_bd_intf_net [get_bd_intf_pins error_signal_0/M_AXIS_out] [get_bd_intf_pins subset_3/S_AXIS]

#connect_bd_intf_net [get_bd_intf_pins pid_0/M_AXIS_dat_o] [get_bd_intf_pins bcast_3/S_AXIS]
#connect_bd_intf_net [get_bd_intf_pins bcast_3/M00_AXIS] [get_bd_intf_pins subset_2/S_AXIS]
#connect_bd_intf_net [get_bd_intf_pins bcast_3/M01_AXIS] [get_bd_intf_pins subset_3/S_AXIS]


connect_bd_intf_net [get_bd_intf_pins subset_3/M_AXIS] [get_bd_intf_pins axis_red_pitaya_dac_0/S_AXIS]


# connection for GPIO
connect_bd_net [get_bd_pins subset_1/M_AXIS_TDATA] [get_bd_pins axi_gpio_0/gpio2_io_i]

#connect_bd_net [get_bd_pins subset_2/M_AXIS_TDATA] [get_bd_pins axi_gpio_0/gpio2_io_i]

connect_bd_net [get_bd_pins error_signal_0/gpio_setpoint] [get_bd_pins axi_gpio_0/gpio_io_o]
connect_bd_net [get_bd_pins axi_gpio_0/gpio_io_i] [get_bd_pins axi_gpio_0/gpio_io_o]


# Connection for ALL Broadcaster_ 0/1/2/3
connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins bcast_0/aclk]
connect_bd_net [get_bd_pins bcast_0/aresetn] [get_bd_pins rst_0/peripheral_aresetn]

connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins bcast_1/aclk]
connect_bd_net [get_bd_pins bcast_1/aresetn] [get_bd_pins rst_0/peripheral_aresetn]

connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins bcast_2/aclk]
connect_bd_net [get_bd_pins bcast_2/aresetn] [get_bd_pins rst_0/peripheral_aresetn]

#connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins bcast_3/aclk]
#connect_bd_net [get_bd_pins bcast_3/aresetn] [get_bd_pins rst_0/peripheral_aresetn]


# connection for rst_0
connect_bd_net [get_bd_pins xlc_reset/dout] [get_bd_pins rst_0/ext_reset_in]
connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins rst_0/slowest_sync_clk]

# connection for cic_0 & cic_1
connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins cic_0/aclk]
connect_bd_net [get_bd_pins cic_0/aresetn] [get_bd_pins rst_0/peripheral_aresetn]

connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins cic_1/aclk]
connect_bd_net [get_bd_pins cic_1/aresetn] [get_bd_pins rst_0/peripheral_aresetn]


# connection for pos & neg_edge_0
connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins pos_edge_0/clk]
connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins neg_edge_0/clk]
connect_bd_net [get_bd_pins pos_edge_0/rst] [get_bd_pins xlc_reset/dout]
connect_bd_net [get_bd_pins neg_edge_0/rst] [get_bd_pins xlc_reset/dout]

# connection for timer_0
connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins timer_0/clk]
connect_bd_net [get_bd_pins timer_0/rst] [get_bd_pins xlc_reset/dout]


# connection for div_gen_0
connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins div_gen_0/aclk]



# Connection for subset_0/1/2/3/4

connect_bd_net [get_bd_pins subset_0/aresetn] [get_bd_pins rst_0/peripheral_aresetn]
connect_bd_net [get_bd_pins subset_1/aresetn] [get_bd_pins rst_0/peripheral_aresetn]
#connect_bd_net [get_bd_pins subset_2/aresetn] [get_bd_pins rst_0/peripheral_aresetn]
connect_bd_net [get_bd_pins subset_3/aresetn] [get_bd_pins rst_0/peripheral_aresetn]
connect_bd_net [get_bd_pins subset_4/aresetn] [get_bd_pins rst_0/peripheral_aresetn]

connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins subset_0/aclk]
connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins subset_1/aclk]
#connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins subset_2/aclk]
connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins subset_3/aclk]
connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins subset_4/aclk]


# connection for error_signal_0
connect_bd_net [get_bd_pins pll_0/clk_out1] [get_bd_pins error_signal_0/clk]
connect_bd_net [get_bd_pins error_signal_0/rst] [get_bd_pins xlc_reset/dout] 
connect_bd_net [get_bd_pins error_signal_0/trigger_enable] [get_bd_pins neg_edge_0/trigger] 

# pid connection
#connect_bd_net [get_bd_pins pid_0/clk] [get_bd_pins pll_0/clk_out1] 
#connect_bd_net [get_bd_pins pid_0/rstn_i] [get_bd_pins xlc_reset/dout] 
#connect_bd_net [get_bd_pins pid_0/trigger_enable] [get_bd_pins neg_edge_0/trigger] 

#connect_bd_net [get_bd_pins pid_0/set_sp_i] [get_bd_pins const_set_point/dout] 
#connect_bd_net [get_bd_pins pid_0/set_kp_i] [get_bd_pins const_k_p/dout] 
#connect_bd_net [get_bd_pins pid_0/set_ki_i] [get_bd_pins const_k_i/dout] 
#connect_bd_net [get_bd_pins pid_0/set_kd_i] [get_bd_pins const_k_d/dout] 
#connect_bd_net [get_bd_pins pid_0/int_rst_i] [get_bd_pins int_reset/dout] 


apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins axi_gpio_0/S_AXI]

set_property offset 0x42000000 [get_bd_addr_segs {processing_system7_0/Data/SEG_axi_gpio_0_Reg}]
set_property range 4K [get_bd_addr_segs {processing_system7_0/Data/SEG_axi_gpio_0_Reg}]

# ====================================================================================
# Generate output products and wrapper, add constraint 

generate_target all [get_files  $bd_path/system.bd]

make_wrapper -files [get_files $bd_path/system.bd] -top
add_files -norecurse $bd_path/hdl/system_wrapper.v


# Load RedPitaya constraint files
set files [glob -nocomplain cfg/*.xdc]
if {[llength $files] > 0} {
  add_files -norecurse -fileset constrs_1 $files
}

#set_property top system_wrapper [current_fileset]

set_property VERILOG_DEFINE {TOOL_VIVADO} [current_fileset]
set_property STRATEGY Flow_PerfOptimized_High [get_runs synth_1]
set_property STRATEGY Performance_NetDelay_high [get_runs impl_1]

