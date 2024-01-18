
RTL := fpnew/src/fpnew_pkg.sv                                                         \
       fpnew/src/fpnew_classifier.sv                                                  \
       fpnew/src/common_cells/src/rr_arb_tree.sv                                      \
       fpnew/src/fpnew_opgroup_block.sv                                               \
       fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/clk/rtl/gated_clk_cell.v        \
       fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_ctrl.v         \
       fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_ff1.v          \
       fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_pack_single.v  \
       fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_prepare.v      \
       fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_round_single.v \
       fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_special.v      \
       fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_srt_single.v   \
       fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_top.v          \
       fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_dp.v             \
       fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_frbus.v          \
       fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_src_type.v       \
       fpnew/src/fpnew_fma.sv                                                         \
       fpnew/src/fpnew_noncomp.sv                                                     \
       fpnew/src/fpnew_opgroup_fmt_slice.sv                                           \
       fpnew/src/fpnew_opgroup_multifmt_slice.sv                                      \
       fpnew/src/fpnew_rounding.sv                                                    \
       fpnew/src/fpnew_top.sv

build/fpnew.sv: ${RTL} fpnew/src/common_cells/include/common_cells/registers.svh
	mkdir -p build
	cat ${RTL} | sed -e '/`include "common_cells\/registers.svh"/{r fpnew/src/common_cells/include/common_cells/registers.svh' -e 'd}' > $@

%.sv2v.v: %.sv
	sv2v $< > $@

sky130_fd_sc_hd__tt_025C_1v80.lib:
	wget https://raw.githubusercontent.com/efabless/skywater-pdk-libs-sky130_fd_sc_hd/master/timing/sky130_fd_sc_hd__tt_025C_1v80.lib

%.db: %.lib scripts/lc_shell.tcl
	LIB_FILE=$* lc_shell -no_log -no_init -64bit -f scripts/lc_shell.tcl

%.dc.v: %.sv sky130_fd_sc_hd__tt_025C_1v80.db scripts/dc_sv.tcl
	TOP_MODULE=$* design_vision -no_init -64bit -no_log -f scripts/dc_sv.tcl

%.dc.v: %.v sky130_fd_sc_hd__tt_025C_1v80.db scripts/dc_v.tcl
	TOP_MODULE=$* design_vision -no_init -64bit -no_log -f scripts/dc_v.tcl

clean:
	rm -rf build
