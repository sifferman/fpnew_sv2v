module fpnew_classifier (
	operands_i,
	is_boxed_i,
	info_o
);
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	function automatic [2:0] sv2v_cast_0BC43;
		input reg [2:0] inp;
		sv2v_cast_0BC43 = inp;
	endfunction
	parameter [2:0] FpFormat = sv2v_cast_0BC43(0);
	parameter [31:0] NumOperands = 1;
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	localparam [31:0] WIDTH = fpnew_pkg_fp_width(FpFormat);
	input wire [(NumOperands * WIDTH) - 1:0] operands_i;
	input wire [NumOperands - 1:0] is_boxed_i;
	output reg [(NumOperands * 8) - 1:0] info_o;
	function automatic [31:0] fpnew_pkg_exp_bits;
		input reg [2:0] fmt;
		fpnew_pkg_exp_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32];
	endfunction
	localparam [31:0] EXP_BITS = fpnew_pkg_exp_bits(FpFormat);
	function automatic [31:0] fpnew_pkg_man_bits;
		input reg [2:0] fmt;
		fpnew_pkg_man_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32];
	endfunction
	localparam [31:0] MAN_BITS = fpnew_pkg_man_bits(FpFormat);
	genvar op;
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
	generate
		for (op = 0; op < sv2v_cast_32_signed(NumOperands); op = op + 1) begin : gen_num_values
			reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] value;
			reg is_boxed;
			reg is_normal;
			reg is_inf;
			reg is_nan;
			reg is_signalling;
			reg is_quiet;
			reg is_zero;
			reg is_subnormal;
			always @(*) begin : classify_input
				value = operands_i[op * WIDTH+:WIDTH];
				is_boxed = is_boxed_i[op];
				is_normal = (is_boxed && (value[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)] != {((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1) * 1 {1'sb0}})) && (value[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)] != {((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1) * 1 {1'sb1}});
				is_zero = (is_boxed && (value[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)] == {((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1) * 1 {1'sb0}})) && (value[MAN_BITS - 1-:MAN_BITS] == {MAN_BITS * 1 {1'sb0}});
				is_subnormal = (is_boxed && (value[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)] == {((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1) * 1 {1'sb0}})) && !is_zero;
				is_inf = is_boxed && ((value[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)] == {((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1) * 1 {1'sb1}}) && (value[MAN_BITS - 1-:MAN_BITS] == {MAN_BITS * 1 {1'sb0}}));
				is_nan = !is_boxed || ((value[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)] == {((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1) * 1 {1'sb1}}) && (value[MAN_BITS - 1-:MAN_BITS] != {MAN_BITS * 1 {1'sb0}}));
				is_signalling = (is_boxed && is_nan) && (value[(MAN_BITS - 1) - ((MAN_BITS - 1) - (MAN_BITS - 1))] == 1'b0);
				is_quiet = is_nan && !is_signalling;
				info_o[(op * 8) + 7] = is_normal;
				info_o[(op * 8) + 6] = is_subnormal;
				info_o[(op * 8) + 5] = is_zero;
				info_o[(op * 8) + 4] = is_inf;
				info_o[(op * 8) + 3] = is_nan;
				info_o[(op * 8) + 2] = is_signalling;
				info_o[(op * 8) + 1] = is_quiet;
				info_o[op * 8] = is_boxed;
			end
		end
	endgenerate
endmodule
module rr_arb_tree_3B043_A8992 (
	clk_i,
	rst_ni,
	flush_i,
	rr_i,
	req_i,
	gnt_o,
	data_i,
	req_o,
	gnt_i,
	data_o,
	idx_o
);
	parameter [31:0] DataType_Width = 0;
	parameter [31:0] NumIn = 64;
	parameter [31:0] DataWidth = 32;
	parameter [0:0] ExtPrio = 1'b0;
	parameter [0:0] AxiVldRdy = 1'b0;
	parameter [0:0] LockIn = 1'b0;
	parameter [0:0] FairArb = 1'b1;
	parameter [31:0] IdxWidth = (NumIn > 32'd1 ? $unsigned($clog2(NumIn)) : 32'd1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire [IdxWidth - 1:0] rr_i;
	input wire [NumIn - 1:0] req_i;
	output wire [NumIn - 1:0] gnt_o;
	input wire [((DataType_Width + 6) >= 0 ? (NumIn * (DataType_Width + 7)) - 1 : (NumIn * (1 - (DataType_Width + 6))) + (DataType_Width + 5)):((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6)] data_i;
	output wire req_o;
	input wire gnt_i;
	output wire [DataType_Width + 6:0] data_o;
	output wire [IdxWidth - 1:0] idx_o;
	function automatic [IdxWidth - 1:0] sv2v_cast_29535;
		input reg [IdxWidth - 1:0] inp;
		sv2v_cast_29535 = inp;
	endfunction
	function automatic [((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)) - 1:0] sv2v_cast_DA0FF;
		input reg [((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)) - 1:0] inp;
		sv2v_cast_DA0FF = inp;
	endfunction
	generate
		if (NumIn == $unsigned(1)) begin : gen_pass_through
			assign req_o = req_i[0];
			assign gnt_o[0] = gnt_i;
			assign data_o = data_i[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + 0+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))];
			assign idx_o = 1'sb0;
		end
		else begin : gen_arbiter
			localparam [31:0] NumLevels = $unsigned($clog2(NumIn));
			wire [(((2 ** NumLevels) - 2) >= 0 ? (((2 ** NumLevels) - 1) * IdxWidth) - 1 : ((3 - (2 ** NumLevels)) * IdxWidth) + ((((2 ** NumLevels) - 2) * IdxWidth) - 1)):(((2 ** NumLevels) - 2) >= 0 ? 0 : ((2 ** NumLevels) - 2) * IdxWidth)] index_nodes;
			wire [(((2 ** NumLevels) - 2) >= 0 ? ((DataType_Width + 6) >= 0 ? (((2 ** NumLevels) - 1) * (DataType_Width + 7)) - 1 : (((2 ** NumLevels) - 1) * (1 - (DataType_Width + 6))) + (DataType_Width + 5)) : ((DataType_Width + 6) >= 0 ? ((3 - (2 ** NumLevels)) * (DataType_Width + 7)) + ((((2 ** NumLevels) - 2) * (DataType_Width + 7)) - 1) : ((3 - (2 ** NumLevels)) * (1 - (DataType_Width + 6))) + (((DataType_Width + 6) + (((2 ** NumLevels) - 2) * (1 - (DataType_Width + 6)))) - 1))):(((2 ** NumLevels) - 2) >= 0 ? ((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) : ((DataType_Width + 6) >= 0 ? ((2 ** NumLevels) - 2) * (DataType_Width + 7) : (DataType_Width + 6) + (((2 ** NumLevels) - 2) * (1 - (DataType_Width + 6)))))] data_nodes;
			wire [(2 ** NumLevels) - 2:0] gnt_nodes;
			wire [(2 ** NumLevels) - 2:0] req_nodes;
			reg [IdxWidth - 1:0] rr_q;
			wire [NumIn - 1:0] req_d;
			assign req_o = req_nodes[0];
			assign data_o = data_nodes[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((((2 ** NumLevels) - 2) >= 0 ? 0 : (2 ** NumLevels) - 2) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))];
			assign idx_o = index_nodes[(((2 ** NumLevels) - 2) >= 0 ? 0 : (2 ** NumLevels) - 2) * IdxWidth+:IdxWidth];
			if (ExtPrio) begin : gen_ext_rr
				wire [IdxWidth:1] sv2v_tmp_4C2F0;
				assign sv2v_tmp_4C2F0 = rr_i;
				always @(*) rr_q = sv2v_tmp_4C2F0;
				assign req_d = req_i;
			end
			else begin : gen_int_rr
				wire [IdxWidth - 1:0] rr_d;
				if (LockIn) begin : gen_lock
					wire lock_d;
					reg lock_q;
					reg [NumIn - 1:0] req_q;
					assign lock_d = req_o & ~gnt_i;
					assign req_d = (lock_q ? req_q : req_i);
					always @(posedge clk_i or negedge rst_ni) begin : p_lock_reg
						if (!rst_ni)
							lock_q <= 1'sb0;
						else if (flush_i)
							lock_q <= 1'sb0;
						else
							lock_q <= lock_d;
					end
					always @(posedge clk_i or negedge rst_ni) begin : p_req_regs
						if (!rst_ni)
							req_q <= 1'sb0;
						else if (flush_i)
							req_q <= 1'sb0;
						else
							req_q <= req_d;
					end
				end
				else begin : gen_no_lock
					assign req_d = req_i;
				end
				if (FairArb) begin : gen_fair_arb
					wire [NumIn - 1:0] upper_mask;
					wire [NumIn - 1:0] lower_mask;
					wire [IdxWidth - 1:0] upper_idx;
					wire [IdxWidth - 1:0] lower_idx;
					wire [IdxWidth - 1:0] next_idx;
					wire upper_empty;
					wire lower_empty;
					genvar i;
					for (i = 0; i < NumIn; i = i + 1) begin : gen_mask
						assign upper_mask[i] = (i > rr_q ? req_d[i] : 1'b0);
						assign lower_mask[i] = (i <= rr_q ? req_d[i] : 1'b0);
					end
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_upper(
						.in_i(upper_mask),
						.cnt_o(upper_idx),
						.empty_o(upper_empty)
					);
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_lower(
						.in_i(lower_mask),
						.cnt_o(lower_idx),
						.empty_o()
					);
					assign next_idx = (upper_empty ? lower_idx : upper_idx);
					assign rr_d = (gnt_i && req_o ? next_idx : rr_q);
				end
				else begin : gen_unfair_arb
					assign rr_d = (gnt_i && req_o ? (rr_q == sv2v_cast_29535(NumIn - 1) ? {IdxWidth {1'sb0}} : rr_q + 1'b1) : rr_q);
				end
				always @(posedge clk_i or negedge rst_ni) begin : p_rr_regs
					if (!rst_ni)
						rr_q <= 1'sb0;
					else if (flush_i)
						rr_q <= 1'sb0;
					else
						rr_q <= rr_d;
				end
			end
			assign gnt_nodes[0] = gnt_i;
			genvar level;
			for (level = 0; $unsigned(level) < NumLevels; level = level + 1) begin : gen_levels
				genvar l;
				for (l = 0; l < (2 ** level); l = l + 1) begin : gen_level
					wire sel;
					localparam [31:0] Idx0 = ((2 ** level) - 1) + l;
					localparam [31:0] Idx1 = ((2 ** (level + 1)) - 1) + (l * 2);
					if ($unsigned(level) == (NumLevels - 1)) begin : gen_first_level
						if (($unsigned(l) * 2) < (NumIn - 1)) begin : gen_reduce
							assign req_nodes[Idx0] = req_d[l * 2] | req_d[(l * 2) + 1];
							assign sel = ~req_d[l * 2] | (req_d[(l * 2) + 1] & rr_q[(NumLevels - 1) - level]);
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_29535(sel);
							assign data_nodes[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))] = (sel ? data_i[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + (((l * 2) + 1) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))] : data_i[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((l * 2) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))]);
							assign gnt_o[l * 2] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2])) & ~sel;
							assign gnt_o[(l * 2) + 1] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[(l * 2) + 1])) & sel;
						end
						if (($unsigned(l) * 2) == (NumIn - 1)) begin : gen_first
							assign req_nodes[Idx0] = req_d[l * 2];
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = 1'sb0;
							assign data_nodes[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))] = data_i[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((l * 2) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))];
							assign gnt_o[l * 2] = gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2]);
						end
						if (($unsigned(l) * 2) > (NumIn - 1)) begin : gen_out_of_range
							assign req_nodes[Idx0] = 1'b0;
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_29535(1'sb0);
							assign data_nodes[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))] = sv2v_cast_DA0FF(1'sb0);
						end
					end
					else begin : gen_other_levels
						assign req_nodes[Idx0] = req_nodes[Idx1] | req_nodes[Idx1 + 1];
						assign sel = ~req_nodes[Idx1] | (req_nodes[Idx1 + 1] & rr_q[(NumLevels - 1) - level]);
						assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = (sel ? sv2v_cast_29535({1'b1, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 + 1 : ((2 ** NumLevels) - 2) - (Idx1 + 1)) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}) : sv2v_cast_29535({1'b0, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 : ((2 ** NumLevels) - 2) - Idx1) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}));
						assign data_nodes[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))] = (sel ? data_nodes[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((((2 ** NumLevels) - 2) >= 0 ? Idx1 + 1 : ((2 ** NumLevels) - 2) - (Idx1 + 1)) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))] : data_nodes[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((((2 ** NumLevels) - 2) >= 0 ? Idx1 : ((2 ** NumLevels) - 2) - Idx1) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))]);
						assign gnt_nodes[Idx1] = gnt_nodes[Idx0] & ~sel;
						assign gnt_nodes[Idx1 + 1] = gnt_nodes[Idx0] & sel;
					end
				end
			end
		end
	endgenerate
endmodule
module rr_arb_tree_02E82_EBE23 (
	clk_i,
	rst_ni,
	flush_i,
	rr_i,
	req_i,
	gnt_o,
	data_i,
	req_o,
	gnt_i,
	data_o,
	idx_o
);
	parameter [31:0] DataType_WIDTH = 0;
	parameter [31:0] NumIn = 64;
	parameter [31:0] DataWidth = 32;
	parameter [0:0] ExtPrio = 1'b0;
	parameter [0:0] AxiVldRdy = 1'b0;
	parameter [0:0] LockIn = 1'b0;
	parameter [0:0] FairArb = 1'b1;
	parameter [31:0] IdxWidth = (NumIn > 32'd1 ? $unsigned($clog2(NumIn)) : 32'd1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire [IdxWidth - 1:0] rr_i;
	input wire [NumIn - 1:0] req_i;
	output wire [NumIn - 1:0] gnt_o;
	input wire [((DataType_WIDTH + 5) >= 0 ? (NumIn * (DataType_WIDTH + 6)) - 1 : (NumIn * (1 - (DataType_WIDTH + 5))) + (DataType_WIDTH + 4)):((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5)] data_i;
	output wire req_o;
	input wire gnt_i;
	output wire [DataType_WIDTH + 5:0] data_o;
	output wire [IdxWidth - 1:0] idx_o;
	function automatic [IdxWidth - 1:0] sv2v_cast_29535;
		input reg [IdxWidth - 1:0] inp;
		sv2v_cast_29535 = inp;
	endfunction
	function automatic [((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)) - 1:0] sv2v_cast_52D5E;
		input reg [((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)) - 1:0] inp;
		sv2v_cast_52D5E = inp;
	endfunction
	generate
		if (NumIn == $unsigned(1)) begin : gen_pass_through
			assign req_o = req_i[0];
			assign gnt_o[0] = gnt_i;
			assign data_o = data_i[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + 0+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))];
			assign idx_o = 1'sb0;
		end
		else begin : gen_arbiter
			localparam [31:0] NumLevels = $unsigned($clog2(NumIn));
			wire [(((2 ** NumLevels) - 2) >= 0 ? (((2 ** NumLevels) - 1) * IdxWidth) - 1 : ((3 - (2 ** NumLevels)) * IdxWidth) + ((((2 ** NumLevels) - 2) * IdxWidth) - 1)):(((2 ** NumLevels) - 2) >= 0 ? 0 : ((2 ** NumLevels) - 2) * IdxWidth)] index_nodes;
			wire [(((2 ** NumLevels) - 2) >= 0 ? ((DataType_WIDTH + 5) >= 0 ? (((2 ** NumLevels) - 1) * (DataType_WIDTH + 6)) - 1 : (((2 ** NumLevels) - 1) * (1 - (DataType_WIDTH + 5))) + (DataType_WIDTH + 4)) : ((DataType_WIDTH + 5) >= 0 ? ((3 - (2 ** NumLevels)) * (DataType_WIDTH + 6)) + ((((2 ** NumLevels) - 2) * (DataType_WIDTH + 6)) - 1) : ((3 - (2 ** NumLevels)) * (1 - (DataType_WIDTH + 5))) + (((DataType_WIDTH + 5) + (((2 ** NumLevels) - 2) * (1 - (DataType_WIDTH + 5)))) - 1))):(((2 ** NumLevels) - 2) >= 0 ? ((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) : ((DataType_WIDTH + 5) >= 0 ? ((2 ** NumLevels) - 2) * (DataType_WIDTH + 6) : (DataType_WIDTH + 5) + (((2 ** NumLevels) - 2) * (1 - (DataType_WIDTH + 5)))))] data_nodes;
			wire [(2 ** NumLevels) - 2:0] gnt_nodes;
			wire [(2 ** NumLevels) - 2:0] req_nodes;
			reg [IdxWidth - 1:0] rr_q;
			wire [NumIn - 1:0] req_d;
			assign req_o = req_nodes[0];
			assign data_o = data_nodes[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((((2 ** NumLevels) - 2) >= 0 ? 0 : (2 ** NumLevels) - 2) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))];
			assign idx_o = index_nodes[(((2 ** NumLevels) - 2) >= 0 ? 0 : (2 ** NumLevels) - 2) * IdxWidth+:IdxWidth];
			if (ExtPrio) begin : gen_ext_rr
				wire [IdxWidth:1] sv2v_tmp_4C2F0;
				assign sv2v_tmp_4C2F0 = rr_i;
				always @(*) rr_q = sv2v_tmp_4C2F0;
				assign req_d = req_i;
			end
			else begin : gen_int_rr
				wire [IdxWidth - 1:0] rr_d;
				if (LockIn) begin : gen_lock
					wire lock_d;
					reg lock_q;
					reg [NumIn - 1:0] req_q;
					assign lock_d = req_o & ~gnt_i;
					assign req_d = (lock_q ? req_q : req_i);
					always @(posedge clk_i or negedge rst_ni) begin : p_lock_reg
						if (!rst_ni)
							lock_q <= 1'sb0;
						else if (flush_i)
							lock_q <= 1'sb0;
						else
							lock_q <= lock_d;
					end
					always @(posedge clk_i or negedge rst_ni) begin : p_req_regs
						if (!rst_ni)
							req_q <= 1'sb0;
						else if (flush_i)
							req_q <= 1'sb0;
						else
							req_q <= req_d;
					end
				end
				else begin : gen_no_lock
					assign req_d = req_i;
				end
				if (FairArb) begin : gen_fair_arb
					wire [NumIn - 1:0] upper_mask;
					wire [NumIn - 1:0] lower_mask;
					wire [IdxWidth - 1:0] upper_idx;
					wire [IdxWidth - 1:0] lower_idx;
					wire [IdxWidth - 1:0] next_idx;
					wire upper_empty;
					wire lower_empty;
					genvar i;
					for (i = 0; i < NumIn; i = i + 1) begin : gen_mask
						assign upper_mask[i] = (i > rr_q ? req_d[i] : 1'b0);
						assign lower_mask[i] = (i <= rr_q ? req_d[i] : 1'b0);
					end
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_upper(
						.in_i(upper_mask),
						.cnt_o(upper_idx),
						.empty_o(upper_empty)
					);
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_lower(
						.in_i(lower_mask),
						.cnt_o(lower_idx),
						.empty_o()
					);
					assign next_idx = (upper_empty ? lower_idx : upper_idx);
					assign rr_d = (gnt_i && req_o ? next_idx : rr_q);
				end
				else begin : gen_unfair_arb
					assign rr_d = (gnt_i && req_o ? (rr_q == sv2v_cast_29535(NumIn - 1) ? {IdxWidth {1'sb0}} : rr_q + 1'b1) : rr_q);
				end
				always @(posedge clk_i or negedge rst_ni) begin : p_rr_regs
					if (!rst_ni)
						rr_q <= 1'sb0;
					else if (flush_i)
						rr_q <= 1'sb0;
					else
						rr_q <= rr_d;
				end
			end
			assign gnt_nodes[0] = gnt_i;
			genvar level;
			for (level = 0; $unsigned(level) < NumLevels; level = level + 1) begin : gen_levels
				genvar l;
				for (l = 0; l < (2 ** level); l = l + 1) begin : gen_level
					wire sel;
					localparam [31:0] Idx0 = ((2 ** level) - 1) + l;
					localparam [31:0] Idx1 = ((2 ** (level + 1)) - 1) + (l * 2);
					if ($unsigned(level) == (NumLevels - 1)) begin : gen_first_level
						if (($unsigned(l) * 2) < (NumIn - 1)) begin : gen_reduce
							assign req_nodes[Idx0] = req_d[l * 2] | req_d[(l * 2) + 1];
							assign sel = ~req_d[l * 2] | (req_d[(l * 2) + 1] & rr_q[(NumLevels - 1) - level]);
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_29535(sel);
							assign data_nodes[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))] = (sel ? data_i[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + (((l * 2) + 1) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))] : data_i[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((l * 2) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))]);
							assign gnt_o[l * 2] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2])) & ~sel;
							assign gnt_o[(l * 2) + 1] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[(l * 2) + 1])) & sel;
						end
						if (($unsigned(l) * 2) == (NumIn - 1)) begin : gen_first
							assign req_nodes[Idx0] = req_d[l * 2];
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = 1'sb0;
							assign data_nodes[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))] = data_i[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((l * 2) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))];
							assign gnt_o[l * 2] = gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2]);
						end
						if (($unsigned(l) * 2) > (NumIn - 1)) begin : gen_out_of_range
							assign req_nodes[Idx0] = 1'b0;
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_29535(1'sb0);
							assign data_nodes[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))] = sv2v_cast_52D5E(1'sb0);
						end
					end
					else begin : gen_other_levels
						assign req_nodes[Idx0] = req_nodes[Idx1] | req_nodes[Idx1 + 1];
						assign sel = ~req_nodes[Idx1] | (req_nodes[Idx1 + 1] & rr_q[(NumLevels - 1) - level]);
						assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = (sel ? sv2v_cast_29535({1'b1, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 + 1 : ((2 ** NumLevels) - 2) - (Idx1 + 1)) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}) : sv2v_cast_29535({1'b0, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 : ((2 ** NumLevels) - 2) - Idx1) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}));
						assign data_nodes[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))] = (sel ? data_nodes[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((((2 ** NumLevels) - 2) >= 0 ? Idx1 + 1 : ((2 ** NumLevels) - 2) - (Idx1 + 1)) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))] : data_nodes[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((((2 ** NumLevels) - 2) >= 0 ? Idx1 : ((2 ** NumLevels) - 2) - Idx1) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))]);
						assign gnt_nodes[Idx1] = gnt_nodes[Idx0] & ~sel;
						assign gnt_nodes[Idx1 + 1] = gnt_nodes[Idx0] & sel;
					end
				end
			end
		end
	endgenerate
