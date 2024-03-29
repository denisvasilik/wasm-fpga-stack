set project_origin "../"
set project_work  "work"
set project_name "WasmFpgaStack"
set project_part "xc7a100tcsg324-1"
set project_src  "src"
set project_resources "resources"
set project_ip "ip"
set project_tb "tb"
set project_package "package"

proc printMessage {outMsg} {
    puts " --------------------------------------------------------------------------------"
    puts " -- $outMsg"
    puts " --------------------------------------------------------------------------------"
}

printMessage "Project: ${project_name}   Part: ${project_part}   Source Folder: ${project_src}"

# Create project
printMessage "Create the Vivado project"
create_project ${project_name} ${project_work} -part ${project_part} -force

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [current_project]
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "${project_work}/${project_name}.cache/ip" -objects $obj
set_property -name "part" -value ${project_part} -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
set_property -name "target_language" -value "VHDL" -objects $obj
set_property -name "xpm_libraries" -value "XPM_CDC XPM_FIFO XPM_MEMORY" -objects $obj
set_property -name "xsim.array_display_limit" -value "64" -objects $obj

# Need to enable VHDL 2008
set_param project.enableVHDL2008 1

#------------------------------------------------------------------------
printMessage "Include VHDL files into project"

if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

set obj [get_filesets sources_1]
set files_vhd [list \
 [file normalize "${project_src}/WasmFpgaStack.vhd" ]\
 [file normalize "${project_src}/WasmFpgaStackPackage.vhd" ]\
 [file normalize "${project_resources}/wasmfpgastack.package.vhd" ]\
 [file normalize "${project_resources}/wasmfpgastack.wishbone.vhd" ]\
 [file normalize "${project_package}/component.xml" ]\
]
add_files -norecurse -fileset $obj $files_vhd

foreach i $files_vhd {
    set file_obj [get_files -of_objects [get_filesets sources_1] [file tail [list $i]]]
    set_property -name "file_type" -value "VHDL" -objects $file_obj
}

set file "${project_package}/component.xml"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "IP-XACT" -objects $file_obj

set obj [get_filesets sources_1]
set_property -name "top" -value "WasmFpgaStack" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj
set_property -name "top_file" -value "${project_src}/WasmFpgaStack.vhd" -objects $obj

#------------------------------------------------------------------------
printMessage "Adding simulation files..."

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
set files [list \
 "[file normalize "${project_tb}/tb_WasmFpgaStack.vhd"]"\
 "[file normalize "${project_tb}/tb_FileIo.vhd"]"\
 "[file normalize "${project_tb}/tb_pkg_helper.vhd"]"\
 "[file normalize "${project_tb}/tb_pkg.vhd"]"\
 "[file normalize "${project_tb}/tb_std_logic_1164_additions.vhd"]"\
 "[file normalize "${project_tb}/tb_Types.vhd"]"\
 "[file normalize "${project_tb}/tb_WbRam.vhd"]"\
]
add_files -norecurse -fileset $obj $files

foreach i $files {
    set file_obj [get_files -of_objects [get_filesets sim_1] [list $i]]
    set_property "file_type" "VHDL" $file_obj
}

#------------------------------------------------------------------------
# Block design and other IP inclusion
printMessage "Adding IP cores..."

set files [list \
 "[file normalize "${project_ip}/WasmFpgaTestBenchRam/WasmFpgaTestBenchRam.xci"]"\
]

add_files -fileset sources_1 $files

#------------------------------------------------------------------------
# Block design and other IP inclusion
printMessage "Adding files for simulation..."

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property "top" "tb_WasmFpgaStack" $obj

#------------------------------------------------------------------------
printMessage "Adding constraint files..."

#------------------------------------------------------------------------
close_project -verbose

#------------------------------------------------------------------------
printMessage "Project: ${project_name}   Part: ${project_part}   Source Folder: ${project_src}"
