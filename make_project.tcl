# ==================================================================================================
# make_project.tcl
#
# Simple script for creating a Vivado project from the project/ folder 
# Based on Pavel Demin's red-pitaya-notes-master/ git project
#
# by Anton Potocnik, 02.10.2016 - 14.12.2017
# ==================================================================================================

set project_name "cic_diff_sg_error_signal"

source projects/$project_name/block_design.tcl