endmodule
module fpnew_opgroup_block_E7A9E (
	clk_i,
	rst_ni,
	operands_i,
	is_boxed_i,
	rnd_mode_i,
	op_i,
	op_mod_i,
	src_fmt_i,
	dst_fmt_i,
	int_fmt_i,
	vectorial_op_i,
	tag_i,
	simd_mask_i,
	in_valid_i,
	in_ready_o,
	flush_i,
	result_o,
	status_o,
	extension_bit_o,
	tag_o,
	out_valid_o,
	out_ready_i,
	busy_o
);
	parameter [1:0] OpGroup = 2'd0;
	parameter [31:0] Width = 32;
	parameter [0:0] EnableVectors = 1'b1;
	parameter [0:0] PulpDivsqrt = 1'b1;
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	parameter [0:4] FpFmtMask = 1'sb1;
	localparam [31:0] fpnew_pkg_NUM_INT_FORMATS = 4;
	parameter [0:3] IntFmtMask = 1'sb1;
	parameter [159:0] FmtPipeRegs = {fpnew_pkg_NUM_FP_FORMATS {32'd0}};
	parameter [9:0] FmtUnitTypes = {fpnew_pkg_NUM_FP_FORMATS {2'd1}};
	parameter [1:0] PipeConfig = 2'd0;
	parameter [31:0] TrueSIMDClass = 0;
	localparam [31:0] NUM_FORMATS = fpnew_pkg_NUM_FP_FORMATS;
	function automatic [31:0] fpnew_pkg_num_operands;
		input reg [1:0] grp;
		case (grp)
			2'd0: fpnew_pkg_num_operands = 3;
			2'd1: fpnew_pkg_num_operands = 2;
			2'd2: fpnew_pkg_num_operands = 2;
			2'd3: fpnew_pkg_num_operands = 3;
			default: fpnew_pkg_num_operands = 0;
		endcase
	endfunction
	localparam [31:0] NUM_OPERANDS = fpnew_pkg_num_operands(OpGroup);
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	function automatic signed [31:0] fpnew_pkg_maximum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_maximum = (a > b ? a : b);
	endfunction
	function automatic [2:0] sv2v_cast_0BC43;
		input reg [2:0] inp;
		sv2v_cast_0BC43 = inp;
	endfunction
	function automatic [31:0] fpnew_pkg_max_fp_width;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = 0;
			begin : sv2v_autoblock_1
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i])
						res = $unsigned(fpnew_pkg_maximum(res, fpnew_pkg_fp_width(sv2v_cast_0BC43(i))));
			end
			fpnew_pkg_max_fp_width = res;
		end
	endfunction
	function automatic signed [31:0] fpnew_pkg_minimum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_minimum = (a < b ? a : b);
	endfunction
	function automatic [31:0] fpnew_pkg_min_fp_width;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = fpnew_pkg_max_fp_width(cfg);
			begin : sv2v_autoblock_2
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i])
						res = $unsigned(fpnew_pkg_minimum(res, fpnew_pkg_fp_width(sv2v_cast_0BC43(i))));
			end
			fpnew_pkg_min_fp_width = res;
		end
	endfunction
	function automatic [31:0] fpnew_pkg_max_num_lanes;
		input reg [31:0] width;
		input reg [0:4] cfg;
		input reg vec;
		fpnew_pkg_max_num_lanes = (vec ? width / fpnew_pkg_min_fp_width(cfg) : 1);
	endfunction
	localparam [31:0] NUM_LANES = fpnew_pkg_max_num_lanes(Width, FpFmtMask, EnableVectors);
	input wire clk_i;
	input wire rst_ni;
	input wire [(NUM_OPERANDS * Width) - 1:0] operands_i;
	input wire [(NUM_FORMATS * NUM_OPERANDS) - 1:0] is_boxed_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire op_mod_i;
	input wire [2:0] src_fmt_i;
	input wire [2:0] dst_fmt_i;
	localparam [31:0] fpnew_pkg_INT_FORMAT_BITS = 2;
	input wire [1:0] int_fmt_i;
	input wire vectorial_op_i;
	input wire tag_i;
	input wire [NUM_LANES - 1:0] simd_mask_i;
	input wire in_valid_i;
	output wire in_ready_o;
	input wire flush_i;
	output wire [Width - 1:0] result_o;
	output wire [4:0] status_o;
	output wire extension_bit_o;
	output wire tag_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	wire [4:0] fmt_in_ready;
	wire [4:0] fmt_out_valid;
	wire [4:0] fmt_out_ready;
	wire [4:0] fmt_busy;
	wire [((Width + 6) >= 0 ? (5 * (Width + 7)) - 1 : (5 * (1 - (Width + 6))) + (Width + 5)):((Width + 6) >= 0 ? 0 : Width + 6)] fmt_outputs;
	assign in_ready_o = in_valid_i & fmt_in_ready[dst_fmt_i];
	genvar fmt;
	localparam [0:0] fpnew_pkg_DONT_CARE = 1'b1;
	function automatic fpnew_pkg_any_enabled_multi;
		input reg [9:0] types;
		input reg [0:4] cfg;
		reg [0:1] _sv2v_jump;
		begin
			_sv2v_jump = 2'b00;
			begin : sv2v_autoblock_3
				reg [31:0] i;
				begin : sv2v_autoblock_4
					reg [31:0] _sv2v_value_on_break;
					for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
						if (_sv2v_jump < 2'b10) begin
							_sv2v_jump = 2'b00;
							if (cfg[i] && (types[(4 - i) * 2+:2] == 2'd2)) begin
								fpnew_pkg_any_enabled_multi = 1'b1;
								_sv2v_jump = 2'b11;
							end
							_sv2v_value_on_break = i;
						end
					if (!(_sv2v_jump < 2'b10))
						i = _sv2v_value_on_break;
					if (_sv2v_jump != 2'b11)
						_sv2v_jump = 2'b00;
				end
			end
			if (_sv2v_jump == 2'b00) begin
				fpnew_pkg_any_enabled_multi = 1'b0;
				_sv2v_jump = 2'b11;
			end
		end
	endfunction
	function automatic [2:0] fpnew_pkg_get_first_enabled_multi;
		input reg [9:0] types;
		input reg [0:4] cfg;
		reg [0:1] _sv2v_jump;
		begin
			_sv2v_jump = 2'b00;
			begin : sv2v_autoblock_5
				reg [31:0] i;
				begin : sv2v_autoblock_6
					reg [31:0] _sv2v_value_on_break;
					for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
						if (_sv2v_jump < 2'b10) begin
							_sv2v_jump = 2'b00;
							if (cfg[i] && (types[(4 - i) * 2+:2] == 2'd2)) begin
								fpnew_pkg_get_first_enabled_multi = sv2v_cast_0BC43(i);
								_sv2v_jump = 2'b11;
							end
							_sv2v_value_on_break = i;
						end
					if (!(_sv2v_jump < 2'b10))
						i = _sv2v_value_on_break;
					if (_sv2v_jump != 2'b11)
						_sv2v_jump = 2'b00;
				end
			end
			if (_sv2v_jump == 2'b00) begin
				fpnew_pkg_get_first_enabled_multi = sv2v_cast_0BC43(0);
				_sv2v_jump = 2'b11;
			end
		end
	endfunction
	function automatic fpnew_pkg_is_first_enabled_multi;
		input reg [2:0] fmt;
		input reg [9:0] types;
		input reg [0:4] cfg;
		reg [0:1] _sv2v_jump;
		begin
			_sv2v_jump = 2'b00;
			begin : sv2v_autoblock_7
				reg [31:0] i;
				begin : sv2v_autoblock_8
					reg [31:0] _sv2v_value_on_break;
					for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
						if (_sv2v_jump < 2'b10) begin
							_sv2v_jump = 2'b00;
							if (cfg[i] && (types[(4 - i) * 2+:2] == 2'd2)) begin
								fpnew_pkg_is_first_enabled_multi = sv2v_cast_0BC43(i) == fmt;
								_sv2v_jump = 2'b11;
							end
							_sv2v_value_on_break = i;
						end
					if (!(_sv2v_jump < 2'b10))
						i = _sv2v_value_on_break;
					if (_sv2v_jump != 2'b11)
						_sv2v_jump = 2'b00;
				end
			end
			if (_sv2v_jump == 2'b00) begin
				fpnew_pkg_is_first_enabled_multi = 1'b0;
				_sv2v_jump = 2'b11;
			end
		end
	endfunction
	function automatic [31:0] fpnew_pkg_num_lanes;
		input reg [31:0] width;
		input reg [2:0] fmt;
		input reg vec;
		fpnew_pkg_num_lanes = (vec ? width / fpnew_pkg_fp_width(fmt) : 1);
	endfunction
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	generate
		for (fmt = 0; fmt < sv2v_cast_32_signed(NUM_FORMATS); fmt = fmt + 1) begin : gen_parallel_slices
			localparam [0:0] ANY_MERGED = fpnew_pkg_any_enabled_multi(FmtUnitTypes, FpFmtMask);
			localparam [0:0] IS_FIRST_MERGED = fpnew_pkg_is_first_enabled_multi(sv2v_cast_0BC43(fmt), FmtUnitTypes, FpFmtMask);
			if (FpFmtMask[fmt] && (FmtUnitTypes[(4 - fmt) * 2+:2] == 2'd1)) begin : active_format
				wire in_valid;
				assign in_valid = in_valid_i & (dst_fmt_i == fmt);
				localparam [31:0] INTERNAL_LANES = fpnew_pkg_num_lanes(Width, sv2v_cast_0BC43(fmt), EnableVectors);
				reg [INTERNAL_LANES - 1:0] mask_slice;
				always @(*) begin : sv2v_autoblock_9
					reg signed [31:0] b;
					for (b = 0; b < INTERNAL_LANES; b = b + 1)
						mask_slice[b] = simd_mask_i[(NUM_LANES / INTERNAL_LANES) * b];
				end
				localparam [31:0] sv2v_uu_i_fmt_slice_NumPipeRegs = FmtPipeRegs[(4 - fmt) * 32+:32];
				localparam [31:0] sv2v_uu_i_fmt_slice_ExtRegEnaWidth = (sv2v_uu_i_fmt_slice_NumPipeRegs == 0 ? 1 : sv2v_uu_i_fmt_slice_NumPipeRegs);
				localparam [sv2v_cast_32((sv2v_cast_32(FmtPipeRegs[(4 - fmt) * 32+:32]) == 0 ? 1 : sv2v_cast_32(FmtPipeRegs[(4 - fmt) * 32+:32]))) - 1:0] sv2v_uu_i_fmt_slice_ext_reg_ena_i_0 = 1'sb0;
				fpnew_opgroup_fmt_slice_09303 #(
					.OpGroup(OpGroup),
					.FpFormat(sv2v_cast_0BC43(fmt)),
					.Width(Width),
					.EnableVectors(EnableVectors),
					.NumPipeRegs(FmtPipeRegs[(4 - fmt) * 32+:32]),
					.PipeConfig(PipeConfig),
					.TrueSIMDClass(TrueSIMDClass)
				) i_fmt_slice(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.operands_i(operands_i),
					.is_boxed_i(is_boxed_i[fmt * NUM_OPERANDS+:NUM_OPERANDS]),
					.rnd_mode_i(rnd_mode_i),
					.op_i(op_i),
					.op_mod_i(op_mod_i),
					.vectorial_op_i(vectorial_op_i),
					.tag_i(tag_i),
					.simd_mask_i(mask_slice),
					.in_valid_i(in_valid),
					.in_ready_o(fmt_in_ready[fmt]),
					.flush_i(flush_i),
					.result_o(fmt_outputs[((Width + 6) >= 0 ? (fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6)) : (((fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6))) + ((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))) - 1)-:((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))]),
					.status_o(fmt_outputs[((Width + 6) >= 0 ? (fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0) : ((fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0)) + 4)-:5]),
					.extension_bit_o(fmt_outputs[(fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 1 : Width + 5)]),
					.tag_o(fmt_outputs[(fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 0 : Width + 6)]),
					.out_valid_o(fmt_out_valid[fmt]),
					.out_ready_i(fmt_out_ready[fmt]),
					.busy_o(fmt_busy[fmt]),
					.reg_ena_i(sv2v_uu_i_fmt_slice_ext_reg_ena_i_0)
				);
			end
			else if ((FpFmtMask[fmt] && ANY_MERGED) && !IS_FIRST_MERGED) begin : merged_unused
				localparam FMT = fpnew_pkg_get_first_enabled_multi(FmtUnitTypes, FpFmtMask);
				assign fmt_in_ready[fmt] = fmt_in_ready[sv2v_cast_32_signed(FMT)];
				assign fmt_out_valid[fmt] = 1'b0;
				assign fmt_busy[fmt] = 1'b0;
				assign fmt_outputs[((Width + 6) >= 0 ? (fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6)) : (((fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6))) + ((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))) - 1)-:((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))] = {Width {fpnew_pkg_DONT_CARE}};
				assign fmt_outputs[((Width + 6) >= 0 ? (fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0) : ((fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0)) + 4)-:5] = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
				assign fmt_outputs[(fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 1 : Width + 5)] = fpnew_pkg_DONT_CARE;
				assign fmt_outputs[(fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 0 : Width + 6)] = fpnew_pkg_DONT_CARE;
			end
			else if (!FpFmtMask[fmt] || (FmtUnitTypes[(4 - fmt) * 2+:2] == 2'd0)) begin : disable_fmt
				assign fmt_in_ready[fmt] = 1'b0;
				assign fmt_out_valid[fmt] = 1'b0;
				assign fmt_busy[fmt] = 1'b0;
				assign fmt_outputs[((Width + 6) >= 0 ? (fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6)) : (((fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6))) + ((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))) - 1)-:((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))] = {Width {fpnew_pkg_DONT_CARE}};
				assign fmt_outputs[((Width + 6) >= 0 ? (fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0) : ((fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0)) + 4)-:5] = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
				assign fmt_outputs[(fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 1 : Width + 5)] = fpnew_pkg_DONT_CARE;
				assign fmt_outputs[(fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 0 : Width + 6)] = fpnew_pkg_DONT_CARE;
			end
		end
	endgenerate
	function automatic [31:0] fpnew_pkg_get_num_regs_multi;
		input reg [159:0] regs;
		input reg [9:0] types;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = 0;
			begin : sv2v_autoblock_10
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i] && (types[(4 - i) * 2+:2] == 2'd2))
						res = fpnew_pkg_maximum(res, regs[(4 - i) * 32+:32]);
			end
			fpnew_pkg_get_num_regs_multi = res;
		end
	endfunction
	generate
		if (fpnew_pkg_any_enabled_multi(FmtUnitTypes, FpFmtMask)) begin : gen_merged_slice
			localparam FMT = fpnew_pkg_get_first_enabled_multi(FmtUnitTypes, FpFmtMask);
			localparam REG = fpnew_pkg_get_num_regs_multi(FmtPipeRegs, FmtUnitTypes, FpFmtMask);
			wire in_valid;
			assign in_valid = in_valid_i & (FmtUnitTypes[(4 - dst_fmt_i) * 2+:2] == 2'd2);
			localparam [31:0] sv2v_uu_i_multifmt_slice_NumPipeRegs = REG;
			localparam [31:0] sv2v_uu_i_multifmt_slice_ExtRegEnaWidth = (sv2v_uu_i_multifmt_slice_NumPipeRegs == 0 ? 1 : sv2v_uu_i_multifmt_slice_NumPipeRegs);
			localparam [sv2v_uu_i_multifmt_slice_ExtRegEnaWidth - 1:0] sv2v_uu_i_multifmt_slice_ext_reg_ena_i_0 = 1'sb0;
			fpnew_opgroup_multifmt_slice_180FF #(
				.OpGroup(OpGroup),
				.Width(Width),
				.FpFmtConfig(FpFmtMask),
				.IntFmtConfig(IntFmtMask),
				.EnableVectors(EnableVectors),
				.PulpDivsqrt(PulpDivsqrt),
				.NumPipeRegs(REG),
				.PipeConfig(PipeConfig)
			) i_multifmt_slice(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.operands_i(operands_i),
				.is_boxed_i(is_boxed_i),
				.rnd_mode_i(rnd_mode_i),
				.op_i(op_i),
				.op_mod_i(op_mod_i),
				.src_fmt_i(src_fmt_i),
				.dst_fmt_i(dst_fmt_i),
				.int_fmt_i(int_fmt_i),
				.vectorial_op_i(vectorial_op_i),
				.tag_i(tag_i),
				.simd_mask_i(simd_mask_i),
				.in_valid_i(in_valid),
				.in_ready_o(fmt_in_ready[FMT]),
				.flush_i(flush_i),
				.result_o(fmt_outputs[((Width + 6) >= 0 ? (FMT * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6)) : (((FMT * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6))) + ((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))) - 1)-:((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))]),
				.status_o(fmt_outputs[((Width + 6) >= 0 ? (FMT * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0) : ((FMT * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0)) + 4)-:5]),
				.extension_bit_o(fmt_outputs[(FMT * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 1 : Width + 5)]),
				.tag_o(fmt_outputs[(FMT * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 0 : Width + 6)]),
				.out_valid_o(fmt_out_valid[FMT]),
				.out_ready_i(fmt_out_ready[FMT]),
				.busy_o(fmt_busy[FMT]),
				.reg_ena_i(sv2v_uu_i_multifmt_slice_ext_reg_ena_i_0)
			);
		end
	endgenerate
	wire [Width + 6:0] arbiter_output;
	localparam [31:0] sv2v_uu_i_arbiter_NumIn = NUM_FORMATS;
	localparam [31:0] sv2v_uu_i_arbiter_IdxWidth = $unsigned(3);
	localparam [sv2v_uu_i_arbiter_IdxWidth - 1:0] sv2v_uu_i_arbiter_ext_rr_i_0 = 1'sb0;
	rr_arb_tree_3B043_A8992 #(
		.DataType_Width(Width),
		.NumIn(NUM_FORMATS),
		.AxiVldRdy(1'b1)
	) i_arbiter(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.flush_i(flush_i),
		.rr_i(sv2v_uu_i_arbiter_ext_rr_i_0),
		.req_i(fmt_out_valid),
		.gnt_o(fmt_out_ready),
		.data_i(fmt_outputs),
		.gnt_i(out_ready_i),
		.req_o(out_valid_o),
		.data_o(arbiter_output),
		.idx_o()
	);
	assign result_o = arbiter_output[Width + 6-:((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))];
	assign status_o = arbiter_output[6-:5];
	assign extension_bit_o = arbiter_output[1];
	assign tag_o = arbiter_output[0];
	assign busy_o = |fmt_busy;
endmodule
module gated_clk_cell (
	clk_in,
	global_en,
	module_en,
	local_en,
	external_en,
	pad_yy_icg_scan_en,
	clk_out
);
	input clk_in;
	input global_en;
	input module_en;
	input local_en;
	input external_en;
	input pad_yy_icg_scan_en;
	output wire clk_out;
	wire clk_en_bf_latch;
	wire SE;
	assign clk_en_bf_latch = (global_en && (module_en || local_en)) || external_en;
	assign SE = pad_yy_icg_scan_en;
	assign clk_out = clk_in;
endmodule
module pa_fdsu_ctrl (
	cp0_fpu_icg_en,
	cp0_yy_clk_en,
	cpurst_b,
	ctrl_fdsu_ex1_sel,
	ctrl_xx_ex1_cmplt_dp,
	ctrl_xx_ex1_inst_vld,
	ctrl_xx_ex1_stall,
	ctrl_xx_ex1_warm_up,
	ctrl_xx_ex2_warm_up,
	ctrl_xx_ex3_warm_up,
	ex1_div,
	ex1_expnt_adder_op0,
	ex1_of_result_lfn,
	ex1_op0_id,
	ex1_op0_norm,
	ex1_op1_id_vld,
	ex1_op1_norm,
	ex1_op1_sel,
	ex1_oper_id_expnt,
	ex1_oper_id_expnt_f,
	ex1_pipedown,
	ex1_pipedown_gate,
	ex1_result_sign,
	ex1_rm,
	ex1_save_op0,
	ex1_save_op0_gate,
	ex1_sqrt,
	ex1_srt_skip,
	ex2_expnt_adder_op0,
	ex2_of,
	ex2_pipe_clk,
	ex2_pipedown,
	ex2_potnt_of,
	ex2_potnt_uf,
	ex2_result_inf,
	ex2_result_lfn,
	ex2_rslt_denorm,
	ex2_srt_expnt_rst,
	ex2_srt_first_round,
	ex2_uf,
	ex2_uf_srt_skip,
	ex3_expnt_adjust_result,
	ex3_pipedown,
	ex3_rslt_denorm,
	fdsu_ex1_sel,
	fdsu_fpu_debug_info,
	fdsu_fpu_ex1_cmplt,
	fdsu_fpu_ex1_cmplt_dp,
	fdsu_fpu_ex1_stall,
	fdsu_fpu_no_op,
	fdsu_frbus_wb_vld,
	fdsu_yy_div,
	fdsu_yy_expnt_rst,
	fdsu_yy_of,
	fdsu_yy_of_rm_lfn,
	fdsu_yy_op0_norm,
	fdsu_yy_op1_norm,
	fdsu_yy_potnt_of,
	fdsu_yy_potnt_uf,
	fdsu_yy_result_inf,
	fdsu_yy_result_lfn,
	fdsu_yy_result_sign,
	fdsu_yy_rm,
	fdsu_yy_rslt_denorm,
	fdsu_yy_sqrt,
	fdsu_yy_uf,
	fdsu_yy_wb_freg,
	forever_cpuclk,
	frbus_fdsu_wb_grant,
	idu_fpu_ex1_dst_freg,
	idu_fpu_ex1_eu_sel,
	pad_yy_icg_scan_en,
	rtu_xx_ex1_cancel,
	rtu_xx_ex2_cancel,
	rtu_yy_xx_async_flush,
	rtu_yy_xx_flush,
	srt_remainder_zero,
	srt_sm_on
);
	input wire cp0_fpu_icg_en;
	input wire cp0_yy_clk_en;
	input wire cpurst_b;
	input wire ctrl_fdsu_ex1_sel;
	input wire ctrl_xx_ex1_cmplt_dp;
	input wire ctrl_xx_ex1_inst_vld;
	input wire ctrl_xx_ex1_stall;
	input wire ctrl_xx_ex1_warm_up;
	input wire ctrl_xx_ex2_warm_up;
	input wire ctrl_xx_ex3_warm_up;
	input wire ex1_div;
	input wire [12:0] ex1_expnt_adder_op0;
	input wire ex1_of_result_lfn;
	input wire ex1_op0_id;
	input ex1_op0_norm;
	input wire ex1_op1_id_vld;
	input ex1_op1_norm;
	input wire [12:0] ex1_oper_id_expnt;
	input wire ex1_result_sign;
	input wire [2:0] ex1_rm;
	input wire ex1_sqrt;
	input wire ex1_srt_skip;
	input wire ex2_of;
	input wire ex2_potnt_of;
	input wire ex2_potnt_uf;
	input wire ex2_result_inf;
	input wire ex2_result_lfn;
	input wire ex2_rslt_denorm;
	input wire [9:0] ex2_srt_expnt_rst;
	input wire ex2_uf;
	input wire ex2_uf_srt_skip;
	input wire [9:0] ex3_expnt_adjust_result;
	input wire ex3_rslt_denorm;
	input wire forever_cpuclk;
	input wire frbus_fdsu_wb_grant;
	input wire [4:0] idu_fpu_ex1_dst_freg;
	input wire [2:0] idu_fpu_ex1_eu_sel;
	input wire pad_yy_icg_scan_en;
	input wire rtu_xx_ex1_cancel;
	input wire rtu_xx_ex2_cancel;
	input wire rtu_yy_xx_async_flush;
	input wire rtu_yy_xx_flush;
	input wire srt_remainder_zero;
	output wire ex1_op1_sel;
	output wire [12:0] ex1_oper_id_expnt_f;
	output wire ex1_pipedown;
	output wire ex1_pipedown_gate;
	output wire ex1_save_op0;
	output wire ex1_save_op0_gate;
	output wire [9:0] ex2_expnt_adder_op0;
	output wire ex2_pipe_clk;
	output wire ex2_pipedown;
	output reg ex2_srt_first_round;
	output wire ex3_pipedown;
	output wire fdsu_ex1_sel;
	output wire [4:0] fdsu_fpu_debug_info;
	output wire fdsu_fpu_ex1_cmplt;
	output wire fdsu_fpu_ex1_cmplt_dp;
	output wire fdsu_fpu_ex1_stall;
	output wire fdsu_fpu_no_op;
	output wire fdsu_frbus_wb_vld;
	output wire fdsu_yy_div;
	output wire [9:0] fdsu_yy_expnt_rst;
	output wire fdsu_yy_of;
	output wire fdsu_yy_of_rm_lfn;
	output wire fdsu_yy_op0_norm;
	output wire fdsu_yy_op1_norm;
	output wire fdsu_yy_potnt_of;
	output wire fdsu_yy_potnt_uf;
	output wire fdsu_yy_result_inf;
	output wire fdsu_yy_result_lfn;
	output wire fdsu_yy_result_sign;
	output wire [2:0] fdsu_yy_rm;
	output reg fdsu_yy_rslt_denorm;
	output wire fdsu_yy_sqrt;
	output wire fdsu_yy_uf;
	output wire [4:0] fdsu_yy_wb_freg;
	output wire srt_sm_on;
	reg [2:0] fdsu_cur_state;
	reg fdsu_div;
	reg [9:0] fdsu_expnt_rst;
	reg [2:0] fdsu_next_state;
	reg fdsu_of;
	reg fdsu_of_rm_lfn;
	reg fdsu_potnt_of;
	reg fdsu_potnt_uf;
	reg fdsu_result_inf;
	reg fdsu_result_lfn;
	reg fdsu_result_sign;
	reg [2:0] fdsu_rm;
	reg fdsu_sqrt;
	reg fdsu_uf;
	reg [4:0] fdsu_wb_freg;
	reg [4:0] srt_cnt;
	reg [1:0] wb_cur_state;
	reg [1:0] wb_nxt_state;
	wire ctrl_fdsu_ex1_stall;
	wire ctrl_fdsu_wb_vld;
	wire ctrl_iter_start;
	wire ctrl_iter_start_gate;
	wire ctrl_pack;
	wire ctrl_result_vld;
	wire ctrl_round;
	wire ctrl_sm_cmplt;
	wire ctrl_sm_ex1;
	wire ctrl_sm_idle;
	wire ctrl_sm_start;
	wire ctrl_sm_start_gate;
	wire ctrl_srt_idle;
	wire ctrl_srt_itering;
	wire ctrl_wb_idle;
	wire ctrl_wb_sm_cmplt;
	wire ctrl_wb_sm_ex2;
	wire ctrl_wb_sm_idle;
	wire ctrl_wfi2;
	wire ctrl_wfwb;
	wire ex1_pipe_clk;
	wire ex1_pipe_clk_en;
	wire [4:0] ex1_wb_freg;
	wire ex2_pipe_clk_en;
	wire expnt_rst_clk;
	wire expnt_rst_clk_en;
	wire fdsu_busy;
	wire fdsu_clk;
	wire fdsu_clk_en;
	wire fdsu_dn_stall;
	wire fdsu_ex1_inst_vld;
	wire fdsu_ex1_res_vld;
	wire fdsu_flush;
	wire fdsu_op0_norm;
	wire fdsu_op1_norm;
	wire fdsu_wb_grant;
	wire [4:0] srt_cnt_ini;
	wire srt_cnt_zero;
	wire srt_last_round;
	wire srt_skip;
	assign ex1_wb_freg[4:0] = idu_fpu_ex1_dst_freg[4:0];
	assign fdsu_ex1_inst_vld = ctrl_xx_ex1_inst_vld && ctrl_fdsu_ex1_sel;
	assign fdsu_ex1_sel = idu_fpu_ex1_eu_sel[2];
	assign fdsu_ex1_res_vld = fdsu_ex1_inst_vld && ex1_srt_skip;
	assign fdsu_wb_grant = frbus_fdsu_wb_grant;
	assign ctrl_iter_start = (ctrl_sm_start && !fdsu_dn_stall) || ctrl_wfi2;
	assign ctrl_iter_start_gate = (ctrl_sm_start_gate && !fdsu_dn_stall) || ctrl_wfi2;
	assign ctrl_sm_start = (fdsu_ex1_inst_vld && ctrl_srt_idle) && !ex1_srt_skip;
	assign ctrl_sm_start_gate = fdsu_ex1_inst_vld && ctrl_srt_idle;
	assign srt_last_round = ((srt_skip || srt_remainder_zero) || srt_cnt_zero) && ctrl_srt_itering;
	assign srt_skip = ex2_of || ex2_uf_srt_skip;
	assign srt_cnt_zero = ~|srt_cnt[4:0];
	assign fdsu_dn_stall = ctrl_sm_start && ex1_op1_id_vld;
	parameter IDLE = 3'b000;
	parameter WFI2 = 3'b001;
	parameter ITER = 3'b010;
	parameter RND = 3'b011;
	parameter PACK = 3'b100;
	parameter WFWB = 3'b101;
	always @(posedge fdsu_clk or negedge cpurst_b)
		if (!cpurst_b)
			fdsu_cur_state[2:0] <= IDLE;
		else if (fdsu_flush)
			fdsu_cur_state[2:0] <= IDLE;
		else
			fdsu_cur_state[2:0] <= fdsu_next_state[2:0];
	always @(ctrl_sm_start or fdsu_dn_stall or srt_last_round or fdsu_cur_state[2:0] or fdsu_wb_grant)
		case (fdsu_cur_state[2:0])
			IDLE:
				if (ctrl_sm_start) begin
					if (fdsu_dn_stall)
						fdsu_next_state[2:0] = WFI2;
					else
						fdsu_next_state[2:0] = ITER;
				end
				else
					fdsu_next_state[2:0] = IDLE;
			WFI2: fdsu_next_state[2:0] = ITER;
			ITER:
				if (srt_last_round)
					fdsu_next_state[2:0] = RND;
				else
					fdsu_next_state[2:0] = ITER;
			RND: fdsu_next_state[2:0] = PACK;
			PACK:
				if (fdsu_wb_grant) begin
					if (ctrl_sm_start) begin
						if (fdsu_dn_stall)
							fdsu_next_state[2:0] = WFI2;
						else
							fdsu_next_state[2:0] = ITER;
					end
					else
						fdsu_next_state[2:0] = IDLE;
				end
				else
					fdsu_next_state[2:0] = WFWB;
			WFWB:
				if (fdsu_wb_grant) begin
					if (ctrl_sm_start) begin
						if (fdsu_dn_stall)
							fdsu_next_state[2:0] = WFI2;
						else
							fdsu_next_state[2:0] = ITER;
					end
					else
						fdsu_next_state[2:0] = IDLE;
				end
				else
					fdsu_next_state[2:0] = WFWB;
			default: fdsu_next_state[2:0] = IDLE;
		endcase
	assign ctrl_sm_idle = fdsu_cur_state[2:0] == IDLE;
	assign ctrl_wfi2 = fdsu_cur_state[2:0] == WFI2;
	assign ctrl_srt_itering = fdsu_cur_state[2:0] == ITER;
	assign ctrl_round = fdsu_cur_state[2:0] == RND;
	assign ctrl_pack = fdsu_cur_state[2:0] == PACK;
	assign ctrl_wfwb = fdsu_cur_state[2:0] == WFWB;
	assign ctrl_sm_cmplt = ctrl_pack || ctrl_wfwb;
	assign ctrl_srt_idle = ctrl_sm_idle || fdsu_wb_grant;
	assign ctrl_sm_ex1 = ctrl_srt_idle || ctrl_wfi2;
	always @(posedge fdsu_clk)
		if (fdsu_flush)
			srt_cnt[4:0] <= 5'b00000;
		else if (ctrl_iter_start)
			srt_cnt[4:0] <= srt_cnt_ini[4:0];
		else if (ctrl_srt_itering)
			srt_cnt[4:0] <= srt_cnt[4:0] - 5'b00001;
		else
			srt_cnt[4:0] <= srt_cnt[4:0];
	assign srt_cnt_ini[4:0] = 5'b01110;
	always @(posedge fdsu_clk or negedge cpurst_b)
		if (!cpurst_b)
			ex2_srt_first_round <= 1'b0;
		else if (fdsu_flush)
			ex2_srt_first_round <= 1'b0;
		else if (ex1_pipedown)
			ex2_srt_first_round <= 1'b1;
		else
			ex2_srt_first_round <= 1'b0;
	parameter WB_IDLE = 2'b00;
	parameter WB_EX2 = 2'b10;
	parameter WB_CMPLT = 2'b01;
	always @(posedge fdsu_clk or negedge cpurst_b)
		if (!cpurst_b)
			wb_cur_state[1:0] <= WB_IDLE;
		else if (fdsu_flush)
			wb_cur_state[1:0] <= WB_IDLE;
		else
			wb_cur_state[1:0] <= wb_nxt_state[1:0];
	always @(ctrl_fdsu_wb_vld or fdsu_dn_stall or ctrl_xx_ex1_stall or fdsu_ex1_inst_vld or ctrl_iter_start or fdsu_ex1_res_vld or wb_cur_state[1:0])
		case (wb_cur_state[1:0])
			WB_IDLE:
				if (fdsu_ex1_inst_vld) begin
					if ((ctrl_xx_ex1_stall || fdsu_ex1_res_vld) || fdsu_dn_stall)
						wb_nxt_state[1:0] = WB_IDLE;
					else
						wb_nxt_state[1:0] = WB_EX2;
				end
				else
					wb_nxt_state[1:0] = WB_IDLE;
			WB_EX2:
				if (ctrl_fdsu_wb_vld) begin
					if (ctrl_iter_start && !ctrl_xx_ex1_stall)
						wb_nxt_state[1:0] = WB_EX2;
					else
						wb_nxt_state[1:0] = WB_IDLE;
				end
				else
					wb_nxt_state[1:0] = WB_CMPLT;
			WB_CMPLT:
				if (ctrl_fdsu_wb_vld) begin
					if (ctrl_iter_start && !ctrl_xx_ex1_stall)
						wb_nxt_state[1:0] = WB_EX2;
					else
						wb_nxt_state[1:0] = WB_IDLE;
				end
				else
					wb_nxt_state[1:0] = WB_CMPLT;
			default: wb_nxt_state[1:0] = WB_IDLE;
		endcase
	assign ctrl_wb_idle = (wb_cur_state[1:0] == WB_IDLE) || ((wb_cur_state[1:0] == WB_CMPLT) && ctrl_fdsu_wb_vld);
	assign ctrl_wb_sm_idle = wb_cur_state[1:0] == WB_IDLE;
	assign ctrl_wb_sm_ex2 = wb_cur_state[1:0] == WB_EX2;
	assign ctrl_wb_sm_cmplt = (wb_cur_state[1:0] == WB_EX2) || (wb_cur_state[1:0] == WB_CMPLT);
	assign ctrl_result_vld = ctrl_sm_cmplt && ctrl_wb_sm_cmplt;
	assign ctrl_fdsu_wb_vld = ctrl_result_vld && frbus_fdsu_wb_grant;
	assign ctrl_fdsu_ex1_stall = ((fdsu_ex1_inst_vld && !ctrl_sm_ex1) && !ctrl_wb_idle) || (fdsu_ex1_inst_vld && fdsu_dn_stall);
	always @(posedge ex1_pipe_clk)
		if (ex1_pipedown) begin
			fdsu_wb_freg[4:0] <= ex1_wb_freg[4:0];
			fdsu_result_sign <= ex1_result_sign;
			fdsu_of_rm_lfn <= ex1_of_result_lfn;
			fdsu_div <= ex1_div;
			fdsu_sqrt <= ex1_sqrt;
			fdsu_rm[2:0] <= ex1_rm[2:0];
		end
		else begin
			fdsu_wb_freg[4:0] <= fdsu_wb_freg[4:0];
			fdsu_result_sign <= fdsu_result_sign;
			fdsu_of_rm_lfn <= fdsu_of_rm_lfn;
			fdsu_div <= fdsu_div;
			fdsu_sqrt <= fdsu_sqrt;
			fdsu_rm[2:0] <= fdsu_rm[2:0];
		end
	assign fdsu_op0_norm = 1'b1;
	assign fdsu_op1_norm = 1'b1;
	always @(posedge expnt_rst_clk)
		if (ex1_save_op0)
			fdsu_expnt_rst[9:0] <= ex1_oper_id_expnt[9:0];
		else if (ex1_pipedown)
			fdsu_expnt_rst[9:0] <= ex1_expnt_adder_op0[9:0];
		else if (ex2_pipedown)
			fdsu_expnt_rst[9:0] <= ex2_srt_expnt_rst[9:0];
		else if (ex3_pipedown)
			fdsu_expnt_rst[9:0] <= ex3_expnt_adjust_result[9:0];
		else
			fdsu_expnt_rst[9:0] <= fdsu_expnt_rst[9:0];
	assign ex1_oper_id_expnt_f[12:0] = {3'b001, fdsu_expnt_rst[9:0]};
	always @(posedge expnt_rst_clk)
		if (ex2_pipedown)
			fdsu_yy_rslt_denorm <= ex2_rslt_denorm;
		else if (ex3_pipedown)
			fdsu_yy_rslt_denorm <= ex3_rslt_denorm;
		else
			fdsu_yy_rslt_denorm <= fdsu_yy_rslt_denorm;
	always @(posedge ex2_pipe_clk)
		if (ex2_pipedown) begin
			fdsu_result_inf <= ex2_result_inf;
			fdsu_result_lfn <= ex2_result_lfn;
			fdsu_of <= ex2_of;
			fdsu_uf <= ex2_uf;
			fdsu_potnt_of <= ex2_potnt_of;
			fdsu_potnt_uf <= ex2_potnt_uf;
		end
		else begin
			fdsu_result_inf <= fdsu_result_inf;
			fdsu_result_lfn <= fdsu_result_lfn;
			fdsu_of <= fdsu_of;
			fdsu_uf <= fdsu_uf;
			fdsu_potnt_of <= fdsu_potnt_of;
			fdsu_potnt_uf <= fdsu_potnt_uf;
		end
	assign fdsu_flush = (((rtu_xx_ex1_cancel && ctrl_wb_idle) || (rtu_xx_ex2_cancel && ctrl_wb_sm_ex2)) || ctrl_xx_ex1_warm_up) || rtu_yy_xx_async_flush;
	assign fdsu_busy = (fdsu_ex1_inst_vld || !ctrl_sm_idle) || !ctrl_wb_sm_idle;
	assign fdsu_clk_en = (fdsu_busy || !ctrl_sm_idle) || rtu_yy_xx_flush;
	gated_clk_cell x_fdsu_clk(
		.clk_in(forever_cpuclk),
		.clk_out(fdsu_clk),
		.external_en(1'b0),
		.global_en(cp0_yy_clk_en),
		.local_en(fdsu_clk_en),
		.module_en(cp0_fpu_icg_en),
		.pad_yy_icg_scan_en(pad_yy_icg_scan_en)
	);
	assign ex1_pipe_clk_en = ex1_pipedown_gate;
	gated_clk_cell x_ex1_pipe_clk(
		.clk_in(forever_cpuclk),
		.clk_out(ex1_pipe_clk),
		.external_en(1'b0),
		.global_en(cp0_yy_clk_en),
		.local_en(ex1_pipe_clk_en),
		.module_en(cp0_fpu_icg_en),
		.pad_yy_icg_scan_en(pad_yy_icg_scan_en)
	);
	assign ex2_pipe_clk_en = ex2_pipedown;
	gated_clk_cell x_ex2_pipe_clk(
		.clk_in(forever_cpuclk),
		.clk_out(ex2_pipe_clk),
		.external_en(1'b0),
		.global_en(cp0_yy_clk_en),
		.local_en(ex2_pipe_clk_en),
		.module_en(cp0_fpu_icg_en),
		.pad_yy_icg_scan_en(pad_yy_icg_scan_en)
	);
	assign expnt_rst_clk_en = ((ex1_save_op0_gate || ex1_pipedown_gate) || ex2_pipedown) || ex3_pipedown;
	gated_clk_cell x_expnt_rst_clk(
		.clk_in(forever_cpuclk),
		.clk_out(expnt_rst_clk),
		.external_en(1'b0),
		.global_en(cp0_yy_clk_en),
		.local_en(expnt_rst_clk_en),
		.module_en(cp0_fpu_icg_en),
		.pad_yy_icg_scan_en(pad_yy_icg_scan_en)
	);
	assign fdsu_yy_wb_freg[4:0] = fdsu_wb_freg[4:0];
	assign fdsu_yy_result_sign = fdsu_result_sign;
	assign fdsu_yy_op0_norm = fdsu_op0_norm;
	assign fdsu_yy_op1_norm = fdsu_op1_norm;
	assign fdsu_yy_of_rm_lfn = fdsu_of_rm_lfn;
	assign fdsu_yy_div = fdsu_div;
	assign fdsu_yy_sqrt = fdsu_sqrt;
	assign fdsu_yy_rm[2:0] = fdsu_rm[2:0];
	assign fdsu_yy_expnt_rst[9:0] = fdsu_expnt_rst[9:0];
	assign ex2_expnt_adder_op0[9:0] = fdsu_expnt_rst[9:0];
	assign fdsu_yy_result_inf = fdsu_result_inf;
	assign fdsu_yy_result_lfn = fdsu_result_lfn;
	assign fdsu_yy_of = fdsu_of;
	assign fdsu_yy_uf = fdsu_uf;
	assign fdsu_yy_potnt_of = fdsu_potnt_of;
	assign fdsu_yy_potnt_uf = fdsu_potnt_uf;
	assign ex1_pipedown = ctrl_iter_start || ctrl_xx_ex1_warm_up;
	assign ex1_pipedown_gate = ctrl_iter_start_gate || ctrl_xx_ex1_warm_up;
	assign ex2_pipedown = (ctrl_srt_itering && srt_last_round) || ctrl_xx_ex2_warm_up;
	assign ex3_pipedown = ctrl_round || ctrl_xx_ex3_warm_up;
	assign srt_sm_on = ctrl_srt_itering;
	assign fdsu_fpu_ex1_cmplt = fdsu_ex1_inst_vld;
	assign fdsu_fpu_ex1_cmplt_dp = ctrl_xx_ex1_cmplt_dp && idu_fpu_ex1_eu_sel[2];
	assign fdsu_fpu_ex1_stall = ctrl_fdsu_ex1_stall;
	assign fdsu_frbus_wb_vld = ctrl_result_vld;
	assign fdsu_fpu_no_op = !fdsu_busy;
	assign ex1_op1_sel = ctrl_wfi2;
	assign ex1_save_op0 = (ctrl_sm_start && ex1_op0_id) && ex1_op1_id_vld;
	assign ex1_save_op0_gate = (ctrl_sm_start_gate && ex1_op0_id) && ex1_op1_id_vld;
	assign fdsu_fpu_debug_info[4:0] = {wb_cur_state[1:0], fdsu_cur_state[2:0]};
endmodule
module pa_fdsu_ff1 (
	fanc_shift_num,
	frac_bin_val,
	frac_num
);
	input wire [51:0] frac_num;
	output reg [51:0] fanc_shift_num;
	output reg [12:0] frac_bin_val;
	always @(frac_num[51:0])
		casez (frac_num[51:0])
			52'b1zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h0000;
			52'b01zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fff;
			52'b001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1ffe;
			52'b0001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1ffd;
			52'b00001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1ffc;
			52'b000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1ffb;
			52'b0000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1ffa;
			52'b00000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1ff9;
			52'b000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1ff8;
			52'b0000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1ff7;
			52'b00000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1ff6;
			52'b000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1ff5;
			52'b0000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1ff4;
			52'b00000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1ff3;
			52'b000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1ff2;
			52'b0000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1ff1;
			52'b00000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1ff0;
			52'b000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fef;
			52'b0000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fee;
			52'b00000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fed;
			52'b000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fec;
			52'b0000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1feb;
			52'b00000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fea;
			52'b000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fe9;
			52'b0000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fe8;
			52'b00000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fe7;
			52'b000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fe6;
			52'b0000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fe5;
			52'b00000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fe4;
			52'b000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fe3;
			52'b0000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fe2;
			52'b00000000000000000000000000000001zzzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fe1;
			52'b000000000000000000000000000000001zzzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fe0;
			52'b0000000000000000000000000000000001zzzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fdf;
			52'b00000000000000000000000000000000001zzzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fde;
			52'b000000000000000000000000000000000001zzzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fdd;
			52'b0000000000000000000000000000000000001zzzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fdc;
			52'b00000000000000000000000000000000000001zzzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fdb;
			52'b000000000000000000000000000000000000001zzzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fda;
			52'b0000000000000000000000000000000000000001zzzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fd9;
			52'b00000000000000000000000000000000000000001zzzzzzzzzzz: frac_bin_val[12:0] = 13'h1fd8;
			52'b000000000000000000000000000000000000000001zzzzzzzzzz: frac_bin_val[12:0] = 13'h1fd7;
			52'b0000000000000000000000000000000000000000001zzzzzzzzz: frac_bin_val[12:0] = 13'h1fd6;
			52'b00000000000000000000000000000000000000000001zzzzzzzz: frac_bin_val[12:0] = 13'h1fd5;
			52'b000000000000000000000000000000000000000000001zzzzzzz: frac_bin_val[12:0] = 13'h1fd4;
			52'b0000000000000000000000000000000000000000000001zzzzzz: frac_bin_val[12:0] = 13'h1fd3;
			52'b00000000000000000000000000000000000000000000001zzzzz: frac_bin_val[12:0] = 13'h1fd2;
			52'b000000000000000000000000000000000000000000000001zzzz: frac_bin_val[12:0] = 13'h1fd1;
			52'b0000000000000000000000000000000000000000000000001zzz: frac_bin_val[12:0] = 13'h1fd0;
			52'b00000000000000000000000000000000000000000000000001zz: frac_bin_val[12:0] = 13'h1fcf;
			52'b000000000000000000000000000000000000000000000000001z: frac_bin_val[12:0] = 13'h1fce;
			52'b0000000000000000000000000000000000000000000000000001: frac_bin_val[12:0] = 13'h1fcd;
			52'b0000000000000000000000000000000000000000000000000000: frac_bin_val[12:0] = 13'h1fcc;
			default: frac_bin_val[12:0] = 13'h0000;
		endcase
	always @(frac_num[51:0])
		casez (frac_num[51:0])
			52'b1zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = frac_num[51:0];
			52'b01zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[50:0], 1'b0};
			52'b001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[49:0], 2'b00};
			52'b0001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[48:0], 3'b000};
			52'b00001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[47:0], 4'b0000};
			52'b000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[46:0], 5'b00000};
			52'b0000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[45:0], 6'b000000};
			52'b00000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[44:0], 7'b0000000};
			52'b000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[43:0], 8'b00000000};
			52'b0000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[42:0], 9'b000000000};
			52'b00000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[41:0], 10'b0000000000};
			52'b000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[40:0], 11'b00000000000};
			52'b0000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[39:0], 12'b000000000000};
			52'b00000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[38:0], 13'b0000000000000};
			52'b000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[37:0], 14'b00000000000000};
			52'b0000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[36:0], 15'b000000000000000};
			52'b00000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[35:0], 16'b0000000000000000};
			52'b000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[34:0], 17'b00000000000000000};
			52'b0000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[33:0], 18'b000000000000000000};
			52'b00000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[32:0], 19'b0000000000000000000};
			52'b000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[31:0], 20'b00000000000000000000};
			52'b0000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[30:0], 21'b000000000000000000000};
			52'b00000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[29:0], 22'b0000000000000000000000};
			52'b000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[28:0], 23'b00000000000000000000000};
			52'b0000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[27:0], 24'b000000000000000000000000};
			52'b00000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[26:0], 25'b0000000000000000000000000};
			52'b000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[25:0], 26'b00000000000000000000000000};
			52'b0000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[24:0], 27'b000000000000000000000000000};
			52'b00000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[23:0], 28'b0000000000000000000000000000};
			52'b000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[22:0], 29'b00000000000000000000000000000};
			52'b0000000000000000000000000000001zzzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[21:0], 30'b000000000000000000000000000000};
			52'b00000000000000000000000000000001zzzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[20:0], 31'b0000000000000000000000000000000};
			52'b000000000000000000000000000000001zzzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[19:0], 32'b00000000000000000000000000000000};
			52'b0000000000000000000000000000000001zzzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[18:0], 33'b000000000000000000000000000000000};
			52'b00000000000000000000000000000000001zzzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[17:0], 34'b0000000000000000000000000000000000};
			52'b000000000000000000000000000000000001zzzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[16:0], 35'b00000000000000000000000000000000000};
			52'b0000000000000000000000000000000000001zzzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[15:0], 36'b000000000000000000000000000000000000};
			52'b00000000000000000000000000000000000001zzzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[14:0], 37'b0000000000000000000000000000000000000};
			52'b000000000000000000000000000000000000001zzzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[13:0], 38'b00000000000000000000000000000000000000};
			52'b0000000000000000000000000000000000000001zzzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[12:0], 39'b000000000000000000000000000000000000000};
			52'b00000000000000000000000000000000000000001zzzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[11:0], 40'b0000000000000000000000000000000000000000};
			52'b000000000000000000000000000000000000000001zzzzzzzzzz: fanc_shift_num[51:0] = {frac_num[10:0], 41'b00000000000000000000000000000000000000000};
			52'b0000000000000000000000000000000000000000001zzzzzzzzz: fanc_shift_num[51:0] = {frac_num[9:0], 42'b000000000000000000000000000000000000000000};
			52'b00000000000000000000000000000000000000000001zzzzzzzz: fanc_shift_num[51:0] = {frac_num[8:0], 43'b0000000000000000000000000000000000000000000};
			52'b000000000000000000000000000000000000000000001zzzzzzz: fanc_shift_num[51:0] = {frac_num[7:0], 44'b00000000000000000000000000000000000000000000};
			52'b0000000000000000000000000000000000000000000001zzzzzz: fanc_shift_num[51:0] = {frac_num[6:0], 45'b000000000000000000000000000000000000000000000};
			52'b00000000000000000000000000000000000000000000001zzzzz: fanc_shift_num[51:0] = {frac_num[5:0], 46'b0000000000000000000000000000000000000000000000};
			52'b000000000000000000000000000000000000000000000001zzzz: fanc_shift_num[51:0] = {frac_num[4:0], 47'b00000000000000000000000000000000000000000000000};
			52'b0000000000000000000000000000000000000000000000001zzz: fanc_shift_num[51:0] = {frac_num[3:0], 48'b000000000000000000000000000000000000000000000000};
			52'b00000000000000000000000000000000000000000000000001zz: fanc_shift_num[51:0] = {frac_num[2:0], 49'b0000000000000000000000000000000000000000000000000};
			52'b000000000000000000000000000000000000000000000000001z: fanc_shift_num[51:0] = {frac_num[1:0], 50'b00000000000000000000000000000000000000000000000000};
			52'b0000000000000000000000000000000000000000000000000001: fanc_shift_num[51:0] = {frac_num[0:0], 51'b000000000000000000000000000000000000000000000000000};
			52'b0000000000000000000000000000000000000000000000000000: fanc_shift_num[51:0] = 52'b0000000000000000000000000000000000000000000000000000;
			default: fanc_shift_num[51:0] = 52'b0000000000000000000000000000000000000000000000000000;
		endcase
