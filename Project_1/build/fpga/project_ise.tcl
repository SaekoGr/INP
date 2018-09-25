#============================================================================
# Run: 
#    xtclsh project_ise.tcl  - creates XILINX ISE project file
#    ise project_project.ise - opens the project
#============================================================================
source "../../../../../base/xilinxise.tcl"

project_new "project_project"
project_set_props
puts "Adding source files"
xfile add "../../fpga/ledc8x8.vhd"
puts "Adding simulation files"
xfile add "../../fpga/sim/ledc8x8_tb.vhd" -view Simulation
puts "Libraries"
project_set_isimscript "project_xsim.tcl"
project_set_top "ledc8x8"
project_close
