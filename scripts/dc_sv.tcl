
read_file -format sverilog -rtl $::env(TOP_MODULE).sv
set current_design fpnew_top
write_file -format verilog -output $::env(TOP_MODULE).dc.v

exit