endmodule
module pa_fdsu_pack_single (
	fdsu_ex4_denorm_to_tiny_frac,
	fdsu_ex4_frac,
	fdsu_ex4_nx,
	fdsu_ex4_potnt_norm,
	fdsu_ex4_result_nor,
	fdsu_frbus_data,
	fdsu_frbus_fflags,
	fdsu_frbus_freg,
	fdsu_yy_expnt_rst,
	fdsu_yy_of,
	fdsu_yy_of_rm_lfn,
	fdsu_yy_potnt_of,
	fdsu_yy_potnt_uf,
	fdsu_yy_result_inf,
	fdsu_yy_result_lfn,
	fdsu_yy_result_sign,
	fdsu_yy_rslt_denorm,
	fdsu_yy_uf,
	fdsu_yy_wb_freg
);
	input wire fdsu_ex4_denorm_to_tiny_frac;
	input wire [25:0] fdsu_ex4_frac;
	input wire fdsu_ex4_nx;
	input wire [1:0] fdsu_ex4_potnt_norm;
	input wire fdsu_ex4_result_nor;
	input wire [9:0] fdsu_yy_expnt_rst;
	input wire fdsu_yy_of;
	input wire fdsu_yy_of_rm_lfn;
	input wire fdsu_yy_potnt_of;
	input wire fdsu_yy_potnt_uf;
	input wire fdsu_yy_result_inf;
	input wire fdsu_yy_result_lfn;
	input wire fdsu_yy_result_sign;
	input wire fdsu_yy_rslt_denorm;
	input wire fdsu_yy_uf;
	input wire [4:0] fdsu_yy_wb_freg;
	output wire [31:0] fdsu_frbus_data;
	output wire [4:0] fdsu_frbus_fflags;
	output wire [4:0] fdsu_frbus_freg;
	reg [22:0] ex4_frac_23;
	reg [31:0] ex4_result;
	reg [22:0] ex4_single_denorm_frac;
	reg [9:0] expnt_add_op1;
	wire ex4_cor_nx;
	wire ex4_cor_uf;
	wire ex4_denorm_potnt_norm;
	wire [31:0] ex4_denorm_result;
	wire [9:0] ex4_expnt_rst;
	wire [4:0] ex4_expt;
	wire ex4_final_rst_norm;
	wire [25:0] ex4_frac;
	wire ex4_of_plus;
	wire ex4_result_inf;
	wire ex4_result_lfn;
	wire ex4_rslt_denorm;
	wire [31:0] ex4_rst_inf;
	wire [31:0] ex4_rst_lfn;
	wire ex4_rst_nor;
	wire [31:0] ex4_rst_norm;
	wire ex4_uf_plus;
	wire fdsu_ex4_dz;
	wire [9:0] fdsu_ex4_expnt_rst;
	wire fdsu_ex4_nv;
	wire fdsu_ex4_of;
	wire fdsu_ex4_of_rst_lfn;
	wire fdsu_ex4_potnt_of;
	wire fdsu_ex4_potnt_uf;
	wire fdsu_ex4_result_inf;
	wire fdsu_ex4_result_lfn;
	wire fdsu_ex4_result_sign;
	wire fdsu_ex4_rslt_denorm;
	wire fdsu_ex4_uf;
	assign fdsu_ex4_result_sign = fdsu_yy_result_sign;
	assign fdsu_ex4_of_rst_lfn = fdsu_yy_of_rm_lfn;
	assign fdsu_ex4_result_inf = fdsu_yy_result_inf;
	assign fdsu_ex4_result_lfn = fdsu_yy_result_lfn;
	assign fdsu_ex4_of = fdsu_yy_of;
	assign fdsu_ex4_uf = fdsu_yy_uf;
	assign fdsu_ex4_potnt_of = fdsu_yy_potnt_of;
	assign fdsu_ex4_potnt_uf = fdsu_yy_potnt_uf;
	assign fdsu_ex4_nv = 1'b0;
	assign fdsu_ex4_dz = 1'b0;
	assign fdsu_ex4_expnt_rst[9:0] = fdsu_yy_expnt_rst[9:0];
	assign fdsu_ex4_rslt_denorm = fdsu_yy_rslt_denorm;
	assign ex4_frac[25:0] = fdsu_ex4_frac[25:0];
	always @(ex4_frac[25:24])
		casez (ex4_frac[25:24])
			2'b00: expnt_add_op1[9:0] = 10'h1ff;
			2'b01: expnt_add_op1[9:0] = 10'h000;
			2'b1z: expnt_add_op1[9:0] = 10'h001;
			default: expnt_add_op1[9:0] = 10'b0000000000;
		endcase
	assign ex4_expnt_rst[9:0] = fdsu_ex4_expnt_rst[9:0] + expnt_add_op1[9:0];
	always @(fdsu_ex4_expnt_rst[9:0] or fdsu_ex4_denorm_to_tiny_frac or ex4_frac[25:1])
		case (fdsu_ex4_expnt_rst[9:0])
			10'h001: ex4_single_denorm_frac[22:0] = {ex4_frac[23:1]};
			10'h000: ex4_single_denorm_frac[22:0] = {ex4_frac[24:2]};
			10'h3ff: ex4_single_denorm_frac[22:0] = {ex4_frac[25:3]};
			10'h3fe: ex4_single_denorm_frac[22:0] = {1'b0, ex4_frac[25:4]};
			10'h3fd: ex4_single_denorm_frac[22:0] = {2'b00, ex4_frac[25:5]};
			10'h3fc: ex4_single_denorm_frac[22:0] = {3'b000, ex4_frac[25:6]};
			10'h3fb: ex4_single_denorm_frac[22:0] = {4'b0000, ex4_frac[25:7]};
			10'h3fa: ex4_single_denorm_frac[22:0] = {5'b00000, ex4_frac[25:8]};
			10'h3f9: ex4_single_denorm_frac[22:0] = {6'b000000, ex4_frac[25:9]};
			10'h3f8: ex4_single_denorm_frac[22:0] = {7'b0000000, ex4_frac[25:10]};
			10'h3f7: ex4_single_denorm_frac[22:0] = {8'b00000000, ex4_frac[25:11]};
			10'h3f6: ex4_single_denorm_frac[22:0] = {9'b000000000, ex4_frac[25:12]};
			10'h3f5: ex4_single_denorm_frac[22:0] = {10'b0000000000, ex4_frac[25:13]};
			10'h3f4: ex4_single_denorm_frac[22:0] = {11'b00000000000, ex4_frac[25:14]};
			10'h3f3: ex4_single_denorm_frac[22:0] = {12'b000000000000, ex4_frac[25:15]};
			10'h3f2: ex4_single_denorm_frac[22:0] = {13'b0000000000000, ex4_frac[25:16]};
			10'h3f1: ex4_single_denorm_frac[22:0] = {14'b00000000000000, ex4_frac[25:17]};
			10'h3f0: ex4_single_denorm_frac[22:0] = {15'b000000000000000, ex4_frac[25:18]};
			10'h3ef: ex4_single_denorm_frac[22:0] = {16'b0000000000000000, ex4_frac[25:19]};
			10'h3ee: ex4_single_denorm_frac[22:0] = {17'b00000000000000000, ex4_frac[25:20]};
			10'h3ed: ex4_single_denorm_frac[22:0] = {18'b000000000000000000, ex4_frac[25:21]};
			10'h3ec: ex4_single_denorm_frac[22:0] = {19'b0000000000000000000, ex4_frac[25:22]};
			10'h3eb: ex4_single_denorm_frac[22:0] = {20'b00000000000000000000, ex4_frac[25:23]};
			10'h3ea: ex4_single_denorm_frac[22:0] = {21'b000000000000000000000, ex4_frac[25:24]};
			default: ex4_single_denorm_frac[22:0] = (fdsu_ex4_denorm_to_tiny_frac ? 23'b00000000000000000000001 : 23'b00000000000000000000000);
		endcase
	assign ex4_denorm_potnt_norm = (fdsu_ex4_potnt_norm[1] && ex4_frac[24]) || (fdsu_ex4_potnt_norm[0] && ex4_frac[25]);
	assign ex4_rslt_denorm = fdsu_ex4_rslt_denorm && !ex4_denorm_potnt_norm;
	assign ex4_denorm_result[31:0] = {fdsu_ex4_result_sign, 8'h00, ex4_single_denorm_frac[22:0]};
	assign ex4_rst_nor = fdsu_ex4_result_nor;
	assign ex4_of_plus = (fdsu_ex4_potnt_of && |ex4_frac[25:24]) && ex4_rst_nor;
	assign ex4_uf_plus = (fdsu_ex4_potnt_uf && ~|ex4_frac[25:24]) && ex4_rst_nor;
	assign ex4_result_lfn = (ex4_of_plus && fdsu_ex4_of_rst_lfn) || fdsu_ex4_result_lfn;
	assign ex4_result_inf = (ex4_of_plus && !fdsu_ex4_of_rst_lfn) || fdsu_ex4_result_inf;
	assign ex4_rst_lfn[31:0] = {fdsu_ex4_result_sign, 8'hfe, {23 {1'b1}}};
	assign ex4_rst_inf[31:0] = {fdsu_ex4_result_sign, 31'h7f800000};
	always @(ex4_frac[25:0])
		casez (ex4_frac[25:24])
			2'b00: ex4_frac_23[22:0] = ex4_frac[22:0];
			2'b01: ex4_frac_23[22:0] = ex4_frac[23:1];
			2'b1z: ex4_frac_23[22:0] = ex4_frac[24:2];
			default: ex4_frac_23[22:0] = 23'b00000000000000000000000;
		endcase
	assign ex4_rst_norm[31:0] = {fdsu_ex4_result_sign, ex4_expnt_rst[7:0], ex4_frac_23[22:0]};
	assign ex4_cor_uf = ((fdsu_ex4_uf || ex4_denorm_potnt_norm) || ex4_uf_plus) && fdsu_ex4_nx;
	assign ex4_cor_nx = (fdsu_ex4_nx || fdsu_ex4_of) || ex4_of_plus;
	assign ex4_expt[4:0] = {fdsu_ex4_nv, fdsu_ex4_dz, fdsu_ex4_of | ex4_of_plus, ex4_cor_uf, ex4_cor_nx};
	assign ex4_final_rst_norm = (!ex4_result_inf && !ex4_result_lfn) && !ex4_rslt_denorm;
	always @(ex4_denorm_result[31:0] or ex4_result_lfn or ex4_result_inf or ex4_final_rst_norm or ex4_rst_norm[31:0] or ex4_rst_lfn[31:0] or ex4_rst_inf[31:0] or ex4_rslt_denorm)
		case ({ex4_rslt_denorm, ex4_result_inf, ex4_result_lfn, ex4_final_rst_norm})
			4'b1000: ex4_result[31:0] = ex4_denorm_result[31:0];
			4'b0100: ex4_result[31:0] = ex4_rst_inf[31:0];
			4'b0010: ex4_result[31:0] = ex4_rst_lfn[31:0];
			4'b0001: ex4_result[31:0] = ex4_rst_norm[31:0];
			default: ex4_result[31:0] = 32'b00000000000000000000000000000000;
		endcase
	assign fdsu_frbus_freg[4:0] = fdsu_yy_wb_freg[4:0];
	assign fdsu_frbus_data[31:0] = ex4_result[31:0];
	assign fdsu_frbus_fflags[4:0] = ex4_expt[4:0];
endmodule
module pa_fdsu_prepare (
	dp_xx_ex1_rm,
	ex1_div,
	ex1_divisor,
	ex1_expnt_adder_op0,
	ex1_expnt_adder_op1,
	ex1_of_result_lfn,
	ex1_op0_id,
	ex1_op0_sign,
	ex1_op1_id,
	ex1_op1_id_vld,
	ex1_op1_sel,
	ex1_oper_id_expnt,
	ex1_oper_id_expnt_f,
	ex1_oper_id_frac,
	ex1_oper_id_frac_f,
	ex1_remainder,
	ex1_result_sign,
	ex1_rm,
	ex1_sqrt,
	fdsu_ex1_sel,
	idu_fpu_ex1_func,
	idu_fpu_ex1_srcf0,
	idu_fpu_ex1_srcf1
);
	input wire [2:0] dp_xx_ex1_rm;
	input wire ex1_op0_id;
	input wire ex1_op1_id;
	input wire ex1_op1_sel;
	input wire [12:0] ex1_oper_id_expnt_f;
	input wire [51:0] ex1_oper_id_frac_f;
	input wire fdsu_ex1_sel;
	input wire [9:0] idu_fpu_ex1_func;
	input wire [31:0] idu_fpu_ex1_srcf0;
	input wire [31:0] idu_fpu_ex1_srcf1;
	output wire ex1_div;
	output wire [23:0] ex1_divisor;
	output wire [12:0] ex1_expnt_adder_op0;
	output reg [12:0] ex1_expnt_adder_op1;
	output reg ex1_of_result_lfn;
	output wire ex1_op0_sign;
	output wire ex1_op1_id_vld;
	output wire [12:0] ex1_oper_id_expnt;
	output wire [51:0] ex1_oper_id_frac;
	output wire [31:0] ex1_remainder;
	output wire ex1_result_sign;
	output wire [2:0] ex1_rm;
	output wire ex1_sqrt;
	wire div_sign;
	wire [52:0] ex1_div_noid_nor_srt_op0;
	wire [52:0] ex1_div_noid_nor_srt_op1;
	wire [52:0] ex1_div_nor_srt_op0;
	wire [52:0] ex1_div_nor_srt_op1;
	wire [12:0] ex1_div_op0_expnt;
	wire [12:0] ex1_div_op1_expnt;
	wire [52:0] ex1_div_srt_op0;
	wire [52:0] ex1_div_srt_op1;
	wire ex1_double;
	wire ex1_op0_id_nor;
	wire ex1_op1_id_nor;
	wire ex1_op1_sign;
	wire [63:0] ex1_oper0;
	wire [51:0] ex1_oper0_frac;
	wire [12:0] ex1_oper0_id_expnt;
	wire [51:0] ex1_oper0_id_frac;
	wire [63:0] ex1_oper1;
	wire [51:0] ex1_oper1_frac;
	wire [12:0] ex1_oper1_id_expnt;
	wire [51:0] ex1_oper1_id_frac;
	wire [51:0] ex1_oper_frac;
	wire ex1_single;
	wire ex1_sqrt_expnt_odd;
	wire ex1_sqrt_op0_expnt_0;
	wire [12:0] ex1_sqrt_op1_expnt;
	wire [52:0] ex1_sqrt_srt_op0;
	wire [59:0] sqrt_remainder;
	wire sqrt_sign;
	assign ex1_sqrt = idu_fpu_ex1_func[0];
	assign ex1_div = idu_fpu_ex1_func[1];
	assign ex1_oper0[63:0] = {32'b00000000000000000000000000000000, idu_fpu_ex1_srcf0[31:0] & {32 {fdsu_ex1_sel}}};
	assign ex1_oper1[63:0] = {32'b00000000000000000000000000000000, idu_fpu_ex1_srcf1[31:0] & {32 {fdsu_ex1_sel}}};
	assign ex1_double = 1'b0;
	assign ex1_single = 1'b1;
	assign ex1_op0_id_nor = ex1_op0_id;
	assign ex1_op1_id_nor = ex1_op1_id;
	assign ex1_op0_sign = (ex1_double && ex1_oper0[63]) || (ex1_single && ex1_oper0[31]);
	assign ex1_op1_sign = (ex1_double && ex1_oper1[63]) || (ex1_single && ex1_oper1[31]);
	assign div_sign = ex1_op0_sign ^ ex1_op1_sign;
	assign sqrt_sign = ex1_op0_sign;
	assign ex1_result_sign = (ex1_div ? div_sign : sqrt_sign);
	assign ex1_oper_frac[51:0] = (ex1_op1_sel ? ex1_oper1_frac[51:0] : ex1_oper0_frac[51:0]);
	pa_fdsu_ff1 x_frac_expnt(
		.fanc_shift_num(ex1_oper_id_frac[51:0]),
		.frac_bin_val(ex1_oper_id_expnt[12:0]),
		.frac_num(ex1_oper_frac[51:0])
	);
	assign ex1_oper0_id_expnt[12:0] = (ex1_op1_sel ? ex1_oper_id_expnt_f[12:0] : ex1_oper_id_expnt[12:0]);
	assign ex1_oper0_id_frac[51:0] = (ex1_op1_sel ? ex1_oper_id_frac_f[51:0] : ex1_oper_id_frac[51:0]);
	assign ex1_oper1_id_expnt[12:0] = ex1_oper_id_expnt[12:0];
	assign ex1_oper1_id_frac[51:0] = ex1_oper_id_frac[51:0];
	assign ex1_oper0_frac[51:0] = ({52 {ex1_double}} & ex1_oper0[51:0]) | ({52 {ex1_single}} & {ex1_oper0[22:0], 29'b00000000000000000000000000000});
	assign ex1_oper1_frac[51:0] = ({52 {ex1_double}} & ex1_oper1[51:0]) | ({52 {ex1_single}} & {ex1_oper1[22:0], 29'b00000000000000000000000000000});
	assign ex1_div_op0_expnt[12:0] = ({13 {ex1_double}} & {2'b00, ex1_oper0[62:52]}) | ({13 {ex1_single}} & {5'b00000, ex1_oper0[30:23]});
	assign ex1_expnt_adder_op0[12:0] = (ex1_op0_id_nor ? ex1_oper0_id_expnt[12:0] : ex1_div_op0_expnt[12:0]);
	assign ex1_div_op1_expnt[12:0] = ({13 {ex1_double}} & {2'b00, ex1_oper1[62:52]}) | ({13 {ex1_single}} & {5'b00000, ex1_oper1[30:23]});
	assign ex1_sqrt_op1_expnt[12:0] = ({13 {ex1_double}} & {3'b000, {10 {1'b1}}}) | ({13 {ex1_single}} & {6'b000000, {7 {1'b1}}});
	always @(ex1_oper1_id_expnt[12:0] or ex1_div or ex1_op1_id_nor or ex1_sqrt_op1_expnt[12:0] or ex1_sqrt or ex1_div_op1_expnt[12:0])
		case ({ex1_div, ex1_sqrt})
			2'b10: ex1_expnt_adder_op1[12:0] = (ex1_op1_id_nor ? ex1_oper1_id_expnt[12:0] : ex1_div_op1_expnt[12:0]);
			2'b01: ex1_expnt_adder_op1[12:0] = ex1_sqrt_op1_expnt[12:0];
			default: ex1_expnt_adder_op1[12:0] = 13'b0000000000000;
		endcase
	assign ex1_sqrt_op0_expnt_0 = (ex1_op0_id_nor ? ex1_oper_id_expnt[0] : ex1_div_op0_expnt[0]);
	assign ex1_sqrt_expnt_odd = !ex1_sqrt_op0_expnt_0;
	assign ex1_rm[2:0] = dp_xx_ex1_rm[2:0];
	always @(ex1_rm[2:0] or ex1_result_sign)
		case (ex1_rm[2:0])
			3'b000: ex1_of_result_lfn = 1'b0;
			3'b001: ex1_of_result_lfn = 1'b1;
			3'b010: ex1_of_result_lfn = !ex1_result_sign;
			3'b011: ex1_of_result_lfn = ex1_result_sign;
			3'b100: ex1_of_result_lfn = 1'b0;
			default: ex1_of_result_lfn = 1'b0;
		endcase
	assign ex1_remainder[31:0] = ({32 {ex1_div}} & {5'b00000, ex1_div_srt_op0[52:28], 2'b00}) | ({32 {ex1_sqrt}} & sqrt_remainder[59:28]);
	assign ex1_divisor[23:0] = ex1_div_srt_op1[52:29];
	assign ex1_div_srt_op0[52:0] = ex1_div_nor_srt_op0[52:0];
	assign ex1_div_srt_op1[52:0] = ex1_div_nor_srt_op1[52:0];
	assign ex1_div_noid_nor_srt_op0[52:0] = ({53 {ex1_double}} & {1'b1, ex1_oper0[51:0]}) | ({53 {ex1_single}} & {1'b1, ex1_oper0[22:0], 29'b00000000000000000000000000000});
	assign ex1_div_nor_srt_op0[52:0] = (ex1_op0_id_nor ? {ex1_oper0_id_frac[51:0], 1'b0} : ex1_div_noid_nor_srt_op0[52:0]);
	assign ex1_div_noid_nor_srt_op1[52:0] = ({53 {ex1_double}} & {1'b1, ex1_oper1[51:0]}) | ({53 {ex1_single}} & {1'b1, ex1_oper1[22:0], 29'b00000000000000000000000000000});
	assign ex1_div_nor_srt_op1[52:0] = (ex1_op1_id_nor ? {ex1_oper1_id_frac[51:0], 1'b0} : ex1_div_noid_nor_srt_op1[52:0]);
	assign sqrt_remainder[59:0] = (ex1_sqrt_expnt_odd ? {5'b00000, ex1_sqrt_srt_op0[52:0], 2'b00} : {6'b000000, ex1_sqrt_srt_op0[52:0], 1'b0});
	assign ex1_sqrt_srt_op0[52:0] = ex1_div_srt_op0[52:0];
	assign ex1_op1_id_vld = ex1_op1_id_nor && ex1_div;
endmodule
module pa_fdsu_round_single (
	cp0_fpu_icg_en,
	cp0_yy_clk_en,
	ex3_expnt_adjust_result,
	ex3_frac_final_rst,
	ex3_pipedown,
	ex3_rslt_denorm,
	fdsu_ex3_id_srt_skip,
	fdsu_ex3_rem_sign,
	fdsu_ex3_rem_zero,
	fdsu_ex3_result_denorm_round_add_num,
	fdsu_ex4_denorm_to_tiny_frac,
	fdsu_ex4_nx,
	fdsu_ex4_potnt_norm,
	fdsu_ex4_result_nor,
	fdsu_yy_expnt_rst,
	fdsu_yy_result_inf,
	fdsu_yy_result_lfn,
	fdsu_yy_result_sign,
	fdsu_yy_rm,
	fdsu_yy_rslt_denorm,
	forever_cpuclk,
	pad_yy_icg_scan_en,
	total_qt_rt_30
);
	input wire cp0_fpu_icg_en;
	input wire cp0_yy_clk_en;
	input wire ex3_pipedown;
	input wire fdsu_ex3_id_srt_skip;
	input wire fdsu_ex3_rem_sign;
	input wire fdsu_ex3_rem_zero;
	input wire [23:0] fdsu_ex3_result_denorm_round_add_num;
	input wire [9:0] fdsu_yy_expnt_rst;
	input wire fdsu_yy_result_inf;
	input wire fdsu_yy_result_lfn;
	input wire fdsu_yy_result_sign;
	input wire [2:0] fdsu_yy_rm;
	input wire fdsu_yy_rslt_denorm;
	input wire forever_cpuclk;
	input wire pad_yy_icg_scan_en;
	input wire [29:0] total_qt_rt_30;
	output wire [9:0] ex3_expnt_adjust_result;
	output wire [25:0] ex3_frac_final_rst;
	output wire ex3_rslt_denorm;
	output reg fdsu_ex4_denorm_to_tiny_frac;
	output reg fdsu_ex4_nx;
	output reg [1:0] fdsu_ex4_potnt_norm;
	output reg fdsu_ex4_result_nor;
	reg denorm_to_tiny_frac;
	reg [25:0] frac_add1_op1;
	reg frac_add_1;
	reg frac_orig;
	reg [25:0] frac_sub1_op1;
	reg frac_sub_1;
	reg [27:0] qt_result_single_denorm_for_round;
	reg single_denorm_lst_frac;
	wire ex3_denorm_eq;
	wire ex3_denorm_gr;
	wire ex3_denorm_lst_frac;
	wire ex3_denorm_nx;
	wire ex3_denorm_plus;
	wire ex3_denorm_potnt_norm;
	wire ex3_denorm_zero;
	wire [9:0] ex3_expnt_adjst;
	wire ex3_nx;
	wire ex3_pipe_clk;
	wire ex3_pipe_clk_en;
	wire [1:0] ex3_potnt_norm;
	wire ex3_qt_eq;
	wire ex3_qt_gr;
	wire ex3_qt_sing_lo3_not0;
	wire ex3_qt_sing_lo4_not0;
	wire ex3_qt_zero;
	wire ex3_rst_eq_1;
	wire ex3_rst_nor;
	wire ex3_single_denorm_eq;
	wire ex3_single_denorm_gr;
	wire ex3_single_denorm_zero;
	wire ex3_single_low_not_zero;
	wire [9:0] fdsu_ex3_expnt_rst;
	wire fdsu_ex3_result_inf;
	wire fdsu_ex3_result_lfn;
	wire fdsu_ex3_result_sign;
	wire [2:0] fdsu_ex3_rm;
	wire fdsu_ex3_rslt_denorm;
	wire [25:0] frac_add1_op1_with_denorm;
	wire [25:0] frac_add1_rst;
	wire frac_denorm_rdn_add_1;
	wire frac_denorm_rdn_sub_1;
	wire frac_denorm_rmm_add_1;
	wire frac_denorm_rne_add_1;
	wire frac_denorm_rtz_sub_1;
	wire frac_denorm_rup_add_1;
	wire frac_denorm_rup_sub_1;
	wire [25:0] frac_final_rst;
	wire frac_rdn_add_1;
	wire frac_rdn_sub_1;
	wire frac_rmm_add_1;
	wire frac_rne_add_1;
	wire frac_rtz_sub_1;
	wire frac_rup_add_1;
	wire frac_rup_sub_1;
	wire [25:0] frac_sub1_op1_with_denorm;
	wire [25:0] frac_sub1_rst;
	assign fdsu_ex3_result_sign = fdsu_yy_result_sign;
	assign fdsu_ex3_expnt_rst[9:0] = fdsu_yy_expnt_rst[9:0];
	assign fdsu_ex3_result_inf = fdsu_yy_result_inf;
	assign fdsu_ex3_result_lfn = fdsu_yy_result_lfn;
	assign fdsu_ex3_rm[2:0] = fdsu_yy_rm[2:0];
	assign fdsu_ex3_rslt_denorm = fdsu_yy_rslt_denorm;
	assign ex3_qt_sing_lo4_not0 = |total_qt_rt_30[3:0];
	assign ex3_qt_sing_lo3_not0 = |total_qt_rt_30[2:0];
	assign ex3_qt_gr = (total_qt_rt_30[28] ? total_qt_rt_30[4] && ex3_qt_sing_lo4_not0 : total_qt_rt_30[3] && ex3_qt_sing_lo3_not0);
	assign ex3_qt_eq = (total_qt_rt_30[28] ? total_qt_rt_30[4] && !ex3_qt_sing_lo4_not0 : total_qt_rt_30[3] && !ex3_qt_sing_lo3_not0);
	assign ex3_qt_zero = (total_qt_rt_30[28] ? ~|total_qt_rt_30[4:0] : ~|total_qt_rt_30[3:0]);
	assign ex3_rst_eq_1 = total_qt_rt_30[28] && ~|total_qt_rt_30[27:5];
	assign ex3_denorm_plus = !total_qt_rt_30[28] && (fdsu_ex3_expnt_rst[9:0] == 10'h382);
	assign ex3_denorm_potnt_norm = total_qt_rt_30[28] && (fdsu_ex3_expnt_rst[9:0] == 10'h381);
	assign ex3_rslt_denorm = ex3_denorm_plus || fdsu_ex3_rslt_denorm;
	always @(total_qt_rt_30[28:0] or fdsu_ex3_expnt_rst[9:0])
		case (fdsu_ex3_expnt_rst[9:0])
			10'h382: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[4:0], 23'b00000000000000000000000};
				single_denorm_lst_frac = total_qt_rt_30[5];
			end
			10'h381: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[5:0], 22'b0000000000000000000000};
				single_denorm_lst_frac = total_qt_rt_30[6];
			end
			10'h380: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[6:0], 21'b000000000000000000000};
				single_denorm_lst_frac = total_qt_rt_30[7];
			end
			10'h37f: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[7:0], 20'b00000000000000000000};
				single_denorm_lst_frac = total_qt_rt_30[8];
			end
			10'h37e: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[8:0], 19'b0000000000000000000};
				single_denorm_lst_frac = total_qt_rt_30[9];
			end
			10'h37d: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[9:0], 18'b000000000000000000};
				single_denorm_lst_frac = total_qt_rt_30[10];
			end
			10'h37c: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[10:0], 17'b00000000000000000};
				single_denorm_lst_frac = total_qt_rt_30[11];
			end
			10'h37b: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[11:0], 16'b0000000000000000};
				single_denorm_lst_frac = total_qt_rt_30[12];
			end
			10'h37a: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[12:0], 15'b000000000000000};
				single_denorm_lst_frac = total_qt_rt_30[13];
			end
			10'h379: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[13:0], 14'b00000000000000};
				single_denorm_lst_frac = total_qt_rt_30[14];
			end
			10'h378: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[14:0], 13'b0000000000000};
				single_denorm_lst_frac = total_qt_rt_30[15];
			end
			10'h377: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[15:0], 12'b000000000000};
				single_denorm_lst_frac = total_qt_rt_30[16];
			end
			10'h376: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[16:0], 11'b00000000000};
				single_denorm_lst_frac = total_qt_rt_30[17];
			end
			10'h375: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[17:0], 10'b0000000000};
				single_denorm_lst_frac = total_qt_rt_30[18];
			end
			10'h374: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[18:0], 9'b000000000};
				single_denorm_lst_frac = total_qt_rt_30[19];
			end
			10'h373: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[19:0], 8'b00000000};
				single_denorm_lst_frac = total_qt_rt_30[20];
			end
			10'h372: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[20:0], 7'b0000000};
				single_denorm_lst_frac = total_qt_rt_30[21];
			end
			10'h371: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[21:0], 6'b000000};
				single_denorm_lst_frac = total_qt_rt_30[22];
			end
			10'h370: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[22:0], 5'b00000};
				single_denorm_lst_frac = total_qt_rt_30[23];
			end
			10'h36f: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[23:0], 4'b0000};
				single_denorm_lst_frac = total_qt_rt_30[24];
			end
			10'h36e: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[24:0], 3'b000};
				single_denorm_lst_frac = total_qt_rt_30[25];
			end
			10'h36d: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[25:0], 2'b00};
				single_denorm_lst_frac = total_qt_rt_30[26];
			end
			10'h36c: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[26:0], 1'b0};
				single_denorm_lst_frac = total_qt_rt_30[27];
			end
			10'h36b: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[27:0]};
				single_denorm_lst_frac = total_qt_rt_30[28];
			end
			default: begin
				qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[28:1]};
				single_denorm_lst_frac = 1'b0;
			end
		endcase
	assign ex3_single_denorm_eq = qt_result_single_denorm_for_round[27] && !ex3_single_low_not_zero;
	assign ex3_single_low_not_zero = |qt_result_single_denorm_for_round[26:0];
	assign ex3_single_denorm_gr = qt_result_single_denorm_for_round[27] && ex3_single_low_not_zero;
	assign ex3_single_denorm_zero = !qt_result_single_denorm_for_round[27] && !ex3_single_low_not_zero;
	assign ex3_denorm_eq = ex3_single_denorm_eq;
	assign ex3_denorm_gr = ex3_single_denorm_gr;
	assign ex3_denorm_zero = ex3_single_denorm_zero;
	assign ex3_denorm_lst_frac = single_denorm_lst_frac;
	assign frac_rne_add_1 = ex3_qt_gr || (ex3_qt_eq && !fdsu_ex3_rem_sign);
	assign frac_rtz_sub_1 = ex3_qt_zero && fdsu_ex3_rem_sign;
	assign frac_rup_add_1 = !fdsu_ex3_result_sign && (!ex3_qt_zero || (!fdsu_ex3_rem_sign && !fdsu_ex3_rem_zero));
	assign frac_rup_sub_1 = fdsu_ex3_result_sign && (ex3_qt_zero && fdsu_ex3_rem_sign);
	assign frac_rdn_add_1 = fdsu_ex3_result_sign && (!ex3_qt_zero || (!fdsu_ex3_rem_sign && !fdsu_ex3_rem_zero));
	assign frac_rdn_sub_1 = !fdsu_ex3_result_sign && (ex3_qt_zero && fdsu_ex3_rem_sign);
	assign frac_rmm_add_1 = ex3_qt_gr || (ex3_qt_eq && !fdsu_ex3_rem_sign);
	assign frac_denorm_rne_add_1 = ex3_denorm_gr || (ex3_denorm_eq && ((fdsu_ex3_rem_zero && ex3_denorm_lst_frac) || (!fdsu_ex3_rem_zero && !fdsu_ex3_rem_sign)));
	assign frac_denorm_rtz_sub_1 = ex3_denorm_zero && fdsu_ex3_rem_sign;
	assign frac_denorm_rup_add_1 = !fdsu_ex3_result_sign && (!ex3_denorm_zero || (!fdsu_ex3_rem_sign && !fdsu_ex3_rem_zero));
	assign frac_denorm_rup_sub_1 = fdsu_ex3_result_sign && (ex3_denorm_zero && fdsu_ex3_rem_sign);
	assign frac_denorm_rdn_add_1 = fdsu_ex3_result_sign && (!ex3_denorm_zero || (!fdsu_ex3_rem_sign && !fdsu_ex3_rem_zero));
	assign frac_denorm_rdn_sub_1 = !fdsu_ex3_result_sign && (ex3_denorm_zero && fdsu_ex3_rem_sign);
	assign frac_denorm_rmm_add_1 = ex3_denorm_gr || (ex3_denorm_eq && !fdsu_ex3_rem_sign);
	always @(fdsu_ex3_rm[2:0] or frac_denorm_rdn_add_1 or frac_rne_add_1 or frac_denorm_rdn_sub_1 or fdsu_ex3_result_sign or frac_rup_add_1 or frac_denorm_rup_sub_1 or frac_rdn_sub_1 or frac_rtz_sub_1 or frac_rdn_add_1 or fdsu_ex3_id_srt_skip or frac_denorm_rtz_sub_1 or ex3_rslt_denorm or frac_rup_sub_1 or frac_denorm_rmm_add_1 or frac_denorm_rup_add_1 or frac_denorm_rne_add_1 or frac_rmm_add_1)
		case (fdsu_ex3_rm[2:0])
			3'b000: begin
				frac_add_1 = (ex3_rslt_denorm ? frac_denorm_rne_add_1 : frac_rne_add_1);
				frac_sub_1 = 1'b0;
				frac_orig = (ex3_rslt_denorm ? !frac_denorm_rne_add_1 : !frac_rne_add_1);
				denorm_to_tiny_frac = (fdsu_ex3_id_srt_skip ? 1'b0 : frac_denorm_rne_add_1);
			end
			3'b001: begin
				frac_add_1 = 1'b0;
				frac_sub_1 = (ex3_rslt_denorm ? frac_denorm_rtz_sub_1 : frac_rtz_sub_1);
				frac_orig = (ex3_rslt_denorm ? !frac_denorm_rtz_sub_1 : !frac_rtz_sub_1);
				denorm_to_tiny_frac = 1'b0;
			end
			3'b010: begin
				frac_add_1 = (ex3_rslt_denorm ? frac_denorm_rdn_add_1 : frac_rdn_add_1);
				frac_sub_1 = (ex3_rslt_denorm ? frac_denorm_rdn_sub_1 : frac_rdn_sub_1);
				frac_orig = (ex3_rslt_denorm ? !frac_denorm_rdn_add_1 && !frac_denorm_rdn_sub_1 : !frac_rdn_add_1 && !frac_rdn_sub_1);
				denorm_to_tiny_frac = (fdsu_ex3_id_srt_skip ? fdsu_ex3_result_sign : frac_denorm_rdn_add_1);
			end
			3'b011: begin
				frac_add_1 = (ex3_rslt_denorm ? frac_denorm_rup_add_1 : frac_rup_add_1);
				frac_sub_1 = (ex3_rslt_denorm ? frac_denorm_rup_sub_1 : frac_rup_sub_1);
				frac_orig = (ex3_rslt_denorm ? !frac_denorm_rup_add_1 && !frac_denorm_rup_sub_1 : !frac_rup_add_1 && !frac_rup_sub_1);
				denorm_to_tiny_frac = (fdsu_ex3_id_srt_skip ? !fdsu_ex3_result_sign : frac_denorm_rup_add_1);
			end
			3'b100: begin
				frac_add_1 = (ex3_rslt_denorm ? frac_denorm_rmm_add_1 : frac_rmm_add_1);
				frac_sub_1 = 1'b0;
				frac_orig = (ex3_rslt_denorm ? !frac_denorm_rmm_add_1 : !frac_rmm_add_1);
				denorm_to_tiny_frac = (fdsu_ex3_id_srt_skip ? 1'b0 : frac_denorm_rmm_add_1);
			end
			default: begin
				frac_add_1 = 1'b0;
				frac_sub_1 = 1'b0;
				frac_orig = 1'b0;
				denorm_to_tiny_frac = 1'b0;
			end
		endcase
	always @(total_qt_rt_30[28])
		case (total_qt_rt_30[28])
			1'b0: begin
				frac_add1_op1[25:0] = 26'b00000000000000000000000001;
				frac_sub1_op1[25:0] = {2'b11, {24 {1'b1}}};
			end
			1'b1: begin
				frac_add1_op1[25:0] = 26'b00000000000000000000000010;
				frac_sub1_op1[25:0] = {{25 {1'b1}}, 1'b0};
			end
			default: begin
				frac_add1_op1[25:0] = 26'b00000000000000000000000000;
				frac_sub1_op1[25:0] = 26'b00000000000000000000000000;
			end
		endcase
	assign frac_add1_rst[25:0] = {1'b0, total_qt_rt_30[28:4]} + frac_add1_op1_with_denorm[25:0];
	assign frac_add1_op1_with_denorm[25:0] = (ex3_rslt_denorm ? {1'b0, fdsu_ex3_result_denorm_round_add_num[23:0], 1'b0} : frac_add1_op1[25:0]);
	assign frac_sub1_rst[25:0] = (ex3_rst_eq_1 ? {3'b000, {23 {1'b1}}} : ({1'b0, total_qt_rt_30[28:4]} + frac_sub1_op1_with_denorm[25:0]) + {25'b0000000000000000000000000, ex3_rslt_denorm});
	assign frac_sub1_op1_with_denorm[25:0] = (ex3_rslt_denorm ? ~{1'b0, fdsu_ex3_result_denorm_round_add_num[23:0], 1'b0} : frac_sub1_op1[25:0]);
	assign frac_final_rst[25:0] = ((frac_add1_rst[25:0] & {26 {frac_add_1}}) | (frac_sub1_rst[25:0] & {26 {frac_sub_1}})) | ({1'b0, total_qt_rt_30[28:4]} & {26 {frac_orig}});
	assign ex3_rst_nor = !fdsu_ex3_result_inf && !fdsu_ex3_result_lfn;
	assign ex3_nx = ex3_rst_nor && ((!ex3_qt_zero || !fdsu_ex3_rem_zero) || ex3_denorm_nx);
	assign ex3_denorm_nx = ex3_rslt_denorm && (!ex3_denorm_zero || !fdsu_ex3_rem_zero);
	assign ex3_expnt_adjst[9:0] = 10'h07f;
	assign ex3_expnt_adjust_result[9:0] = fdsu_ex3_expnt_rst[9:0] + ex3_expnt_adjst[9:0];
	assign ex3_potnt_norm[1:0] = {ex3_denorm_plus, ex3_denorm_potnt_norm};
	gated_clk_cell x_ex3_pipe_clk(
		.clk_in(forever_cpuclk),
		.clk_out(ex3_pipe_clk),
		.external_en(1'b0),
		.global_en(cp0_yy_clk_en),
		.local_en(ex3_pipe_clk_en),
		.module_en(cp0_fpu_icg_en),
		.pad_yy_icg_scan_en(pad_yy_icg_scan_en)
	);
	assign ex3_pipe_clk_en = ex3_pipedown;
	always @(posedge ex3_pipe_clk)
		if (ex3_pipedown) begin
			fdsu_ex4_result_nor <= ex3_rst_nor;
			fdsu_ex4_nx <= ex3_nx;
			fdsu_ex4_denorm_to_tiny_frac <= denorm_to_tiny_frac;
			fdsu_ex4_potnt_norm[1:0] <= ex3_potnt_norm[1:0];
		end
		else begin
			fdsu_ex4_result_nor <= fdsu_ex4_result_nor;
			fdsu_ex4_nx <= fdsu_ex4_nx;
			fdsu_ex4_denorm_to_tiny_frac <= fdsu_ex4_denorm_to_tiny_frac;
			fdsu_ex4_potnt_norm[1:0] <= fdsu_ex4_potnt_norm[1:0];
		end
	assign ex3_frac_final_rst[25:0] = frac_final_rst[25:0];
endmodule
module pa_fdsu_special (
	cp0_fpu_xx_dqnan,
	dp_xx_ex1_cnan,
	dp_xx_ex1_id,
	dp_xx_ex1_inf,
	dp_xx_ex1_qnan,
	dp_xx_ex1_snan,
	dp_xx_ex1_zero,
	ex1_div,
	ex1_op0_id,
	ex1_op0_norm,
	ex1_op0_sign,
	ex1_op1_id,
	ex1_op1_norm,
	ex1_result_sign,
	ex1_sqrt,
	ex1_srt_skip,
	fdsu_fpu_ex1_fflags,
	fdsu_fpu_ex1_special_sel,
	fdsu_fpu_ex1_special_sign
);
	input wire cp0_fpu_xx_dqnan;
	input wire [2:0] dp_xx_ex1_cnan;
	input wire [2:0] dp_xx_ex1_id;
	input wire [2:0] dp_xx_ex1_inf;
	input wire [2:0] dp_xx_ex1_qnan;
	input wire [2:0] dp_xx_ex1_snan;
	input wire [2:0] dp_xx_ex1_zero;
	input wire ex1_div;
	input wire ex1_op0_sign;
	input wire ex1_result_sign;
	input wire ex1_sqrt;
	output wire ex1_op0_id;
	output wire ex1_op0_norm;
	output wire ex1_op1_id;
	output wire ex1_op1_norm;
	output wire ex1_srt_skip;
	output wire [4:0] fdsu_fpu_ex1_fflags;
	output wire [7:0] fdsu_fpu_ex1_special_sel;
	output wire [3:0] fdsu_fpu_ex1_special_sign;
	reg ex1_result_cnan;
	reg ex1_result_qnan_op0;
	reg ex1_result_qnan_op1;
	wire ex1_div_dz;
	wire ex1_div_nv;
	wire ex1_div_rst_inf;
	wire ex1_div_rst_qnan;
	wire ex1_div_rst_zero;
	wire ex1_dz;
	wire [4:0] ex1_fflags;
	wire ex1_nv;
	wire ex1_op0_cnan;
	wire ex1_op0_inf;
	wire ex1_op0_is_qnan;
	wire ex1_op0_is_snan;
	wire ex1_op0_qnan;
	wire ex1_op0_snan;
	wire ex1_op0_tt_zero;
	wire ex1_op0_zero;
	wire ex1_op1_cnan;
	wire ex1_op1_inf;
	wire ex1_op1_is_qnan;
	wire ex1_op1_is_snan;
	wire ex1_op1_qnan;
	wire ex1_op1_snan;
	wire ex1_op1_tt_zero;
	wire ex1_op1_zero;
	wire ex1_result_inf;
	wire ex1_result_lfn;
	wire ex1_result_qnan;
	wire ex1_result_zero;
	wire ex1_rst_default_qnan;
	wire [7:0] ex1_special_sel;
	wire [3:0] ex1_special_sign;
	wire ex1_sqrt_nv;
	wire ex1_sqrt_rst_inf;
	wire ex1_sqrt_rst_qnan;
	wire ex1_sqrt_rst_zero;
	assign ex1_op0_inf = dp_xx_ex1_inf[0];
	assign ex1_op1_inf = dp_xx_ex1_inf[1];
	assign ex1_op0_zero = dp_xx_ex1_zero[0];
	assign ex1_op1_zero = dp_xx_ex1_zero[1];
	assign ex1_op0_id = dp_xx_ex1_id[0];
	assign ex1_op1_id = dp_xx_ex1_id[1];
	assign ex1_op0_cnan = dp_xx_ex1_cnan[0];
	assign ex1_op1_cnan = dp_xx_ex1_cnan[1];
	assign ex1_op0_snan = dp_xx_ex1_snan[0];
	assign ex1_op1_snan = dp_xx_ex1_snan[1];
	assign ex1_op0_qnan = dp_xx_ex1_qnan[0];
	assign ex1_op1_qnan = dp_xx_ex1_qnan[1];
	assign ex1_nv = (ex1_div && ex1_div_nv) || (ex1_sqrt && ex1_sqrt_nv);
	assign ex1_div_nv = ((ex1_op0_snan || ex1_op1_snan) || (ex1_op0_tt_zero && ex1_op1_tt_zero)) || (ex1_op0_inf && ex1_op1_inf);
	assign ex1_op0_tt_zero = ex1_op0_zero;
	assign ex1_op1_tt_zero = ex1_op1_zero;
	assign ex1_sqrt_nv = ex1_op0_snan || (ex1_op0_sign && (ex1_op0_norm || ex1_op0_inf));
	assign ex1_op0_norm = (((!ex1_op0_inf && !ex1_op0_zero) && !ex1_op0_snan) && !ex1_op0_qnan) && !ex1_op0_cnan;
	assign ex1_op1_norm = (((!ex1_op1_inf && !ex1_op1_zero) && !ex1_op1_snan) && !ex1_op1_qnan) && !ex1_op1_cnan;
	assign ex1_dz = ex1_div && ex1_div_dz;
	assign ex1_div_dz = ex1_op1_tt_zero && ex1_op0_norm;
	assign ex1_result_zero = (ex1_div_rst_zero && ex1_div) || (ex1_sqrt_rst_zero && ex1_sqrt);
	assign ex1_div_rst_zero = (ex1_op0_tt_zero && ex1_op1_norm) || ((((!ex1_op0_inf && !ex1_op0_qnan) && !ex1_op0_snan) && !ex1_op0_cnan) && ex1_op1_inf);
	assign ex1_sqrt_rst_zero = ex1_op0_tt_zero;
	assign ex1_result_qnan = ((ex1_div_rst_qnan && ex1_div) || (ex1_sqrt_rst_qnan && ex1_sqrt)) || ex1_nv;
	assign ex1_div_rst_qnan = ex1_op0_qnan || ex1_op1_qnan;
	assign ex1_sqrt_rst_qnan = ex1_op0_qnan;
	assign ex1_rst_default_qnan = (((ex1_div && ex1_op0_zero) && ex1_op1_zero) || ((ex1_div && ex1_op0_inf) && ex1_op1_inf)) || ((ex1_sqrt && ex1_op0_sign) && (ex1_op0_norm || ex1_op0_inf));
	assign ex1_result_inf = ((ex1_div_rst_inf && ex1_div) || (ex1_sqrt_rst_inf && ex1_sqrt)) || ex1_dz;
	assign ex1_div_rst_inf = (((ex1_op0_inf && !ex1_op1_inf) && !ex1_op1_qnan) && !ex1_op1_snan) && !ex1_op1_cnan;
	assign ex1_sqrt_rst_inf = ex1_op0_inf && !ex1_op0_sign;
	assign ex1_result_lfn = 1'b0;
	assign ex1_op0_is_snan = ex1_op0_snan;
	assign ex1_op1_is_snan = ex1_op1_snan && ex1_div;
	assign ex1_op0_is_qnan = ex1_op0_qnan;
	assign ex1_op1_is_qnan = ex1_op1_qnan && ex1_div;
	always @(ex1_op0_is_snan or ex1_op0_cnan or ex1_result_qnan or ex1_op0_is_qnan or ex1_rst_default_qnan or cp0_fpu_xx_dqnan or ex1_op1_cnan or ex1_op1_is_qnan or ex1_op1_is_snan)
		if (ex1_rst_default_qnan) begin
			ex1_result_qnan_op0 = 1'b0;
			ex1_result_qnan_op1 = 1'b0;
			ex1_result_cnan = ex1_result_qnan;
		end
		else if (ex1_op0_is_snan && cp0_fpu_xx_dqnan) begin
			ex1_result_qnan_op0 = ex1_result_qnan;
			ex1_result_qnan_op1 = 1'b0;
			ex1_result_cnan = 1'b0;
		end
		else if (ex1_op1_is_snan && cp0_fpu_xx_dqnan) begin
			ex1_result_qnan_op0 = 1'b0;
			ex1_result_qnan_op1 = ex1_result_qnan;
			ex1_result_cnan = 1'b0;
		end
		else if (ex1_op0_is_qnan && cp0_fpu_xx_dqnan) begin
			ex1_result_qnan_op0 = ex1_result_qnan && !ex1_op0_cnan;
			ex1_result_qnan_op1 = 1'b0;
			ex1_result_cnan = ex1_result_qnan && ex1_op0_cnan;
		end
		else if (ex1_op1_is_qnan && cp0_fpu_xx_dqnan) begin
			ex1_result_qnan_op0 = 1'b0;
			ex1_result_qnan_op1 = ex1_result_qnan && !ex1_op1_cnan;
			ex1_result_cnan = ex1_result_qnan && ex1_op1_cnan;
		end
		else begin
			ex1_result_qnan_op0 = 1'b0;
			ex1_result_qnan_op1 = 1'b0;
			ex1_result_cnan = ex1_result_qnan;
		end
	assign ex1_srt_skip = ((ex1_result_zero || ex1_result_qnan) || ex1_result_lfn) || ex1_result_inf;
	assign ex1_fflags[4:0] = {ex1_nv, ex1_dz, 3'b000};
	assign ex1_special_sel[7:0] = {1'b0, ex1_result_qnan_op1, ex1_result_qnan_op0, ex1_result_cnan, ex1_result_lfn, ex1_result_inf, ex1_result_zero, 1'b0};
	assign ex1_special_sign[3:0] = {ex1_result_sign, ex1_result_sign, ex1_result_sign, 1'b0};
	assign fdsu_fpu_ex1_fflags[4:0] = ex1_fflags[4:0];
	assign fdsu_fpu_ex1_special_sel[7:0] = ex1_special_sel[7:0];
	assign fdsu_fpu_ex1_special_sign[3:0] = ex1_special_sign[3:0];
endmodule
module pa_fdsu_srt_single (
	cp0_fpu_icg_en,
	cp0_yy_clk_en,
	ex1_divisor,
	ex1_expnt_adder_op1,
	ex1_oper_id_frac,
	ex1_oper_id_frac_f,
	ex1_pipedown,
	ex1_pipedown_gate,
	ex1_remainder,
	ex1_save_op0,
	ex1_save_op0_gate,
	ex2_expnt_adder_op0,
	ex2_of,
	ex2_pipe_clk,
	ex2_pipedown,
	ex2_potnt_of,
	ex2_potnt_uf,
	ex2_result_inf,
	ex2_result_lfn,
	ex2_rslt_denorm,
	ex2_srt_expnt_rst,
	ex2_srt_first_round,
	ex2_uf,
	ex2_uf_srt_skip,
	ex3_frac_final_rst,
	ex3_pipedown,
	fdsu_ex3_id_srt_skip,
	fdsu_ex3_rem_sign,
	fdsu_ex3_rem_zero,
	fdsu_ex3_result_denorm_round_add_num,
	fdsu_ex4_frac,
	fdsu_yy_div,
	fdsu_yy_of_rm_lfn,
	fdsu_yy_op0_norm,
	fdsu_yy_op1_norm,
	fdsu_yy_sqrt,
	forever_cpuclk,
	pad_yy_icg_scan_en,
	srt_remainder_zero,
	srt_sm_on,
	total_qt_rt_30
);
	input wire cp0_fpu_icg_en;
	input wire cp0_yy_clk_en;
	input wire [23:0] ex1_divisor;
	input wire [12:0] ex1_expnt_adder_op1;
	input wire [51:0] ex1_oper_id_frac;
	input wire ex1_pipedown;
	input wire ex1_pipedown_gate;
	input wire [31:0] ex1_remainder;
	input wire ex1_save_op0;
	input wire ex1_save_op0_gate;
	input wire [9:0] ex2_expnt_adder_op0;
	input wire ex2_pipe_clk;
	input wire ex2_pipedown;
	input wire ex2_srt_first_round;
	input wire [25:0] ex3_frac_final_rst;
	input wire ex3_pipedown;
	input wire fdsu_yy_div;
	input wire fdsu_yy_of_rm_lfn;
	input wire fdsu_yy_op0_norm;
	input wire fdsu_yy_op1_norm;
	input wire fdsu_yy_sqrt;
	input wire forever_cpuclk;
	input wire pad_yy_icg_scan_en;
	input wire srt_sm_on;
	output wire [51:0] ex1_oper_id_frac_f;
	output wire ex2_of;
	output wire ex2_potnt_of;
	output wire ex2_potnt_uf;
	output wire ex2_result_inf;
	output wire ex2_result_lfn;
	output wire ex2_rslt_denorm;
	output wire [9:0] ex2_srt_expnt_rst;
	output wire ex2_uf;
	output wire ex2_uf_srt_skip;
	output reg fdsu_ex3_id_srt_skip;
	output reg fdsu_ex3_rem_sign;
	output reg fdsu_ex3_rem_zero;
	output reg [23:0] fdsu_ex3_result_denorm_round_add_num;
	output wire [25:0] fdsu_ex4_frac;
	output wire srt_remainder_zero;
	output reg [29:0] total_qt_rt_30;
	reg [31:0] cur_rem;
	reg [7:0] digit_bound_1;
	reg [7:0] digit_bound_2;
	reg [23:0] ex2_result_denorm_round_add_num;
	reg [29:0] qt_rt_const_shift_std;
	reg [7:0] qtrt_sel_rem;
	reg [31:0] rem_add1_op1;
	reg [31:0] rem_add2_op1;
	reg [25:0] srt_divisor;
	reg [31:0] srt_remainder;
	reg [29:0] total_qt_rt_30_next;
	reg [29:0] total_qt_rt_minus_30;
	reg [29:0] total_qt_rt_minus_30_next;
	wire [7:0] bound1_cmp_result;
	wire bound1_cmp_sign;
	wire [7:0] bound2_cmp_result;
	wire bound2_cmp_sign;
	wire [3:0] bound_sel;
	wire [31:0] cur_doub_rem_1;
	wire [31:0] cur_doub_rem_2;
	wire [31:0] cur_rem_1;
	wire [31:0] cur_rem_2;
	wire [31:0] div_qt_1_rem_add_op1;
	wire [31:0] div_qt_2_rem_add_op1;
	wire [31:0] div_qt_r1_rem_add_op1;
	wire [31:0] div_qt_r2_rem_add_op1;
	wire ex1_ex2_pipe_clk;
	wire ex1_ex2_pipe_clk_en;
	wire ex2_div_of;
	wire ex2_div_uf;
	wire [9:0] ex2_expnt_adder_op1;
	wire ex2_expnt_of;
	wire [9:0] ex2_expnt_result;
	wire ex2_expnt_uf;
	wire ex2_id_nor_srt_skip;
	wire ex2_of_plus;
	wire ex2_potnt_of_pre;
	wire ex2_potnt_uf_pre;
	wire [9:0] ex2_sqrt_expnt_result;
	wire ex2_uf_plus;
	wire fdsu_ex2_div;
	wire [9:0] fdsu_ex2_expnt_rst;
	wire fdsu_ex2_of_rm_lfn;
	wire fdsu_ex2_op0_norm;
	wire fdsu_ex2_op1_norm;
	wire fdsu_ex2_result_lfn;
	wire fdsu_ex2_sqrt;
	wire qt_clk;
	wire qt_clk_en;
	wire [29:0] qt_rt_const_pre_sel_q1;
	wire [29:0] qt_rt_const_pre_sel_q2;
	wire [29:0] qt_rt_const_q1;
	wire [29:0] qt_rt_const_q2;
	wire [29:0] qt_rt_const_q3;
	wire [29:0] qt_rt_const_shift_std_next;
	wire [29:0] qt_rt_mins_const_pre_sel_q1;
	wire [29:0] qt_rt_mins_const_pre_sel_q2;
	wire rem_sign;
	wire [31:0] sqrt_qt_1_rem_add_op1;
	wire [31:0] sqrt_qt_2_rem_add_op1;
	wire [31:0] sqrt_qt_r1_rem_add_op1;
	wire [31:0] sqrt_qt_r2_rem_add_op1;
	wire srt_div_clk;
	wire srt_div_clk_en;
	wire [31:0] srt_remainder_nxt;
	wire [31:0] srt_remainder_shift;
	wire srt_remainder_sign;
	wire [29:0] total_qt_rt_pre_sel;
	assign fdsu_ex2_div = fdsu_yy_div;
	assign fdsu_ex2_sqrt = fdsu_yy_sqrt;
	assign fdsu_ex2_op0_norm = fdsu_yy_op0_norm;
	assign fdsu_ex2_op1_norm = fdsu_yy_op1_norm;
	assign fdsu_ex2_of_rm_lfn = fdsu_yy_of_rm_lfn;
	assign fdsu_ex2_result_lfn = 1'b0;
	assign ex2_expnt_result[9:0] = ex2_expnt_adder_op0[9:0] - ex2_expnt_adder_op1[9:0];
	assign ex2_sqrt_expnt_result[9:0] = {ex2_expnt_result[9], ex2_expnt_result[9:1]};
	assign ex2_srt_expnt_rst[9:0] = (fdsu_ex2_sqrt ? ex2_sqrt_expnt_result[9:0] : ex2_expnt_result[9:0]);
	assign fdsu_ex2_expnt_rst[9:0] = ex2_srt_expnt_rst[9:0];
	assign ex2_expnt_of = ~fdsu_ex2_expnt_rst[9] && (fdsu_ex2_expnt_rst[8] || (fdsu_ex2_expnt_rst[7] && |fdsu_ex2_expnt_rst[6:0]));
	assign ex2_potnt_of_pre = ((~fdsu_ex2_expnt_rst[9] && ~fdsu_ex2_expnt_rst[8]) && fdsu_ex2_expnt_rst[7]) && ~|fdsu_ex2_expnt_rst[6:0];
	assign ex2_potnt_of = ((ex2_potnt_of_pre && fdsu_ex2_op0_norm) && fdsu_ex2_op1_norm) && fdsu_ex2_div;
	assign ex2_expnt_uf = fdsu_ex2_expnt_rst[9] && (fdsu_ex2_expnt_rst[8:0] <= 9'h181);
	assign ex2_potnt_uf_pre = ((&fdsu_ex2_expnt_rst[9:7] && ~|fdsu_ex2_expnt_rst[6:2]) && fdsu_ex2_expnt_rst[1]) && !fdsu_ex2_expnt_rst[0];
	assign ex2_potnt_uf = (((ex2_potnt_uf_pre && fdsu_ex2_op0_norm) && fdsu_ex2_op1_norm) && fdsu_ex2_div) || (ex2_potnt_uf_pre && fdsu_ex2_op0_norm);
	assign ex2_of = ex2_of_plus;
	assign ex2_of_plus = ex2_div_of && fdsu_ex2_div;
	assign ex2_div_of = (fdsu_ex2_op0_norm && fdsu_ex2_op1_norm) && ex2_expnt_of;
	assign ex2_uf = ex2_uf_plus;
	assign ex2_uf_plus = ex2_div_uf && fdsu_ex2_div;
	assign ex2_div_uf = (fdsu_ex2_op0_norm && fdsu_ex2_op1_norm) && ex2_expnt_uf;
	assign ex2_id_nor_srt_skip = fdsu_ex2_expnt_rst[9] && (fdsu_ex2_expnt_rst[8:0] < 9'h16a);
	assign ex2_uf_srt_skip = ex2_id_nor_srt_skip;
	assign ex2_rslt_denorm = ex2_uf;
	always @(fdsu_ex2_expnt_rst[9:0])
		case (fdsu_ex2_expnt_rst[9:0])
			10'h382: ex2_result_denorm_round_add_num[23:0] = 24'h000001;
			10'h381: ex2_result_denorm_round_add_num[23:0] = 24'h000002;
			10'h380: ex2_result_denorm_round_add_num[23:0] = 24'h000004;
			10'h37f: ex2_result_denorm_round_add_num[23:0] = 24'h000008;
			10'h37e: ex2_result_denorm_round_add_num[23:0] = 24'h000010;
			10'h37d: ex2_result_denorm_round_add_num[23:0] = 24'h000020;
			10'h37c: ex2_result_denorm_round_add_num[23:0] = 24'h000040;
			10'h37b: ex2_result_denorm_round_add_num[23:0] = 24'h000080;
			10'h37a: ex2_result_denorm_round_add_num[23:0] = 24'h000100;
			10'h379: ex2_result_denorm_round_add_num[23:0] = 24'h000200;
			10'h378: ex2_result_denorm_round_add_num[23:0] = 24'h000400;
			10'h377: ex2_result_denorm_round_add_num[23:0] = 24'h000800;
			10'h376: ex2_result_denorm_round_add_num[23:0] = 24'h001000;
			10'h375: ex2_result_denorm_round_add_num[23:0] = 24'h002000;
			10'h374: ex2_result_denorm_round_add_num[23:0] = 24'h004000;
			10'h373: ex2_result_denorm_round_add_num[23:0] = 24'h008000;
			10'h372: ex2_result_denorm_round_add_num[23:0] = 24'h010000;
			10'h371: ex2_result_denorm_round_add_num[23:0] = 24'h020000;
			10'h370: ex2_result_denorm_round_add_num[23:0] = 24'h040000;
			10'h36f: ex2_result_denorm_round_add_num[23:0] = 24'h080000;
			10'h36e: ex2_result_denorm_round_add_num[23:0] = 24'h100000;
			10'h36d: ex2_result_denorm_round_add_num[23:0] = 24'h200000;
			10'h36c: ex2_result_denorm_round_add_num[23:0] = 24'h400000;
			10'h36b: ex2_result_denorm_round_add_num[23:0] = 24'h800000;
			default: ex2_result_denorm_round_add_num[23:0] = 24'h000000;
		endcase
	assign ex2_result_inf = ex2_of_plus && !fdsu_ex2_of_rm_lfn;
	assign ex2_result_lfn = fdsu_ex2_result_lfn || (ex2_of_plus && fdsu_ex2_of_rm_lfn);
	always @(posedge ex1_ex2_pipe_clk)
		if (ex1_pipedown)
			fdsu_ex3_result_denorm_round_add_num[23:0] <= {14'b00000000000000, ex1_expnt_adder_op1[9:0]};
		else if (ex2_pipedown)
			fdsu_ex3_result_denorm_round_add_num[23:0] <= ex2_result_denorm_round_add_num[23:0];
		else
			fdsu_ex3_result_denorm_round_add_num[23:0] <= fdsu_ex3_result_denorm_round_add_num[23:0];
	assign ex2_expnt_adder_op1 = fdsu_ex3_result_denorm_round_add_num[9:0];
	assign ex1_ex2_pipe_clk_en = ex1_pipedown_gate || ex2_pipedown;
	gated_clk_cell x_ex1_ex2_pipe_clk(
		.clk_in(forever_cpuclk),
		.clk_out(ex1_ex2_pipe_clk),
		.external_en(1'b0),
		.global_en(cp0_yy_clk_en),
		.local_en(ex1_ex2_pipe_clk_en),
		.module_en(cp0_fpu_icg_en),
		.pad_yy_icg_scan_en(pad_yy_icg_scan_en)
	);
	always @(posedge ex2_pipe_clk)
		if (ex2_pipedown) begin
			fdsu_ex3_rem_sign <= srt_remainder_sign;
			fdsu_ex3_rem_zero <= srt_remainder_zero;
			fdsu_ex3_id_srt_skip <= ex2_id_nor_srt_skip;
		end
		else begin
			fdsu_ex3_rem_sign <= fdsu_ex3_rem_sign;
			fdsu_ex3_rem_zero <= fdsu_ex3_rem_zero;
			fdsu_ex3_id_srt_skip <= fdsu_ex3_id_srt_skip;
		end
	always @(posedge qt_clk)
		if (ex1_pipedown)
			srt_remainder[31:0] <= ex1_remainder[31:0];
		else if (srt_sm_on)
			srt_remainder[31:0] <= srt_remainder_nxt[31:0];
		else
			srt_remainder[31:0] <= srt_remainder[31:0];
	gated_clk_cell x_srt_div_clk(
		.clk_in(forever_cpuclk),
		.clk_out(srt_div_clk),
		.external_en(1'b0),
		.global_en(cp0_yy_clk_en),
		.local_en(srt_div_clk_en),
		.module_en(cp0_fpu_icg_en),
		.pad_yy_icg_scan_en(pad_yy_icg_scan_en)
	);
	assign srt_div_clk_en = (ex1_pipedown_gate || ex1_save_op0_gate) || ex3_pipedown;
	always @(posedge srt_div_clk)
		if (ex1_save_op0)
			srt_divisor[25:0] <= {3'b000, ex1_oper_id_frac[51:29]};
		else if (ex1_pipedown)
			srt_divisor[25:0] <= {2'b00, ex1_divisor[23:0]};
		else if (ex3_pipedown)
			srt_divisor[25:0] <= ex3_frac_final_rst[25:0];
		else
			srt_divisor[25:0] <= srt_divisor[25:0];
	assign ex1_oper_id_frac_f[51:0] = {srt_divisor[22:0], 29'b00000000000000000000000000000};
	assign fdsu_ex4_frac[25:0] = srt_divisor[25:0];
	assign bound_sel[3:0] = (fdsu_ex2_div ? srt_divisor[23:20] : (ex2_srt_first_round ? 4'b1010 : total_qt_rt_30[28:25]));
	always @(bound_sel[3:0])
		case (bound_sel[3:0])
			4'b0000: begin
				digit_bound_1[7:0] = 8'b11110100;
				digit_bound_2[7:0] = 8'b11010001;
			end
			4'b1000: begin
				digit_bound_1[7:0] = 8'b11111001;
				digit_bound_2[7:0] = 8'b11100111;
			end
			4'b1001: begin
				digit_bound_1[7:0] = 8'b11111001;
				digit_bound_2[7:0] = 8'b11100100;
			end
			4'b1010: begin
				digit_bound_1[7:0] = 8'b11111000;
				digit_bound_2[7:0] = 8'b11100001;
			end
			4'b1011: begin
				digit_bound_1[7:0] = 8'b11110111;
				digit_bound_2[7:0] = 8'b11011111;
			end
			4'b1100: begin
				digit_bound_1[7:0] = 8'b11110111;
				digit_bound_2[7:0] = 8'b11011100;
			end
			4'b1101: begin
				digit_bound_1[7:0] = 8'b11110110;
				digit_bound_2[7:0] = 8'b11011001;
			end
			4'b1110: begin
				digit_bound_1[7:0] = 8'b11110101;
				digit_bound_2[7:0] = 8'b11010111;
			end
			4'b1111: begin
				digit_bound_1[7:0] = 8'b11110100;
				digit_bound_2[7:0] = 8'b11010001;
			end
			default: begin
				digit_bound_1[7:0] = 8'b11111001;
				digit_bound_2[7:0] = 8'b11100111;
			end
		endcase
	assign bound1_cmp_result[7:0] = qtrt_sel_rem[7:0] + digit_bound_1[7:0];
	assign bound2_cmp_result[7:0] = qtrt_sel_rem[7:0] + digit_bound_2[7:0];
	assign bound1_cmp_sign = bound1_cmp_result[7];
	assign bound2_cmp_sign = bound2_cmp_result[7];
	assign rem_sign = srt_remainder[29];
	always @(ex2_srt_first_round or fdsu_ex2_sqrt or srt_remainder[29:21])
		if (ex2_srt_first_round && fdsu_ex2_sqrt)
			qtrt_sel_rem[7:0] = {srt_remainder[29], srt_remainder[27:21]};
		else
			qtrt_sel_rem[7:0] = (srt_remainder[29] ? ~srt_remainder[29:22] : srt_remainder[29:22]);
	gated_clk_cell x_qt_clk(
		.clk_in(forever_cpuclk),
		.clk_out(qt_clk),
		.external_en(1'b0),
		.global_en(cp0_yy_clk_en),
		.local_en(qt_clk_en),
		.module_en(cp0_fpu_icg_en),
		.pad_yy_icg_scan_en(pad_yy_icg_scan_en)
	);
	assign qt_clk_en = srt_sm_on || ex1_pipedown_gate;
	always @(posedge qt_clk)
		if (ex1_pipedown) begin
			qt_rt_const_shift_std[29:0] <= 30'b010000000000000000000000000000;
			total_qt_rt_30[29:0] <= 30'b000000000000000000000000000000;
			total_qt_rt_minus_30[29:0] <= 30'b000000000000000000000000000000;
		end
		else if (srt_sm_on) begin
			qt_rt_const_shift_std[29:0] <= qt_rt_const_shift_std_next[29:0];
			total_qt_rt_30[29:0] <= total_qt_rt_30_next[29:0];
			total_qt_rt_minus_30[29:0] <= total_qt_rt_minus_30_next[29:0];
		end
		else begin
			qt_rt_const_shift_std[29:0] <= qt_rt_const_shift_std[29:0];
			total_qt_rt_30[29:0] <= total_qt_rt_30[29:0];
			total_qt_rt_minus_30[29:0] <= total_qt_rt_minus_30[29:0];
		end
	assign qt_rt_const_q1[29:0] = qt_rt_const_shift_std[29:0];
	assign qt_rt_const_q2[29:0] = {qt_rt_const_shift_std[28:0], 1'b0};
	assign qt_rt_const_q3[29:0] = qt_rt_const_q1[29:0] | qt_rt_const_q2[29:0];
	assign qt_rt_const_shift_std_next[29:0] = {2'b00, qt_rt_const_shift_std[29:2]};
	assign total_qt_rt_pre_sel[29:0] = (rem_sign ? total_qt_rt_minus_30[29:0] : total_qt_rt_30[29:0]);
	assign qt_rt_const_pre_sel_q2[29:0] = qt_rt_const_q2[29:0];
	assign qt_rt_mins_const_pre_sel_q2[29:0] = qt_rt_const_q1[29:0];
	assign qt_rt_const_pre_sel_q1[29:0] = (rem_sign ? qt_rt_const_q3[29:0] : qt_rt_const_q1[29:0]);
	assign qt_rt_mins_const_pre_sel_q1[29:0] = (rem_sign ? qt_rt_const_q2[29:0] : 30'b000000000000000000000000000000);
	always @(qt_rt_const_q3[29:0] or qt_rt_mins_const_pre_sel_q1[29:0] or bound1_cmp_sign or total_qt_rt_30[29:0] or qt_rt_mins_const_pre_sel_q2[29:0] or total_qt_rt_minus_30[29:0] or bound2_cmp_sign or qt_rt_const_pre_sel_q2[29:0] or qt_rt_const_pre_sel_q1[29:0] or total_qt_rt_pre_sel[29:0])
		casez ({bound1_cmp_sign, bound2_cmp_sign})
			2'b00: begin
				total_qt_rt_30_next[29:0] = total_qt_rt_pre_sel[29:0] | qt_rt_const_pre_sel_q2[29:0];
				total_qt_rt_minus_30_next[29:0] = total_qt_rt_pre_sel[29:0] | qt_rt_mins_const_pre_sel_q2[29:0];
			end
			2'b01: begin
				total_qt_rt_30_next[29:0] = total_qt_rt_pre_sel[29:0] | qt_rt_const_pre_sel_q1[29:0];
				total_qt_rt_minus_30_next[29:0] = total_qt_rt_pre_sel[29:0] | qt_rt_mins_const_pre_sel_q1[29:0];
			end
			2'b1z: begin
				total_qt_rt_30_next[29:0] = total_qt_rt_30[29:0];
				total_qt_rt_minus_30_next[29:0] = total_qt_rt_minus_30[29:0] | qt_rt_const_q3[29:0];
			end
			default: begin
				total_qt_rt_30_next[29:0] = 30'b000000000000000000000000000000;
				total_qt_rt_minus_30_next[29:0] = 30'b000000000000000000000000000000;
			end
		endcase
	assign div_qt_1_rem_add_op1[31:0] = ~{3'b000, srt_divisor[23:0], 5'b00000};
	assign div_qt_2_rem_add_op1[31:0] = ~{2'b00, srt_divisor[23:0], 6'b000000};
	assign div_qt_r1_rem_add_op1[31:0] = {3'b000, srt_divisor[23:0], 5'b00000};
	assign div_qt_r2_rem_add_op1[31:0] = {2'b00, srt_divisor[23:0], 6'b000000};
	assign sqrt_qt_1_rem_add_op1[31:0] = ~({2'b00, total_qt_rt_30[29:0]} | {3'b000, qt_rt_const_q1[29:1]});
	assign sqrt_qt_2_rem_add_op1[31:0] = ~({1'b0, total_qt_rt_30[29:0], 1'b0} | {1'b0, qt_rt_const_q1[29:0], 1'b0});
	assign sqrt_qt_r1_rem_add_op1[31:0] = (({2'b00, total_qt_rt_minus_30[29:0]} | {1'b0, qt_rt_const_q1[29:0], 1'b0}) | {2'b00, qt_rt_const_q1[29:0]}) | {3'b000, qt_rt_const_q1[29:1]};
	assign sqrt_qt_r2_rem_add_op1[31:0] = ({1'b0, total_qt_rt_minus_30[29:0], 1'b0} | {qt_rt_const_q1[29:0], 2'b00}) | {1'b0, qt_rt_const_q1[29:0], 1'b0};
	always @(div_qt_2_rem_add_op1[31:0] or sqrt_qt_r2_rem_add_op1[31:0] or sqrt_qt_r1_rem_add_op1[31:0] or rem_sign or div_qt_r2_rem_add_op1[31:0] or div_qt_1_rem_add_op1[31:0] or sqrt_qt_2_rem_add_op1[31:0] or fdsu_ex2_sqrt or div_qt_r1_rem_add_op1[31:0] or sqrt_qt_1_rem_add_op1[31:0])
		case ({rem_sign, fdsu_ex2_sqrt})
			2'b01: begin
				rem_add1_op1[31:0] = sqrt_qt_1_rem_add_op1[31:0];
				rem_add2_op1[31:0] = sqrt_qt_2_rem_add_op1[31:0];
			end
			2'b00: begin
				rem_add1_op1[31:0] = div_qt_1_rem_add_op1[31:0];
				rem_add2_op1[31:0] = div_qt_2_rem_add_op1[31:0];
			end
			2'b11: begin
				rem_add1_op1[31:0] = sqrt_qt_r1_rem_add_op1[31:0];
				rem_add2_op1[31:0] = sqrt_qt_r2_rem_add_op1[31:0];
			end
			2'b10: begin
				rem_add1_op1[31:0] = div_qt_r1_rem_add_op1[31:0];
				rem_add2_op1[31:0] = div_qt_r2_rem_add_op1[31:0];
			end
			default: begin
				rem_add1_op1[31:0] = 32'b00000000000000000000000000000000;
				rem_add2_op1[31:0] = 32'b00000000000000000000000000000000;
			end
		endcase
	assign srt_remainder_shift[31:0] = {srt_remainder[31], srt_remainder[28:0], 2'b00};
	assign cur_doub_rem_1[31:0] = (srt_remainder_shift[31:0] + rem_add1_op1[31:0]) + {31'b0000000000000000000000000000000, ~rem_sign};
	assign cur_doub_rem_2[31:0] = (srt_remainder_shift[31:0] + rem_add2_op1[31:0]) + {31'b0000000000000000000000000000000, ~rem_sign};
	assign cur_rem_1[31:0] = cur_doub_rem_1[31:0];
	assign cur_rem_2[31:0] = cur_doub_rem_2[31:0];
	always @(cur_rem_2[31:0] or bound1_cmp_sign or srt_remainder_shift[31:0] or bound2_cmp_sign or cur_rem_1[31:0])
		case ({bound1_cmp_sign, bound2_cmp_sign})
			2'b00: cur_rem[31:0] = cur_rem_2[31:0];
			2'b01: cur_rem[31:0] = cur_rem_1[31:0];
			default: cur_rem[31:0] = srt_remainder_shift[31:0];
		endcase
	assign srt_remainder_nxt[31:0] = cur_rem[31:0];
	assign srt_remainder_zero = ~|srt_remainder[31:0];
	assign srt_remainder_sign = srt_remainder[31];
endmodule
module pa_fdsu_top (
	cp0_fpu_icg_en,
	cp0_fpu_xx_dqnan,
	cp0_yy_clk_en,
	cpurst_b,
	ctrl_fdsu_ex1_sel,
	ctrl_xx_ex1_cmplt_dp,
	ctrl_xx_ex1_inst_vld,
	ctrl_xx_ex1_stall,
	ctrl_xx_ex1_warm_up,
	ctrl_xx_ex2_warm_up,
	ctrl_xx_ex3_warm_up,
	dp_xx_ex1_cnan,
	dp_xx_ex1_id,
	dp_xx_ex1_inf,
	dp_xx_ex1_qnan,
	dp_xx_ex1_rm,
	dp_xx_ex1_snan,
	dp_xx_ex1_zero,
	fdsu_fpu_debug_info,
	fdsu_fpu_ex1_cmplt,
	fdsu_fpu_ex1_cmplt_dp,
	fdsu_fpu_ex1_fflags,
	fdsu_fpu_ex1_special_sel,
	fdsu_fpu_ex1_special_sign,
	fdsu_fpu_ex1_stall,
	fdsu_fpu_no_op,
	fdsu_frbus_data,
	fdsu_frbus_fflags,
	fdsu_frbus_freg,
	fdsu_frbus_wb_vld,
	forever_cpuclk,
	frbus_fdsu_wb_grant,
	idu_fpu_ex1_dst_freg,
	idu_fpu_ex1_eu_sel,
	idu_fpu_ex1_func,
	idu_fpu_ex1_srcf0,
	idu_fpu_ex1_srcf1,
	pad_yy_icg_scan_en,
	rtu_xx_ex1_cancel,
	rtu_xx_ex2_cancel,
	rtu_yy_xx_async_flush,
	rtu_yy_xx_flush
);
	input wire cp0_fpu_icg_en;
	input wire cp0_fpu_xx_dqnan;
	input wire cp0_yy_clk_en;
	input wire cpurst_b;
	input wire ctrl_fdsu_ex1_sel;
	input wire ctrl_xx_ex1_cmplt_dp;
	input wire ctrl_xx_ex1_inst_vld;
	input wire ctrl_xx_ex1_stall;
	input wire ctrl_xx_ex1_warm_up;
	input wire ctrl_xx_ex2_warm_up;
	input wire ctrl_xx_ex3_warm_up;
	input wire [2:0] dp_xx_ex1_cnan;
	input wire [2:0] dp_xx_ex1_id;
	input wire [2:0] dp_xx_ex1_inf;
	input wire [2:0] dp_xx_ex1_qnan;
	input wire [2:0] dp_xx_ex1_rm;
	input wire [2:0] dp_xx_ex1_snan;
	input wire [2:0] dp_xx_ex1_zero;
	input wire forever_cpuclk;
	input wire frbus_fdsu_wb_grant;
	input wire [4:0] idu_fpu_ex1_dst_freg;
	input wire [2:0] idu_fpu_ex1_eu_sel;
	input wire [9:0] idu_fpu_ex1_func;
	input wire [31:0] idu_fpu_ex1_srcf0;
	input wire [31:0] idu_fpu_ex1_srcf1;
	input wire pad_yy_icg_scan_en;
	input wire rtu_xx_ex1_cancel;
	input wire rtu_xx_ex2_cancel;
	input wire rtu_yy_xx_async_flush;
	input wire rtu_yy_xx_flush;
	output wire [4:0] fdsu_fpu_debug_info;
	output wire fdsu_fpu_ex1_cmplt;
	output wire fdsu_fpu_ex1_cmplt_dp;
	output wire [4:0] fdsu_fpu_ex1_fflags;
	output wire [7:0] fdsu_fpu_ex1_special_sel;
	output wire [3:0] fdsu_fpu_ex1_special_sign;
	output wire fdsu_fpu_ex1_stall;
	output wire fdsu_fpu_no_op;
	output wire [31:0] fdsu_frbus_data;
	output wire [4:0] fdsu_frbus_fflags;
	output wire [4:0] fdsu_frbus_freg;
	output wire fdsu_frbus_wb_vld;
	wire ex1_div;
	wire [23:0] ex1_divisor;
	wire [12:0] ex1_expnt_adder_op0;
	wire [12:0] ex1_expnt_adder_op1;
	wire ex1_of_result_lfn;
	wire ex1_op0_id;
	wire ex1_op0_norm;
	wire ex1_op0_sign;
	wire ex1_op1_id;
	wire ex1_op1_id_vld;
	wire ex1_op1_norm;
	wire ex1_op1_sel;
	wire [12:0] ex1_oper_id_expnt;
	wire [12:0] ex1_oper_id_expnt_f;
	wire [51:0] ex1_oper_id_frac;
	wire [51:0] ex1_oper_id_frac_f;
	wire ex1_pipedown;
	wire ex1_pipedown_gate;
	wire [31:0] ex1_remainder;
	wire ex1_result_sign;
	wire [2:0] ex1_rm;
	wire ex1_save_op0;
	wire ex1_save_op0_gate;
	wire ex1_sqrt;
	wire ex1_srt_skip;
	wire [9:0] ex2_expnt_adder_op0;
	wire ex2_of;
	wire ex2_pipe_clk;
	wire ex2_pipedown;
	wire ex2_potnt_of;
	wire ex2_potnt_uf;
	wire ex2_result_inf;
	wire ex2_result_lfn;
	wire ex2_rslt_denorm;
	wire [9:0] ex2_srt_expnt_rst;
	wire ex2_srt_first_round;
	wire ex2_uf;
	wire ex2_uf_srt_skip;
	wire [9:0] ex3_expnt_adjust_result;
	wire [25:0] ex3_frac_final_rst;
	wire ex3_pipedown;
	wire ex3_rslt_denorm;
	wire fdsu_ex1_sel;
	wire fdsu_ex3_id_srt_skip;
	wire fdsu_ex3_rem_sign;
	wire fdsu_ex3_rem_zero;
	wire [23:0] fdsu_ex3_result_denorm_round_add_num;
	wire fdsu_ex4_denorm_to_tiny_frac;
	wire [25:0] fdsu_ex4_frac;
	wire fdsu_ex4_nx;
	wire [1:0] fdsu_ex4_potnt_norm;
	wire fdsu_ex4_result_nor;
	wire fdsu_yy_div;
	wire [9:0] fdsu_yy_expnt_rst;
	wire fdsu_yy_of;
	wire fdsu_yy_of_rm_lfn;
	wire fdsu_yy_op0_norm;
	wire fdsu_yy_op1_norm;
	wire fdsu_yy_potnt_of;
	wire fdsu_yy_potnt_uf;
	wire fdsu_yy_result_inf;
	wire fdsu_yy_result_lfn;
	wire fdsu_yy_result_sign;
	wire [2:0] fdsu_yy_rm;
	wire fdsu_yy_rslt_denorm;
	wire fdsu_yy_sqrt;
	wire fdsu_yy_uf;
	wire [4:0] fdsu_yy_wb_freg;
	wire srt_remainder_zero;
	wire srt_sm_on;
	wire [29:0] total_qt_rt_30;
	pa_fdsu_special x_pa_fdsu_special(
		.cp0_fpu_xx_dqnan(cp0_fpu_xx_dqnan),
		.dp_xx_ex1_cnan(dp_xx_ex1_cnan),
		.dp_xx_ex1_id(dp_xx_ex1_id),
		.dp_xx_ex1_inf(dp_xx_ex1_inf),
		.dp_xx_ex1_qnan(dp_xx_ex1_qnan),
		.dp_xx_ex1_snan(dp_xx_ex1_snan),
		.dp_xx_ex1_zero(dp_xx_ex1_zero),
		.ex1_div(ex1_div),
		.ex1_op0_id(ex1_op0_id),
		.ex1_op0_norm(ex1_op0_norm),
		.ex1_op0_sign(ex1_op0_sign),
		.ex1_op1_id(ex1_op1_id),
		.ex1_op1_norm(ex1_op1_norm),
		.ex1_result_sign(ex1_result_sign),
		.ex1_sqrt(ex1_sqrt),
		.ex1_srt_skip(ex1_srt_skip),
		.fdsu_fpu_ex1_fflags(fdsu_fpu_ex1_fflags),
		.fdsu_fpu_ex1_special_sel(fdsu_fpu_ex1_special_sel),
		.fdsu_fpu_ex1_special_sign(fdsu_fpu_ex1_special_sign)
	);
	pa_fdsu_prepare x_pa_fdsu_prepare(
		.dp_xx_ex1_rm(dp_xx_ex1_rm),
		.ex1_div(ex1_div),
		.ex1_divisor(ex1_divisor),
		.ex1_expnt_adder_op0(ex1_expnt_adder_op0),
		.ex1_expnt_adder_op1(ex1_expnt_adder_op1),
		.ex1_of_result_lfn(ex1_of_result_lfn),
		.ex1_op0_id(ex1_op0_id),
		.ex1_op0_sign(ex1_op0_sign),
		.ex1_op1_id(ex1_op1_id),
		.ex1_op1_id_vld(ex1_op1_id_vld),
		.ex1_op1_sel(ex1_op1_sel),
		.ex1_oper_id_expnt(ex1_oper_id_expnt),
		.ex1_oper_id_expnt_f(ex1_oper_id_expnt_f),
		.ex1_oper_id_frac(ex1_oper_id_frac),
		.ex1_oper_id_frac_f(ex1_oper_id_frac_f),
		.ex1_remainder(ex1_remainder),
		.ex1_result_sign(ex1_result_sign),
		.ex1_rm(ex1_rm),
		.ex1_sqrt(ex1_sqrt),
		.fdsu_ex1_sel(fdsu_ex1_sel),
		.idu_fpu_ex1_func(idu_fpu_ex1_func),
		.idu_fpu_ex1_srcf0(idu_fpu_ex1_srcf0),
		.idu_fpu_ex1_srcf1(idu_fpu_ex1_srcf1)
	);
	pa_fdsu_srt_single x_pa_fdsu_srt(
		.cp0_fpu_icg_en(cp0_fpu_icg_en),
		.cp0_yy_clk_en(cp0_yy_clk_en),
		.ex1_divisor(ex1_divisor),
		.ex1_expnt_adder_op1(ex1_expnt_adder_op1),
		.ex1_oper_id_frac(ex1_oper_id_frac),
		.ex1_oper_id_frac_f(ex1_oper_id_frac_f),
		.ex1_pipedown(ex1_pipedown),
		.ex1_pipedown_gate(ex1_pipedown_gate),
		.ex1_remainder(ex1_remainder),
		.ex1_save_op0(ex1_save_op0),
		.ex1_save_op0_gate(ex1_save_op0_gate),
		.ex2_expnt_adder_op0(ex2_expnt_adder_op0),
		.ex2_of(ex2_of),
		.ex2_pipe_clk(ex2_pipe_clk),
		.ex2_pipedown(ex2_pipedown),
		.ex2_potnt_of(ex2_potnt_of),
		.ex2_potnt_uf(ex2_potnt_uf),
		.ex2_result_inf(ex2_result_inf),
		.ex2_result_lfn(ex2_result_lfn),
		.ex2_rslt_denorm(ex2_rslt_denorm),
		.ex2_srt_expnt_rst(ex2_srt_expnt_rst),
		.ex2_srt_first_round(ex2_srt_first_round),
		.ex2_uf(ex2_uf),
		.ex2_uf_srt_skip(ex2_uf_srt_skip),
		.ex3_frac_final_rst(ex3_frac_final_rst),
		.ex3_pipedown(ex3_pipedown),
		.fdsu_ex3_id_srt_skip(fdsu_ex3_id_srt_skip),
		.fdsu_ex3_rem_sign(fdsu_ex3_rem_sign),
		.fdsu_ex3_rem_zero(fdsu_ex3_rem_zero),
		.fdsu_ex3_result_denorm_round_add_num(fdsu_ex3_result_denorm_round_add_num),
		.fdsu_ex4_frac(fdsu_ex4_frac),
		.fdsu_yy_div(fdsu_yy_div),
		.fdsu_yy_of_rm_lfn(fdsu_yy_of_rm_lfn),
		.fdsu_yy_op0_norm(fdsu_yy_op0_norm),
		.fdsu_yy_op1_norm(fdsu_yy_op1_norm),
		.fdsu_yy_sqrt(fdsu_yy_sqrt),
		.forever_cpuclk(forever_cpuclk),
		.pad_yy_icg_scan_en(pad_yy_icg_scan_en),
		.srt_remainder_zero(srt_remainder_zero),
		.srt_sm_on(srt_sm_on),
		.total_qt_rt_30(total_qt_rt_30)
	);
	pa_fdsu_round_single x_pa_fdsu_round(
		.cp0_fpu_icg_en(cp0_fpu_icg_en),
		.cp0_yy_clk_en(cp0_yy_clk_en),
		.ex3_expnt_adjust_result(ex3_expnt_adjust_result),
		.ex3_frac_final_rst(ex3_frac_final_rst),
		.ex3_pipedown(ex3_pipedown),
		.ex3_rslt_denorm(ex3_rslt_denorm),
		.fdsu_ex3_id_srt_skip(fdsu_ex3_id_srt_skip),
		.fdsu_ex3_rem_sign(fdsu_ex3_rem_sign),
		.fdsu_ex3_rem_zero(fdsu_ex3_rem_zero),
		.fdsu_ex3_result_denorm_round_add_num(fdsu_ex3_result_denorm_round_add_num),
		.fdsu_ex4_denorm_to_tiny_frac(fdsu_ex4_denorm_to_tiny_frac),
		.fdsu_ex4_nx(fdsu_ex4_nx),
		.fdsu_ex4_potnt_norm(fdsu_ex4_potnt_norm),
		.fdsu_ex4_result_nor(fdsu_ex4_result_nor),
		.fdsu_yy_expnt_rst(fdsu_yy_expnt_rst),
		.fdsu_yy_result_inf(fdsu_yy_result_inf),
		.fdsu_yy_result_lfn(fdsu_yy_result_lfn),
		.fdsu_yy_result_sign(fdsu_yy_result_sign),
		.fdsu_yy_rm(fdsu_yy_rm),
		.fdsu_yy_rslt_denorm(fdsu_yy_rslt_denorm),
		.forever_cpuclk(forever_cpuclk),
		.pad_yy_icg_scan_en(pad_yy_icg_scan_en),
		.total_qt_rt_30(total_qt_rt_30)
	);
	pa_fdsu_pack_single x_pa_fdsu_pack(
		.fdsu_ex4_denorm_to_tiny_frac(fdsu_ex4_denorm_to_tiny_frac),
		.fdsu_ex4_frac(fdsu_ex4_frac),
		.fdsu_ex4_nx(fdsu_ex4_nx),
		.fdsu_ex4_potnt_norm(fdsu_ex4_potnt_norm),
		.fdsu_ex4_result_nor(fdsu_ex4_result_nor),
		.fdsu_frbus_data(fdsu_frbus_data),
		.fdsu_frbus_fflags(fdsu_frbus_fflags),
		.fdsu_frbus_freg(fdsu_frbus_freg),
		.fdsu_yy_expnt_rst(fdsu_yy_expnt_rst),
		.fdsu_yy_of(fdsu_yy_of),
		.fdsu_yy_of_rm_lfn(fdsu_yy_of_rm_lfn),
		.fdsu_yy_potnt_of(fdsu_yy_potnt_of),
		.fdsu_yy_potnt_uf(fdsu_yy_potnt_uf),
		.fdsu_yy_result_inf(fdsu_yy_result_inf),
		.fdsu_yy_result_lfn(fdsu_yy_result_lfn),
		.fdsu_yy_result_sign(fdsu_yy_result_sign),
		.fdsu_yy_rslt_denorm(fdsu_yy_rslt_denorm),
		.fdsu_yy_uf(fdsu_yy_uf),
		.fdsu_yy_wb_freg(fdsu_yy_wb_freg)
	);
	pa_fdsu_ctrl x_pa_fdsu_ctrl(
		.cp0_fpu_icg_en(cp0_fpu_icg_en),
		.cp0_yy_clk_en(cp0_yy_clk_en),
		.cpurst_b(cpurst_b),
		.ctrl_fdsu_ex1_sel(ctrl_fdsu_ex1_sel),
		.ctrl_xx_ex1_cmplt_dp(ctrl_xx_ex1_cmplt_dp),
		.ctrl_xx_ex1_inst_vld(ctrl_xx_ex1_inst_vld),
		.ctrl_xx_ex1_stall(ctrl_xx_ex1_stall),
		.ctrl_xx_ex1_warm_up(ctrl_xx_ex1_warm_up),
		.ctrl_xx_ex2_warm_up(ctrl_xx_ex2_warm_up),
		.ctrl_xx_ex3_warm_up(ctrl_xx_ex3_warm_up),
		.ex1_div(ex1_div),
		.ex1_expnt_adder_op0(ex1_expnt_adder_op0),
		.ex1_of_result_lfn(ex1_of_result_lfn),
		.ex1_op0_id(ex1_op0_id),
		.ex1_op0_norm(ex1_op0_norm),
		.ex1_op1_id_vld(ex1_op1_id_vld),
		.ex1_op1_norm(ex1_op1_norm),
		.ex1_op1_sel(ex1_op1_sel),
		.ex1_oper_id_expnt(ex1_oper_id_expnt),
		.ex1_oper_id_expnt_f(ex1_oper_id_expnt_f),
		.ex1_pipedown(ex1_pipedown),
		.ex1_pipedown_gate(ex1_pipedown_gate),
		.ex1_result_sign(ex1_result_sign),
		.ex1_rm(ex1_rm),
		.ex1_save_op0(ex1_save_op0),
		.ex1_save_op0_gate(ex1_save_op0_gate),
		.ex1_sqrt(ex1_sqrt),
		.ex1_srt_skip(ex1_srt_skip),
		.ex2_expnt_adder_op0(ex2_expnt_adder_op0),
		.ex2_of(ex2_of),
		.ex2_pipe_clk(ex2_pipe_clk),
		.ex2_pipedown(ex2_pipedown),
		.ex2_potnt_of(ex2_potnt_of),
		.ex2_potnt_uf(ex2_potnt_uf),
		.ex2_result_inf(ex2_result_inf),
		.ex2_result_lfn(ex2_result_lfn),
		.ex2_rslt_denorm(ex2_rslt_denorm),
		.ex2_srt_expnt_rst(ex2_srt_expnt_rst),
		.ex2_srt_first_round(ex2_srt_first_round),
		.ex2_uf(ex2_uf),
		.ex2_uf_srt_skip(ex2_uf_srt_skip),
		.ex3_expnt_adjust_result(ex3_expnt_adjust_result),
		.ex3_pipedown(ex3_pipedown),
		.ex3_rslt_denorm(ex3_rslt_denorm),
		.fdsu_ex1_sel(fdsu_ex1_sel),
		.fdsu_fpu_debug_info(fdsu_fpu_debug_info),
		.fdsu_fpu_ex1_cmplt(fdsu_fpu_ex1_cmplt),
		.fdsu_fpu_ex1_cmplt_dp(fdsu_fpu_ex1_cmplt_dp),
		.fdsu_fpu_ex1_stall(fdsu_fpu_ex1_stall),
		.fdsu_fpu_no_op(fdsu_fpu_no_op),
		.fdsu_frbus_wb_vld(fdsu_frbus_wb_vld),
		.fdsu_yy_div(fdsu_yy_div),
		.fdsu_yy_expnt_rst(fdsu_yy_expnt_rst),
		.fdsu_yy_of(fdsu_yy_of),
		.fdsu_yy_of_rm_lfn(fdsu_yy_of_rm_lfn),
		.fdsu_yy_op0_norm(fdsu_yy_op0_norm),
		.fdsu_yy_op1_norm(fdsu_yy_op1_norm),
		.fdsu_yy_potnt_of(fdsu_yy_potnt_of),
		.fdsu_yy_potnt_uf(fdsu_yy_potnt_uf),
		.fdsu_yy_result_inf(fdsu_yy_result_inf),
		.fdsu_yy_result_lfn(fdsu_yy_result_lfn),
		.fdsu_yy_result_sign(fdsu_yy_result_sign),
		.fdsu_yy_rm(fdsu_yy_rm),
		.fdsu_yy_rslt_denorm(fdsu_yy_rslt_denorm),
		.fdsu_yy_sqrt(fdsu_yy_sqrt),
		.fdsu_yy_uf(fdsu_yy_uf),
		.fdsu_yy_wb_freg(fdsu_yy_wb_freg),
		.forever_cpuclk(forever_cpuclk),
		.frbus_fdsu_wb_grant(frbus_fdsu_wb_grant),
		.idu_fpu_ex1_dst_freg(idu_fpu_ex1_dst_freg),
		.idu_fpu_ex1_eu_sel(idu_fpu_ex1_eu_sel),
		.pad_yy_icg_scan_en(pad_yy_icg_scan_en),
		.rtu_xx_ex1_cancel(rtu_xx_ex1_cancel),
		.rtu_xx_ex2_cancel(rtu_xx_ex2_cancel),
		.rtu_yy_xx_async_flush(rtu_yy_xx_async_flush),
		.rtu_yy_xx_flush(rtu_yy_xx_flush),
		.srt_remainder_zero(srt_remainder_zero),
		.srt_sm_on(srt_sm_on)
	);
endmodule
module pa_fpu_dp (
	cp0_fpu_icg_en,
	cp0_fpu_xx_rm,
	cp0_yy_clk_en,
	ctrl_xx_ex1_inst_vld,
	ctrl_xx_ex1_stall,
	ctrl_xx_ex1_warm_up,
	dp_frbus_ex2_data,
	dp_frbus_ex2_fflags,
	dp_xx_ex1_cnan,
	dp_xx_ex1_id,
	dp_xx_ex1_inf,
	dp_xx_ex1_norm,
	dp_xx_ex1_qnan,
	dp_xx_ex1_snan,
	dp_xx_ex1_zero,
	ex2_inst_wb,
	fdsu_fpu_ex1_fflags,
	fdsu_fpu_ex1_special_sel,
	fdsu_fpu_ex1_special_sign,
	forever_cpuclk,
	idu_fpu_ex1_eu_sel,
	idu_fpu_ex1_func,
	idu_fpu_ex1_gateclk_vld,
	idu_fpu_ex1_rm,
	idu_fpu_ex1_srcf0,
	idu_fpu_ex1_srcf1,
	idu_fpu_ex1_srcf2,
	pad_yy_icg_scan_en
);
	input wire cp0_fpu_icg_en;
	input wire [2:0] cp0_fpu_xx_rm;
	input wire cp0_yy_clk_en;
	input wire ctrl_xx_ex1_inst_vld;
	input wire ctrl_xx_ex1_stall;
	input wire ctrl_xx_ex1_warm_up;
	input wire [4:0] fdsu_fpu_ex1_fflags;
	input wire [7:0] fdsu_fpu_ex1_special_sel;
	input wire [3:0] fdsu_fpu_ex1_special_sign;
	input wire forever_cpuclk;
	input wire [2:0] idu_fpu_ex1_eu_sel;
	input wire [9:0] idu_fpu_ex1_func;
	input wire idu_fpu_ex1_gateclk_vld;
	input wire [2:0] idu_fpu_ex1_rm;
	input wire [31:0] idu_fpu_ex1_srcf0;
	input wire [31:0] idu_fpu_ex1_srcf1;
	input wire [31:0] idu_fpu_ex1_srcf2;
	input wire pad_yy_icg_scan_en;
	output wire [31:0] dp_frbus_ex2_data;
	output wire [4:0] dp_frbus_ex2_fflags;
	output wire [2:0] dp_xx_ex1_cnan;
	output wire [2:0] dp_xx_ex1_id;
	output wire [2:0] dp_xx_ex1_inf;
	output wire [2:0] dp_xx_ex1_norm;
	output wire [2:0] dp_xx_ex1_qnan;
	output wire [2:0] dp_xx_ex1_snan;
	output wire [2:0] dp_xx_ex1_zero;
	output wire ex2_inst_wb;
	reg [4:0] ex1_fflags;
	reg [31:0] ex1_special_data;
	reg [8:0] ex1_special_sel;
	reg [3:0] ex1_special_sign;
	reg [4:0] ex2_fflags;
	reg [31:0] ex2_result;
	reg [31:0] ex2_special_data;
	reg [6:0] ex2_special_sel;
	reg [3:0] ex2_special_sign;
	wire [2:0] ex1_decode_rm;
	wire ex1_double;
	wire [2:0] ex1_eu_sel;
	wire [9:0] ex1_func;
	wire [2:0] ex1_global_rm;
	wire [2:0] ex1_rm;
	wire ex1_single;
	wire [31:0] ex1_special_data_final;
	wire [63:0] ex1_src0;
	wire [63:0] ex1_src1;
	wire [63:0] ex1_src2;
	wire ex1_src2_vld;
	wire [2:0] ex1_src_cnan;
	wire [2:0] ex1_src_id;
	wire [2:0] ex1_src_inf;
	wire [2:0] ex1_src_norm;
	wire [2:0] ex1_src_qnan;
	wire [2:0] ex1_src_snan;
	wire [2:0] ex1_src_zero;
	wire ex2_data_clk;
	wire ex2_data_clk_en;
	parameter DOUBLE_WIDTH = 64;
	parameter SINGLE_WIDTH = 32;
	parameter FUNC_WIDTH = 10;
	assign ex1_eu_sel[2:0] = idu_fpu_ex1_eu_sel[2:0];
	assign ex1_func[FUNC_WIDTH - 1:0] = idu_fpu_ex1_func[FUNC_WIDTH - 1:0];
	assign ex1_global_rm[2:0] = cp0_fpu_xx_rm[2:0];
	assign ex1_decode_rm[2:0] = idu_fpu_ex1_rm[2:0];
	assign ex1_rm[2:0] = (ex1_decode_rm[2:0] == 3'b111 ? ex1_global_rm[2:0] : ex1_decode_rm[2:0]);
	assign ex1_src2_vld = idu_fpu_ex1_eu_sel[1] && ex1_func[0];
	assign ex1_src0[DOUBLE_WIDTH - 1:0] = {{SINGLE_WIDTH {1'b1}}, idu_fpu_ex1_srcf0[SINGLE_WIDTH - 1:0]};
	assign ex1_src1[DOUBLE_WIDTH - 1:0] = {{SINGLE_WIDTH {1'b1}}, idu_fpu_ex1_srcf1[SINGLE_WIDTH - 1:0]};
	assign ex1_src2[DOUBLE_WIDTH - 1:0] = (ex1_src2_vld ? {{SINGLE_WIDTH {1'b1}}, idu_fpu_ex1_srcf2[SINGLE_WIDTH - 1:0]} : {{SINGLE_WIDTH {1'b1}}, {SINGLE_WIDTH {1'b0}}});
	assign ex1_double = 1'b0;
	assign ex1_single = 1'b1;
	pa_fpu_src_type x_pa_fpu_ex1_srcf0_type(
		.inst_double(ex1_double),
		.inst_single(ex1_single),
		.src_cnan(ex1_src_cnan[0]),
		.src_id(ex1_src_id[0]),
		.src_in(ex1_src0),
		.src_inf(ex1_src_inf[0]),
		.src_norm(ex1_src_norm[0]),
		.src_qnan(ex1_src_qnan[0]),
		.src_snan(ex1_src_snan[0]),
		.src_zero(ex1_src_zero[0])
	);
	pa_fpu_src_type x_pa_fpu_ex1_srcf1_type(
		.inst_double(ex1_double),
		.inst_single(ex1_single),
		.src_cnan(ex1_src_cnan[1]),
		.src_id(ex1_src_id[1]),
		.src_in(ex1_src1),
		.src_inf(ex1_src_inf[1]),
		.src_norm(ex1_src_norm[1]),
		.src_qnan(ex1_src_qnan[1]),
		.src_snan(ex1_src_snan[1]),
		.src_zero(ex1_src_zero[1])
	);
	pa_fpu_src_type x_pa_fpu_ex1_srcf2_type(
		.inst_double(ex1_double),
		.inst_single(ex1_single),
		.src_cnan(ex1_src_cnan[2]),
		.src_id(ex1_src_id[2]),
		.src_in(ex1_src2),
		.src_inf(ex1_src_inf[2]),
		.src_norm(ex1_src_norm[2]),
		.src_qnan(ex1_src_qnan[2]),
		.src_snan(ex1_src_snan[2]),
		.src_zero(ex1_src_zero[2])
	);
	assign dp_xx_ex1_cnan[2:0] = ex1_src_cnan[2:0];
	assign dp_xx_ex1_snan[2:0] = ex1_src_snan[2:0];
	assign dp_xx_ex1_qnan[2:0] = ex1_src_qnan[2:0];
	assign dp_xx_ex1_norm[2:0] = ex1_src_norm[2:0];
	assign dp_xx_ex1_zero[2:0] = ex1_src_zero[2:0];
	assign dp_xx_ex1_inf[2:0] = ex1_src_inf[2:0];
	assign dp_xx_ex1_id[2:0] = ex1_src_id[2:0];
	always @(fdsu_fpu_ex1_special_sign[3:0] or fdsu_fpu_ex1_fflags[4:0] or ex1_eu_sel[2:0] or fdsu_fpu_ex1_special_sel[7:0])
		case (ex1_eu_sel[2:0])
			3'b100: begin
				ex1_fflags[4:0] = fdsu_fpu_ex1_fflags[4:0];
				ex1_special_sel[8:0] = {1'b0, fdsu_fpu_ex1_special_sel[7:0]};
				ex1_special_sign[3:0] = fdsu_fpu_ex1_special_sign[3:0];
			end
			default: begin
				ex1_fflags[4:0] = {5 {1'b0}};
				ex1_special_sel[8:0] = {9 {1'b0}};
				ex1_special_sign[3:0] = {4 {1'b0}};
			end
		endcase
	always @(ex1_special_sel[8:5] or ex1_src0[31:0] or ex1_src1[31:0] or ex1_src2[31:0])
		case (ex1_special_sel[8:5])
			4'b0001: ex1_special_data[SINGLE_WIDTH - 1:0] = ex1_src0[SINGLE_WIDTH - 1:0];
			4'b0010: ex1_special_data[SINGLE_WIDTH - 1:0] = ex1_src1[SINGLE_WIDTH - 1:0];
			4'b0100: ex1_special_data[SINGLE_WIDTH - 1:0] = ex1_src2[SINGLE_WIDTH - 1:0];
			default: ex1_special_data[SINGLE_WIDTH - 1:0] = ex1_src2[SINGLE_WIDTH - 1:0];
		endcase
	assign ex1_special_data_final[SINGLE_WIDTH - 1:0] = ex1_special_data[SINGLE_WIDTH - 1:0];
	assign ex2_data_clk_en = idu_fpu_ex1_gateclk_vld || ctrl_xx_ex1_warm_up;
	gated_clk_cell x_fpu_data_ex2_gated_clk(
		.clk_in(forever_cpuclk),
		.clk_out(ex2_data_clk),
		.external_en(1'b0),
		.global_en(cp0_yy_clk_en),
		.local_en(ex2_data_clk_en),
		.module_en(cp0_fpu_icg_en),
		.pad_yy_icg_scan_en(pad_yy_icg_scan_en)
	);
	always @(posedge ex2_data_clk)
		if ((ctrl_xx_ex1_inst_vld && !ctrl_xx_ex1_stall) || ctrl_xx_ex1_warm_up) begin
			ex2_fflags[4:0] <= ex1_fflags[4:0];
			ex2_special_sign[3:0] <= ex1_special_sign[3:0];
			ex2_special_sel[6:0] <= {ex1_special_sel[8], |ex1_special_sel[7:5], ex1_special_sel[4:0]};
			ex2_special_data[SINGLE_WIDTH - 1:0] <= ex1_special_data_final[SINGLE_WIDTH - 1:0];
		end
	assign ex2_inst_wb = |ex2_special_sel[6:0];
	always @(ex2_special_sel[6:0] or ex2_special_data[31:0] or ex2_special_sign[3:0])
		case (ex2_special_sel[6:0])
			7'b0000001: ex2_result[SINGLE_WIDTH - 1:0] = {ex2_special_sign[0], ex2_special_data[SINGLE_WIDTH - 2:0]};
			7'b0000010: ex2_result[SINGLE_WIDTH - 1:0] = {ex2_special_sign[1], {31 {1'b0}}};
			7'b0000100: ex2_result[SINGLE_WIDTH - 1:0] = {ex2_special_sign[2], {8 {1'b1}}, {23 {1'b0}}};
			7'b0001000: ex2_result[SINGLE_WIDTH - 1:0] = {ex2_special_sign[3], {7 {1'b1}}, 1'b0, {23 {1'b1}}};
			7'b0010000: ex2_result[SINGLE_WIDTH - 1:0] = {1'b0, {8 {1'b1}}, 1'b1, {22 {1'b0}}};
			7'b0100000: ex2_result[SINGLE_WIDTH - 1:0] = {ex2_special_data[31], {8 {1'b1}}, 1'b1, ex2_special_data[21:0]};
			7'b1000000: ex2_result[SINGLE_WIDTH - 1:0] = ex2_special_data[SINGLE_WIDTH - 1:0];
			default: ex2_result[SINGLE_WIDTH - 1:0] = {SINGLE_WIDTH {1'b0}};
		endcase
	assign dp_frbus_ex2_data[SINGLE_WIDTH - 1:0] = ex2_result[SINGLE_WIDTH - 1:0];
	assign dp_frbus_ex2_fflags[4:0] = ex2_fflags[4:0];
endmodule
module pa_fpu_frbus (
	ctrl_frbus_ex2_wb_req,
	dp_frbus_ex2_data,
	dp_frbus_ex2_fflags,
	fdsu_frbus_data,
	fdsu_frbus_fflags,
	fdsu_frbus_wb_vld,
	fpu_idu_fwd_data,
	fpu_idu_fwd_fflags,
	fpu_idu_fwd_vld
);
	input wire ctrl_frbus_ex2_wb_req;
	input [31:0] dp_frbus_ex2_data;
	input [4:0] dp_frbus_ex2_fflags;
	input wire [31:0] fdsu_frbus_data;
	input wire [4:0] fdsu_frbus_fflags;
	input wire fdsu_frbus_wb_vld;
	output wire [31:0] fpu_idu_fwd_data;
	output wire [4:0] fpu_idu_fwd_fflags;
	output wire fpu_idu_fwd_vld;
	reg [31:0] frbus_wb_data;
	reg [4:0] frbus_wb_fflags;
	wire frbus_ex2_wb_vld;
	wire frbus_fdsu_wb_vld;
	wire frbus_wb_vld;
	wire [3:0] frbus_source_vld;
	assign frbus_fdsu_wb_vld = fdsu_frbus_wb_vld;
	assign frbus_ex2_wb_vld = ctrl_frbus_ex2_wb_req;
	assign frbus_source_vld[3:0] = {2'b00, frbus_ex2_wb_vld, frbus_fdsu_wb_vld};
	assign frbus_wb_vld = frbus_ex2_wb_vld | frbus_fdsu_wb_vld;
	always @(frbus_source_vld[3:0] or fdsu_frbus_data[31:0] or dp_frbus_ex2_data[31:0] or fdsu_frbus_fflags[4:0] or dp_frbus_ex2_fflags[4:0])
		case (frbus_source_vld[3:0])
			4'b0001: begin
				frbus_wb_data[31:0] = fdsu_frbus_data[31:0];
				frbus_wb_fflags[4:0] = fdsu_frbus_fflags[4:0];
			end
			4'b0010: begin
				frbus_wb_data[31:0] = dp_frbus_ex2_data[31:0];
				frbus_wb_fflags[4:0] = dp_frbus_ex2_fflags[4:0];
			end
			default: begin
				frbus_wb_data[31:0] = {31 {1'b0}};
				frbus_wb_fflags[4:0] = 5'b00000;
			end
		endcase
	assign fpu_idu_fwd_vld = frbus_wb_vld;
	assign fpu_idu_fwd_fflags[4:0] = frbus_wb_fflags[4:0];
	assign fpu_idu_fwd_data[31:0] = frbus_wb_data[31:0];
endmodule
module pa_fpu_src_type (
	inst_double,
	inst_single,
	src_cnan,
	src_id,
	src_in,
	src_inf,
	src_norm,
	src_qnan,
	src_snan,
	src_zero
);
	input wire inst_double;
	input wire inst_single;
	input wire [63:0] src_in;
	output wire src_cnan;
	output wire src_id;
	output wire src_inf;
	output wire src_norm;
	output wire src_qnan;
	output wire src_snan;
	output wire src_zero;
	wire [63:0] src;
	wire src_expn_max;
	wire src_expn_zero;
	wire src_frac_msb;
	wire src_frac_zero;
	assign src[63:0] = src_in[63:0];
	assign src_cnan = !(&src[63:32]) && inst_single;
	assign src_expn_zero = (!(|src[62:52]) && inst_double) || (!(|src[30:23]) && inst_single);
	assign src_expn_max = (&src[62:52] && inst_double) || (&src[30:23] && inst_single);
	assign src_frac_zero = (!(|src[51:0]) && inst_double) || (!(|src[22:0]) && inst_single);
	assign src_frac_msb = (src[51] && inst_double) || (src[22] && inst_single);
	assign src_snan = ((src_expn_max && !src_frac_msb) && !src_frac_zero) && !src_cnan;
	assign src_qnan = (src_expn_max && src_frac_msb) || src_cnan;
	assign src_zero = (src_expn_zero && src_frac_zero) && !src_cnan;
	assign src_id = (src_expn_zero && !src_frac_zero) && !src_cnan;
	assign src_inf = (src_expn_max && src_frac_zero) && !src_cnan;
	assign src_norm = (!(src_expn_zero && src_frac_zero) && !src_expn_max) && !src_cnan;
endmodule
module fpnew_fma_141C6 (
	clk_i,
	rst_ni,
	operands_i,
	is_boxed_i,
	rnd_mode_i,
	op_i,
	op_mod_i,
	tag_i,
	mask_i,
	aux_i,
	in_valid_i,
	in_ready_o,
	flush_i,
	result_o,
	status_o,
	extension_bit_o,
	tag_o,
	mask_o,
	aux_o,
	out_valid_o,
	out_ready_i,
	busy_o,
	reg_ena_i
);
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	function automatic [2:0] sv2v_cast_0BC43;
		input reg [2:0] inp;
		sv2v_cast_0BC43 = inp;
	endfunction
	parameter [2:0] FpFormat = sv2v_cast_0BC43(0);
	parameter [31:0] NumPipeRegs = 0;
	parameter [1:0] PipeConfig = 2'd0;
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	localparam [31:0] WIDTH = fpnew_pkg_fp_width(FpFormat);
	localparam [31:0] ExtRegEnaWidth = (NumPipeRegs == 0 ? 1 : NumPipeRegs);
	input wire clk_i;
	input wire rst_ni;
	input wire [(3 * WIDTH) - 1:0] operands_i;
	input wire [2:0] is_boxed_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire op_mod_i;
	input wire tag_i;
	input wire mask_i;
	input wire aux_i;
	input wire in_valid_i;
	output wire in_ready_o;
	input wire flush_i;
	output wire [WIDTH - 1:0] result_o;
	output wire [4:0] status_o;
	output wire extension_bit_o;
	output wire tag_o;
	output wire mask_o;
	output wire aux_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	input wire [ExtRegEnaWidth - 1:0] reg_ena_i;
	function automatic [31:0] fpnew_pkg_exp_bits;
		input reg [2:0] fmt;
		fpnew_pkg_exp_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32];
	endfunction
	localparam [31:0] EXP_BITS = fpnew_pkg_exp_bits(FpFormat);
	function automatic [31:0] fpnew_pkg_man_bits;
		input reg [2:0] fmt;
		fpnew_pkg_man_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32];
	endfunction
	localparam [31:0] MAN_BITS = fpnew_pkg_man_bits(FpFormat);
	function automatic [31:0] fpnew_pkg_bias;
		input reg [2:0] fmt;
		fpnew_pkg_bias = $unsigned((2 ** (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] - 1)) - 1);
	endfunction
	localparam [31:0] BIAS = fpnew_pkg_bias(FpFormat);
	localparam [31:0] PRECISION_BITS = MAN_BITS + 1;
	localparam [31:0] LOWER_SUM_WIDTH = (2 * PRECISION_BITS) + 3;
	localparam [31:0] LZC_RESULT_WIDTH = $clog2(LOWER_SUM_WIDTH);
	function automatic signed [31:0] fpnew_pkg_maximum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_maximum = (a > b ? a : b);
	endfunction
	localparam [31:0] EXP_WIDTH = $unsigned(fpnew_pkg_maximum(EXP_BITS + 2, LZC_RESULT_WIDTH));
	localparam [31:0] SHIFT_AMOUNT_WIDTH = $clog2((3 * PRECISION_BITS) + 5);
	localparam NUM_INP_REGS = (PipeConfig == 2'd0 ? NumPipeRegs : (PipeConfig == 2'd3 ? (NumPipeRegs + 1) / 3 : 0));
	localparam NUM_MID_REGS = (PipeConfig == 2'd2 ? NumPipeRegs : (PipeConfig == 2'd3 ? (NumPipeRegs + 2) / 3 : 0));
	localparam NUM_OUT_REGS = (PipeConfig == 2'd1 ? NumPipeRegs : (PipeConfig == 2'd3 ? NumPipeRegs / 3 : 0));
	reg [((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) - (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0)) + 1) * WIDTH) + (((0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) * WIDTH) - 1) : ((((0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)) + 1) * WIDTH) + (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) * WIDTH) - 1)):((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) * WIDTH : (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) * WIDTH)] inp_pipe_operands_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0)] inp_pipe_is_boxed_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0)] inp_pipe_rnd_mode_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * fpnew_pkg_OP_BITS) + ((NUM_INP_REGS * fpnew_pkg_OP_BITS) - 1) : ((NUM_INP_REGS + 1) * fpnew_pkg_OP_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * fpnew_pkg_OP_BITS : 0)] inp_pipe_op_q;
	reg [0:NUM_INP_REGS] inp_pipe_op_mod_q;
	reg [0:NUM_INP_REGS] inp_pipe_tag_q;
	reg [0:NUM_INP_REGS] inp_pipe_mask_q;
	reg [0:NUM_INP_REGS] inp_pipe_aux_q;
	reg [0:NUM_INP_REGS] inp_pipe_valid_q;
	wire [0:NUM_INP_REGS] inp_pipe_ready;
	wire [3 * WIDTH:1] sv2v_tmp_BC8B9;
	assign sv2v_tmp_BC8B9 = operands_i;
	always @(*) inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3 : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3 : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3] = sv2v_tmp_BC8B9;
	wire [3:1] sv2v_tmp_FE389;
	assign sv2v_tmp_FE389 = is_boxed_i;
	always @(*) inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3+:3] = sv2v_tmp_FE389;
	wire [3:1] sv2v_tmp_E1339;
	assign sv2v_tmp_E1339 = rnd_mode_i;
	always @(*) inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3+:3] = sv2v_tmp_E1339;
	wire [4:1] sv2v_tmp_CBA8F;
	assign sv2v_tmp_CBA8F = op_i;
	always @(*) inp_pipe_op_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] = sv2v_tmp_CBA8F;
	wire [1:1] sv2v_tmp_D1C37;
	assign sv2v_tmp_D1C37 = op_mod_i;
	always @(*) inp_pipe_op_mod_q[0] = sv2v_tmp_D1C37;
	wire [1:1] sv2v_tmp_76699;
	assign sv2v_tmp_76699 = tag_i;
	always @(*) inp_pipe_tag_q[0] = sv2v_tmp_76699;
	wire [1:1] sv2v_tmp_407DF;
	assign sv2v_tmp_407DF = mask_i;
	always @(*) inp_pipe_mask_q[0] = sv2v_tmp_407DF;
	wire [1:1] sv2v_tmp_8D189;
	assign sv2v_tmp_8D189 = aux_i;
	always @(*) inp_pipe_aux_q[0] = sv2v_tmp_8D189;
	wire [1:1] sv2v_tmp_73AEA;
	assign sv2v_tmp_73AEA = in_valid_i;
	always @(*) inp_pipe_valid_q[0] = sv2v_tmp_73AEA;
	assign in_ready_o = inp_pipe_ready[0];
	genvar i;
	function automatic [3:0] sv2v_cast_A53F3;
		input reg [3:0] inp;
		sv2v_cast_A53F3 = inp;
	endfunction
	generate
		for (i = 0; i < NUM_INP_REGS; i = i + 1) begin : gen_input_pipeline
			wire reg_ena;
			assign inp_pipe_ready[i] = inp_pipe_ready[i + 1] | ~inp_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_valid_q[i + 1] <= 1'b0;
				else
					inp_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (inp_pipe_ready[i] ? inp_pipe_valid_q[i] : inp_pipe_valid_q[i + 1]));
			assign reg_ena = (inp_pipe_ready[i] & inp_pipe_valid_q[i]) | reg_ena_i[i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3] <= 1'sb0;
				else
					inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3] <= (reg_ena ? inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3 : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3 : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3] : inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= 1'sb0;
				else
					inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= (reg_ena ? inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3+:3] : inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= 3'b000;
				else
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= (reg_ena ? inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3+:3] : inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= sv2v_cast_A53F3(0);
				else
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= (reg_ena ? inp_pipe_op_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] : inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_op_mod_q[i + 1] <= 1'sb0;
				else
					inp_pipe_op_mod_q[i + 1] <= (reg_ena ? inp_pipe_op_mod_q[i] : inp_pipe_op_mod_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_tag_q[i + 1] <= 1'b0;
				else
					inp_pipe_tag_q[i + 1] <= (reg_ena ? inp_pipe_tag_q[i] : inp_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_mask_q[i + 1] <= 1'sb0;
				else
					inp_pipe_mask_q[i + 1] <= (reg_ena ? inp_pipe_mask_q[i] : inp_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_aux_q[i + 1] <= 1'b0;
				else
					inp_pipe_aux_q[i + 1] <= (reg_ena ? inp_pipe_aux_q[i] : inp_pipe_aux_q[i + 1]);
		end
	endgenerate
	wire [23:0] info_q;
	fpnew_classifier #(
		.FpFormat(FpFormat),
		.NumOperands(3)
	) i_class_inputs(
		.operands_i(inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3 : ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3 : ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3]),
		.is_boxed_i(inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3]),
		.info_o(info_q)
	);
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] operand_a;
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] operand_b;
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] operand_c;
	reg [7:0] info_a;
	reg [7:0] info_b;
	reg [7:0] info_c;
	localparam [0:0] fpnew_pkg_DONT_CARE = 1'b1;
	function automatic [EXP_BITS - 1:0] sv2v_cast_91364;
		input reg [EXP_BITS - 1:0] inp;
		sv2v_cast_91364 = inp;
	endfunction
	function automatic [MAN_BITS - 1:0] sv2v_cast_60B87;
		input reg [MAN_BITS - 1:0] inp;
		sv2v_cast_60B87 = inp;
	endfunction
	function automatic [EXP_BITS - 1:0] sv2v_cast_F33EE;
		input reg [EXP_BITS - 1:0] inp;
		sv2v_cast_F33EE = inp;
	endfunction
	function automatic [MAN_BITS - 1:0] sv2v_cast_14681;
		input reg [MAN_BITS - 1:0] inp;
		sv2v_cast_14681 = inp;
	endfunction
	always @(*) begin : op_select
		operand_a = inp_pipe_operands_q[((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3 : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1))) * WIDTH+:WIDTH];
		operand_b = inp_pipe_operands_q[((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) + 1 : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - ((((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1))) * WIDTH+:WIDTH];
		operand_c = inp_pipe_operands_q[((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) + 2 : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - ((((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1))) * WIDTH+:WIDTH];
		info_a = info_q[0+:8];
		info_b = info_q[8+:8];
		info_c = info_q[16+:8];
		operand_c[1 + (EXP_BITS + (MAN_BITS - 1))] = operand_c[1 + (EXP_BITS + (MAN_BITS - 1))] ^ inp_pipe_op_mod_q[NUM_INP_REGS];
		case (inp_pipe_op_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS])
			sv2v_cast_A53F3(0):
				;
			sv2v_cast_A53F3(1): operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] = ~operand_a[1 + (EXP_BITS + (MAN_BITS - 1))];
			sv2v_cast_A53F3(2): begin
				operand_a = {1'b0, sv2v_cast_91364(BIAS), sv2v_cast_60B87(1'sb0)};
				info_a = 8'b10000001;
			end
			sv2v_cast_A53F3(3): begin
				if (inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3] == 3'b010)
					operand_c = {1'b0, sv2v_cast_F33EE(1'sb0), sv2v_cast_60B87(1'sb0)};
				else
					operand_c = {1'b1, sv2v_cast_F33EE(1'sb0), sv2v_cast_60B87(1'sb0)};
				info_c = 8'b00100001;
			end
			default: begin
				operand_a = {fpnew_pkg_DONT_CARE, sv2v_cast_91364(fpnew_pkg_DONT_CARE), sv2v_cast_14681(fpnew_pkg_DONT_CARE)};
				operand_b = {fpnew_pkg_DONT_CARE, sv2v_cast_91364(fpnew_pkg_DONT_CARE), sv2v_cast_14681(fpnew_pkg_DONT_CARE)};
				operand_c = {fpnew_pkg_DONT_CARE, sv2v_cast_91364(fpnew_pkg_DONT_CARE), sv2v_cast_14681(fpnew_pkg_DONT_CARE)};
				info_a = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
				info_b = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
				info_c = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
			end
		endcase
	end
	wire any_operand_inf;
	wire any_operand_nan;
	wire signalling_nan;
	wire effective_subtraction;
	wire tentative_sign;
	assign any_operand_inf = |{info_a[4], info_b[4], info_c[4]};
	assign any_operand_nan = |{info_a[3], info_b[3], info_c[3]};
	assign signalling_nan = |{info_a[2], info_b[2], info_c[2]};
	assign effective_subtraction = (operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] ^ operand_b[1 + (EXP_BITS + (MAN_BITS - 1))]) ^ operand_c[1 + (EXP_BITS + (MAN_BITS - 1))];
	assign tentative_sign = operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] ^ operand_b[1 + (EXP_BITS + (MAN_BITS - 1))];
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] special_result;
	reg [4:0] special_status;
	reg result_is_special;
	always @(*) begin : special_cases
		special_result = {1'b0, sv2v_cast_F33EE(1'sb1), sv2v_cast_14681(2 ** (MAN_BITS - 1))};
		special_status = 1'sb0;
		result_is_special = 1'b0;
		if ((info_a[4] && info_b[5]) || (info_a[5] && info_b[4])) begin
			result_is_special = 1'b1;
			special_status[4] = 1'b1;
		end
		else if (any_operand_nan) begin
			result_is_special = 1'b1;
			special_status[4] = signalling_nan;
		end
		else if (any_operand_inf) begin
			result_is_special = 1'b1;
			if (((info_a[4] || info_b[4]) && info_c[4]) && effective_subtraction)
				special_status[4] = 1'b1;
			else if (info_a[4] || info_b[4])
				special_result = {operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] ^ operand_b[1 + (EXP_BITS + (MAN_BITS - 1))], sv2v_cast_F33EE(1'sb1), sv2v_cast_60B87(1'sb0)};
			else if (info_c[4])
				special_result = {operand_c[1 + (EXP_BITS + (MAN_BITS - 1))], sv2v_cast_F33EE(1'sb1), sv2v_cast_60B87(1'sb0)};
		end
	end
	wire signed [EXP_WIDTH - 1:0] exponent_a;
	wire signed [EXP_WIDTH - 1:0] exponent_b;
	wire signed [EXP_WIDTH - 1:0] exponent_c;
	wire signed [EXP_WIDTH - 1:0] exponent_addend;
	wire signed [EXP_WIDTH - 1:0] exponent_product;
	wire signed [EXP_WIDTH - 1:0] exponent_difference;
	wire signed [EXP_WIDTH - 1:0] tentative_exponent;
	assign exponent_a = $signed({1'b0, operand_a[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)]});
	assign exponent_b = $signed({1'b0, operand_b[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)]});
	assign exponent_c = $signed({1'b0, operand_c[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)]});
	assign exponent_addend = $signed(exponent_c + $signed({1'b0, ~info_c[7]}));
	assign exponent_product = (info_a[5] || info_b[5] ? 2 - $signed(BIAS) : $signed((((exponent_a + info_a[6]) + exponent_b) + info_b[6]) - $signed(BIAS)));
	assign exponent_difference = exponent_addend - exponent_product;
	assign tentative_exponent = (exponent_difference > 0 ? exponent_addend : exponent_product);
	reg [SHIFT_AMOUNT_WIDTH - 1:0] addend_shamt;
	always @(*) begin : addend_shift_amount
		if (exponent_difference <= $signed((-2 * PRECISION_BITS) - 1))
			addend_shamt = (3 * PRECISION_BITS) + 4;
		else if (exponent_difference <= $signed(PRECISION_BITS + 2))
			addend_shamt = $unsigned(($signed(PRECISION_BITS) + 3) - exponent_difference);
		else
			addend_shamt = 0;
	end
	wire [PRECISION_BITS - 1:0] mantissa_a;
	wire [PRECISION_BITS - 1:0] mantissa_b;
	wire [PRECISION_BITS - 1:0] mantissa_c;
	wire [(2 * PRECISION_BITS) - 1:0] product;
	wire [(3 * PRECISION_BITS) + 3:0] product_shifted;
	assign mantissa_a = {info_a[7], operand_a[MAN_BITS - 1-:MAN_BITS]};
	assign mantissa_b = {info_b[7], operand_b[MAN_BITS - 1-:MAN_BITS]};
	assign mantissa_c = {info_c[7], operand_c[MAN_BITS - 1-:MAN_BITS]};
	assign product = mantissa_a * mantissa_b;
	assign product_shifted = product << 2;
	wire [(3 * PRECISION_BITS) + 3:0] addend_after_shift;
	wire [PRECISION_BITS - 1:0] addend_sticky_bits;
	wire sticky_before_add;
	wire [(3 * PRECISION_BITS) + 3:0] addend_shifted;
	wire inject_carry_in;
	assign {addend_after_shift, addend_sticky_bits} = (mantissa_c << ((3 * PRECISION_BITS) + 4)) >> addend_shamt;
	assign sticky_before_add = |addend_sticky_bits;
	assign addend_shifted = (effective_subtraction ? ~addend_after_shift : addend_after_shift);
	assign inject_carry_in = effective_subtraction & ~sticky_before_add;
	wire [(3 * PRECISION_BITS) + 4:0] sum_raw;
	wire sum_carry;
	wire [(3 * PRECISION_BITS) + 3:0] sum;
	wire final_sign;
	assign sum_raw = (product_shifted + addend_shifted) + inject_carry_in;
	assign sum_carry = sum_raw[(3 * PRECISION_BITS) + 4];
	assign sum = (effective_subtraction && ~sum_carry ? -sum_raw : sum_raw);
	assign final_sign = (effective_subtraction && (sum_carry == tentative_sign) ? 1'b1 : (effective_subtraction ? 1'b0 : tentative_sign));
	wire effective_subtraction_q;
	wire signed [EXP_WIDTH - 1:0] exponent_product_q;
	wire signed [EXP_WIDTH - 1:0] exponent_difference_q;
	wire signed [EXP_WIDTH - 1:0] tentative_exponent_q;
	wire [SHIFT_AMOUNT_WIDTH - 1:0] addend_shamt_q;
	wire sticky_before_add_q;
	wire [(3 * PRECISION_BITS) + 3:0] sum_q;
	wire final_sign_q;
	wire [2:0] rnd_mode_q;
	wire result_is_special_q;
	wire [((1 + EXP_BITS) + MAN_BITS) - 1:0] special_result_q;
	wire [4:0] special_status_q;
	reg [0:NUM_MID_REGS] mid_pipe_eff_sub_q;
	reg signed [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * EXP_WIDTH) + ((NUM_MID_REGS * EXP_WIDTH) - 1) : ((NUM_MID_REGS + 1) * EXP_WIDTH) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * EXP_WIDTH : 0)] mid_pipe_exp_prod_q;
	reg signed [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * EXP_WIDTH) + ((NUM_MID_REGS * EXP_WIDTH) - 1) : ((NUM_MID_REGS + 1) * EXP_WIDTH) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * EXP_WIDTH : 0)] mid_pipe_exp_diff_q;
	reg signed [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * EXP_WIDTH) + ((NUM_MID_REGS * EXP_WIDTH) - 1) : ((NUM_MID_REGS + 1) * EXP_WIDTH) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * EXP_WIDTH : 0)] mid_pipe_tent_exp_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * SHIFT_AMOUNT_WIDTH) + ((NUM_MID_REGS * SHIFT_AMOUNT_WIDTH) - 1) : ((NUM_MID_REGS + 1) * SHIFT_AMOUNT_WIDTH) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * SHIFT_AMOUNT_WIDTH : 0)] mid_pipe_add_shamt_q;
	reg [0:NUM_MID_REGS] mid_pipe_sticky_q;
	reg [(0 >= NUM_MID_REGS ? (((3 * PRECISION_BITS) + 3) >= 0 ? ((1 - NUM_MID_REGS) * ((3 * PRECISION_BITS) + 4)) + ((NUM_MID_REGS * ((3 * PRECISION_BITS) + 4)) - 1) : ((1 - NUM_MID_REGS) * (1 - ((3 * PRECISION_BITS) + 3))) + ((((3 * PRECISION_BITS) + 3) + (NUM_MID_REGS * (1 - ((3 * PRECISION_BITS) + 3)))) - 1)) : (((3 * PRECISION_BITS) + 3) >= 0 ? ((NUM_MID_REGS + 1) * ((3 * PRECISION_BITS) + 4)) - 1 : ((NUM_MID_REGS + 1) * (1 - ((3 * PRECISION_BITS) + 3))) + ((3 * PRECISION_BITS) + 2))):(0 >= NUM_MID_REGS ? (((3 * PRECISION_BITS) + 3) >= 0 ? NUM_MID_REGS * ((3 * PRECISION_BITS) + 4) : ((3 * PRECISION_BITS) + 3) + (NUM_MID_REGS * (1 - ((3 * PRECISION_BITS) + 3)))) : (((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3))] mid_pipe_sum_q;
	reg [0:NUM_MID_REGS] mid_pipe_final_sign_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * 3) + ((NUM_MID_REGS * 3) - 1) : ((NUM_MID_REGS + 1) * 3) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * 3 : 0)] mid_pipe_rnd_mode_q;
	reg [0:NUM_MID_REGS] mid_pipe_res_is_spec_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * ((1 + EXP_BITS) + MAN_BITS)) + ((NUM_MID_REGS * ((1 + EXP_BITS) + MAN_BITS)) - 1) : ((NUM_MID_REGS + 1) * ((1 + EXP_BITS) + MAN_BITS)) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * ((1 + EXP_BITS) + MAN_BITS) : 0)] mid_pipe_spec_res_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * 5) + ((NUM_MID_REGS * 5) - 1) : ((NUM_MID_REGS + 1) * 5) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * 5 : 0)] mid_pipe_spec_stat_q;
	reg [0:NUM_MID_REGS] mid_pipe_tag_q;
	reg [0:NUM_MID_REGS] mid_pipe_mask_q;
	reg [0:NUM_MID_REGS] mid_pipe_aux_q;
	reg [0:NUM_MID_REGS] mid_pipe_valid_q;
	wire [0:NUM_MID_REGS] mid_pipe_ready;
	wire [1:1] sv2v_tmp_56A72;
	assign sv2v_tmp_56A72 = effective_subtraction;
	always @(*) mid_pipe_eff_sub_q[0] = sv2v_tmp_56A72;
	wire [EXP_WIDTH * 1:1] sv2v_tmp_2D21E;
	assign sv2v_tmp_2D21E = exponent_product;
	always @(*) mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH] = sv2v_tmp_2D21E;
	wire [EXP_WIDTH * 1:1] sv2v_tmp_00793;
	assign sv2v_tmp_00793 = exponent_difference;
	always @(*) mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH] = sv2v_tmp_00793;
	wire [EXP_WIDTH * 1:1] sv2v_tmp_B4C85;
	assign sv2v_tmp_B4C85 = tentative_exponent;
	always @(*) mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH] = sv2v_tmp_B4C85;
	wire [SHIFT_AMOUNT_WIDTH * 1:1] sv2v_tmp_83404;
	assign sv2v_tmp_83404 = addend_shamt;
	always @(*) mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH] = sv2v_tmp_83404;
	wire [1:1] sv2v_tmp_6F5F7;
	assign sv2v_tmp_6F5F7 = sticky_before_add;
	always @(*) mid_pipe_sticky_q[0] = sv2v_tmp_6F5F7;
	wire [(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)) * 1:1] sv2v_tmp_CEAB3;
	assign sv2v_tmp_CEAB3 = sum;
	always @(*) mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))] = sv2v_tmp_CEAB3;
	wire [1:1] sv2v_tmp_D7BD0;
	assign sv2v_tmp_D7BD0 = final_sign;
	always @(*) mid_pipe_final_sign_q[0] = sv2v_tmp_D7BD0;
	wire [3:1] sv2v_tmp_A74E2;
	assign sv2v_tmp_A74E2 = inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3];
	always @(*) mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * 3+:3] = sv2v_tmp_A74E2;
	wire [1:1] sv2v_tmp_7DEC5;
	assign sv2v_tmp_7DEC5 = result_is_special;
	always @(*) mid_pipe_res_is_spec_q[0] = sv2v_tmp_7DEC5;
	wire [((1 + EXP_BITS) + MAN_BITS) * 1:1] sv2v_tmp_4A83E;
	assign sv2v_tmp_4A83E = special_result;
	always @(*) mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] = sv2v_tmp_4A83E;
	wire [5:1] sv2v_tmp_EC01B;
	assign sv2v_tmp_EC01B = special_status;
	always @(*) mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * 5+:5] = sv2v_tmp_EC01B;
	wire [1:1] sv2v_tmp_44BCE;
	assign sv2v_tmp_44BCE = inp_pipe_tag_q[NUM_INP_REGS];
	always @(*) mid_pipe_tag_q[0] = sv2v_tmp_44BCE;
	wire [1:1] sv2v_tmp_D7646;
	assign sv2v_tmp_D7646 = inp_pipe_mask_q[NUM_INP_REGS];
	always @(*) mid_pipe_mask_q[0] = sv2v_tmp_D7646;
	wire [1:1] sv2v_tmp_CDA0E;
	assign sv2v_tmp_CDA0E = inp_pipe_aux_q[NUM_INP_REGS];
	always @(*) mid_pipe_aux_q[0] = sv2v_tmp_CDA0E;
	wire [1:1] sv2v_tmp_CB10A;
	assign sv2v_tmp_CB10A = inp_pipe_valid_q[NUM_INP_REGS];
	always @(*) mid_pipe_valid_q[0] = sv2v_tmp_CB10A;
	assign inp_pipe_ready[NUM_INP_REGS] = mid_pipe_ready[0];
	generate
		for (i = 0; i < NUM_MID_REGS; i = i + 1) begin : gen_inside_pipeline
			wire reg_ena;
			assign mid_pipe_ready[i] = mid_pipe_ready[i + 1] | ~mid_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_valid_q[i + 1] <= 1'b0;
				else
					mid_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (mid_pipe_ready[i] ? mid_pipe_valid_q[i] : mid_pipe_valid_q[i + 1]));
			assign reg_ena = (mid_pipe_ready[i] & mid_pipe_valid_q[i]) | reg_ena_i[NUM_INP_REGS + i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_eff_sub_q[i + 1] <= 1'sb0;
				else
					mid_pipe_eff_sub_q[i + 1] <= (reg_ena ? mid_pipe_eff_sub_q[i] : mid_pipe_eff_sub_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= 1'sb0;
				else
					mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= (reg_ena ? mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * EXP_WIDTH+:EXP_WIDTH] : mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= 1'sb0;
				else
					mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= (reg_ena ? mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * EXP_WIDTH+:EXP_WIDTH] : mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= 1'sb0;
				else
					mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= (reg_ena ? mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * EXP_WIDTH+:EXP_WIDTH] : mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH] <= 1'sb0;
				else
					mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH] <= (reg_ena ? mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH] : mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_sticky_q[i + 1] <= 1'sb0;
				else
					mid_pipe_sticky_q[i + 1] <= (reg_ena ? mid_pipe_sticky_q[i] : mid_pipe_sticky_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))] <= 1'sb0;
				else
					mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))] <= (reg_ena ? mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))] : mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_final_sign_q[i + 1] <= 1'sb0;
				else
					mid_pipe_final_sign_q[i + 1] <= (reg_ena ? mid_pipe_final_sign_q[i] : mid_pipe_final_sign_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 3+:3] <= 3'b000;
				else
					mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 3+:3] <= (reg_ena ? mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * 3+:3] : mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 3+:3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_res_is_spec_q[i + 1] <= 1'sb0;
				else
					mid_pipe_res_is_spec_q[i + 1] <= (reg_ena ? mid_pipe_res_is_spec_q[i] : mid_pipe_res_is_spec_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] <= 1'sb0;
				else
					mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] <= (reg_ena ? mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] : mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 5+:5] <= 1'sb0;
				else
					mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 5+:5] <= (reg_ena ? mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * 5+:5] : mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 5+:5]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_tag_q[i + 1] <= 1'b0;
				else
					mid_pipe_tag_q[i + 1] <= (reg_ena ? mid_pipe_tag_q[i] : mid_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_mask_q[i + 1] <= 1'sb0;
				else
					mid_pipe_mask_q[i + 1] <= (reg_ena ? mid_pipe_mask_q[i] : mid_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_aux_q[i + 1] <= 1'b0;
				else
					mid_pipe_aux_q[i + 1] <= (reg_ena ? mid_pipe_aux_q[i] : mid_pipe_aux_q[i + 1]);
		end
	endgenerate
	assign effective_subtraction_q = mid_pipe_eff_sub_q[NUM_MID_REGS];
	assign exponent_product_q = mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH];
	assign exponent_difference_q = mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH];
	assign tentative_exponent_q = mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH];
	assign addend_shamt_q = mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH];
	assign sticky_before_add_q = mid_pipe_sticky_q[NUM_MID_REGS];
	assign sum_q = mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))];
	assign final_sign_q = mid_pipe_final_sign_q[NUM_MID_REGS];
	assign rnd_mode_q = mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * 3+:3];
	assign result_is_special_q = mid_pipe_res_is_spec_q[NUM_MID_REGS];
	assign special_result_q = mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS];
	assign special_status_q = mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * 5+:5];
	wire [LOWER_SUM_WIDTH - 1:0] sum_lower;
	wire [LZC_RESULT_WIDTH - 1:0] leading_zero_count;
	wire signed [LZC_RESULT_WIDTH:0] leading_zero_count_sgn;
	wire lzc_zeroes;
	reg [SHIFT_AMOUNT_WIDTH - 1:0] norm_shamt;
	reg signed [EXP_WIDTH - 1:0] normalized_exponent;
	wire [(3 * PRECISION_BITS) + 4:0] sum_shifted;
	reg [PRECISION_BITS:0] final_mantissa;
	reg [(2 * PRECISION_BITS) + 2:0] sum_sticky_bits;
	wire sticky_after_norm;
	reg signed [EXP_WIDTH - 1:0] final_exponent;
	assign sum_lower = sum_q[LOWER_SUM_WIDTH - 1:0];
	lzc #(
		.WIDTH(LOWER_SUM_WIDTH),
		.MODE(1)
	) i_lzc(
		.in_i(sum_lower),
		.cnt_o(leading_zero_count),
		.empty_o(lzc_zeroes)
	);
	assign leading_zero_count_sgn = $signed({1'b0, leading_zero_count});
	always @(*) begin : norm_shift_amount
		if ((exponent_difference_q <= 0) || (effective_subtraction_q && (exponent_difference_q <= 2))) begin
			if ((((exponent_product_q - leading_zero_count_sgn) + 1) >= 0) && !lzc_zeroes) begin
				norm_shamt = (PRECISION_BITS + 2) + leading_zero_count;
				normalized_exponent = (exponent_product_q - leading_zero_count_sgn) + 1;
			end
			else begin
				norm_shamt = $unsigned(($signed(PRECISION_BITS) + 2) + exponent_product_q);
				normalized_exponent = 0;
			end
		end
		else begin
			norm_shamt = addend_shamt_q;
			normalized_exponent = tentative_exponent_q;
		end
	end
	assign sum_shifted = sum_q << norm_shamt;
	always @(*) begin : small_norm
		{final_mantissa, sum_sticky_bits} = sum_shifted;
		final_exponent = normalized_exponent;
		if (sum_shifted[(3 * PRECISION_BITS) + 4]) begin
			{final_mantissa, sum_sticky_bits} = sum_shifted >> 1;
			final_exponent = normalized_exponent + 1;
		end
		else if (sum_shifted[(3 * PRECISION_BITS) + 3])
			;
		else if (normalized_exponent > 1) begin
			{final_mantissa, sum_sticky_bits} = sum_shifted << 1;
			final_exponent = normalized_exponent - 1;
		end
		else
			final_exponent = 1'sb0;
	end
	assign sticky_after_norm = |{sum_sticky_bits} | sticky_before_add_q;
	wire pre_round_sign;
	wire [EXP_BITS - 1:0] pre_round_exponent;
	wire [MAN_BITS - 1:0] pre_round_mantissa;
	wire [(EXP_BITS + MAN_BITS) - 1:0] pre_round_abs;
	wire [1:0] round_sticky_bits;
	wire of_before_round;
	wire of_after_round;
	wire uf_before_round;
	wire uf_after_round;
	wire result_zero;
	wire rounded_sign;
	wire [(EXP_BITS + MAN_BITS) - 1:0] rounded_abs;
	assign of_before_round = final_exponent >= ((2 ** EXP_BITS) - 1);
	assign uf_before_round = final_exponent == 0;
	assign pre_round_sign = final_sign_q;
	assign pre_round_exponent = (of_before_round ? (2 ** EXP_BITS) - 2 : $unsigned(final_exponent[EXP_BITS - 1:0]));
	assign pre_round_mantissa = (of_before_round ? {MAN_BITS {1'sb1}} : final_mantissa[MAN_BITS:1]);
	assign pre_round_abs = {pre_round_exponent, pre_round_mantissa};
	assign round_sticky_bits = (of_before_round ? 2'b11 : {final_mantissa[0], sticky_after_norm});
	fpnew_rounding #(.AbsWidth(EXP_BITS + MAN_BITS)) i_fpnew_rounding(
		.abs_value_i(pre_round_abs),
		.sign_i(pre_round_sign),
		.round_sticky_bits_i(round_sticky_bits),
		.rnd_mode_i(rnd_mode_q),
		.effective_subtraction_i(effective_subtraction_q),
		.abs_rounded_o(rounded_abs),
		.sign_o(rounded_sign),
		.exact_zero_o(result_zero)
	);
	assign uf_after_round = (rounded_abs[(EXP_BITS + MAN_BITS) - 1:MAN_BITS] == {(((EXP_BITS + MAN_BITS) - 1) >= MAN_BITS ? (((EXP_BITS + MAN_BITS) - 1) - MAN_BITS) + 1 : (MAN_BITS - ((EXP_BITS + MAN_BITS) - 1)) + 1) * 1 {1'sb0}}) || (((pre_round_abs[(EXP_BITS + MAN_BITS) - 1:MAN_BITS] == {(((EXP_BITS + MAN_BITS) - 1) >= MAN_BITS ? (((EXP_BITS + MAN_BITS) - 1) - MAN_BITS) + 1 : (MAN_BITS - ((EXP_BITS + MAN_BITS) - 1)) + 1) * 1 {1'sb0}}) && (rounded_abs[(EXP_BITS + MAN_BITS) - 1:MAN_BITS] == 1)) && ((round_sticky_bits != 2'b11) || (!sum_sticky_bits[(MAN_BITS * 2) + 4] && ((rnd_mode_i == 3'b000) || (rnd_mode_i == 3'b100)))));
	assign of_after_round = rounded_abs[(EXP_BITS + MAN_BITS) - 1:MAN_BITS] == {(((EXP_BITS + MAN_BITS) - 1) >= MAN_BITS ? (((EXP_BITS + MAN_BITS) - 1) - MAN_BITS) + 1 : (MAN_BITS - ((EXP_BITS + MAN_BITS) - 1)) + 1) * 1 {1'sb1}};
	wire [WIDTH - 1:0] regular_result;
	wire [4:0] regular_status;
	assign regular_result = {rounded_sign, rounded_abs};
	assign regular_status[4] = 1'b0;
	assign regular_status[3] = 1'b0;
	assign regular_status[2] = of_before_round | of_after_round;
	assign regular_status[1] = uf_after_round & regular_status[0];
	assign regular_status[0] = (|round_sticky_bits | of_before_round) | of_after_round;
	wire [((1 + EXP_BITS) + MAN_BITS) - 1:0] result_d;
	wire [4:0] status_d;
	assign result_d = (result_is_special_q ? special_result_q : regular_result);
	assign status_d = (result_is_special_q ? special_status_q : regular_status);
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * ((1 + EXP_BITS) + MAN_BITS)) + ((NUM_OUT_REGS * ((1 + EXP_BITS) + MAN_BITS)) - 1) : ((NUM_OUT_REGS + 1) * ((1 + EXP_BITS) + MAN_BITS)) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * ((1 + EXP_BITS) + MAN_BITS) : 0)] out_pipe_result_q;
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * 5) + ((NUM_OUT_REGS * 5) - 1) : ((NUM_OUT_REGS + 1) * 5) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * 5 : 0)] out_pipe_status_q;
	reg [0:NUM_OUT_REGS] out_pipe_tag_q;
	reg [0:NUM_OUT_REGS] out_pipe_mask_q;
	reg [0:NUM_OUT_REGS] out_pipe_aux_q;
	reg [0:NUM_OUT_REGS] out_pipe_valid_q;
	wire [0:NUM_OUT_REGS] out_pipe_ready;
	wire [((1 + EXP_BITS) + MAN_BITS) * 1:1] sv2v_tmp_0252C;
	assign sv2v_tmp_0252C = result_d;
	always @(*) out_pipe_result_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] = sv2v_tmp_0252C;
	wire [5:1] sv2v_tmp_2A843;
	assign sv2v_tmp_2A843 = status_d;
	always @(*) out_pipe_status_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * 5+:5] = sv2v_tmp_2A843;
	wire [1:1] sv2v_tmp_DF7DA;
	assign sv2v_tmp_DF7DA = mid_pipe_tag_q[NUM_MID_REGS];
	always @(*) out_pipe_tag_q[0] = sv2v_tmp_DF7DA;
	wire [1:1] sv2v_tmp_DB780;
	assign sv2v_tmp_DB780 = mid_pipe_mask_q[NUM_MID_REGS];
	always @(*) out_pipe_mask_q[0] = sv2v_tmp_DB780;
	wire [1:1] sv2v_tmp_9E262;
	assign sv2v_tmp_9E262 = mid_pipe_aux_q[NUM_MID_REGS];
	always @(*) out_pipe_aux_q[0] = sv2v_tmp_9E262;
	wire [1:1] sv2v_tmp_25EE6;
	assign sv2v_tmp_25EE6 = mid_pipe_valid_q[NUM_MID_REGS];
	always @(*) out_pipe_valid_q[0] = sv2v_tmp_25EE6;
	assign mid_pipe_ready[NUM_MID_REGS] = out_pipe_ready[0];
	generate
		for (i = 0; i < NUM_OUT_REGS; i = i + 1) begin : gen_output_pipeline
			wire reg_ena;
			assign out_pipe_ready[i] = out_pipe_ready[i + 1] | ~out_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_valid_q[i + 1] <= 1'b0;
				else
					out_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (out_pipe_ready[i] ? out_pipe_valid_q[i] : out_pipe_valid_q[i + 1]));
			assign reg_ena = (out_pipe_ready[i] & out_pipe_valid_q[i]) | reg_ena_i[(NUM_INP_REGS + NUM_MID_REGS) + i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] <= 1'sb0;
				else
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] <= (reg_ena ? out_pipe_result_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] : out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= 1'sb0;
				else
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= (reg_ena ? out_pipe_status_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * 5+:5] : out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_tag_q[i + 1] <= 1'b0;
				else
					out_pipe_tag_q[i + 1] <= (reg_ena ? out_pipe_tag_q[i] : out_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_mask_q[i + 1] <= 1'sb0;
				else
					out_pipe_mask_q[i + 1] <= (reg_ena ? out_pipe_mask_q[i] : out_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_aux_q[i + 1] <= 1'b0;
				else
					out_pipe_aux_q[i + 1] <= (reg_ena ? out_pipe_aux_q[i] : out_pipe_aux_q[i + 1]);
		end
	endgenerate
	assign out_pipe_ready[NUM_OUT_REGS] = out_ready_i;
	assign result_o = out_pipe_result_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS];
	assign status_o = out_pipe_status_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * 5+:5];
	assign extension_bit_o = 1'b1;
	assign tag_o = out_pipe_tag_q[NUM_OUT_REGS];
	assign mask_o = out_pipe_mask_q[NUM_OUT_REGS];
	assign aux_o = out_pipe_aux_q[NUM_OUT_REGS];
	assign out_valid_o = out_pipe_valid_q[NUM_OUT_REGS];
	assign busy_o = |{inp_pipe_valid_q, mid_pipe_valid_q, out_pipe_valid_q};
