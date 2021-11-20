
# ==================================================================================================
# block_design.tcl - Create Vivado Project - 8_adc_differentiator_dac
#
# This script should be run from the base redpitaya-guides/ folder inside Vivado tcl console.
#
# This script is modification of Pavel Demin's project.tcl and block_design.tcl files
# by Anton Potocnik, 08.01.2017
# Tested with Vivado 2016.4
# ==================================================================================================

# Create basic Red Pitaya Block Design
source projects/$project_name/basic_red_pitaya_bd.tcl

# ====================================================================================
# Hierarchies

group_bd_cells PS7 [get_bd_cells processing_system7_0] [get_bd_cells rst_ps7_0_125M] [get_bd_cells ps7_0_axi_periph]

group_bd_cells TransmissionPeakDetection [get_bd_cells cic_0] [get_bd_cells cic_1] [get_bd_cells bcast_1] [get_bd_cells discriminator_0] [get_bd_cells differentiator_0] [get_bd_cells and_0] [get_bd_cells pos_edge_0]
 
