
read_file -format verilog -rtl $::env(TOP_MODULE).v
set current_design fpnew_top
write_file -format verilog -output $::env(TOP_MODULE).dc.v

exit