endmodule
module fpnew_noncomp_1F07E (
	clk_i,
	rst_ni,
	operands_i,
	is_boxed_i,
	rnd_mode_i,
	op_i,
	op_mod_i,
	tag_i,
	mask_i,
	aux_i,
	in_valid_i,
	in_ready_o,
	flush_i,
	result_o,
	status_o,
	extension_bit_o,
	class_mask_o,
	is_class_o,
	tag_o,
	mask_o,
	aux_o,
	out_valid_o,
	out_ready_i,
	busy_o,
	reg_ena_i
);
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	function automatic [2:0] sv2v_cast_0BC43;
		input reg [2:0] inp;
		sv2v_cast_0BC43 = inp;
	endfunction
	parameter [2:0] FpFormat = sv2v_cast_0BC43(0);
	parameter [31:0] NumPipeRegs = 0;
	parameter [1:0] PipeConfig = 2'd0;
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	localparam [31:0] WIDTH = fpnew_pkg_fp_width(FpFormat);
	localparam [31:0] ExtRegEnaWidth = (NumPipeRegs == 0 ? 1 : NumPipeRegs);
	input wire clk_i;
	input wire rst_ni;
	input wire [(2 * WIDTH) - 1:0] operands_i;
	input wire [1:0] is_boxed_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire op_mod_i;
	input wire tag_i;
	input wire mask_i;
	input wire aux_i;
	input wire in_valid_i;
	output wire in_ready_o;
	input wire flush_i;
	output wire [WIDTH - 1:0] result_o;
	output wire [4:0] status_o;
	output wire extension_bit_o;
	output wire [9:0] class_mask_o;
	output wire is_class_o;
	output wire tag_o;
	output wire mask_o;
	output wire aux_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	input wire [ExtRegEnaWidth - 1:0] reg_ena_i;
	function automatic [31:0] fpnew_pkg_exp_bits;
		input reg [2:0] fmt;
		fpnew_pkg_exp_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32];
	endfunction
	localparam [31:0] EXP_BITS = fpnew_pkg_exp_bits(FpFormat);
	function automatic [31:0] fpnew_pkg_man_bits;
		input reg [2:0] fmt;
		fpnew_pkg_man_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32];
	endfunction
	localparam [31:0] MAN_BITS = fpnew_pkg_man_bits(FpFormat);
	localparam NUM_INP_REGS = ((PipeConfig == 2'd0) || (PipeConfig == 2'd2) ? NumPipeRegs : (PipeConfig == 2'd3 ? (NumPipeRegs + 1) / 2 : 0));
	localparam NUM_OUT_REGS = (PipeConfig == 2'd1 ? NumPipeRegs : (PipeConfig == 2'd3 ? NumPipeRegs / 2 : 0));
	reg [((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) - (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0)) + 1) * WIDTH) + (((0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) * WIDTH) - 1) : ((((0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)) + 1) * WIDTH) + (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) * WIDTH) - 1)):((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) * WIDTH : (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) * WIDTH)] inp_pipe_operands_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0)] inp_pipe_is_boxed_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0)] inp_pipe_rnd_mode_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * fpnew_pkg_OP_BITS) + ((NUM_INP_REGS * fpnew_pkg_OP_BITS) - 1) : ((NUM_INP_REGS + 1) * fpnew_pkg_OP_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * fpnew_pkg_OP_BITS : 0)] inp_pipe_op_q;
	reg [0:NUM_INP_REGS] inp_pipe_op_mod_q;
	reg [0:NUM_INP_REGS] inp_pipe_tag_q;
	reg [0:NUM_INP_REGS] inp_pipe_mask_q;
	reg [0:NUM_INP_REGS] inp_pipe_aux_q;
	reg [0:NUM_INP_REGS] inp_pipe_valid_q;
	wire [0:NUM_INP_REGS] inp_pipe_ready;
	wire [2 * WIDTH:1] sv2v_tmp_D1067;
	assign sv2v_tmp_D1067 = operands_i;
	always @(*) inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2] = sv2v_tmp_D1067;
	wire [2:1] sv2v_tmp_86D63;
	assign sv2v_tmp_86D63 = is_boxed_i;
	always @(*) inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2+:2] = sv2v_tmp_86D63;
	wire [3:1] sv2v_tmp_62109;
	assign sv2v_tmp_62109 = rnd_mode_i;
	always @(*) inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3+:3] = sv2v_tmp_62109;
	wire [4:1] sv2v_tmp_0B797;
	assign sv2v_tmp_0B797 = op_i;
	always @(*) inp_pipe_op_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] = sv2v_tmp_0B797;
	wire [1:1] sv2v_tmp_D1C37;
	assign sv2v_tmp_D1C37 = op_mod_i;
	always @(*) inp_pipe_op_mod_q[0] = sv2v_tmp_D1C37;
	wire [1:1] sv2v_tmp_76699;
	assign sv2v_tmp_76699 = tag_i;
	always @(*) inp_pipe_tag_q[0] = sv2v_tmp_76699;
	wire [1:1] sv2v_tmp_407DF;
	assign sv2v_tmp_407DF = mask_i;
	always @(*) inp_pipe_mask_q[0] = sv2v_tmp_407DF;
	wire [1:1] sv2v_tmp_8D189;
	assign sv2v_tmp_8D189 = aux_i;
	always @(*) inp_pipe_aux_q[0] = sv2v_tmp_8D189;
	wire [1:1] sv2v_tmp_73AEA;
	assign sv2v_tmp_73AEA = in_valid_i;
	always @(*) inp_pipe_valid_q[0] = sv2v_tmp_73AEA;
	assign in_ready_o = inp_pipe_ready[0];
	genvar i;
	function automatic [3:0] sv2v_cast_A53F3;
		input reg [3:0] inp;
		sv2v_cast_A53F3 = inp;
	endfunction
	generate
		for (i = 0; i < NUM_INP_REGS; i = i + 1) begin : gen_input_pipeline
			wire reg_ena;
			assign inp_pipe_ready[i] = inp_pipe_ready[i + 1] | ~inp_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_valid_q[i + 1] <= 1'b0;
				else
					inp_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (inp_pipe_ready[i] ? inp_pipe_valid_q[i] : inp_pipe_valid_q[i + 1]));
			assign reg_ena = (inp_pipe_ready[i] & inp_pipe_valid_q[i]) | reg_ena_i[i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2] <= 1'sb0;
				else
					inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2] <= (reg_ena ? inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2 : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2 : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2] : inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2+:2] <= 1'sb0;
				else
					inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2+:2] <= (reg_ena ? inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2+:2] : inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2+:2]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= 3'b000;
				else
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= (reg_ena ? inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3+:3] : inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= sv2v_cast_A53F3(0);
				else
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= (reg_ena ? inp_pipe_op_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] : inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_op_mod_q[i + 1] <= 1'sb0;
				else
					inp_pipe_op_mod_q[i + 1] <= (reg_ena ? inp_pipe_op_mod_q[i] : inp_pipe_op_mod_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_tag_q[i + 1] <= 1'b0;
				else
					inp_pipe_tag_q[i + 1] <= (reg_ena ? inp_pipe_tag_q[i] : inp_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_mask_q[i + 1] <= 1'sb0;
				else
					inp_pipe_mask_q[i + 1] <= (reg_ena ? inp_pipe_mask_q[i] : inp_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_aux_q[i + 1] <= 1'b0;
				else
					inp_pipe_aux_q[i + 1] <= (reg_ena ? inp_pipe_aux_q[i] : inp_pipe_aux_q[i + 1]);
		end
	endgenerate
	wire [15:0] info_q;
	fpnew_classifier #(
		.FpFormat(FpFormat),
		.NumOperands(2)
	) i_class_a(
		.operands_i(inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2]),
		.is_boxed_i(inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2+:2]),
		.info_o(info_q)
	);
	wire [((1 + EXP_BITS) + MAN_BITS) - 1:0] operand_a;
	wire [((1 + EXP_BITS) + MAN_BITS) - 1:0] operand_b;
	wire [7:0] info_a;
	wire [7:0] info_b;
	assign operand_a = inp_pipe_operands_q[((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2 : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1))) * WIDTH+:WIDTH];
	assign operand_b = inp_pipe_operands_q[((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2) + 1 : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - ((((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1))) * WIDTH+:WIDTH];
	assign info_a = info_q[0+:8];
	assign info_b = info_q[8+:8];
	wire any_operand_inf;
	wire any_operand_nan;
	wire signalling_nan;
	assign any_operand_inf = |{info_a[4], info_b[4]};
	assign any_operand_nan = |{info_a[3], info_b[3]};
	assign signalling_nan = |{info_a[2], info_b[2]};
	wire operands_equal;
	wire operand_a_smaller;
	assign operands_equal = (operand_a == operand_b) || (info_a[5] && info_b[5]);
	assign operand_a_smaller = (operand_a < operand_b) ^ (operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] || operand_b[1 + (EXP_BITS + (MAN_BITS - 1))]);
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] sgnj_result;
	wire [4:0] sgnj_status;
	wire sgnj_extension_bit;
	localparam [0:0] fpnew_pkg_DONT_CARE = 1'b1;
	function automatic [EXP_BITS - 1:0] sv2v_cast_F2D56;
		input reg [EXP_BITS - 1:0] inp;
		sv2v_cast_F2D56 = inp;
	endfunction
	function automatic [MAN_BITS - 1:0] sv2v_cast_14681;
		input reg [MAN_BITS - 1:0] inp;
		sv2v_cast_14681 = inp;
	endfunction
	function automatic [EXP_BITS - 1:0] sv2v_cast_91364;
		input reg [EXP_BITS - 1:0] inp;
		sv2v_cast_91364 = inp;
	endfunction
	always @(*) begin : sign_injections
		reg sign_a;
		reg sign_b;
		sgnj_result = operand_a;
		if (!info_a[0])
			sgnj_result = {1'b0, sv2v_cast_F2D56(1'sb1), sv2v_cast_14681(2 ** (MAN_BITS - 1))};
		sign_a = operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] & info_a[0];
		sign_b = operand_b[1 + (EXP_BITS + (MAN_BITS - 1))] & info_b[0];
		case (inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3])
			3'b000: sgnj_result[1 + (EXP_BITS + (MAN_BITS - 1))] = sign_b;
			3'b001: sgnj_result[1 + (EXP_BITS + (MAN_BITS - 1))] = ~sign_b;
			3'b010: sgnj_result[1 + (EXP_BITS + (MAN_BITS - 1))] = sign_a ^ sign_b;
			3'b011: sgnj_result = operand_a;
			default: sgnj_result = {fpnew_pkg_DONT_CARE, sv2v_cast_91364(fpnew_pkg_DONT_CARE), sv2v_cast_14681(fpnew_pkg_DONT_CARE)};
		endcase
	end
	assign sgnj_status = 1'sb0;
	assign sgnj_extension_bit = (inp_pipe_op_mod_q[NUM_INP_REGS] ? sgnj_result[1 + (EXP_BITS + (MAN_BITS - 1))] : 1'b1);
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] minmax_result;
	reg [4:0] minmax_status;
	wire minmax_extension_bit;
	always @(*) begin : min_max
		minmax_status = 1'sb0;
		minmax_status[4] = signalling_nan;
		if (info_a[3] && info_b[3])
			minmax_result = {1'b0, sv2v_cast_F2D56(1'sb1), sv2v_cast_14681(2 ** (MAN_BITS - 1))};
		else if (info_a[3])
			minmax_result = operand_b;
		else if (info_b[3])
			minmax_result = operand_a;
		else
			case (inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3])
				3'b000: minmax_result = (operand_a_smaller ? operand_a : operand_b);
				3'b001: minmax_result = (operand_a_smaller ? operand_b : operand_a);
				default: minmax_result = {fpnew_pkg_DONT_CARE, sv2v_cast_91364(fpnew_pkg_DONT_CARE), sv2v_cast_14681(fpnew_pkg_DONT_CARE)};
			endcase
	end
	assign minmax_extension_bit = 1'b1;
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] cmp_result;
	reg [4:0] cmp_status;
	wire cmp_extension_bit;
	always @(*) begin : comparisons
		cmp_result = 1'sb0;
		cmp_status = 1'sb0;
		if (signalling_nan)
			cmp_status[4] = 1'b1;
		else
			case (inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3])
				3'b000:
					if (any_operand_nan)
						cmp_status[4] = 1'b1;
					else
						cmp_result = (operand_a_smaller | operands_equal) ^ inp_pipe_op_mod_q[NUM_INP_REGS];
				3'b001:
					if (any_operand_nan)
						cmp_status[4] = 1'b1;
					else
						cmp_result = (operand_a_smaller & ~operands_equal) ^ inp_pipe_op_mod_q[NUM_INP_REGS];
				3'b010:
					if (any_operand_nan)
						cmp_result = inp_pipe_op_mod_q[NUM_INP_REGS];
					else
						cmp_result = operands_equal ^ inp_pipe_op_mod_q[NUM_INP_REGS];
				default: cmp_result = {fpnew_pkg_DONT_CARE, sv2v_cast_91364(fpnew_pkg_DONT_CARE), sv2v_cast_14681(fpnew_pkg_DONT_CARE)};
			endcase
	end
	assign cmp_extension_bit = 1'b0;
	wire [4:0] class_status;
	wire class_extension_bit;
	reg [9:0] class_mask_d;
	always @(*) begin : classify
		if (info_a[7])
			class_mask_d = (operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] ? 10'b0000000010 : 10'b0001000000);
		else if (info_a[6])
			class_mask_d = (operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] ? 10'b0000000100 : 10'b0000100000);
		else if (info_a[5])
			class_mask_d = (operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] ? 10'b0000001000 : 10'b0000010000);
		else if (info_a[4])
			class_mask_d = (operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] ? 10'b0000000001 : 10'b0010000000);
		else if (info_a[3])
			class_mask_d = (info_a[2] ? 10'b0100000000 : 10'b1000000000);
		else
			class_mask_d = 10'b1000000000;
	end
	assign class_status = 1'sb0;
	assign class_extension_bit = 1'b0;
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] result_d;
	reg [4:0] status_d;
	reg extension_bit_d;
	wire is_class_d;
	always @(*) begin : select_result
		case (inp_pipe_op_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS])
			sv2v_cast_A53F3(6): begin
				result_d = sgnj_result;
				status_d = sgnj_status;
				extension_bit_d = sgnj_extension_bit;
			end
			sv2v_cast_A53F3(7): begin
				result_d = minmax_result;
				status_d = minmax_status;
				extension_bit_d = minmax_extension_bit;
			end
			sv2v_cast_A53F3(8): begin
				result_d = cmp_result;
				status_d = cmp_status;
				extension_bit_d = cmp_extension_bit;
			end
			sv2v_cast_A53F3(9): begin
				result_d = {fpnew_pkg_DONT_CARE, sv2v_cast_91364(fpnew_pkg_DONT_CARE), sv2v_cast_14681(fpnew_pkg_DONT_CARE)};
				status_d = class_status;
				extension_bit_d = class_extension_bit;
			end
			default: begin
				result_d = {fpnew_pkg_DONT_CARE, sv2v_cast_91364(fpnew_pkg_DONT_CARE), sv2v_cast_14681(fpnew_pkg_DONT_CARE)};
				status_d = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
				extension_bit_d = fpnew_pkg_DONT_CARE;
			end
		endcase
	end
	assign is_class_d = inp_pipe_op_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] == sv2v_cast_A53F3(9);
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * ((1 + EXP_BITS) + MAN_BITS)) + ((NUM_OUT_REGS * ((1 + EXP_BITS) + MAN_BITS)) - 1) : ((NUM_OUT_REGS + 1) * ((1 + EXP_BITS) + MAN_BITS)) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * ((1 + EXP_BITS) + MAN_BITS) : 0)] out_pipe_result_q;
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * 5) + ((NUM_OUT_REGS * 5) - 1) : ((NUM_OUT_REGS + 1) * 5) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * 5 : 0)] out_pipe_status_q;
	reg [0:NUM_OUT_REGS] out_pipe_extension_bit_q;
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * 10) + ((NUM_OUT_REGS * 10) - 1) : ((NUM_OUT_REGS + 1) * 10) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * 10 : 0)] out_pipe_class_mask_q;
	reg [0:NUM_OUT_REGS] out_pipe_is_class_q;
	reg [0:NUM_OUT_REGS] out_pipe_tag_q;
	reg [0:NUM_OUT_REGS] out_pipe_mask_q;
	reg [0:NUM_OUT_REGS] out_pipe_aux_q;
	reg [0:NUM_OUT_REGS] out_pipe_valid_q;
	wire [0:NUM_OUT_REGS] out_pipe_ready;
	wire [((1 + EXP_BITS) + MAN_BITS) * 1:1] sv2v_tmp_07494;
	assign sv2v_tmp_07494 = result_d;
	always @(*) out_pipe_result_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] = sv2v_tmp_07494;
	wire [5:1] sv2v_tmp_CCE43;
	assign sv2v_tmp_CCE43 = status_d;
	always @(*) out_pipe_status_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * 5+:5] = sv2v_tmp_CCE43;
	wire [1:1] sv2v_tmp_8E9A9;
	assign sv2v_tmp_8E9A9 = extension_bit_d;
	always @(*) out_pipe_extension_bit_q[0] = sv2v_tmp_8E9A9;
	wire [10:1] sv2v_tmp_94259;
	assign sv2v_tmp_94259 = class_mask_d;
	always @(*) out_pipe_class_mask_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * 10+:10] = sv2v_tmp_94259;
	wire [1:1] sv2v_tmp_7DF01;
	assign sv2v_tmp_7DF01 = is_class_d;
	always @(*) out_pipe_is_class_q[0] = sv2v_tmp_7DF01;
	wire [1:1] sv2v_tmp_35518;
	assign sv2v_tmp_35518 = inp_pipe_tag_q[NUM_INP_REGS];
	always @(*) out_pipe_tag_q[0] = sv2v_tmp_35518;
	wire [1:1] sv2v_tmp_20A3C;
	assign sv2v_tmp_20A3C = inp_pipe_mask_q[NUM_INP_REGS];
	always @(*) out_pipe_mask_q[0] = sv2v_tmp_20A3C;
	wire [1:1] sv2v_tmp_FA930;
	assign sv2v_tmp_FA930 = inp_pipe_aux_q[NUM_INP_REGS];
	always @(*) out_pipe_aux_q[0] = sv2v_tmp_FA930;
	wire [1:1] sv2v_tmp_2CB8C;
	assign sv2v_tmp_2CB8C = inp_pipe_valid_q[NUM_INP_REGS];
	always @(*) out_pipe_valid_q[0] = sv2v_tmp_2CB8C;
	assign inp_pipe_ready[NUM_INP_REGS] = out_pipe_ready[0];
	generate
		for (i = 0; i < NUM_OUT_REGS; i = i + 1) begin : gen_output_pipeline
			wire reg_ena;
			assign out_pipe_ready[i] = out_pipe_ready[i + 1] | ~out_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_valid_q[i + 1] <= 1'b0;
				else
					out_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (out_pipe_ready[i] ? out_pipe_valid_q[i] : out_pipe_valid_q[i + 1]));
			assign reg_ena = (out_pipe_ready[i] & out_pipe_valid_q[i]) | reg_ena_i[NUM_INP_REGS + i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] <= 1'sb0;
				else
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] <= (reg_ena ? out_pipe_result_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] : out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= 1'sb0;
				else
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= (reg_ena ? out_pipe_status_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * 5+:5] : out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_extension_bit_q[i + 1] <= 1'sb0;
				else
					out_pipe_extension_bit_q[i + 1] <= (reg_ena ? out_pipe_extension_bit_q[i] : out_pipe_extension_bit_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_class_mask_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 10+:10] <= 10'b1000000000;
				else
					out_pipe_class_mask_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 10+:10] <= (reg_ena ? out_pipe_class_mask_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * 10+:10] : out_pipe_class_mask_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 10+:10]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_is_class_q[i + 1] <= 1'sb0;
				else
					out_pipe_is_class_q[i + 1] <= (reg_ena ? out_pipe_is_class_q[i] : out_pipe_is_class_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_tag_q[i + 1] <= 1'b0;
				else
					out_pipe_tag_q[i + 1] <= (reg_ena ? out_pipe_tag_q[i] : out_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_mask_q[i + 1] <= 1'sb0;
				else
					out_pipe_mask_q[i + 1] <= (reg_ena ? out_pipe_mask_q[i] : out_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_aux_q[i + 1] <= 1'b0;
				else
					out_pipe_aux_q[i + 1] <= (reg_ena ? out_pipe_aux_q[i] : out_pipe_aux_q[i + 1]);
		end
	endgenerate
	assign out_pipe_ready[NUM_OUT_REGS] = out_ready_i;
	assign result_o = out_pipe_result_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS];
	assign status_o = out_pipe_status_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * 5+:5];
	assign extension_bit_o = out_pipe_extension_bit_q[NUM_OUT_REGS];
	assign class_mask_o = out_pipe_class_mask_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * 10+:10];
	assign is_class_o = out_pipe_is_class_q[NUM_OUT_REGS];
	assign tag_o = out_pipe_tag_q[NUM_OUT_REGS];
	assign mask_o = out_pipe_mask_q[NUM_OUT_REGS];
	assign aux_o = out_pipe_aux_q[NUM_OUT_REGS];
	assign out_valid_o = out_pipe_valid_q[NUM_OUT_REGS];
	assign busy_o = |{inp_pipe_valid_q, out_pipe_valid_q};
