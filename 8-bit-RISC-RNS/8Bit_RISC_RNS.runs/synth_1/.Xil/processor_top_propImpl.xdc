set_property SRC_FILE_INFO {cfile:C:/code-projs/CIS4900/Cmod-A7-Master.xdc rfile:../../../../Cmod-A7-Master.xdc id:1} [current_design]
set_property src_info {type:XDC file:1 line:7 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports { sysclk }]; #IO_L12P_T1_MRCC_14 Sch=gclk
set_property src_info {type:XDC file:1 line:12 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN A17   IOSTANDARD LVCMOS33 } [get_ports { PLL_LOCK }]; #IO_L12N_T1_MRCC_16 Sch=led[1]
set_property src_info {type:XDC file:1 line:22 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33 } [get_ports { reset }]; #IO_L19N_T3_VREF_16 Sch=btn[0]