endmodule
module fpnew_opgroup_fmt_slice_09303 (
	clk_i,
	rst_ni,
	operands_i,
	is_boxed_i,
	rnd_mode_i,
	op_i,
	op_mod_i,
	vectorial_op_i,
	tag_i,
	simd_mask_i,
	in_valid_i,
	in_ready_o,
	flush_i,
	result_o,
	status_o,
	extension_bit_o,
	tag_o,
	out_valid_o,
	out_ready_i,
	busy_o,
	reg_ena_i
);
	parameter [1:0] OpGroup = 2'd0;
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	function automatic [2:0] sv2v_cast_0BC43;
		input reg [2:0] inp;
		sv2v_cast_0BC43 = inp;
	endfunction
	parameter [2:0] FpFormat = sv2v_cast_0BC43(0);
	parameter [31:0] Width = 32;
	parameter [0:0] EnableVectors = 1'b1;
	parameter [31:0] NumPipeRegs = 0;
	parameter [1:0] PipeConfig = 2'd0;
	parameter [0:0] ExtRegEna = 1'b0;
	parameter [31:0] TrueSIMDClass = 0;
	function automatic [31:0] fpnew_pkg_num_operands;
		input reg [1:0] grp;
		case (grp)
			2'd0: fpnew_pkg_num_operands = 3;
			2'd1: fpnew_pkg_num_operands = 2;
			2'd2: fpnew_pkg_num_operands = 2;
			2'd3: fpnew_pkg_num_operands = 3;
			default: fpnew_pkg_num_operands = 0;
		endcase
	endfunction
	localparam [31:0] NUM_OPERANDS = fpnew_pkg_num_operands(OpGroup);
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	function automatic [31:0] fpnew_pkg_num_lanes;
		input reg [31:0] width;
		input reg [2:0] fmt;
		input reg vec;
		fpnew_pkg_num_lanes = (vec ? width / fpnew_pkg_fp_width(fmt) : 1);
	endfunction
	localparam [31:0] NUM_LANES = fpnew_pkg_num_lanes(Width, FpFormat, EnableVectors);
	localparam [31:0] ExtRegEnaWidth = (NumPipeRegs == 0 ? 1 : NumPipeRegs);
	input wire clk_i;
	input wire rst_ni;
	input wire [(NUM_OPERANDS * Width) - 1:0] operands_i;
	input wire [NUM_OPERANDS - 1:0] is_boxed_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire op_mod_i;
	input wire vectorial_op_i;
	input wire tag_i;
	input wire [NUM_LANES - 1:0] simd_mask_i;
	input wire in_valid_i;
	output wire in_ready_o;
	input wire flush_i;
	output wire [Width - 1:0] result_o;
	output reg [4:0] status_o;
	output wire extension_bit_o;
	output wire tag_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	input wire [ExtRegEnaWidth - 1:0] reg_ena_i;
	localparam [31:0] FP_WIDTH = fpnew_pkg_fp_width(FpFormat);
	localparam [31:0] SIMD_WIDTH = $unsigned(Width / NUM_LANES);
	wire [NUM_LANES - 1:0] lane_in_ready;
	wire [NUM_LANES - 1:0] lane_out_valid;
	wire vectorial_op;
	wire [(NUM_LANES * FP_WIDTH) - 1:0] slice_result;
	wire [Width - 1:0] slice_regular_result;
	wire [Width - 1:0] slice_class_result;
	wire [Width - 1:0] slice_vec_class_result;
	wire [(NUM_LANES * 5) - 1:0] lane_status;
	wire [NUM_LANES - 1:0] lane_ext_bit;
	wire [(NUM_LANES * 10) - 1:0] lane_class_mask;
	wire [NUM_LANES - 1:0] lane_tags;
	wire [NUM_LANES - 1:0] lane_masks;
	wire [NUM_LANES - 1:0] lane_vectorial;
	wire [NUM_LANES - 1:0] lane_busy;
	wire [NUM_LANES - 1:0] lane_is_class;
	wire result_is_vector;
	wire result_is_class;
	assign in_ready_o = lane_in_ready[0];
	assign vectorial_op = vectorial_op_i & EnableVectors;
	genvar lane;
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
	generate
		for (lane = 0; lane < sv2v_cast_32_signed(NUM_LANES); lane = lane + 1) begin : gen_num_lanes
			wire [FP_WIDTH - 1:0] local_result;
			wire local_sign;
			if ((lane == 0) || EnableVectors) begin : active_lane
				wire in_valid;
				wire out_valid;
				wire out_ready;
				reg [(NUM_OPERANDS * FP_WIDTH) - 1:0] local_operands;
				wire [FP_WIDTH - 1:0] op_result;
				wire [4:0] op_status;
				assign in_valid = in_valid_i & ((lane == 0) | vectorial_op);
				always @(*) begin : prepare_input
					begin : sv2v_autoblock_1
						reg signed [31:0] i;
						for (i = 0; i < sv2v_cast_32_signed(NUM_OPERANDS); i = i + 1)
							local_operands[i * FP_WIDTH+:FP_WIDTH] = operands_i[(i * Width) + (((($unsigned(lane) + 1) * FP_WIDTH) - 1) >= ($unsigned(lane) * FP_WIDTH) ? (($unsigned(lane) + 1) * FP_WIDTH) - 1 : (((($unsigned(lane) + 1) * FP_WIDTH) - 1) + (((($unsigned(lane) + 1) * FP_WIDTH) - 1) >= ($unsigned(lane) * FP_WIDTH) ? (((($unsigned(lane) + 1) * FP_WIDTH) - 1) - ($unsigned(lane) * FP_WIDTH)) + 1 : (($unsigned(lane) * FP_WIDTH) - ((($unsigned(lane) + 1) * FP_WIDTH) - 1)) + 1)) - 1)-:(((($unsigned(lane) + 1) * FP_WIDTH) - 1) >= ($unsigned(lane) * FP_WIDTH) ? (((($unsigned(lane) + 1) * FP_WIDTH) - 1) - ($unsigned(lane) * FP_WIDTH)) + 1 : (($unsigned(lane) * FP_WIDTH) - ((($unsigned(lane) + 1) * FP_WIDTH) - 1)) + 1)];
					end
				end
				if (OpGroup == 2'd0) begin : lane_instance
					fpnew_fma_141C6 #(
						.FpFormat(FpFormat),
						.NumPipeRegs(NumPipeRegs),
						.PipeConfig(PipeConfig)
					) i_fma(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.operands_i(local_operands),
						.is_boxed_i(is_boxed_i[NUM_OPERANDS - 1:0]),
						.rnd_mode_i(rnd_mode_i),
						.op_i(op_i),
						.op_mod_i(op_mod_i),
						.tag_i(tag_i),
						.mask_i(simd_mask_i[lane]),
						.aux_i(vectorial_op),
						.in_valid_i(in_valid),
						.in_ready_o(lane_in_ready[lane]),
						.flush_i(flush_i),
						.result_o(op_result),
						.status_o(op_status),
						.extension_bit_o(lane_ext_bit[lane]),
						.tag_o(lane_tags[lane]),
						.mask_o(lane_masks[lane]),
						.aux_o(lane_vectorial[lane]),
						.out_valid_o(out_valid),
						.out_ready_i(out_ready),
						.busy_o(lane_busy[lane]),
						.reg_ena_i(reg_ena_i)
					);
					assign lane_is_class[lane] = 1'b0;
					assign lane_class_mask[lane * 10+:10] = 10'b0000000001;
				end
				else if (OpGroup == 2'd1) begin
					;
				end
				else if (OpGroup == 2'd2) begin : lane_instance
					fpnew_noncomp_1F07E #(
						.FpFormat(FpFormat),
						.NumPipeRegs(NumPipeRegs),
						.PipeConfig(PipeConfig)
					) i_noncomp(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.operands_i(local_operands),
						.is_boxed_i(is_boxed_i[NUM_OPERANDS - 1:0]),
						.rnd_mode_i(rnd_mode_i),
						.op_i(op_i),
						.op_mod_i(op_mod_i),
						.tag_i(tag_i),
						.mask_i(simd_mask_i[lane]),
						.aux_i(vectorial_op),
						.in_valid_i(in_valid),
						.in_ready_o(lane_in_ready[lane]),
						.flush_i(flush_i),
						.result_o(op_result),
						.status_o(op_status),
						.extension_bit_o(lane_ext_bit[lane]),
						.class_mask_o(lane_class_mask[lane * 10+:10]),
						.is_class_o(lane_is_class[lane]),
						.tag_o(lane_tags[lane]),
						.mask_o(lane_masks[lane]),
						.aux_o(lane_vectorial[lane]),
						.out_valid_o(out_valid),
						.out_ready_i(out_ready),
						.busy_o(lane_busy[lane]),
						.reg_ena_i(reg_ena_i)
					);
				end
				assign out_ready = out_ready_i & ((lane == 0) | result_is_vector);
				assign lane_out_valid[lane] = out_valid & ((lane == 0) | result_is_vector);
				assign local_result = (lane_out_valid[lane] | ExtRegEna ? op_result : {FP_WIDTH {lane_ext_bit[0]}});
				assign lane_status[lane * 5+:5] = (lane_out_valid[lane] | ExtRegEna ? op_status : {5 {1'sb0}});
			end
			else begin : genblk1
				assign lane_out_valid[lane] = 1'b0;
				assign lane_in_ready[lane] = 1'b0;
				assign local_result = {FP_WIDTH {lane_ext_bit[0]}};
				assign lane_status[lane * 5+:5] = 1'sb0;
				assign lane_busy[lane] = 1'b0;
				assign lane_is_class[lane] = 1'b0;
			end
			assign slice_result[(($unsigned(lane) + 1) * FP_WIDTH) - 1:$unsigned(lane) * FP_WIDTH] = local_result;
			if (TrueSIMDClass && (SIMD_WIDTH >= 10)) begin : vectorial_true_class
				assign slice_vec_class_result[lane * SIMD_WIDTH+:10] = lane_class_mask[lane * 10+:10];
				assign slice_vec_class_result[((lane + 1) * SIMD_WIDTH) - 1-:SIMD_WIDTH - 10] = 1'sb0;
			end
			else if (((lane + 1) * 8) <= Width) begin : vectorial_class
				assign local_sign = (((lane_class_mask[lane * 10+:10] == 10'b0000000001) || (lane_class_mask[lane * 10+:10] == 10'b0000000010)) || (lane_class_mask[lane * 10+:10] == 10'b0000000100)) || (lane_class_mask[lane * 10+:10] == 10'b0000001000);
				assign slice_vec_class_result[((lane + 1) * 8) - 1:lane * 8] = {local_sign, ~local_sign, lane_class_mask[lane * 10+:10] == 10'b1000000000, lane_class_mask[lane * 10+:10] == 10'b0100000000, (lane_class_mask[lane * 10+:10] == 10'b0000010000) || (lane_class_mask[lane * 10+:10] == 10'b0000001000), (lane_class_mask[lane * 10+:10] == 10'b0000100000) || (lane_class_mask[lane * 10+:10] == 10'b0000000100), (lane_class_mask[lane * 10+:10] == 10'b0001000000) || (lane_class_mask[lane * 10+:10] == 10'b0000000010), (lane_class_mask[lane * 10+:10] == 10'b0010000000) || (lane_class_mask[lane * 10+:10] == 10'b0000000001)};
			end
		end
	endgenerate
	assign result_is_vector = lane_vectorial[0];
	assign result_is_class = lane_is_class[0];
	assign slice_regular_result = $signed({extension_bit_o, slice_result});
	localparam [31:0] CLASS_VEC_BITS = ((NUM_LANES * 8) > Width ? 8 * (Width / 8) : NUM_LANES * 8);
	generate
		if (!(TrueSIMDClass && (SIMD_WIDTH >= 10))) begin : genblk2
			if (CLASS_VEC_BITS < Width) begin : pad_vectorial_class
				assign slice_vec_class_result[Width - 1:CLASS_VEC_BITS] = 1'sb0;
			end
		end
	endgenerate
	assign slice_class_result = (result_is_vector ? slice_vec_class_result : lane_class_mask[0+:10]);
	assign result_o = (result_is_class ? slice_class_result : slice_regular_result);
	assign extension_bit_o = lane_ext_bit[0];
	assign tag_o = lane_tags[0];
	assign busy_o = |lane_busy;
	assign out_valid_o = lane_out_valid[0];
	always @(*) begin : output_processing
		reg [4:0] temp_status;
		temp_status = 1'sb0;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < sv2v_cast_32_signed(NUM_LANES); i = i + 1)
				temp_status = temp_status | (lane_status[i * 5+:5] & {5 {lane_masks[i]}});
		end
		status_o = temp_status;
	end
endmodule
module fpnew_opgroup_multifmt_slice_180FF (
	clk_i,
	rst_ni,
	operands_i,
	is_boxed_i,
	rnd_mode_i,
	op_i,
	op_mod_i,
	src_fmt_i,
	dst_fmt_i,
	int_fmt_i,
	vectorial_op_i,
	tag_i,
	simd_mask_i,
	in_valid_i,
	in_ready_o,
	flush_i,
	result_o,
	status_o,
	extension_bit_o,
	tag_o,
	out_valid_o,
	out_ready_i,
	busy_o,
	reg_ena_i
);
	parameter [1:0] OpGroup = 2'd3;
	parameter [31:0] Width = 64;
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	parameter [0:4] FpFmtConfig = 1'sb1;
	localparam [31:0] fpnew_pkg_NUM_INT_FORMATS = 4;
	parameter [0:3] IntFmtConfig = 1'sb1;
	parameter [0:0] EnableVectors = 1'b1;
	parameter [0:0] PulpDivsqrt = 1'b1;
	parameter [31:0] NumPipeRegs = 0;
	parameter [1:0] PipeConfig = 2'd0;
	parameter [0:0] ExtRegEna = 1'b0;
	function automatic [31:0] fpnew_pkg_num_operands;
		input reg [1:0] grp;
		case (grp)
			2'd0: fpnew_pkg_num_operands = 3;
			2'd1: fpnew_pkg_num_operands = 2;
			2'd2: fpnew_pkg_num_operands = 2;
			2'd3: fpnew_pkg_num_operands = 3;
			default: fpnew_pkg_num_operands = 0;
		endcase
	endfunction
	localparam [31:0] NUM_OPERANDS = fpnew_pkg_num_operands(OpGroup);
	localparam [31:0] NUM_FORMATS = fpnew_pkg_NUM_FP_FORMATS;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	function automatic signed [31:0] fpnew_pkg_maximum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_maximum = (a > b ? a : b);
	endfunction
	function automatic [2:0] sv2v_cast_0BC43;
		input reg [2:0] inp;
		sv2v_cast_0BC43 = inp;
	endfunction
	function automatic [31:0] fpnew_pkg_max_fp_width;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = 0;
			begin : sv2v_autoblock_1
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i])
						res = $unsigned(fpnew_pkg_maximum(res, fpnew_pkg_fp_width(sv2v_cast_0BC43(i))));
			end
			fpnew_pkg_max_fp_width = res;
		end
	endfunction
	function automatic signed [31:0] fpnew_pkg_minimum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_minimum = (a < b ? a : b);
	endfunction
	function automatic [31:0] fpnew_pkg_min_fp_width;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = fpnew_pkg_max_fp_width(cfg);
			begin : sv2v_autoblock_2
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i])
						res = $unsigned(fpnew_pkg_minimum(res, fpnew_pkg_fp_width(sv2v_cast_0BC43(i))));
			end
			fpnew_pkg_min_fp_width = res;
		end
	endfunction
	function automatic [31:0] fpnew_pkg_max_num_lanes;
		input reg [31:0] width;
		input reg [0:4] cfg;
		input reg vec;
		fpnew_pkg_max_num_lanes = (vec ? width / fpnew_pkg_min_fp_width(cfg) : 1);
	endfunction
	localparam [31:0] NUM_SIMD_LANES = fpnew_pkg_max_num_lanes(Width, FpFmtConfig, EnableVectors);
	localparam [31:0] ExtRegEnaWidth = (NumPipeRegs == 0 ? 1 : NumPipeRegs);
	input wire clk_i;
	input wire rst_ni;
	input wire [(NUM_OPERANDS * Width) - 1:0] operands_i;
	input wire [(NUM_FORMATS * NUM_OPERANDS) - 1:0] is_boxed_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire op_mod_i;
	input wire [2:0] src_fmt_i;
	input wire [2:0] dst_fmt_i;
	localparam [31:0] fpnew_pkg_INT_FORMAT_BITS = 2;
	input wire [1:0] int_fmt_i;
	input wire vectorial_op_i;
	input wire tag_i;
	input wire [NUM_SIMD_LANES - 1:0] simd_mask_i;
	input wire in_valid_i;
	output wire in_ready_o;
	input wire flush_i;
	output wire [Width - 1:0] result_o;
	output reg [4:0] status_o;
	output wire extension_bit_o;
	output wire tag_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	input wire [ExtRegEnaWidth - 1:0] reg_ena_i;
	generate
		if (((OpGroup == 2'd1) && !PulpDivsqrt) && !((FpFmtConfig[0] == 1) && (FpFmtConfig[1:4] == {4 {1'sb0}}))) begin : genblk1
			initial $fatal(1, "T-Head-based DivSqrt unit supported only in FP32-only configurations. Set PulpDivsqrt to 1 not to use the PULP DivSqrt unit or set Features.FpFmtMask to support only FP32");
		end
	endgenerate
	localparam [31:0] MAX_FP_WIDTH = fpnew_pkg_max_fp_width(FpFmtConfig);
	function automatic [1:0] sv2v_cast_87CC5;
		input reg [1:0] inp;
		sv2v_cast_87CC5 = inp;
	endfunction
	function automatic [31:0] fpnew_pkg_int_width;
		input reg [1:0] ifmt;
		case (ifmt)
			sv2v_cast_87CC5(0): fpnew_pkg_int_width = 8;
			sv2v_cast_87CC5(1): fpnew_pkg_int_width = 16;
			sv2v_cast_87CC5(2): fpnew_pkg_int_width = 32;
			sv2v_cast_87CC5(3): fpnew_pkg_int_width = 64;
			default: fpnew_pkg_int_width = sv2v_cast_87CC5(0);
		endcase
	endfunction
	function automatic [31:0] fpnew_pkg_max_int_width;
		input reg [0:3] cfg;
		reg [31:0] res;
		begin
			res = 0;
			begin : sv2v_autoblock_3
				reg signed [31:0] ifmt;
				for (ifmt = 0; ifmt < fpnew_pkg_NUM_INT_FORMATS; ifmt = ifmt + 1)
					if (cfg[ifmt])
						res = fpnew_pkg_maximum(res, fpnew_pkg_int_width(sv2v_cast_87CC5(ifmt)));
			end
			fpnew_pkg_max_int_width = res;
		end
	endfunction
	localparam [31:0] MAX_INT_WIDTH = fpnew_pkg_max_int_width(IntFmtConfig);
	localparam [31:0] NUM_LANES = fpnew_pkg_max_num_lanes(Width, FpFmtConfig, 1'b1);
	localparam [31:0] NUM_INT_FORMATS = fpnew_pkg_NUM_INT_FORMATS;
	localparam [31:0] FMT_BITS = fpnew_pkg_maximum(3, 2);
	localparam [31:0] AUX_BITS = FMT_BITS + 2;
	wire [NUM_LANES - 1:0] lane_in_ready;
	wire [NUM_LANES - 1:0] lane_out_valid;
	wire [NUM_LANES - 1:0] divsqrt_done;
	wire [NUM_LANES - 1:0] divsqrt_ready;
	wire vectorial_op;
	wire [FMT_BITS - 1:0] dst_fmt;
	wire [AUX_BITS - 1:0] aux_data;
	wire dst_fmt_is_int;
	wire dst_is_cpk;
	wire [1:0] dst_vec_op;
	wire [2:0] target_aux_d;
	wire is_up_cast;
	wire is_down_cast;
	wire [(NUM_FORMATS * Width) - 1:0] fmt_slice_result;
	wire [(NUM_INT_FORMATS * Width) - 1:0] ifmt_slice_result;
	wire [Width - 1:0] conv_target_d;
	wire [Width - 1:0] conv_target_q;
	wire [(NUM_LANES * 5) - 1:0] lane_status;
	wire [NUM_LANES - 1:0] lane_ext_bit;
	wire [NUM_LANES - 1:0] lane_tags;
	wire [NUM_LANES - 1:0] lane_masks;
	wire [(NUM_LANES * AUX_BITS) - 1:0] lane_aux;
	wire [NUM_LANES - 1:0] lane_busy;
	wire result_is_vector;
	wire [FMT_BITS - 1:0] result_fmt;
	wire result_fmt_is_int;
	wire result_is_cpk;
	wire [1:0] result_vec_op;
	wire simd_synch_rdy;
	wire simd_synch_done;
	assign in_ready_o = lane_in_ready[0];
	assign vectorial_op = vectorial_op_i & EnableVectors;
	function automatic [3:0] sv2v_cast_A53F3;
		input reg [3:0] inp;
		sv2v_cast_A53F3 = inp;
	endfunction
	assign dst_fmt_is_int = (OpGroup == 2'd3) & (op_i == sv2v_cast_A53F3(11));
	assign dst_is_cpk = (OpGroup == 2'd3) & ((op_i == sv2v_cast_A53F3(13)) || (op_i == sv2v_cast_A53F3(14)));
	assign dst_vec_op = (OpGroup == 2'd3) & {op_i == sv2v_cast_A53F3(14), op_mod_i};
	assign is_up_cast = fpnew_pkg_fp_width(dst_fmt_i) > fpnew_pkg_fp_width(src_fmt_i);
	assign is_down_cast = fpnew_pkg_fp_width(dst_fmt_i) < fpnew_pkg_fp_width(src_fmt_i);
	assign dst_fmt = (dst_fmt_is_int ? int_fmt_i : dst_fmt_i);
	assign aux_data = {dst_fmt_is_int, vectorial_op, dst_fmt};
	assign target_aux_d = {dst_vec_op, dst_is_cpk};
	generate
		if (OpGroup == 2'd3) begin : conv_target
			assign conv_target_d = (dst_is_cpk ? operands_i[2 * Width+:Width] : operands_i[Width+:Width]);
		end
		else begin : not_conv_target
			assign conv_target_d = 1'sb0;
		end
	endgenerate
	reg [4:0] is_boxed_1op;
	reg [9:0] is_boxed_2op;
	always @(*) begin : boxed_2op
		begin : sv2v_autoblock_4
			reg signed [31:0] fmt;
			for (fmt = 0; fmt < NUM_FORMATS; fmt = fmt + 1)
				begin
					is_boxed_1op[fmt] = is_boxed_i[fmt * NUM_OPERANDS];
					is_boxed_2op[fmt * 2+:2] = is_boxed_i[(fmt * NUM_OPERANDS) + 1-:2];
				end
		end
	end
	genvar lane;
	localparam [0:4] fpnew_pkg_CPK_FORMATS = 5'b11000;
	function automatic [0:4] fpnew_pkg_get_conv_lane_formats;
		input reg [31:0] width;
		input reg [0:4] cfg;
		input reg [31:0] lane_no;
		reg [0:4] res;
		begin
			begin : sv2v_autoblock_5
				reg [31:0] fmt;
				for (fmt = 0; fmt < fpnew_pkg_NUM_FP_FORMATS; fmt = fmt + 1)
					res[fmt] = cfg[fmt] && (((width / fpnew_pkg_fp_width(sv2v_cast_0BC43(fmt))) > lane_no) || (fpnew_pkg_CPK_FORMATS[fmt] && (lane_no < 2)));
			end
			fpnew_pkg_get_conv_lane_formats = res;
		end
	endfunction
	function automatic [0:3] fpnew_pkg_get_conv_lane_int_formats;
		input reg [31:0] width;
		input reg [0:4] cfg;
		input reg [0:3] icfg;
		input reg [31:0] lane_no;
		reg [0:3] res;
		reg [0:4] lanefmts;
		begin
			res = 1'sb0;
			lanefmts = fpnew_pkg_get_conv_lane_formats(width, cfg, lane_no);
			begin : sv2v_autoblock_6
				reg [31:0] ifmt;
				for (ifmt = 0; ifmt < fpnew_pkg_NUM_INT_FORMATS; ifmt = ifmt + 1)
					begin : sv2v_autoblock_7
						reg [31:0] fmt;
						for (fmt = 0; fmt < fpnew_pkg_NUM_FP_FORMATS; fmt = fmt + 1)
							res[ifmt] = res[ifmt] | ((icfg[ifmt] && lanefmts[fmt]) && (fpnew_pkg_fp_width(sv2v_cast_0BC43(fmt)) == fpnew_pkg_int_width(sv2v_cast_87CC5(ifmt))));
					end
			end
			fpnew_pkg_get_conv_lane_int_formats = res;
		end
	endfunction
	function automatic [0:4] fpnew_pkg_get_lane_formats;
		input reg [31:0] width;
		input reg [0:4] cfg;
		input reg [31:0] lane_no;
		reg [0:4] res;
		begin
			begin : sv2v_autoblock_8
				reg [31:0] fmt;
				for (fmt = 0; fmt < fpnew_pkg_NUM_FP_FORMATS; fmt = fmt + 1)
					res[fmt] = cfg[fmt] & ((width / fpnew_pkg_fp_width(sv2v_cast_0BC43(fmt))) > lane_no);
			end
			fpnew_pkg_get_lane_formats = res;
		end
	endfunction
	function automatic [0:3] fpnew_pkg_get_lane_int_formats;
		input reg [31:0] width;
		input reg [0:4] cfg;
		input reg [0:3] icfg;
		input reg [31:0] lane_no;
		reg [0:3] res;
		reg [0:4] lanefmts;
		begin
			res = 1'sb0;
			lanefmts = fpnew_pkg_get_lane_formats(width, cfg, lane_no);
			begin : sv2v_autoblock_9
				reg [31:0] ifmt;
				for (ifmt = 0; ifmt < fpnew_pkg_NUM_INT_FORMATS; ifmt = ifmt + 1)
					begin : sv2v_autoblock_10
						reg [31:0] fmt;
						for (fmt = 0; fmt < fpnew_pkg_NUM_FP_FORMATS; fmt = fmt + 1)
							if (fpnew_pkg_fp_width(sv2v_cast_0BC43(fmt)) == fpnew_pkg_int_width(sv2v_cast_87CC5(ifmt)))
								res[ifmt] = res[ifmt] | (icfg[ifmt] && lanefmts[fmt]);
					end
			end
			fpnew_pkg_get_lane_int_formats = res;
		end
	endfunction
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	function automatic [4:0] sv2v_cast_F8FCA;
		input reg [4:0] inp;
		sv2v_cast_F8FCA = inp;
	endfunction
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
	generate
		for (lane = 0; lane < sv2v_cast_32_signed(NUM_LANES); lane = lane + 1) begin : gen_num_lanes
			localparam [31:0] LANE = $unsigned(lane);
			localparam [0:4] ACTIVE_FORMATS = fpnew_pkg_get_lane_formats(Width, FpFmtConfig, LANE);
			localparam [0:3] ACTIVE_INT_FORMATS = fpnew_pkg_get_lane_int_formats(Width, FpFmtConfig, IntFmtConfig, LANE);
			localparam [31:0] MAX_WIDTH = fpnew_pkg_max_fp_width(ACTIVE_FORMATS);
			localparam [0:4] CONV_FORMATS = fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, LANE);
			localparam [0:3] CONV_INT_FORMATS = fpnew_pkg_get_conv_lane_int_formats(Width, FpFmtConfig, IntFmtConfig, LANE);
			localparam [31:0] CONV_WIDTH = fpnew_pkg_max_fp_width(CONV_FORMATS);
			localparam [0:4] LANE_FORMATS = (OpGroup == 2'd3 ? CONV_FORMATS : ACTIVE_FORMATS);
			localparam [31:0] LANE_WIDTH = (OpGroup == 2'd3 ? CONV_WIDTH : MAX_WIDTH);
			wire [LANE_WIDTH - 1:0] local_result;
			if ((lane == 0) || EnableVectors) begin : active_lane
				wire in_valid;
				wire out_valid;
				wire out_ready;
				reg [(NUM_OPERANDS * LANE_WIDTH) - 1:0] local_operands;
				wire [LANE_WIDTH - 1:0] op_result;
				wire [4:0] op_status;
				assign in_valid = in_valid_i & ((lane == 0) | vectorial_op);
				always @(*) begin : prepare_input
					begin : sv2v_autoblock_11
						reg [31:0] i;
						for (i = 0; i < NUM_OPERANDS; i = i + 1)
							if (i == 2)
								local_operands[i * (OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))))+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))))] = operands_i[i * Width+:Width] >> (LANE * fpnew_pkg_fp_width(dst_fmt_i));
							else
								local_operands[i * (OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))))+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))))] = operands_i[i * Width+:Width] >> (LANE * fpnew_pkg_fp_width(src_fmt_i));
					end
					if (OpGroup == 2'd3) begin
						if (op_i == sv2v_cast_A53F3(12))
							local_operands[0+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))))] = operands_i[0+:Width] >> (LANE * fpnew_pkg_int_width(int_fmt_i));
						else if (op_i == sv2v_cast_A53F3(10)) begin
							if ((vectorial_op && op_mod_i) && is_up_cast)
								local_operands[0+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))))] = operands_i[0+:Width] >> ((LANE * fpnew_pkg_fp_width(src_fmt_i)) + (MAX_FP_WIDTH / 2));
						end
						else if (dst_is_cpk) begin
							if (lane == 1)
								local_operands[0+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))))] = operands_i[Width + (LANE_WIDTH - 1)-:LANE_WIDTH];
						end
					end
				end
				if (OpGroup == 2'd0) begin : lane_instance
					fpnew_fma_multi_EB884_B8BD0_B7913 #(
						.AuxType_AUX_BITS(AUX_BITS),
						.FpFmtConfig(LANE_FORMATS),
						.NumPipeRegs(NumPipeRegs),
						.PipeConfig(PipeConfig)
					) i_fpnew_fma_multi(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.operands_i(local_operands),
						.is_boxed_i(is_boxed_i),
						.rnd_mode_i(rnd_mode_i),
						.op_i(op_i),
						.op_mod_i(op_mod_i),
						.src_fmt_i(src_fmt_i),
						.dst_fmt_i(dst_fmt_i),
						.tag_i(tag_i),
						.mask_i(simd_mask_i[lane]),
						.aux_i(aux_data),
						.in_valid_i(in_valid),
						.in_ready_o(lane_in_ready[lane]),
						.flush_i(flush_i),
						.result_o(op_result),
						.status_o(op_status),
						.extension_bit_o(lane_ext_bit[lane]),
						.tag_o(lane_tags[lane]),
						.mask_o(lane_masks[lane]),
						.aux_o(lane_aux[lane * AUX_BITS+:AUX_BITS]),
						.out_valid_o(out_valid),
						.out_ready_i(out_ready),
						.busy_o(lane_busy[lane]),
						.reg_ena_i(reg_ena_i)
					);
				end
				else if (OpGroup == 2'd1) begin : lane_instance
					if ((!PulpDivsqrt && LANE_FORMATS[0]) && (LANE_FORMATS[1:4] == {4 {1'sb0}})) begin : genblk1
						fpnew_divsqrt_th_32_F3200_27D86_0305C #(
							.AuxType_AUX_BITS(AUX_BITS),
							.NumPipeRegs(NumPipeRegs),
							.PipeConfig(PipeConfig)
						) i_fpnew_divsqrt_multi_th(
							.clk_i(clk_i),
							.rst_ni(rst_ni),
							.operands_i(local_operands[0+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane))))) * 2]),
							.is_boxed_i(is_boxed_2op),
							.rnd_mode_i(rnd_mode_i),
							.op_i(op_i),
							.tag_i(tag_i),
							.mask_i(simd_mask_i[lane]),
							.aux_i(aux_data),
							.in_valid_i(in_valid),
							.in_ready_o(lane_in_ready[lane]),
							.flush_i(flush_i),
							.result_o(op_result),
							.status_o(op_status),
							.extension_bit_o(lane_ext_bit[lane]),
							.tag_o(lane_tags[lane]),
							.mask_o(lane_masks[lane]),
							.aux_o(lane_aux[lane * AUX_BITS+:AUX_BITS]),
							.out_valid_o(out_valid),
							.out_ready_i(out_ready),
							.busy_o(lane_busy[lane]),
							.reg_ena_i(reg_ena_i)
						);
					end
					else begin : genblk1
						fpnew_divsqrt_multi_4A82D_052FB_D4F83 #(
							.AuxType_AUX_BITS(AUX_BITS),
							.FpFmtConfig(LANE_FORMATS),
							.NumPipeRegs(NumPipeRegs),
							.PipeConfig(PipeConfig)
						) i_fpnew_divsqrt_multi(
							.clk_i(clk_i),
							.rst_ni(rst_ni),
							.operands_i(local_operands[0+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane))))) * 2]),
							.is_boxed_i(is_boxed_2op),
							.rnd_mode_i(rnd_mode_i),
							.op_i(op_i),
							.dst_fmt_i(dst_fmt_i),
							.tag_i(tag_i),
							.mask_i(simd_mask_i[lane]),
							.aux_i(aux_data),
							.vectorial_op_i(vectorial_op),
							.in_valid_i(in_valid),
							.in_ready_o(lane_in_ready[lane]),
							.divsqrt_done_o(divsqrt_done[lane]),
							.simd_synch_done_i(simd_synch_done),
							.divsqrt_ready_o(divsqrt_ready[lane]),
							.simd_synch_rdy_i(simd_synch_rdy),
							.flush_i(flush_i),
							.result_o(op_result),
							.status_o(op_status),
							.extension_bit_o(lane_ext_bit[lane]),
							.tag_o(lane_tags[lane]),
							.mask_o(lane_masks[lane]),
							.aux_o(lane_aux[lane * AUX_BITS+:AUX_BITS]),
							.out_valid_o(out_valid),
							.out_ready_i(out_ready),
							.busy_o(lane_busy[lane]),
							.reg_ena_i(reg_ena_i)
						);
					end
				end
				else if (OpGroup == 2'd2) begin
					;
				end
				else if (OpGroup == 2'd3) begin : lane_instance
					fpnew_cast_multi_CCABA_3744F_F1342 #(
						.AuxType_AUX_BITS(AUX_BITS),
						.FpFmtConfig(LANE_FORMATS),
						.IntFmtConfig(CONV_INT_FORMATS),
						.NumPipeRegs(NumPipeRegs),
						.PipeConfig(PipeConfig)
					) i_fpnew_cast_multi(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.operands_i(local_operands[0+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))))]),
						.is_boxed_i(is_boxed_1op),
						.rnd_mode_i(rnd_mode_i),
						.op_i(op_i),
						.op_mod_i(op_mod_i),
						.src_fmt_i(src_fmt_i),
						.dst_fmt_i(dst_fmt_i),
						.int_fmt_i(int_fmt_i),
						.tag_i(tag_i),
						.mask_i(simd_mask_i[lane]),
						.aux_i(aux_data),
						.in_valid_i(in_valid),
						.in_ready_o(lane_in_ready[lane]),
						.flush_i(flush_i),
						.result_o(op_result),
						.status_o(op_status),
						.extension_bit_o(lane_ext_bit[lane]),
						.tag_o(lane_tags[lane]),
						.mask_o(lane_masks[lane]),
						.aux_o(lane_aux[lane * AUX_BITS+:AUX_BITS]),
						.out_valid_o(out_valid),
						.out_ready_i(out_ready),
						.busy_o(lane_busy[lane]),
						.reg_ena_i(reg_ena_i)
					);
				end
				assign out_ready = out_ready_i & ((lane == 0) | result_is_vector);
				assign lane_out_valid[lane] = out_valid & ((lane == 0) | result_is_vector);
				assign local_result = (lane_out_valid[lane] | ExtRegEna ? op_result : {(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(sv2v_cast_F8FCA(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane))))) : fpnew_pkg_max_fp_width(sv2v_cast_F8FCA(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(lane)))))) {lane_ext_bit[0]}});
				assign lane_status[lane * 5+:5] = (lane_out_valid[lane] | ExtRegEna ? op_status : {5 {1'sb0}});
			end
			else begin : inactive_lane
				assign lane_out_valid[lane] = 1'b0;
				assign lane_in_ready[lane] = 1'b0;
				assign lane_aux[lane * AUX_BITS+:AUX_BITS] = 1'b0;
				assign lane_masks[lane] = 1'b1;
				assign lane_tags[lane] = 1'b0;
				assign divsqrt_done[lane] = 1'b0;
				assign divsqrt_ready[lane] = 1'b0;
				assign lane_ext_bit[lane] = 1'b1;
				assign local_result = {LANE_WIDTH {lane_ext_bit[0]}};
				assign lane_status[lane * 5+:5] = 1'sb0;
				assign lane_busy[lane] = 1'b0;
			end
			genvar fmt;
			for (fmt = 0; fmt < NUM_FORMATS; fmt = fmt + 1) begin : pack_fp_result
				localparam [31:0] FP_WIDTH = fpnew_pkg_fp_width(sv2v_cast_0BC43(fmt));
				if (ACTIVE_FORMATS[fmt]) begin : genblk1
					assign fmt_slice_result[(fmt * Width) + ((((LANE + 1) * FP_WIDTH) - 1) >= (LANE * FP_WIDTH) ? ((LANE + 1) * FP_WIDTH) - 1 : ((((LANE + 1) * FP_WIDTH) - 1) + ((((LANE + 1) * FP_WIDTH) - 1) >= (LANE * FP_WIDTH) ? ((((LANE + 1) * FP_WIDTH) - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (((LANE + 1) * FP_WIDTH) - 1)) + 1)) - 1)-:((((LANE + 1) * FP_WIDTH) - 1) >= (LANE * FP_WIDTH) ? ((((LANE + 1) * FP_WIDTH) - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (((LANE + 1) * FP_WIDTH) - 1)) + 1)] = local_result[FP_WIDTH - 1:0];
				end
				else if (((LANE + 1) * FP_WIDTH) <= Width) begin : genblk1
					assign fmt_slice_result[(fmt * Width) + ((((LANE + 1) * FP_WIDTH) - 1) >= (LANE * FP_WIDTH) ? ((LANE + 1) * FP_WIDTH) - 1 : ((((LANE + 1) * FP_WIDTH) - 1) + ((((LANE + 1) * FP_WIDTH) - 1) >= (LANE * FP_WIDTH) ? ((((LANE + 1) * FP_WIDTH) - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (((LANE + 1) * FP_WIDTH) - 1)) + 1)) - 1)-:((((LANE + 1) * FP_WIDTH) - 1) >= (LANE * FP_WIDTH) ? ((((LANE + 1) * FP_WIDTH) - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (((LANE + 1) * FP_WIDTH) - 1)) + 1)] = {((((LANE + 1) * FP_WIDTH) - 1) >= (LANE * FP_WIDTH) ? ((((LANE + 1) * FP_WIDTH) - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (((LANE + 1) * FP_WIDTH) - 1)) + 1) {lane_ext_bit[LANE]}};
				end
				else if ((LANE * FP_WIDTH) < Width) begin : genblk1
					assign fmt_slice_result[(fmt * Width) + ((Width - 1) >= (LANE * FP_WIDTH) ? Width - 1 : ((Width - 1) + ((Width - 1) >= (LANE * FP_WIDTH) ? ((Width - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (Width - 1)) + 1)) - 1)-:((Width - 1) >= (LANE * FP_WIDTH) ? ((Width - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (Width - 1)) + 1)] = {((Width - 1) >= (LANE * FP_WIDTH) ? ((Width - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (Width - 1)) + 1) {lane_ext_bit[LANE]}};
				end
			end
			if (OpGroup == 2'd3) begin : int_results_enabled
				genvar ifmt;
				for (ifmt = 0; ifmt < NUM_INT_FORMATS; ifmt = ifmt + 1) begin : pack_int_result
					localparam [31:0] INT_WIDTH = fpnew_pkg_int_width(sv2v_cast_87CC5(ifmt));
					if (ACTIVE_INT_FORMATS[ifmt]) begin : genblk1
						assign ifmt_slice_result[(ifmt * Width) + ((((LANE + 1) * INT_WIDTH) - 1) >= (LANE * INT_WIDTH) ? ((LANE + 1) * INT_WIDTH) - 1 : ((((LANE + 1) * INT_WIDTH) - 1) + ((((LANE + 1) * INT_WIDTH) - 1) >= (LANE * INT_WIDTH) ? ((((LANE + 1) * INT_WIDTH) - 1) - (LANE * INT_WIDTH)) + 1 : ((LANE * INT_WIDTH) - (((LANE + 1) * INT_WIDTH) - 1)) + 1)) - 1)-:((((LANE + 1) * INT_WIDTH) - 1) >= (LANE * INT_WIDTH) ? ((((LANE + 1) * INT_WIDTH) - 1) - (LANE * INT_WIDTH)) + 1 : ((LANE * INT_WIDTH) - (((LANE + 1) * INT_WIDTH) - 1)) + 1)] = local_result[INT_WIDTH - 1:0];
					end
					else if (((LANE + 1) * INT_WIDTH) <= Width) begin : genblk1
						assign ifmt_slice_result[(ifmt * Width) + ((((LANE + 1) * INT_WIDTH) - 1) >= (LANE * INT_WIDTH) ? ((LANE + 1) * INT_WIDTH) - 1 : ((((LANE + 1) * INT_WIDTH) - 1) + ((((LANE + 1) * INT_WIDTH) - 1) >= (LANE * INT_WIDTH) ? ((((LANE + 1) * INT_WIDTH) - 1) - (LANE * INT_WIDTH)) + 1 : ((LANE * INT_WIDTH) - (((LANE + 1) * INT_WIDTH) - 1)) + 1)) - 1)-:((((LANE + 1) * INT_WIDTH) - 1) >= (LANE * INT_WIDTH) ? ((((LANE + 1) * INT_WIDTH) - 1) - (LANE * INT_WIDTH)) + 1 : ((LANE * INT_WIDTH) - (((LANE + 1) * INT_WIDTH) - 1)) + 1)] = 1'sb0;
					end
					else if ((LANE * INT_WIDTH) < Width) begin : genblk1
						assign ifmt_slice_result[(ifmt * Width) + ((Width - 1) >= (LANE * INT_WIDTH) ? Width - 1 : ((Width - 1) + ((Width - 1) >= (LANE * INT_WIDTH) ? ((Width - 1) - (LANE * INT_WIDTH)) + 1 : ((LANE * INT_WIDTH) - (Width - 1)) + 1)) - 1)-:((Width - 1) >= (LANE * INT_WIDTH) ? ((Width - 1) - (LANE * INT_WIDTH)) + 1 : ((LANE * INT_WIDTH) - (Width - 1)) + 1)] = 1'sb0;
					end
				end
			end
		end
	endgenerate
	genvar fmt;
	generate
		for (fmt = 0; fmt < NUM_FORMATS; fmt = fmt + 1) begin : extend_fp_result
			localparam [31:0] FP_WIDTH = fpnew_pkg_fp_width(sv2v_cast_0BC43(fmt));
			if ((NUM_LANES * FP_WIDTH) < Width) begin : genblk1
				assign fmt_slice_result[(fmt * Width) + ((Width - 1) >= (NUM_LANES * FP_WIDTH) ? Width - 1 : ((Width - 1) + ((Width - 1) >= (NUM_LANES * FP_WIDTH) ? ((Width - 1) - (NUM_LANES * FP_WIDTH)) + 1 : ((NUM_LANES * FP_WIDTH) - (Width - 1)) + 1)) - 1)-:((Width - 1) >= (NUM_LANES * FP_WIDTH) ? ((Width - 1) - (NUM_LANES * FP_WIDTH)) + 1 : ((NUM_LANES * FP_WIDTH) - (Width - 1)) + 1)] = {((Width - 1) >= (NUM_LANES * FP_WIDTH) ? ((Width - 1) - (NUM_LANES * FP_WIDTH)) + 1 : ((NUM_LANES * FP_WIDTH) - (Width - 1)) + 1) {lane_ext_bit[0]}};
			end
		end
	endgenerate
	genvar ifmt;
	generate
		for (ifmt = 0; ifmt < NUM_INT_FORMATS; ifmt = ifmt + 1) begin : extend_or_mute_int_result
			if (OpGroup != 2'd3) begin : mute_int_result
				assign ifmt_slice_result[ifmt * Width+:Width] = 1'sb0;
			end
			else begin : extend_int_result
				localparam [31:0] INT_WIDTH = fpnew_pkg_int_width(sv2v_cast_87CC5(ifmt));
				if ((NUM_LANES * INT_WIDTH) < Width) begin : genblk1
					assign ifmt_slice_result[(ifmt * Width) + ((Width - 1) >= (NUM_LANES * INT_WIDTH) ? Width - 1 : ((Width - 1) + ((Width - 1) >= (NUM_LANES * INT_WIDTH) ? ((Width - 1) - (NUM_LANES * INT_WIDTH)) + 1 : ((NUM_LANES * INT_WIDTH) - (Width - 1)) + 1)) - 1)-:((Width - 1) >= (NUM_LANES * INT_WIDTH) ? ((Width - 1) - (NUM_LANES * INT_WIDTH)) + 1 : ((NUM_LANES * INT_WIDTH) - (Width - 1)) + 1)] = 1'sb0;
				end
			end
		end
		if (OpGroup == 2'd3) begin : target_regs
			reg [(0 >= NumPipeRegs ? ((1 - NumPipeRegs) * Width) + ((NumPipeRegs * Width) - 1) : ((NumPipeRegs + 1) * Width) - 1):(0 >= NumPipeRegs ? NumPipeRegs * Width : 0)] byp_pipe_target_q;
			reg [(0 >= NumPipeRegs ? ((1 - NumPipeRegs) * 3) + ((NumPipeRegs * 3) - 1) : ((NumPipeRegs + 1) * 3) - 1):(0 >= NumPipeRegs ? NumPipeRegs * 3 : 0)] byp_pipe_aux_q;
			reg [0:NumPipeRegs] byp_pipe_valid_q;
			wire [0:NumPipeRegs] byp_pipe_ready;
			wire [Width * 1:1] sv2v_tmp_FBD8C;
			assign sv2v_tmp_FBD8C = conv_target_d;
			always @(*) byp_pipe_target_q[(0 >= NumPipeRegs ? 0 : NumPipeRegs) * Width+:Width] = sv2v_tmp_FBD8C;
			wire [3:1] sv2v_tmp_A0A5D;
			assign sv2v_tmp_A0A5D = target_aux_d;
			always @(*) byp_pipe_aux_q[(0 >= NumPipeRegs ? 0 : NumPipeRegs) * 3+:3] = sv2v_tmp_A0A5D;
			wire [1:1] sv2v_tmp_49222;
			assign sv2v_tmp_49222 = in_valid_i & vectorial_op;
			always @(*) byp_pipe_valid_q[0] = sv2v_tmp_49222;
			genvar i;
			for (i = 0; i < NumPipeRegs; i = i + 1) begin : gen_bypass_pipeline
				wire reg_ena;
				assign byp_pipe_ready[i] = byp_pipe_ready[i + 1] | ~byp_pipe_valid_q[i + 1];
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						byp_pipe_valid_q[i + 1] <= 1'b0;
					else
						byp_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (byp_pipe_ready[i] ? byp_pipe_valid_q[i] : byp_pipe_valid_q[i + 1]));
				assign reg_ena = (byp_pipe_ready[i] & byp_pipe_valid_q[i]) | reg_ena_i[i];
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						byp_pipe_target_q[(0 >= NumPipeRegs ? i + 1 : NumPipeRegs - (i + 1)) * Width+:Width] <= 1'sb0;
					else
						byp_pipe_target_q[(0 >= NumPipeRegs ? i + 1 : NumPipeRegs - (i + 1)) * Width+:Width] <= (reg_ena ? byp_pipe_target_q[(0 >= NumPipeRegs ? i : NumPipeRegs - i) * Width+:Width] : byp_pipe_target_q[(0 >= NumPipeRegs ? i + 1 : NumPipeRegs - (i + 1)) * Width+:Width]);
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						byp_pipe_aux_q[(0 >= NumPipeRegs ? i + 1 : NumPipeRegs - (i + 1)) * 3+:3] <= 1'sb0;
					else
						byp_pipe_aux_q[(0 >= NumPipeRegs ? i + 1 : NumPipeRegs - (i + 1)) * 3+:3] <= (reg_ena ? byp_pipe_aux_q[(0 >= NumPipeRegs ? i : NumPipeRegs - i) * 3+:3] : byp_pipe_aux_q[(0 >= NumPipeRegs ? i + 1 : NumPipeRegs - (i + 1)) * 3+:3]);
			end
			assign byp_pipe_ready[NumPipeRegs] = out_ready_i & result_is_vector;
			assign conv_target_q = byp_pipe_target_q[(0 >= NumPipeRegs ? NumPipeRegs : NumPipeRegs - NumPipeRegs) * Width+:Width];
			assign {result_vec_op, result_is_cpk} = byp_pipe_aux_q[(0 >= NumPipeRegs ? NumPipeRegs : NumPipeRegs - NumPipeRegs) * 3+:3];
		end
		else begin : no_conv
			assign {result_vec_op, result_is_cpk} = 1'sb0;
			assign conv_target_q = 1'sb0;
		end
		if (PulpDivsqrt && !ExtRegEna) begin : genblk7
			assign simd_synch_rdy = (EnableVectors ? &divsqrt_ready : divsqrt_ready[0]);
			assign simd_synch_done = (EnableVectors ? &divsqrt_done : divsqrt_done[0]);
		end
		else begin : genblk7
			assign simd_synch_rdy = 1'sb0;
			assign simd_synch_done = 1'sb0;
		end
	endgenerate
	assign {result_fmt_is_int, result_is_vector, result_fmt} = lane_aux[0+:AUX_BITS];
	assign result_o = (result_fmt_is_int ? ifmt_slice_result[result_fmt * Width+:Width] : fmt_slice_result[result_fmt * Width+:Width]);
	assign extension_bit_o = lane_ext_bit[0];
	assign tag_o = lane_tags[0];
	assign busy_o = |lane_busy;
	assign out_valid_o = lane_out_valid[0];
	always @(*) begin : output_processing
		reg [4:0] temp_status;
		temp_status = 1'sb0;
		begin : sv2v_autoblock_12
			reg signed [31:0] i;
			for (i = 0; i < sv2v_cast_32_signed(NUM_LANES); i = i + 1)
				temp_status = temp_status | (lane_status[i * 5+:5] & {5 {lane_masks[i]}});
		end
		status_o = temp_status;
	end
endmodule
module fpnew_rounding (
	abs_value_i,
	sign_i,
	round_sticky_bits_i,
	rnd_mode_i,
	effective_subtraction_i,
	abs_rounded_o,
	sign_o,
	exact_zero_o
);
	parameter [31:0] AbsWidth = 2;
	input wire [AbsWidth - 1:0] abs_value_i;
	input wire sign_i;
	input wire [1:0] round_sticky_bits_i;
	input wire [2:0] rnd_mode_i;
	input wire effective_subtraction_i;
	output wire [AbsWidth - 1:0] abs_rounded_o;
	output wire sign_o;
	output wire exact_zero_o;
	reg round_up;
	localparam [0:0] fpnew_pkg_DONT_CARE = 1'b1;
	always @(*) begin : rounding_decision
		case (rnd_mode_i)
			3'b000:
				case (round_sticky_bits_i)
					2'b00, 2'b01: round_up = 1'b0;
					2'b10: round_up = abs_value_i[0];
					2'b11: round_up = 1'b1;
					default: round_up = fpnew_pkg_DONT_CARE;
				endcase
			3'b001: round_up = 1'b0;
			3'b010: round_up = (|round_sticky_bits_i ? sign_i : 1'b0);
			3'b011: round_up = (|round_sticky_bits_i ? ~sign_i : 1'b0);
			3'b100: round_up = round_sticky_bits_i[1];
			3'b101: round_up = ~abs_value_i[0] & |round_sticky_bits_i;
			default: round_up = fpnew_pkg_DONT_CARE;
		endcase
	end
	assign abs_rounded_o = abs_value_i + round_up;
	assign exact_zero_o = (abs_value_i == {AbsWidth {1'sb0}}) && (round_sticky_bits_i == {2 {1'sb0}});
	assign sign_o = (exact_zero_o && effective_subtraction_i ? rnd_mode_i == 3'b010 : sign_i);
endmodule
module fpnew_top (
	clk_i,
	rst_ni,
	operands_i,
	rnd_mode_i,
	op_i,
	op_mod_i,
	src_fmt_i,
	dst_fmt_i,
	int_fmt_i,
	vectorial_op_i,
	tag_i,
	simd_mask_i,
	in_valid_i,
	in_ready_o,
	flush_i,
	result_o,
	status_o,
	tag_o,
	out_valid_o,
	out_ready_i,
	busy_o
);
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] fpnew_pkg_NUM_INT_FORMATS = 4;
	localparam [42:0] fpnew_pkg_RV64D_Xsflt = 43'h000000207ff;
	parameter [42:0] Features = fpnew_pkg_RV64D_Xsflt;
	localparam [31:0] fpnew_pkg_NUM_OPGROUPS = 4;
	function automatic [159:0] sv2v_cast_B9240;
		input reg [159:0] inp;
		sv2v_cast_B9240 = inp;
	endfunction
	function automatic [((32'd4 * 32'd5) * 32) - 1:0] sv2v_cast_CDC93;
		input reg [((32'd4 * 32'd5) * 32) - 1:0] inp;
		sv2v_cast_CDC93 = inp;
	endfunction
	function automatic [((32'd4 * 32'd5) * 2) - 1:0] sv2v_cast_15FEF;
		input reg [((32'd4 * 32'd5) * 2) - 1:0] inp;
		sv2v_cast_15FEF = inp;
	endfunction
	localparam [(((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 32) + ((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 2)) + 1:0] fpnew_pkg_DEFAULT_NOREGS = {sv2v_cast_CDC93({fpnew_pkg_NUM_OPGROUPS {sv2v_cast_B9240(0)}}), sv2v_cast_15FEF({{fpnew_pkg_NUM_FP_FORMATS {2'd1}}, {fpnew_pkg_NUM_FP_FORMATS {2'd2}}, {fpnew_pkg_NUM_FP_FORMATS {2'd1}}, {fpnew_pkg_NUM_FP_FORMATS {2'd2}}}), 2'd0};
	parameter [(((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 32) + ((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 2)) + 1:0] Implementation = fpnew_pkg_DEFAULT_NOREGS;
	parameter [0:0] PulpDivsqrt = 1'b1;
	parameter [31:0] TrueSIMDClass = 0;
	parameter [31:0] EnableSIMDMask = 0;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	function automatic signed [31:0] fpnew_pkg_maximum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_maximum = (a > b ? a : b);
	endfunction
	function automatic [2:0] sv2v_cast_0BC43;
		input reg [2:0] inp;
		sv2v_cast_0BC43 = inp;
	endfunction
	function automatic [31:0] fpnew_pkg_max_fp_width;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = 0;
			begin : sv2v_autoblock_1
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i])
						res = $unsigned(fpnew_pkg_maximum(res, fpnew_pkg_fp_width(sv2v_cast_0BC43(i))));
			end
			fpnew_pkg_max_fp_width = res;
		end
	endfunction
	function automatic signed [31:0] fpnew_pkg_minimum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_minimum = (a < b ? a : b);
	endfunction
	function automatic [31:0] fpnew_pkg_min_fp_width;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = fpnew_pkg_max_fp_width(cfg);
			begin : sv2v_autoblock_2
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i])
						res = $unsigned(fpnew_pkg_minimum(res, fpnew_pkg_fp_width(sv2v_cast_0BC43(i))));
			end
			fpnew_pkg_min_fp_width = res;
		end
	endfunction
	function automatic [31:0] fpnew_pkg_max_num_lanes;
		input reg [31:0] width;
		input reg [0:4] cfg;
		input reg vec;
		fpnew_pkg_max_num_lanes = (vec ? width / fpnew_pkg_min_fp_width(cfg) : 1);
	endfunction
	localparam [31:0] NumLanes = fpnew_pkg_max_num_lanes(Features[42-:32], Features[8-:5], Features[10]);
	localparam [31:0] WIDTH = Features[42-:32];
	localparam [31:0] NUM_OPERANDS = 3;
	input wire clk_i;
	input wire rst_ni;
	input wire [(NUM_OPERANDS * WIDTH) - 1:0] operands_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire op_mod_i;
	input wire [2:0] src_fmt_i;
	input wire [2:0] dst_fmt_i;
	localparam [31:0] fpnew_pkg_INT_FORMAT_BITS = 2;
	input wire [1:0] int_fmt_i;
	input wire vectorial_op_i;
	input wire tag_i;
	input wire [NumLanes - 1:0] simd_mask_i;
	input wire in_valid_i;
	output wire in_ready_o;
	input wire flush_i;
	output wire [WIDTH - 1:0] result_o;
	output wire [4:0] status_o;
	output wire tag_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	localparam [31:0] NUM_OPGROUPS = fpnew_pkg_NUM_OPGROUPS;
	localparam [31:0] NUM_FORMATS = fpnew_pkg_NUM_FP_FORMATS;
	wire [3:0] opgrp_in_ready;
	wire [3:0] opgrp_out_valid;
	wire [3:0] opgrp_out_ready;
	wire [3:0] opgrp_ext;
	wire [3:0] opgrp_busy;
	wire [((WIDTH + 5) >= 0 ? (4 * (WIDTH + 6)) - 1 : (4 * (1 - (WIDTH + 5))) + (WIDTH + 4)):((WIDTH + 5) >= 0 ? 0 : WIDTH + 5)] opgrp_outputs;
	wire [(NUM_FORMATS * NUM_OPERANDS) - 1:0] is_boxed;
	function automatic [3:0] sv2v_cast_A53F3;
		input reg [3:0] inp;
		sv2v_cast_A53F3 = inp;
	endfunction
	function automatic [1:0] fpnew_pkg_get_opgroup;
		input reg [3:0] op;
		case (op)
			sv2v_cast_A53F3(0), sv2v_cast_A53F3(1), sv2v_cast_A53F3(2), sv2v_cast_A53F3(3): fpnew_pkg_get_opgroup = 2'd0;
			sv2v_cast_A53F3(4), sv2v_cast_A53F3(5): fpnew_pkg_get_opgroup = 2'd1;
			sv2v_cast_A53F3(6), sv2v_cast_A53F3(7), sv2v_cast_A53F3(8), sv2v_cast_A53F3(9): fpnew_pkg_get_opgroup = 2'd2;
			sv2v_cast_A53F3(10), sv2v_cast_A53F3(11), sv2v_cast_A53F3(12), sv2v_cast_A53F3(13), sv2v_cast_A53F3(14): fpnew_pkg_get_opgroup = 2'd3;
			default: fpnew_pkg_get_opgroup = 2'd2;
		endcase
	endfunction
	assign in_ready_o = in_valid_i & opgrp_in_ready[fpnew_pkg_get_opgroup(op_i)];
	genvar fmt;
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
	generate
		for (fmt = 0; fmt < sv2v_cast_32_signed(NUM_FORMATS); fmt = fmt + 1) begin : gen_nanbox_check
			localparam [31:0] FP_WIDTH = fpnew_pkg_fp_width(sv2v_cast_0BC43(fmt));
			if (Features[9] && (FP_WIDTH < WIDTH)) begin : check
				genvar op;
				for (op = 0; op < sv2v_cast_32_signed(NUM_OPERANDS); op = op + 1) begin : operands
					assign is_boxed[(fmt * NUM_OPERANDS) + op] = (!vectorial_op_i ? operands_i[(op * WIDTH) + ((WIDTH - 1) >= FP_WIDTH ? WIDTH - 1 : ((WIDTH - 1) + ((WIDTH - 1) >= FP_WIDTH ? ((WIDTH - 1) - FP_WIDTH) + 1 : (FP_WIDTH - (WIDTH - 1)) + 1)) - 1)-:((WIDTH - 1) >= FP_WIDTH ? ((WIDTH - 1) - FP_WIDTH) + 1 : (FP_WIDTH - (WIDTH - 1)) + 1)] == {((WIDTH - 1) >= FP_WIDTH ? ((WIDTH - 1) - FP_WIDTH) + 1 : (FP_WIDTH - (WIDTH - 1)) + 1) * 1 {1'sb1}} : 1'b1);
				end
			end
			else begin : no_check
				assign is_boxed[fmt * NUM_OPERANDS+:NUM_OPERANDS] = 1'sb1;
			end
		end
	endgenerate
	wire [NumLanes - 1:0] simd_mask;
	function automatic [0:0] sv2v_cast_1;
		input reg [0:0] inp;
		sv2v_cast_1 = inp;
	endfunction
	assign simd_mask = simd_mask_i | ~{NumLanes {sv2v_cast_1(EnableSIMDMask)}};
	genvar opgrp;
	function automatic [31:0] fpnew_pkg_num_operands;
		input reg [1:0] grp;
		case (grp)
			2'd0: fpnew_pkg_num_operands = 3;
			2'd1: fpnew_pkg_num_operands = 2;
			2'd2: fpnew_pkg_num_operands = 2;
			2'd3: fpnew_pkg_num_operands = 3;
			default: fpnew_pkg_num_operands = 0;
		endcase
	endfunction
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	generate
		for (opgrp = 0; opgrp < sv2v_cast_32_signed(NUM_OPGROUPS); opgrp = opgrp + 1) begin : gen_operation_groups
			localparam [31:0] NUM_OPS = fpnew_pkg_num_operands(sv2v_cast_2(opgrp));
			wire in_valid;
			reg [(NUM_FORMATS * NUM_OPS) - 1:0] input_boxed;
			assign in_valid = in_valid_i & (fpnew_pkg_get_opgroup(op_i) == sv2v_cast_2(opgrp));
			always @(*) begin : slice_inputs
				begin : sv2v_autoblock_3
					reg [31:0] fmt;
					for (fmt = 0; fmt < NUM_FORMATS; fmt = fmt + 1)
						input_boxed[fmt * fpnew_pkg_num_operands(sv2v_cast_2(opgrp))+:fpnew_pkg_num_operands(sv2v_cast_2(opgrp))] = is_boxed[(fmt * NUM_OPERANDS) + (NUM_OPS - 1)-:NUM_OPS];
				end
			end
			fpnew_opgroup_block_E7A9E #(
				.OpGroup(sv2v_cast_2(opgrp)),
				.Width(WIDTH),
				.EnableVectors(Features[10]),
				.PulpDivsqrt(PulpDivsqrt),
				.FpFmtMask(Features[8-:5]),
				.IntFmtMask(Features[3-:fpnew_pkg_NUM_INT_FORMATS]),
				.FmtPipeRegs(Implementation[(((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 32) + (((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 2) + 1)) - ((((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 32) - 1) - (32 * ((3 - opgrp) * fpnew_pkg_NUM_FP_FORMATS)))+:160]),
				.FmtUnitTypes(Implementation[(((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 2) + 1) - ((((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 2) - 1) - (2 * ((3 - opgrp) * fpnew_pkg_NUM_FP_FORMATS)))+:10]),
				.PipeConfig(Implementation[1-:2]),
				.TrueSIMDClass(TrueSIMDClass)
			) i_opgroup_block(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.operands_i(operands_i[WIDTH * ((NUM_OPS - 1) - (NUM_OPS - 1))+:WIDTH * NUM_OPS]),
				.is_boxed_i(input_boxed),
				.rnd_mode_i(rnd_mode_i),
				.op_i(op_i),
				.op_mod_i(op_mod_i),
				.src_fmt_i(src_fmt_i),
				.dst_fmt_i(dst_fmt_i),
				.int_fmt_i(int_fmt_i),
				.vectorial_op_i(vectorial_op_i),
				.tag_i(tag_i),
				.simd_mask_i(simd_mask),
				.in_valid_i(in_valid),
				.in_ready_o(opgrp_in_ready[opgrp]),
				.flush_i(flush_i),
				.result_o(opgrp_outputs[((WIDTH + 5) >= 0 ? (opgrp * ((WIDTH + 5) >= 0 ? WIDTH + 6 : 1 - (WIDTH + 5))) + ((WIDTH + 5) >= 0 ? WIDTH + 5 : (WIDTH + 5) - (WIDTH + 5)) : (((opgrp * ((WIDTH + 5) >= 0 ? WIDTH + 6 : 1 - (WIDTH + 5))) + ((WIDTH + 5) >= 0 ? WIDTH + 5 : (WIDTH + 5) - (WIDTH + 5))) + ((WIDTH + 5) >= 6 ? WIDTH + 0 : 7 - (WIDTH + 5))) - 1)-:((WIDTH + 5) >= 6 ? WIDTH + 0 : 7 - (WIDTH + 5))]),
				.status_o(opgrp_outputs[((WIDTH + 5) >= 0 ? (opgrp * ((WIDTH + 5) >= 0 ? WIDTH + 6 : 1 - (WIDTH + 5))) + ((WIDTH + 5) >= 0 ? 5 : WIDTH + 0) : ((opgrp * ((WIDTH + 5) >= 0 ? WIDTH + 6 : 1 - (WIDTH + 5))) + ((WIDTH + 5) >= 0 ? 5 : WIDTH + 0)) + 4)-:5]),
				.extension_bit_o(opgrp_ext[opgrp]),
				.tag_o(opgrp_outputs[(opgrp * ((WIDTH + 5) >= 0 ? WIDTH + 6 : 1 - (WIDTH + 5))) + ((WIDTH + 5) >= 0 ? 0 : WIDTH + 5)]),
				.out_valid_o(opgrp_out_valid[opgrp]),
				.out_ready_i(opgrp_out_ready[opgrp]),
				.busy_o(opgrp_busy[opgrp])
			);
		end
	endgenerate
	wire [WIDTH + 5:0] arbiter_output;
	localparam [31:0] sv2v_uu_i_arbiter_NumIn = NUM_OPGROUPS;
	localparam [31:0] sv2v_uu_i_arbiter_IdxWidth = $unsigned(2);
	localparam [sv2v_uu_i_arbiter_IdxWidth - 1:0] sv2v_uu_i_arbiter_ext_rr_i_0 = 1'sb0;
	rr_arb_tree_02E82_EBE23 #(
		.DataType_WIDTH(WIDTH),
		.NumIn(NUM_OPGROUPS),
		.AxiVldRdy(1'b1)
	) i_arbiter(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.flush_i(flush_i),
		.rr_i(sv2v_uu_i_arbiter_ext_rr_i_0),
		.req_i(opgrp_out_valid),
		.gnt_o(opgrp_out_ready),
		.data_i(opgrp_outputs),
		.gnt_i(out_ready_i),
		.req_o(out_valid_o),
		.data_o(arbiter_output),
		.idx_o()
	);
	assign result_o = arbiter_output[WIDTH + 5-:((WIDTH + 5) >= 6 ? WIDTH + 0 : 7 - (WIDTH + 5))];
	assign status_o = arbiter_output[5-:5];
	assign tag_o = arbiter_output[0];
	assign busy_o = |opgrp_busy;
endmodule
