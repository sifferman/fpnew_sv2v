// Copyright 2019 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// SPDX-License-Identifier: SHL-0.51

// Author: Stefan Mach <smach@iis.ee.ethz.ch>

package fpnew_pkg;

  // ---------
  // FP TYPES
  // ---------
  // | Enumerator | Format           | Width  | EXP_BITS | MAN_BITS
  // |:----------:|------------------|-------:|:--------:|:--------:
  // | FP32       | IEEE binary32    | 32 bit | 8        | 23
  // | FP64       | IEEE binary64    | 64 bit | 11       | 52
  // | FP16       | IEEE binary16    | 16 bit | 5        | 10
  // | FP8        | binary8          |  8 bit | 5        | 2
  // | FP16ALT    | binary16alt      | 16 bit | 8        | 7
  // *NOTE:* Add new formats only at the end of the enumeration for backwards compatibilty!

  // Encoding for a format
  typedef struct packed {
    int unsigned exp_bits;
    int unsigned man_bits;
  } fp_encoding_t;

  localparam int unsigned NUM_FP_FORMATS = 5; // change me to add formats
  localparam int unsigned FP_FORMAT_BITS = $clog2(NUM_FP_FORMATS);

  // FP formats
  typedef enum logic [FP_FORMAT_BITS-1:0] {
    FP32    = 'd0,
    FP64    = 'd1,
    FP16    = 'd2,
    FP8     = 'd3,
    FP16ALT = 'd4
    // add new formats here
  } fp_format_e;

  // Encodings for supported FP formats
  localparam fp_encoding_t [0:NUM_FP_FORMATS-1] FP_ENCODINGS  = '{
    '{8,  23}, // IEEE binary32 (single)
    '{11, 52}, // IEEE binary64 (double)
    '{5,  10}, // IEEE binary16 (half)
    '{5,  2},  // custom binary8
    '{8,  7}   // custom binary16alt
    // add new formats here
  };

  typedef logic [0:NUM_FP_FORMATS-1]       fmt_logic_t;    // Logic indexed by FP format (for masks)
  typedef logic [0:NUM_FP_FORMATS-1][31:0] fmt_unsigned_t; // Unsigned indexed by FP format

  localparam fmt_logic_t CPK_FORMATS = 5'b11000; // FP32 and FP64 can provide CPK only

  // ---------
  // INT TYPES
  // ---------
  // | Enumerator | Width  |
  // |:----------:|-------:|
  // | INT8       |  8 bit |
  // | INT16      | 16 bit |
  // | INT32      | 32 bit |
  // | INT64      | 64 bit |
  // *NOTE:* Add new formats only at the end of the enumeration for backwards compatibilty!

  localparam int unsigned NUM_INT_FORMATS = 4; // change me to add formats
  localparam int unsigned INT_FORMAT_BITS = $clog2(NUM_INT_FORMATS);

  // Int formats
  typedef enum logic [INT_FORMAT_BITS-1:0] {
    INT8,
    INT16,
    INT32,
    INT64
    // add new formats here
  } int_format_e;

  // Returns the width of an INT format by index
  function automatic int unsigned int_width(int_format_e ifmt);
    unique case (ifmt)
      INT8:  return 8;
      INT16: return 16;
      INT32: return 32;
      INT64: return 64;
      default: begin
        // just return any integer to avoid any latches
        // hopefully this error is caught by simulation
        return INT8;
      end
    endcase
  endfunction

  typedef logic [0:NUM_INT_FORMATS-1] ifmt_logic_t; // Logic indexed by INT format (for masks)

  // --------------
  // FP OPERATIONS
  // --------------
  localparam int unsigned NUM_OPGROUPS = 4;

  // Each FP operation belongs to an operation group
  typedef enum logic [1:0] {
    ADDMUL, DIVSQRT, NONCOMP, CONV
  } opgroup_e;

  localparam int unsigned OP_BITS = 4;

  typedef enum logic [OP_BITS-1:0] {
    FMADD, FNMSUB, ADD, MUL,     // ADDMUL operation group
    DIV, SQRT,                   // DIVSQRT operation group
    SGNJ, MINMAX, CMP, CLASSIFY, // NONCOMP operation group
    F2F, F2I, I2F, CPKAB, CPKCD  // CONV operation group
  } operation_e;

  // -------------------
  // RISC-V FP-SPECIFIC
  // -------------------
  // Rounding modes
  typedef enum logic [2:0] {
    RNE = 3'b000,
    RTZ = 3'b001,
    RDN = 3'b010,
    RUP = 3'b011,
    RMM = 3'b100,
    ROD = 3'b101,  // This mode is not defined in RISC-V FP-SPEC
    DYN = 3'b111
  } roundmode_e;

  // Status flags
  typedef struct packed {
    logic NV; // Invalid
    logic DZ; // Divide by zero
    logic OF; // Overflow
    logic UF; // Underflow
    logic NX; // Inexact
  } status_t;

  // Information about a floating point value
  typedef struct packed {
    logic is_normal;     // is the value normal
    logic is_subnormal;  // is the value subnormal
    logic is_zero;       // is the value zero
    logic is_inf;        // is the value infinity
    logic is_nan;        // is the value NaN
    logic is_signalling; // is the value a signalling NaN
    logic is_quiet;      // is the value a quiet NaN
    logic is_boxed;      // is the value properly NaN-boxed (RISC-V specific)
  } fp_info_t;

  // Classification mask
  typedef enum logic [9:0] {
    NEGINF     = 10'b00_0000_0001,
    NEGNORM    = 10'b00_0000_0010,
    NEGSUBNORM = 10'b00_0000_0100,
    NEGZERO    = 10'b00_0000_1000,
    POSZERO    = 10'b00_0001_0000,
    POSSUBNORM = 10'b00_0010_0000,
    POSNORM    = 10'b00_0100_0000,
    POSINF     = 10'b00_1000_0000,
    SNAN       = 10'b01_0000_0000,
    QNAN       = 10'b10_0000_0000
  } classmask_e;

  // ------------------
  // FPU configuration
  // ------------------
  // Pipelining registers can be inserted (at elaboration time) into operational units
  typedef enum logic [1:0] {
    BEFORE,     // registers are inserted at the inputs of the unit
    AFTER,      // registers are inserted at the outputs of the unit
    INSIDE,     // registers are inserted at predetermined (suboptimal) locations in the unit
    DISTRIBUTED // registers are evenly distributed, INSIDE >= AFTER >= BEFORE
  } pipe_config_t;

  // Arithmetic units can be arranged in parallel (per format), merged (multi-format) or not at all.
  typedef enum logic [1:0] {
    DISABLED, // arithmetic units are not generated
    PARALLEL, // arithmetic units are generated in prallel slices, one for each format
    MERGED    // arithmetic units are contained within a merged unit holding multiple formats
  } unit_type_t;

  // Array of unit types indexed by format
  typedef unit_type_t [0:NUM_FP_FORMATS-1] fmt_unit_types_t;

  // Array of format-specific unit types by opgroup
  typedef fmt_unit_types_t [0:NUM_OPGROUPS-1] opgrp_fmt_unit_types_t;
  // same with unsigned
  typedef fmt_unsigned_t [0:NUM_OPGROUPS-1] opgrp_fmt_unsigned_t;

  // FPU configuration: features
  typedef struct packed {
    int unsigned Width;
    logic        EnableVectors;
    logic        EnableNanBox;
    fmt_logic_t  FpFmtMask;
    ifmt_logic_t IntFmtMask;
  } fpu_features_t;

  localparam fpu_features_t RV64D = '{
    Width:         64,
    EnableVectors: 1'b0,
    EnableNanBox:  1'b1,
    FpFmtMask:     5'b11000,
    IntFmtMask:    4'b0011
  };

  localparam fpu_features_t RV32D = '{
    Width:         64,
    EnableVectors: 1'b1,
    EnableNanBox:  1'b1,
    FpFmtMask:     5'b11000,
    IntFmtMask:    4'b0010
  };

  localparam fpu_features_t RV32F = '{
    Width:         32,
    EnableVectors: 1'b0,
    EnableNanBox:  1'b1,
    FpFmtMask:     5'b10000,
    IntFmtMask:    4'b0010
  };

  localparam fpu_features_t RV64D_Xsflt = '{
    Width:         64,
    EnableVectors: 1'b1,
    EnableNanBox:  1'b1,
    FpFmtMask:     5'b11111,
    IntFmtMask:    4'b1111
  };

  localparam fpu_features_t RV32F_Xsflt = '{
    Width:         32,
    EnableVectors: 1'b1,
    EnableNanBox:  1'b1,
    FpFmtMask:     5'b10111,
    IntFmtMask:    4'b1110
  };

  localparam fpu_features_t RV32F_Xf16alt_Xfvec = '{
    Width:         32,
    EnableVectors: 1'b1,
    EnableNanBox:  1'b1,
    FpFmtMask:     5'b10001,
    IntFmtMask:    4'b0110
  };


  // FPU configuraion: implementation
  typedef struct packed {
    opgrp_fmt_unsigned_t   PipeRegs;
    opgrp_fmt_unit_types_t UnitTypes;
    pipe_config_t          PipeConfig;
  } fpu_implementation_t;

  localparam fpu_implementation_t DEFAULT_NOREGS = '{
    PipeRegs:   '{default: 0},
    UnitTypes:  '{'{default: PARALLEL}, // ADDMUL
                  '{default: MERGED},   // DIVSQRT
                  '{default: PARALLEL}, // NONCOMP
                  '{default: MERGED}},  // CONV
    PipeConfig: BEFORE
  };

  localparam fpu_implementation_t DEFAULT_SNITCH = '{
    PipeRegs:   '{default: 1},
    UnitTypes:  '{'{default: PARALLEL}, // ADDMUL
                  '{default: DISABLED}, // DIVSQRT
                  '{default: PARALLEL}, // NONCOMP
                  '{default: MERGED}},  // CONV
    PipeConfig: BEFORE
  };

  // -----------------------
  // Synthesis optimization
  // -----------------------
  localparam logic DONT_CARE = 1'b1; // the value to assign as don't care

  // -------------------------
  // General helper functions
  // -------------------------
  function automatic int minimum(int a, int b);
    return (a < b) ? a : b;
  endfunction

  function automatic int maximum(int a, int b);
    return (a > b) ? a : b;
  endfunction

  // -------------------------------------------
  // Helper functions for FP formats and values
  // -------------------------------------------
  // Returns the width of a FP format
  function automatic int unsigned fp_width(fp_format_e fmt);
    return FP_ENCODINGS[fmt].exp_bits + FP_ENCODINGS[fmt].man_bits + 1;
  endfunction

  // Returns the widest FP format present
  function automatic int unsigned max_fp_width(fmt_logic_t cfg);
    automatic int unsigned res = 0;
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++)
      if (cfg[i])
        res = unsigned'(maximum(res, fp_width(fp_format_e'(i))));
    return res;
  endfunction

  // Returns the narrowest FP format present
  function automatic int unsigned min_fp_width(fmt_logic_t cfg);
    automatic int unsigned res = max_fp_width(cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++)
      if (cfg[i])
        res = unsigned'(minimum(res, fp_width(fp_format_e'(i))));
    return res;
  endfunction

  // Returns the number of expoent bits for a format
  function automatic int unsigned exp_bits(fp_format_e fmt);
    return FP_ENCODINGS[fmt].exp_bits;
  endfunction

  // Returns the number of mantissa bits for a format
  function automatic int unsigned man_bits(fp_format_e fmt);
    return FP_ENCODINGS[fmt].man_bits;
  endfunction

  // Returns the bias value for a given format (as per IEEE 754-2008)
  function automatic int unsigned bias(fp_format_e fmt);
    return unsigned'(2**(FP_ENCODINGS[fmt].exp_bits-1)-1); // symmetrical bias
  endfunction

  function automatic fp_encoding_t super_format(fmt_logic_t cfg);
    automatic fp_encoding_t res;
    res = '0;
    for (int unsigned fmt = 0; fmt < NUM_FP_FORMATS; fmt++)
      if (cfg[fmt]) begin // only active format
        res.exp_bits = unsigned'(maximum(res.exp_bits, exp_bits(fp_format_e'(fmt))));
        res.man_bits = unsigned'(maximum(res.man_bits, man_bits(fp_format_e'(fmt))));
      end
    return res;
  endfunction

  // -------------------------------------------
  // Helper functions for INT formats and values
  // -------------------------------------------
  // Returns the widest INT format present
  function automatic int unsigned max_int_width(ifmt_logic_t cfg);
    automatic int unsigned res = 0;
    for (int ifmt = 0; ifmt < NUM_INT_FORMATS; ifmt++) begin
      if (cfg[ifmt]) res = maximum(res, int_width(int_format_e'(ifmt)));
    end
    return res;
  endfunction

  // --------------------------------------------------
  // Helper functions for operations and FPU structure
  // --------------------------------------------------
  // Returns the operation group of the given operation
  function automatic opgroup_e get_opgroup(operation_e op);
    unique case (op)
      FMADD, FNMSUB, ADD, MUL:     return ADDMUL;
      DIV, SQRT:                   return DIVSQRT;
      SGNJ, MINMAX, CMP, CLASSIFY: return NONCOMP;
      F2F, F2I, I2F, CPKAB, CPKCD: return CONV;
      default:                     return NONCOMP;
    endcase
  endfunction

  // Returns the number of operands by operation group
  function automatic int unsigned num_operands(opgroup_e grp);
    unique case (grp)
      ADDMUL:  return 3;
      DIVSQRT: return 2;
      NONCOMP: return 2;
      CONV:    return 3; // vectorial casts use 3 operands
      default: return 0;
    endcase
  endfunction

  // Returns the number of lanes according to width, format and vectors
  function automatic int unsigned num_lanes(int unsigned width, fp_format_e fmt, logic vec);
    return vec ? width / fp_width(fmt) : 1; // if no vectors, only one lane
  endfunction

  // Returns the maximum number of lanes in the FPU according to width, format config and vectors
  function automatic int unsigned max_num_lanes(int unsigned width, fmt_logic_t cfg, logic vec);
    return vec ? width / min_fp_width(cfg) : 1; // if no vectors, only one lane
  endfunction

  // Returns a mask of active FP formats that are present in lane lane_no of a multiformat slice
  function automatic fmt_logic_t get_lane_formats(int unsigned width,
                                                  fmt_logic_t cfg,
                                                  int unsigned lane_no);
    automatic fmt_logic_t res;
    for (int unsigned fmt = 0; fmt < NUM_FP_FORMATS; fmt++)
      // Mask active formats with the number of lanes for that format
      res[fmt] = cfg[fmt] & (width / fp_width(fp_format_e'(fmt)) > lane_no);
    return res;
  endfunction

  // Returns a mask of active INT formats that are present in lane lane_no of a multiformat slice
  function automatic ifmt_logic_t get_lane_int_formats(int unsigned width,
                                                       fmt_logic_t cfg,
                                                       ifmt_logic_t icfg,
                                                       int unsigned lane_no);
    automatic ifmt_logic_t res;
    automatic fmt_logic_t lanefmts;
    res = '0;
    lanefmts = get_lane_formats(width, cfg, lane_no);

    for (int unsigned ifmt = 0; ifmt < NUM_INT_FORMATS; ifmt++)
      for (int unsigned fmt = 0; fmt < NUM_FP_FORMATS; fmt++)
        // Mask active int formats with the width of the float formats
        if ((fp_width(fp_format_e'(fmt)) == int_width(int_format_e'(ifmt))))
          res[ifmt] |= icfg[ifmt] && lanefmts[fmt];
    return res;
  endfunction

  // Returns a mask of active FP formats that are present in lane lane_no of a CONV slice
  function automatic fmt_logic_t get_conv_lane_formats(int unsigned width,
                                                       fmt_logic_t cfg,
                                                       int unsigned lane_no);
    automatic fmt_logic_t res;
    for (int unsigned fmt = 0; fmt < NUM_FP_FORMATS; fmt++)
      // Mask active formats with the number of lanes for that format, CPK at least twice
      res[fmt] = cfg[fmt] && ((width / fp_width(fp_format_e'(fmt)) > lane_no) ||
                             (CPK_FORMATS[fmt] && (lane_no < 2)));
    return res;
  endfunction

  // Returns a mask of active INT formats that are present in lane lane_no of a CONV slice
  function automatic ifmt_logic_t get_conv_lane_int_formats(int unsigned width,
                                                            fmt_logic_t cfg,
                                                            ifmt_logic_t icfg,
                                                            int unsigned lane_no);
    automatic ifmt_logic_t res;
    automatic fmt_logic_t lanefmts;
    res = '0;
    lanefmts = get_conv_lane_formats(width, cfg, lane_no);

    for (int unsigned ifmt = 0; ifmt < NUM_INT_FORMATS; ifmt++)
      for (int unsigned fmt = 0; fmt < NUM_FP_FORMATS; fmt++)
        // Mask active int formats with the width of the float formats
        res[ifmt] |= icfg[ifmt] && lanefmts[fmt] &&
                     (fp_width(fp_format_e'(fmt)) == int_width(int_format_e'(ifmt)));
    return res;
  endfunction

  // Return whether any active format is set as MERGED
  function automatic logic any_enabled_multi(fmt_unit_types_t types, fmt_logic_t cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++)
      if (cfg[i] && types[i] == MERGED)
        return 1'b1;
      return 1'b0;
  endfunction

  // Return whether the given format is the first active one set as MERGED
  function automatic logic is_first_enabled_multi(fp_format_e fmt,
                                                  fmt_unit_types_t types,
                                                  fmt_logic_t cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++) begin
      if (cfg[i] && types[i] == MERGED) return (fp_format_e'(i) == fmt);
    end
    return 1'b0;
  endfunction

  // Returns the first format that is active and is set as MERGED
  function automatic fp_format_e get_first_enabled_multi(fmt_unit_types_t types, fmt_logic_t cfg);
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++)
      if (cfg[i] && types[i] == MERGED)
        return fp_format_e'(i);
      return fp_format_e'(0);
  endfunction

  // Returns the largest number of regs that is active and is set as MERGED
  function automatic int unsigned get_num_regs_multi(fmt_unsigned_t regs,
                                                     fmt_unit_types_t types,
                                                     fmt_logic_t cfg);
    automatic int unsigned res = 0;
    for (int unsigned i = 0; i < NUM_FP_FORMATS; i++) begin
      if (cfg[i] && types[i] == MERGED) res = maximum(res, regs[i]);
    end
    return res;
  endfunction

endpackage
// Copyright 2019 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// SPDX-License-Identifier: SHL-0.51

// Author: Stefan Mach <smach@iis.ee.ethz.ch>

module fpnew_classifier #(
  parameter fpnew_pkg::fp_format_e   FpFormat = fpnew_pkg::fp_format_e'(0),
  parameter int unsigned             NumOperands = 1,
  // Do not change
  localparam int unsigned WIDTH = fpnew_pkg::fp_width(FpFormat)
) (
  input  logic                [NumOperands-1:0][WIDTH-1:0] operands_i,
  input  logic                [NumOperands-1:0]            is_boxed_i,
  output fpnew_pkg::fp_info_t [NumOperands-1:0]            info_o
);

  localparam int unsigned EXP_BITS = fpnew_pkg::exp_bits(FpFormat);
  localparam int unsigned MAN_BITS = fpnew_pkg::man_bits(FpFormat);

  // Type definition
  typedef struct packed {
    logic                sign;
    logic [EXP_BITS-1:0] exponent;
    logic [MAN_BITS-1:0] mantissa;
  } fp_t;

  // Iterate through all operands
  for (genvar op = 0; op < int'(NumOperands); op++) begin : gen_num_values

    fp_t value;
    logic is_boxed;
    logic is_normal;
    logic is_inf;
    logic is_nan;
    logic is_signalling;
    logic is_quiet;
    logic is_zero;
    logic is_subnormal;

    // ---------------
    // Classify Input
    // ---------------
    always_comb begin : classify_input
      value         = operands_i[op];
      is_boxed      = is_boxed_i[op];
      is_normal     = is_boxed && (value.exponent != '0) && (value.exponent != '1);
      is_zero       = is_boxed && (value.exponent == '0) && (value.mantissa == '0);
      is_subnormal  = is_boxed && (value.exponent == '0) && !is_zero;
      is_inf        = is_boxed && ((value.exponent == '1) && (value.mantissa == '0));
      is_nan        = !is_boxed || ((value.exponent == '1) && (value.mantissa != '0));
      is_signalling = is_boxed && is_nan && (value.mantissa[MAN_BITS-1] == 1'b0);
      is_quiet      = is_nan && !is_signalling;
      // Assign output for current input
      info_o[op].is_normal     = is_normal;
      info_o[op].is_subnormal  = is_subnormal;
      info_o[op].is_zero       = is_zero;
      info_o[op].is_inf        = is_inf;
      info_o[op].is_nan        = is_nan;
      info_o[op].is_signalling = is_signalling;
      info_o[op].is_quiet      = is_quiet;
      info_o[op].is_boxed      = is_boxed;
    end
  end
endmodule
// Copyright 2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Michael Schaffner <schaffner@iis.ee.ethz.ch>, ETH Zurich
//         Wolfgang Roenninger <wroennin@iis.ee.ethz.ch>, ETH Zurich
// Date: 02.04.2019
// Description: logarithmic arbitration tree with round robin arbitration scheme.

/// The rr_arb_tree employs non-starving round robin-arbitration - i.e., the priorities
/// rotate each cycle.
///
/// ## Fair vs. unfair Arbitration
///
/// This refers to fair throughput distribution when not all inputs have active requests.
/// This module has an internal state `rr_q` which defines the highest priority input. (When
/// `ExtPrio` is `1'b1` this state is provided from the outside.) The arbitration tree will
/// choose the input with the same index as currently defined by the state if it has an active
/// request. Otherwise a *random* other active input is selected. The parameter `FairArb` is used
/// to distinguish between two methods of calculating the next state.
/// * `1'b0`: The next state is calculated by advancing the current state by one. This leads to the
///           state being calculated without the context of the active request. Leading to an
///           unfair throughput distribution if not all inputs have active requests.
/// * `1'b1`: The next state jumps to the next unserved request with higher index.
///           This is achieved by using two trailing-zero-counters (`lzc`). The upper has the masked
///           `req_i` signal with all indices which will have a higher priority in the next state.
///           The trailing zero count defines the input index with the next highest priority after
///           the current one is served. When the upper is empty the lower `lzc` provides the
///           wrapped index if there are outstanding requests with lower or same priority.
/// The implication of throughput fairness on the module timing are:
/// * The trailing zero counter (`lzc`) has a loglog relation of input to output timing. This means
///   that in this module the input to register path scales with Log(Log(`NumIn`)).
/// * The `rr_arb_tree` data multiplexing scales with Log(`NumIn`). This means that the input to output
///   timing path of this module also scales scales with Log(`NumIn`).
/// This implies that in this module the input to output path is always longer than the input to
/// register path. As the output data usually also terminates in a register the parameter `FairArb`
/// only has implications on the area. When it is `1'b0` a static plus one adder is instantiated.
/// If it is `1'b1` two `lzc`, a masking logic stage and a two input multiplexer are instantiated.
/// However these are small in respect of the data multiplexers needed, as the width of the `req_i`
/// signal is usually less as than `DataWidth`.
module rr_arb_tree #(
  /// Number of inputs to be arbitrated.
  parameter int unsigned NumIn      = 64,
  /// Data width of the payload in bits. Not needed if `DataType` is overwritten.
  parameter int unsigned DataWidth  = 32,
  /// Data type of the payload, can be overwritten with custom type. Only use of `DataWidth`.
  parameter type         DataType   = logic [DataWidth-1:0],
  /// The `ExtPrio` option allows to override the internal round robin counter via the
  /// `rr_i` signal. This can be useful in case multiple arbiters need to have
  /// rotating priorities that are operating in lock-step. If static priority arbitration
  /// is needed, just connect `rr_i` to '0.
  ///
  /// Set to 1'b1 to enable.
  parameter bit          ExtPrio    = 1'b0,
  /// If `AxiVldRdy` is set, the req/gnt signals are compliant with the AXI style vld/rdy
  /// handshake. Namely, upstream vld (req) must not depend on rdy (gnt), as it can be deasserted
  /// again even though vld is asserted. Enabling `AxiVldRdy` leads to a reduction of arbiter
  /// delay and area.
  ///
  /// Set to `1'b1` to treat req/gnt as vld/rdy.
  parameter bit          AxiVldRdy  = 1'b0,
  /// The `LockIn` option prevents the arbiter from changing the arbitration
  /// decision when the arbiter is disabled. I.e., the index of the first request
  /// that wins the arbitration will be locked in case the destination is not
  /// able to grant the request in the same cycle.
  ///
  /// Set to `1'b1` to enable.
  parameter bit          LockIn     = 1'b0,
  /// When set, ensures that throughput gets distributed evenly between all inputs.
  ///
  /// Set to `1'b0` to disable.
  parameter bit          FairArb    = 1'b1,
  /// Dependent parameter, do **not** overwrite.
  /// Width of the arbitration priority signal and the arbitrated index.
  parameter int unsigned IdxWidth   = (NumIn > 32'd1) ? unsigned'($clog2(NumIn)) : 32'd1,
  /// Dependent parameter, do **not** overwrite.
  /// Type for defining the arbitration priority and arbitrated index signal.
  parameter type         idx_t      = logic [IdxWidth-1:0]
) (
  /// Clock, positive edge triggered.
  input  logic                clk_i,
  /// Asynchronous reset, active low.
  input  logic                rst_ni,
  /// Clears the arbiter state. Only used if `ExtPrio` is `1'b0` or `LockIn` is `1'b1`.
  input  logic                flush_i,
  /// External round-robin priority. Only used if `ExtPrio` is `1'b1.`
  input  idx_t                rr_i,
  /// Input requests arbitration.
  input  logic    [NumIn-1:0] req_i,
  /* verilator lint_off UNOPTFLAT */
  /// Input request is granted.
  output logic    [NumIn-1:0] gnt_o,
  /* verilator lint_on UNOPTFLAT */
  /// Input data for arbitration.
  input  DataType [NumIn-1:0] data_i,
  /// Output request is valid.
  output logic                req_o,
  /// Output request is granted.
  input  logic                gnt_i,
  /// Output data.
  output DataType             data_o,
  /// Index from which input the data came from.
  output idx_t                idx_o
);

  // just pass through in this corner case
  if (NumIn == unsigned'(1)) begin : gen_pass_through
    assign req_o    = req_i[0];
    assign gnt_o[0] = gnt_i;
    assign data_o   = data_i[0];
    assign idx_o    = '0;
  // non-degenerate cases
  end else begin : gen_arbiter
    localparam int unsigned NumLevels = unsigned'($clog2(NumIn));

    /* verilator lint_off UNOPTFLAT */
    idx_t    [2**NumLevels-2:0] index_nodes; // used to propagate the indices
    DataType [2**NumLevels-2:0] data_nodes;  // used to propagate the data
    logic    [2**NumLevels-2:0] gnt_nodes;   // used to propagate the grant to masters
    logic    [2**NumLevels-2:0] req_nodes;   // used to propagate the requests to slave
    /* lint_off */
    idx_t                       rr_q;
    logic [NumIn-1:0]           req_d;

    // the final arbitration decision can be taken from the root of the tree
    assign req_o        = req_nodes[0];
    assign data_o       = data_nodes[0];
    assign idx_o        = index_nodes[0];

    if (ExtPrio) begin : gen_ext_rr
      assign rr_q       = rr_i;
      assign req_d      = req_i;
    end else begin : gen_int_rr
      idx_t rr_d;

      // lock arbiter decision in case we got at least one req and no acknowledge
      if (LockIn) begin : gen_lock
        logic  lock_d, lock_q;
        logic [NumIn-1:0] req_q;

        assign lock_d     = req_o & ~gnt_i;
        assign req_d      = (lock_q) ? req_q : req_i;

        always_ff @(posedge clk_i or negedge rst_ni) begin : p_lock_reg
          if (!rst_ni) begin
            lock_q <= '0;
          end else begin
            if (flush_i) begin
              lock_q <= '0;
            end else begin
              lock_q <= lock_d;
            end
          end
        end

        always_ff @(posedge clk_i or negedge rst_ni) begin : p_req_regs
          if (!rst_ni) begin
            req_q  <= '0;
          end else begin
            if (flush_i) begin
              req_q  <= '0;
            end else begin
              req_q  <= req_d;
            end
          end
        end
      end else begin : gen_no_lock
        assign req_d = req_i;
      end

      if (FairArb) begin : gen_fair_arb
        logic [NumIn-1:0] upper_mask,  lower_mask;
        idx_t             upper_idx,   lower_idx,   next_idx;
        logic             upper_empty, lower_empty;

        for (genvar i = 0; i < NumIn; i++) begin : gen_mask
          assign upper_mask[i] = (i >  rr_q) ? req_d[i] : 1'b0;
          assign lower_mask[i] = (i <= rr_q) ? req_d[i] : 1'b0;
        end

        lzc #(
          .WIDTH ( NumIn ),
          .MODE  ( 1'b0  )
        ) i_lzc_upper (
          .in_i    ( upper_mask  ),
          .cnt_o   ( upper_idx   ),
          .empty_o ( upper_empty )
        );

        lzc #(
          .WIDTH ( NumIn ),
          .MODE  ( 1'b0  )
        ) i_lzc_lower (
          .in_i    ( lower_mask  ),
          .cnt_o   ( lower_idx   ),
          .empty_o ( /*unused*/  )
        );

        assign next_idx = upper_empty      ? lower_idx : upper_idx;
        assign rr_d     = (gnt_i && req_o) ? next_idx  : rr_q;

      end else begin : gen_unfair_arb
        assign rr_d = (gnt_i && req_o) ? ((rr_q == idx_t'(NumIn-1)) ? '0 : rr_q + 1'b1) : rr_q;
      end

      // this holds the highest priority
      always_ff @(posedge clk_i or negedge rst_ni) begin : p_rr_regs
        if (!rst_ni) begin
          rr_q   <= '0;
        end else begin
          if (flush_i) begin
            rr_q   <= '0;
          end else begin
            rr_q   <= rr_d;
          end
        end
      end
    end

    assign gnt_nodes[0] = gnt_i;

    // arbiter tree
    for (genvar level = 0; unsigned'(level) < NumLevels; level++) begin : gen_levels
      for (genvar l = 0; l < 2**level; l++) begin : gen_level
        // local select signal
        logic sel;
        // index calcs
        localparam int unsigned Idx0 = 2**level-1+l;// current node
        localparam int unsigned Idx1 = 2**(level+1)-1+l*2;
        //////////////////////////////////////////////////////////////
        // uppermost level where data is fed in from the inputs
        if (unsigned'(level) == NumLevels-1) begin : gen_first_level
          // if two successive indices are still in the vector...
          if (unsigned'(l) * 2 < NumIn-1) begin : gen_reduce
            assign req_nodes[Idx0]   = req_d[l*2] | req_d[l*2+1];

            // arbitration: round robin
            assign sel =  ~req_d[l*2] | req_d[l*2+1] & rr_q[NumLevels-1-level];

            assign index_nodes[Idx0] = idx_t'(sel);
            assign data_nodes[Idx0]  = (sel) ? data_i[l*2+1] : data_i[l*2];
            assign gnt_o[l*2]        = gnt_nodes[Idx0] & (AxiVldRdy | req_d[l*2])   & ~sel;
            assign gnt_o[l*2+1]      = gnt_nodes[Idx0] & (AxiVldRdy | req_d[l*2+1]) & sel;
          end
          // if only the first index is still in the vector...
          if (unsigned'(l) * 2 == NumIn-1) begin : gen_first
            assign req_nodes[Idx0]   = req_d[l*2];
            assign index_nodes[Idx0] = '0;// always zero in this case
            assign data_nodes[Idx0]  = data_i[l*2];
            assign gnt_o[l*2]        = gnt_nodes[Idx0] & (AxiVldRdy | req_d[l*2]);
          end
          // if index is out of range, fill up with zeros (will get pruned)
          if (unsigned'(l) * 2 > NumIn-1) begin : gen_out_of_range
            assign req_nodes[Idx0]   = 1'b0;
            assign index_nodes[Idx0] = idx_t'('0);
            assign data_nodes[Idx0]  = DataType'('0);
          end
        //////////////////////////////////////////////////////////////
        // general case for other levels within the tree
        end else begin : gen_other_levels
          assign req_nodes[Idx0]   = req_nodes[Idx1] | req_nodes[Idx1+1];

          // arbitration: round robin
          assign sel =  ~req_nodes[Idx1] | req_nodes[Idx1+1] & rr_q[NumLevels-1-level];

          assign index_nodes[Idx0] = (sel) ?
            idx_t'({1'b1, index_nodes[Idx1+1][NumLevels-unsigned'(level)-2:0]}) :
            idx_t'({1'b0, index_nodes[Idx1][NumLevels-unsigned'(level)-2:0]});

          assign data_nodes[Idx0]  = (sel) ? data_nodes[Idx1+1] : data_nodes[Idx1];
          assign gnt_nodes[Idx1]   = gnt_nodes[Idx0] & ~sel;
          assign gnt_nodes[Idx1+1] = gnt_nodes[Idx0] & sel;
        end
        //////////////////////////////////////////////////////////////
      end
    end

  end

endmodule : rr_arb_tree
// Copyright 2019 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// SPDX-License-Identifier: SHL-0.51

// Author: Stefan Mach <smach@iis.ee.ethz.ch>

module fpnew_opgroup_block #(
  parameter fpnew_pkg::opgroup_e        OpGroup       = fpnew_pkg::ADDMUL,
  // FPU configuration
  parameter int unsigned                Width         = 32,
  parameter logic                       EnableVectors = 1'b1,
  parameter logic                       PulpDivsqrt   = 1'b1,
  parameter fpnew_pkg::fmt_logic_t      FpFmtMask     = '1,
  parameter fpnew_pkg::ifmt_logic_t     IntFmtMask    = '1,
  parameter fpnew_pkg::fmt_unsigned_t   FmtPipeRegs   = '{default: 0},
  parameter fpnew_pkg::fmt_unit_types_t FmtUnitTypes  = '{default: fpnew_pkg::PARALLEL},
  parameter fpnew_pkg::pipe_config_t    PipeConfig    = fpnew_pkg::BEFORE,
  parameter type                        TagType       = logic,
  parameter int unsigned                TrueSIMDClass = 0,
  // Do not change
  localparam int unsigned NUM_FORMATS  = fpnew_pkg::NUM_FP_FORMATS,
  localparam int unsigned NUM_OPERANDS = fpnew_pkg::num_operands(OpGroup),
  localparam int unsigned NUM_LANES    = fpnew_pkg::max_num_lanes(Width, FpFmtMask, EnableVectors),
  localparam type         MaskType     = logic [NUM_LANES-1:0]
) (
  input logic                                     clk_i,
  input logic                                     rst_ni,
  // Input signals
  input logic [NUM_OPERANDS-1:0][Width-1:0]       operands_i,
  input logic [NUM_FORMATS-1:0][NUM_OPERANDS-1:0] is_boxed_i,
  input fpnew_pkg::roundmode_e                    rnd_mode_i,
  input fpnew_pkg::operation_e                    op_i,
  input logic                                     op_mod_i,
  input fpnew_pkg::fp_format_e                    src_fmt_i,
  input fpnew_pkg::fp_format_e                    dst_fmt_i,
  input fpnew_pkg::int_format_e                   int_fmt_i,
  input logic                                     vectorial_op_i,
  input TagType                                   tag_i,
  input MaskType                                  simd_mask_i,
  // Input Handshake
  input  logic                                    in_valid_i,
  output logic                                    in_ready_o,
  input  logic                                    flush_i,
  // Output signals
  output logic [Width-1:0]                        result_o,
  output fpnew_pkg::status_t                      status_o,
  output logic                                    extension_bit_o,
  output TagType                                  tag_o,
  // Output handshake
  output logic                                    out_valid_o,
  input  logic                                    out_ready_i,
  // Indication of valid data in flight
  output logic                                    busy_o
);

  // ----------------
  // Type Definition
  // ----------------
  typedef struct packed {
    logic [Width-1:0]   result;
    fpnew_pkg::status_t status;
    logic               ext_bit;
    TagType             tag;
  } output_t;

  // Handshake signals for the slices
  logic [NUM_FORMATS-1:0] fmt_in_ready, fmt_out_valid, fmt_out_ready, fmt_busy;
  output_t [NUM_FORMATS-1:0] fmt_outputs;

  // -----------
  // Input Side
  // -----------
  assign in_ready_o = in_valid_i & fmt_in_ready[dst_fmt_i]; // Ready is given by selected format

  // -------------------------
  // Generate Parallel Slices
  // -------------------------
  for (genvar fmt = 0; fmt < int'(NUM_FORMATS); fmt++) begin : gen_parallel_slices
    // Some constants for this format
    localparam logic ANY_MERGED = fpnew_pkg::any_enabled_multi(FmtUnitTypes, FpFmtMask);
    localparam logic IS_FIRST_MERGED =
        fpnew_pkg::is_first_enabled_multi(fpnew_pkg::fp_format_e'(fmt), FmtUnitTypes, FpFmtMask);

    // Generate slice only if format enabled
    if (FpFmtMask[fmt] && (FmtUnitTypes[fmt] == fpnew_pkg::PARALLEL)) begin : active_format

      logic in_valid;

      assign in_valid = in_valid_i & (dst_fmt_i == fmt); // enable selected format

      // Forward masks related to the right SIMD lane
      localparam int unsigned INTERNAL_LANES = fpnew_pkg::num_lanes(Width, fpnew_pkg::fp_format_e'(fmt), EnableVectors);
      logic [INTERNAL_LANES-1:0] mask_slice;
      always_comb for (int b = 0; b < INTERNAL_LANES; b++) mask_slice[b] = simd_mask_i[(NUM_LANES/INTERNAL_LANES)*b];

      fpnew_opgroup_fmt_slice #(
        .OpGroup       ( OpGroup                      ),
        .FpFormat      ( fpnew_pkg::fp_format_e'(fmt) ),
        .Width         ( Width                        ),
        .EnableVectors ( EnableVectors                ),
        .NumPipeRegs   ( FmtPipeRegs[fmt]             ),
        .PipeConfig    ( PipeConfig                   ),
        .TagType       ( TagType                      ),
        .TrueSIMDClass ( TrueSIMDClass                )
      ) i_fmt_slice (
        .clk_i,
        .rst_ni,
        .operands_i     ( operands_i               ),
        .is_boxed_i     ( is_boxed_i[fmt]          ),
        .rnd_mode_i,
        .op_i,
        .op_mod_i,
        .vectorial_op_i,
        .tag_i,
        .simd_mask_i    ( mask_slice               ),
        .in_valid_i     ( in_valid                 ),
        .in_ready_o     ( fmt_in_ready[fmt]        ),
        .flush_i,
        .result_o       ( fmt_outputs[fmt].result  ),
        .status_o       ( fmt_outputs[fmt].status  ),
        .extension_bit_o( fmt_outputs[fmt].ext_bit ),
        .tag_o          ( fmt_outputs[fmt].tag     ),
        .out_valid_o    ( fmt_out_valid[fmt]       ),
        .out_ready_i    ( fmt_out_ready[fmt]       ),
        .busy_o         ( fmt_busy[fmt]            ),
        .reg_ena_i      ( '0                       )
      );
    // If the format wants to use merged ops, tie off the dangling ones not used here
    end else if (FpFmtMask[fmt] && ANY_MERGED && !IS_FIRST_MERGED) begin : merged_unused

      localparam FMT = fpnew_pkg::get_first_enabled_multi(FmtUnitTypes, FpFmtMask);
      // Ready is split up into formats
      assign fmt_in_ready[fmt]  = fmt_in_ready[int'(FMT)];

      assign fmt_out_valid[fmt] = 1'b0; // don't emit values
      assign fmt_busy[fmt]      = 1'b0; // never busy
      // Outputs are don't care
      assign fmt_outputs[fmt].result  = '{default: fpnew_pkg::DONT_CARE};
      assign fmt_outputs[fmt].status  = '{default: fpnew_pkg::DONT_CARE};
      assign fmt_outputs[fmt].ext_bit = fpnew_pkg::DONT_CARE;
      assign fmt_outputs[fmt].tag     = TagType'(fpnew_pkg::DONT_CARE);

    // Tie off disabled formats
    end else if (!FpFmtMask[fmt] || (FmtUnitTypes[fmt] == fpnew_pkg::DISABLED)) begin : disable_fmt
      assign fmt_in_ready[fmt]  = 1'b0; // don't accept operations
      assign fmt_out_valid[fmt] = 1'b0; // don't emit values
      assign fmt_busy[fmt]      = 1'b0; // never busy
      // Outputs are don't care
      assign fmt_outputs[fmt].result  = '{default: fpnew_pkg::DONT_CARE};
      assign fmt_outputs[fmt].status  = '{default: fpnew_pkg::DONT_CARE};
      assign fmt_outputs[fmt].ext_bit = fpnew_pkg::DONT_CARE;
      assign fmt_outputs[fmt].tag     = TagType'(fpnew_pkg::DONT_CARE);
    end
  end

  // ----------------------
  // Generate Merged Slice
  // ----------------------
  if (fpnew_pkg::any_enabled_multi(FmtUnitTypes, FpFmtMask)) begin : gen_merged_slice

    localparam FMT = fpnew_pkg::get_first_enabled_multi(FmtUnitTypes, FpFmtMask);
    localparam REG = fpnew_pkg::get_num_regs_multi(FmtPipeRegs, FmtUnitTypes, FpFmtMask);

    logic in_valid;

    assign in_valid = in_valid_i & (FmtUnitTypes[dst_fmt_i] == fpnew_pkg::MERGED);

    fpnew_opgroup_multifmt_slice #(
      .OpGroup       ( OpGroup          ),
      .Width         ( Width            ),
      .FpFmtConfig   ( FpFmtMask        ),
      .IntFmtConfig  ( IntFmtMask       ),
      .EnableVectors ( EnableVectors    ),
      .PulpDivsqrt   ( PulpDivsqrt      ),
      .NumPipeRegs   ( REG              ),
      .PipeConfig    ( PipeConfig       ),
      .TagType       ( TagType          )
    ) i_multifmt_slice (
      .clk_i,
      .rst_ni,
      .operands_i,
      .is_boxed_i,
      .rnd_mode_i,
      .op_i,
      .op_mod_i,
      .src_fmt_i,
      .dst_fmt_i,
      .int_fmt_i,
      .vectorial_op_i,
      .tag_i,
      .simd_mask_i     ( simd_mask_i              ),
      .in_valid_i      ( in_valid                 ),
      .in_ready_o      ( fmt_in_ready[FMT]        ),
      .flush_i,
      .result_o        ( fmt_outputs[FMT].result  ),
      .status_o        ( fmt_outputs[FMT].status  ),
      .extension_bit_o ( fmt_outputs[FMT].ext_bit ),
      .tag_o           ( fmt_outputs[FMT].tag     ),
      .out_valid_o     ( fmt_out_valid[FMT]       ),
      .out_ready_i     ( fmt_out_ready[FMT]       ),
      .busy_o          ( fmt_busy[FMT]            ),
      .reg_ena_i       ( '0                       )
    );

  end

  // ------------------
  // Arbitrate Outputs
  // ------------------
  output_t arbiter_output;

  // Round-Robin arbiter to decide which result to use
  rr_arb_tree #(
    .NumIn     ( NUM_FORMATS ),
    .DataType  ( output_t    ),
    .AxiVldRdy ( 1'b1        )
  ) i_arbiter (
    .clk_i,
    .rst_ni,
    .flush_i,
    .rr_i   ( '0             ),
    .req_i  ( fmt_out_valid  ),
    .gnt_o  ( fmt_out_ready  ),
    .data_i ( fmt_outputs    ),
    .gnt_i  ( out_ready_i    ),
    .req_o  ( out_valid_o    ),
    .data_o ( arbiter_output ),
    .idx_o  ( /* unused */   )
  );

  // Unpack output
  assign result_o        = arbiter_output.result;
  assign status_o        = arbiter_output.status;
  assign extension_bit_o = arbiter_output.ext_bit;
  assign tag_o           = arbiter_output.tag;

  assign busy_o = (| fmt_busy);

endmodule
/*Copyright 2020-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

module gated_clk_cell(
  clk_in,
  global_en,
  module_en,
  local_en,
  external_en,
  pad_yy_icg_scan_en,
  clk_out
);

input  clk_in;
input  global_en;
input  module_en;
input  local_en;
input  external_en;
input  pad_yy_icg_scan_en;
output clk_out;

wire   clk_en_bf_latch;
wire   SE;

assign clk_en_bf_latch = (global_en && (module_en || local_en)) || external_en ;

// SE driven from primary input, held constant
assign SE	       = pad_yy_icg_scan_en;

// //   &Connect(    .clk_in           (clk_in), @50
// //                .SE               (SE), @51
// //                .external_en      (clk_en_bf_latch), @52
// //                .clk_out          (clk_out) @53
// //                ) ; @54

assign clk_out = clk_in;

endmodule
/*Copyright 2020-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// &ModuleBeg; @23
module pa_fdsu_ctrl(
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

// &Ports; @24
input           cp0_fpu_icg_en;
input           cp0_yy_clk_en;
input           cpurst_b;
input           ctrl_fdsu_ex1_sel;
input           ctrl_xx_ex1_cmplt_dp;
input           ctrl_xx_ex1_inst_vld;
input           ctrl_xx_ex1_stall;
input           ctrl_xx_ex1_warm_up;
input           ctrl_xx_ex2_warm_up;
input           ctrl_xx_ex3_warm_up;
input           ex1_div;
input   [12:0]  ex1_expnt_adder_op0;
input           ex1_of_result_lfn;
input           ex1_op0_id;
input           ex1_op0_norm;
input           ex1_op1_id_vld;
input           ex1_op1_norm;
input   [12:0]  ex1_oper_id_expnt;
input           ex1_result_sign;
input   [2 :0]  ex1_rm;
input           ex1_sqrt;
input           ex1_srt_skip;
input           ex2_of;
input           ex2_potnt_of;
input           ex2_potnt_uf;
input           ex2_result_inf;
input           ex2_result_lfn;
input           ex2_rslt_denorm;
input   [9 :0]  ex2_srt_expnt_rst;
input           ex2_uf;
input           ex2_uf_srt_skip;
input   [9 :0]  ex3_expnt_adjust_result;
input           ex3_rslt_denorm;
input           forever_cpuclk;
input           frbus_fdsu_wb_grant;
input   [4 :0]  idu_fpu_ex1_dst_freg;
input   [2 :0]  idu_fpu_ex1_eu_sel;
input           pad_yy_icg_scan_en;
input           rtu_xx_ex1_cancel;
input           rtu_xx_ex2_cancel;
input           rtu_yy_xx_async_flush;
input           rtu_yy_xx_flush;
input           srt_remainder_zero;
output          ex1_op1_sel;
output  [12:0]  ex1_oper_id_expnt_f;
output          ex1_pipedown;
output          ex1_pipedown_gate;
output          ex1_save_op0;
output          ex1_save_op0_gate;
output  [9 :0]  ex2_expnt_adder_op0;
output          ex2_pipe_clk;
output          ex2_pipedown;
output          ex2_srt_first_round;
output          ex3_pipedown;
output          fdsu_ex1_sel;
output  [4 :0]  fdsu_fpu_debug_info;
output          fdsu_fpu_ex1_cmplt;
output          fdsu_fpu_ex1_cmplt_dp;
output          fdsu_fpu_ex1_stall;
output          fdsu_fpu_no_op;
output          fdsu_frbus_wb_vld;
output          fdsu_yy_div;
output  [9 :0]  fdsu_yy_expnt_rst;
output          fdsu_yy_of;
output          fdsu_yy_of_rm_lfn;
output          fdsu_yy_op0_norm;
output          fdsu_yy_op1_norm;
output          fdsu_yy_potnt_of;
output          fdsu_yy_potnt_uf;
output          fdsu_yy_result_inf;
output          fdsu_yy_result_lfn;
output          fdsu_yy_result_sign;
output  [2 :0]  fdsu_yy_rm;
output          fdsu_yy_rslt_denorm;
output          fdsu_yy_sqrt;
output          fdsu_yy_uf;
output  [4 :0]  fdsu_yy_wb_freg;
output          srt_sm_on;

// &Regs; @25
reg             ex2_srt_first_round;
reg     [2 :0]  fdsu_cur_state;
reg             fdsu_div;
reg     [9 :0]  fdsu_expnt_rst;
reg     [2 :0]  fdsu_next_state;
reg             fdsu_of;
reg             fdsu_of_rm_lfn;
reg             fdsu_potnt_of;
reg             fdsu_potnt_uf;
reg             fdsu_result_inf;
reg             fdsu_result_lfn;
reg             fdsu_result_sign;
reg     [2 :0]  fdsu_rm;
reg             fdsu_sqrt;
reg             fdsu_uf;
reg     [4 :0]  fdsu_wb_freg;
reg             fdsu_yy_rslt_denorm;
reg     [4 :0]  srt_cnt;
reg     [1 :0]  wb_cur_state;
reg     [1 :0]  wb_nxt_state;

// &Wires; @26
wire            cp0_fpu_icg_en;
wire            cp0_yy_clk_en;
wire            cpurst_b;
wire            ctrl_fdsu_ex1_sel;
wire            ctrl_fdsu_ex1_stall;
wire            ctrl_fdsu_wb_vld;
wire            ctrl_iter_start;
wire            ctrl_iter_start_gate;
wire            ctrl_pack;
wire            ctrl_result_vld;
wire            ctrl_round;
wire            ctrl_sm_cmplt;
wire            ctrl_sm_ex1;
wire            ctrl_sm_idle;
wire            ctrl_sm_start;
wire            ctrl_sm_start_gate;
wire            ctrl_srt_idle;
wire            ctrl_srt_itering;
wire            ctrl_wb_idle;
wire            ctrl_wb_sm_cmplt;
wire            ctrl_wb_sm_ex2;
wire            ctrl_wb_sm_idle;
wire            ctrl_wfi2;
wire            ctrl_wfwb;
wire            ctrl_xx_ex1_cmplt_dp;
wire            ctrl_xx_ex1_inst_vld;
wire            ctrl_xx_ex1_stall;
wire            ctrl_xx_ex1_warm_up;
wire            ctrl_xx_ex2_warm_up;
wire            ctrl_xx_ex3_warm_up;
wire            ex1_div;
wire    [12:0]  ex1_expnt_adder_op0;
wire            ex1_of_result_lfn;
wire            ex1_op0_id;
wire            ex1_op1_id_vld;
wire            ex1_op1_sel;
wire    [12:0]  ex1_oper_id_expnt;
wire    [12:0]  ex1_oper_id_expnt_f;
wire            ex1_pipe_clk;
wire            ex1_pipe_clk_en;
wire            ex1_pipedown;
wire            ex1_pipedown_gate;
wire            ex1_result_sign;
wire    [2 :0]  ex1_rm;
wire            ex1_save_op0;
wire            ex1_save_op0_gate;
wire            ex1_sqrt;
wire            ex1_srt_skip;
wire    [4 :0]  ex1_wb_freg;
wire    [9 :0]  ex2_expnt_adder_op0;
wire            ex2_of;
wire            ex2_pipe_clk;
wire            ex2_pipe_clk_en;
wire            ex2_pipedown;
wire            ex2_potnt_of;
wire            ex2_potnt_uf;
wire            ex2_result_inf;
wire            ex2_result_lfn;
wire            ex2_rslt_denorm;
wire    [9 :0]  ex2_srt_expnt_rst;
wire            ex2_uf;
wire            ex2_uf_srt_skip;
wire    [9 :0]  ex3_expnt_adjust_result;
wire            ex3_pipedown;
wire            ex3_rslt_denorm;
wire            expnt_rst_clk;
wire            expnt_rst_clk_en;
wire            fdsu_busy;
wire            fdsu_clk;
wire            fdsu_clk_en;
wire            fdsu_dn_stall;
wire            fdsu_ex1_inst_vld;
wire            fdsu_ex1_res_vld;
wire            fdsu_ex1_sel;
wire            fdsu_flush;
wire    [4 :0]  fdsu_fpu_debug_info;
wire            fdsu_fpu_ex1_cmplt;
wire            fdsu_fpu_ex1_cmplt_dp;
wire            fdsu_fpu_ex1_stall;
wire            fdsu_fpu_no_op;
wire            fdsu_frbus_wb_vld;
wire            fdsu_op0_norm;
wire            fdsu_op1_norm;
wire            fdsu_wb_grant;
wire            fdsu_yy_div;
wire    [9 :0]  fdsu_yy_expnt_rst;
wire            fdsu_yy_of;
wire            fdsu_yy_of_rm_lfn;
wire            fdsu_yy_op0_norm;
wire            fdsu_yy_op1_norm;
wire            fdsu_yy_potnt_of;
wire            fdsu_yy_potnt_uf;
wire            fdsu_yy_result_inf;
wire            fdsu_yy_result_lfn;
wire            fdsu_yy_result_sign;
wire    [2 :0]  fdsu_yy_rm;
wire            fdsu_yy_sqrt;
wire            fdsu_yy_uf;
wire    [4 :0]  fdsu_yy_wb_freg;
wire            forever_cpuclk;
wire            frbus_fdsu_wb_grant;
wire    [4 :0]  idu_fpu_ex1_dst_freg;
wire    [2 :0]  idu_fpu_ex1_eu_sel;
wire            pad_yy_icg_scan_en;
wire            rtu_xx_ex1_cancel;
wire            rtu_xx_ex2_cancel;
wire            rtu_yy_xx_async_flush;
wire            rtu_yy_xx_flush;
wire    [4 :0]  srt_cnt_ini;
wire            srt_cnt_zero;
wire            srt_last_round;
wire            srt_remainder_zero;
wire            srt_skip;
wire            srt_sm_on;


//==========================================================
//                       Input Signal
//==========================================================
assign ex1_wb_freg[4:0] = idu_fpu_ex1_dst_freg[4:0];
assign fdsu_ex1_inst_vld = ctrl_xx_ex1_inst_vld && ctrl_fdsu_ex1_sel;
assign fdsu_ex1_sel      = idu_fpu_ex1_eu_sel[2];
// &Force("input", "idu_fpu_ex1_eu_sel"); &Force("bus", "idu_fpu_ex1_eu_sel", 2, 0); @34

//==========================================================
//                 FDSU Main State Machine
//==========================================================
assign fdsu_ex1_res_vld  = fdsu_ex1_inst_vld && ex1_srt_skip;
assign fdsu_wb_grant = frbus_fdsu_wb_grant;

assign ctrl_iter_start = ctrl_sm_start && !fdsu_dn_stall
                      || ctrl_wfi2;
assign ctrl_iter_start_gate = ctrl_sm_start_gate && !fdsu_dn_stall
                           || ctrl_wfi2;
assign ctrl_sm_start = fdsu_ex1_inst_vld && ctrl_srt_idle
                   && !ex1_srt_skip;
assign ctrl_sm_start_gate = fdsu_ex1_inst_vld && ctrl_srt_idle;

assign srt_last_round = (srt_skip ||
                         srt_remainder_zero ||
                         srt_cnt_zero)      &&
                         ctrl_srt_itering;
assign srt_skip       =  ex2_of ||
                         ex2_uf_srt_skip;
assign srt_cnt_zero   = ~|srt_cnt[4:0];
assign fdsu_dn_stall  = ctrl_sm_start && ex1_op1_id_vld;

parameter IDLE  = 3'b000;
parameter WFI2  = 3'b001;
parameter ITER  = 3'b010;
parameter RND   = 3'b011;
parameter PACK  = 3'b100;
parameter WFWB  = 3'b101;

always @ (posedge fdsu_clk or negedge cpurst_b)
begin
  if (!cpurst_b)
    fdsu_cur_state[2:0] <= IDLE;
  else if (fdsu_flush)
    fdsu_cur_state[2:0] <= IDLE;
  else
    fdsu_cur_state[2:0] <= fdsu_next_state[2:0];
end

// &CombBeg; @76
always @( ctrl_sm_start
       or fdsu_dn_stall
       or srt_last_round
       or fdsu_cur_state[2:0]
       or fdsu_wb_grant)
begin
case (fdsu_cur_state[2:0])
  IDLE:
  begin
    if (ctrl_sm_start)
      if (fdsu_dn_stall)
        fdsu_next_state[2:0] = WFI2;
      else
        fdsu_next_state[2:0] = ITER;
    else
      fdsu_next_state[2:0] = IDLE;
  end
  WFI2:
    fdsu_next_state[2:0] = ITER;
  ITER:
  begin
    if (srt_last_round)
      fdsu_next_state[2:0] = RND;
    else
      fdsu_next_state[2:0] = ITER;
  end
  RND:
    fdsu_next_state[2:0] = PACK;
  PACK:
  begin
    if (fdsu_wb_grant)
      if (ctrl_sm_start)
        if (fdsu_dn_stall)
          fdsu_next_state[2:0] = WFI2;
        else
          fdsu_next_state[2:0] = ITER;
      else
        fdsu_next_state[2:0] = IDLE;
    else
      fdsu_next_state[2:0] = WFWB;
  end
  WFWB:
  begin
    if (fdsu_wb_grant)
      if (ctrl_sm_start)
        if (fdsu_dn_stall)
          fdsu_next_state[2:0] = WFI2;
        else
          fdsu_next_state[2:0] = ITER;
      else
        fdsu_next_state[2:0] = IDLE;
    else
      fdsu_next_state[2:0] = WFWB;
  end
  default:
    fdsu_next_state[2:0] = IDLE;
endcase
// &CombEnd; @128
end

assign ctrl_sm_idle     = fdsu_cur_state[2:0] == IDLE;
assign ctrl_wfi2        = fdsu_cur_state[2:0] == WFI2;
assign ctrl_srt_itering = fdsu_cur_state[2:0] == ITER;
assign ctrl_round       = fdsu_cur_state[2:0] == RND;
assign ctrl_pack        = fdsu_cur_state[2:0] == PACK;
assign ctrl_wfwb        = fdsu_cur_state[2:0] == WFWB;

assign ctrl_sm_cmplt    = ctrl_pack || ctrl_wfwb;
assign ctrl_srt_idle     = ctrl_sm_idle
                       || fdsu_wb_grant;
assign ctrl_sm_ex1      = ctrl_srt_idle || ctrl_wfi2;

//==========================================================
//                    Iteration Counter
//==========================================================
always @ (posedge fdsu_clk)
begin
  if (fdsu_flush)
    srt_cnt[4:0] <= 5'b0;
  else if (ctrl_iter_start)
    srt_cnt[4:0] <= srt_cnt_ini[4:0];
  else if (ctrl_srt_itering)
    srt_cnt[4:0] <= srt_cnt[4:0] - 5'b1;
  else
    srt_cnt[4:0] <= srt_cnt[4:0];
end

//srt_cnt_ini[4:0]
//For Double, initial is 5'b11100('d28), calculate 29 round
//For Single, initial is 5'b01110('d14), calculate 15 round
assign srt_cnt_ini[4:0] = 5'b01110;

//fdsu srt first round signal
//For srt calculate special use
always @(posedge fdsu_clk or negedge cpurst_b)
begin
  if(!cpurst_b)
    ex2_srt_first_round <= 1'b0;
  else if(fdsu_flush)
    ex2_srt_first_round <= 1'b0;
  else if(ex1_pipedown)
    ex2_srt_first_round <= 1'b1;
  else
    ex2_srt_first_round <= 1'b0;
end

//==========================================================
//                 Write Back State Machine
//==========================================================
parameter WB_IDLE  = 2'b00,
          WB_EX2   = 2'b10,
          WB_CMPLT = 2'b01;

always @ (posedge fdsu_clk or negedge cpurst_b)
begin
  if (!cpurst_b)
    wb_cur_state[1:0] <= WB_IDLE;
  else if (fdsu_flush)
    wb_cur_state[1:0] <= WB_IDLE;
  else
    wb_cur_state[1:0] <= wb_nxt_state[1:0];
end

// &CombBeg; @215
always @( ctrl_fdsu_wb_vld
       or fdsu_dn_stall
       or ctrl_xx_ex1_stall
       or fdsu_ex1_inst_vld
       or ctrl_iter_start
       or fdsu_ex1_res_vld
       or wb_cur_state[1:0])
begin
  case(wb_cur_state[1:0])
    WB_IDLE:
      if (fdsu_ex1_inst_vld)
        if (ctrl_xx_ex1_stall || fdsu_ex1_res_vld || fdsu_dn_stall)
          wb_nxt_state[1:0] = WB_IDLE;
        else
          wb_nxt_state[1:0] = WB_EX2;
      else
        wb_nxt_state[1:0] = WB_IDLE;
    WB_EX2:
      // if (ctrl_xx_ex2_stall)
      //   wb_nxt_state[1:0] = WB_EX2;
      // else
        if (ctrl_fdsu_wb_vld)
          if (ctrl_iter_start && !ctrl_xx_ex1_stall)
            wb_nxt_state[1:0] = WB_EX2;
          else
            wb_nxt_state[1:0] = WB_IDLE;
        else
          wb_nxt_state[1:0] = WB_CMPLT;
    WB_CMPLT:
      if (ctrl_fdsu_wb_vld)
        if (ctrl_iter_start && !ctrl_xx_ex1_stall)
          wb_nxt_state[1:0] = WB_EX2;
        else
          wb_nxt_state[1:0] = WB_IDLE;
      else
        wb_nxt_state[1:0] = WB_CMPLT;
    default:
      wb_nxt_state[1:0] = WB_IDLE;
  endcase
// &CombEnd; @247
end

assign ctrl_wb_idle  = wb_cur_state[1:0] == WB_IDLE
                       || wb_cur_state[1:0] == WB_CMPLT && ctrl_fdsu_wb_vld;
assign ctrl_wb_sm_idle  = wb_cur_state[1:0] == WB_IDLE;
assign ctrl_wb_sm_ex2   = wb_cur_state[1:0] == WB_EX2;
assign ctrl_wb_sm_cmplt = wb_cur_state[1:0] == WB_EX2
                       || wb_cur_state[1:0] == WB_CMPLT;

assign ctrl_result_vld  = ctrl_sm_cmplt && ctrl_wb_sm_cmplt;
assign ctrl_fdsu_wb_vld = ctrl_result_vld && frbus_fdsu_wb_grant;

assign ctrl_fdsu_ex1_stall = fdsu_ex1_inst_vld && !ctrl_sm_ex1 && !ctrl_wb_idle
                          || fdsu_ex1_inst_vld && fdsu_dn_stall;

//==========================================================
//                          Flops
//==========================================================
always @(posedge ex1_pipe_clk)
begin
  if(ex1_pipedown)
  begin
    fdsu_wb_freg[4:0]    <= ex1_wb_freg[4:0];
    fdsu_result_sign     <= ex1_result_sign;
    fdsu_of_rm_lfn       <= ex1_of_result_lfn;
    fdsu_div             <= ex1_div;
    fdsu_sqrt            <= ex1_sqrt;
    fdsu_rm[2:0]         <= ex1_rm[2:0];
  end
  else
  begin
    fdsu_wb_freg[4:0]    <= fdsu_wb_freg[4:0];
    fdsu_result_sign     <= fdsu_result_sign;
    fdsu_of_rm_lfn       <= fdsu_of_rm_lfn;
    fdsu_div             <= fdsu_div;
    fdsu_sqrt            <= fdsu_sqrt;
    fdsu_rm[2:0]         <= fdsu_rm[2:0];
  end
end

// In 906 FDSU, if one op0/1 is not norm, it will not enter EX2.
assign fdsu_op0_norm = 1'b1;
assign fdsu_op1_norm = 1'b1;
// &Force("input", "ex1_op0_norm"); @337
// &Force("input", "ex1_op1_norm"); @338

// fdsu_expnt_rst is used to save:
//  1. op0 denormal expnt;
//  2. op0 expnt;
//  3. result expnt.
// &Force("bus", "ex1_oper_id_expnt", 12, 0); @378
// &Force("bus", "ex1_expnt_adder_op0", 12, 0); @379


always @ (posedge expnt_rst_clk)
begin
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
end

assign ex1_oper_id_expnt_f[12:0] = {3'b1, fdsu_expnt_rst[9:0]};

always @ (posedge expnt_rst_clk)
begin
  if (ex2_pipedown)
    fdsu_yy_rslt_denorm <= ex2_rslt_denorm;
  else if (ex3_pipedown)
    fdsu_yy_rslt_denorm <= ex3_rslt_denorm;
  else
    fdsu_yy_rslt_denorm <= fdsu_yy_rslt_denorm;
end
// &Force("output", "fdsu_yy_rslt_denorm"); @440

// EX2 signal used in EX3 & EX4
always @ (posedge ex2_pipe_clk)
begin
  if (ex2_pipedown)
  begin
    fdsu_result_inf <= ex2_result_inf;
    fdsu_result_lfn <= ex2_result_lfn;
    fdsu_of         <= ex2_of;
    fdsu_uf         <= ex2_uf;
    fdsu_potnt_of   <= ex2_potnt_of;
    fdsu_potnt_uf   <= ex2_potnt_uf;
  end
  else
  begin
    fdsu_result_inf <= fdsu_result_inf;
    fdsu_result_lfn <= fdsu_result_lfn;
    fdsu_of         <= fdsu_of;
    fdsu_uf         <= fdsu_uf;
    fdsu_potnt_of   <= fdsu_potnt_of;
    fdsu_potnt_uf   <= fdsu_potnt_uf;
  end
end

//==========================================================
//                          Flush
//==========================================================
assign fdsu_flush = rtu_xx_ex1_cancel && ctrl_wb_idle
                 || rtu_xx_ex2_cancel && ctrl_wb_sm_ex2
                 || ctrl_xx_ex1_warm_up
                 || rtu_yy_xx_async_flush;

//==========================================================
//                           ICG
//==========================================================
assign fdsu_busy = fdsu_ex1_inst_vld
                || !ctrl_sm_idle
                || !ctrl_wb_sm_idle;
assign fdsu_clk_en = fdsu_busy
                  || !ctrl_sm_idle
                  || rtu_yy_xx_flush;
// &Instance("gated_clk_cell", "x_fdsu_clk"); @514
gated_clk_cell  x_fdsu_clk (
  .clk_in             (forever_cpuclk    ),
  .clk_out            (fdsu_clk          ),
  .external_en        (1'b0              ),
  .global_en          (cp0_yy_clk_en     ),
  .local_en           (fdsu_clk_en       ),
  .module_en          (cp0_fpu_icg_en    ),
  .pad_yy_icg_scan_en (pad_yy_icg_scan_en)
);

// &Connect(.clk_in      (forever_cpuclk), @515
//          .external_en (1'b0), @516
//          .global_en   (cp0_yy_clk_en), @517
//          .module_en   (cp0_fpu_icg_en), @518
//          .local_en    (fdsu_clk_en), @519
//          .clk_out     (fdsu_clk)); @520

assign ex1_pipe_clk_en = ex1_pipedown_gate;
// &Instance("gated_clk_cell","x_ex1_pipe_clk"); @523
gated_clk_cell  x_ex1_pipe_clk (
  .clk_in             (forever_cpuclk    ),
  .clk_out            (ex1_pipe_clk      ),
  .external_en        (1'b0              ),
  .global_en          (cp0_yy_clk_en     ),
  .local_en           (ex1_pipe_clk_en   ),
  .module_en          (cp0_fpu_icg_en    ),
  .pad_yy_icg_scan_en (pad_yy_icg_scan_en)
);

// &Connect( .clk_in         (forever_cpuclk), @524
//           .clk_out        (ex1_pipe_clk),//Out Clock @525
//           .external_en    (1'b0), @526
//           .global_en      (cp0_yy_clk_en), @527
//           .local_en       (ex1_pipe_clk_en),//Local Condition @528
//           .module_en      (cp0_fpu_icg_en) @529
//         ); @530

assign ex2_pipe_clk_en = ex2_pipedown;
// &Instance("gated_clk_cell","x_ex2_pipe_clk"); @533
gated_clk_cell  x_ex2_pipe_clk (
  .clk_in             (forever_cpuclk    ),
  .clk_out            (ex2_pipe_clk      ),
  .external_en        (1'b0              ),
  .global_en          (cp0_yy_clk_en     ),
  .local_en           (ex2_pipe_clk_en   ),
  .module_en          (cp0_fpu_icg_en    ),
  .pad_yy_icg_scan_en (pad_yy_icg_scan_en)
);

// &Connect( .clk_in         (forever_cpuclk), @534
//           .clk_out        (ex2_pipe_clk),//Out Clock @535
//           .external_en    (1'b0), @536
//           .global_en      (cp0_yy_clk_en), @537
//           .local_en       (ex2_pipe_clk_en),//Local Condition @538
//           .module_en      (cp0_fpu_icg_en) @539
//         ); @540
// &Force("output", "ex2_pipe_clk"); @541

assign expnt_rst_clk_en = ex1_save_op0_gate
                       || ex1_pipedown_gate
                       || ex2_pipedown
                       || ex3_pipedown;
// &Instance("gated_clk_cell", "x_expnt_rst_clk"); @547
gated_clk_cell  x_expnt_rst_clk (
  .clk_in             (forever_cpuclk    ),
  .clk_out            (expnt_rst_clk     ),
  .external_en        (1'b0              ),
  .global_en          (cp0_yy_clk_en     ),
  .local_en           (expnt_rst_clk_en  ),
  .module_en          (cp0_fpu_icg_en    ),
  .pad_yy_icg_scan_en (pad_yy_icg_scan_en)
);

// &Connect(.clk_in      (forever_cpuclk), @548
//          .external_en (1'b0), @549
//          .global_en   (cp0_yy_clk_en), @550
//          .module_en   (cp0_fpu_icg_en), @551
//          .local_en    (expnt_rst_clk_en), @552
//          .clk_out     (expnt_rst_clk)); @553

//==========================================================
//                      Output Signal
//==========================================================
assign fdsu_yy_wb_freg[4:0]    = fdsu_wb_freg[4:0];
assign fdsu_yy_result_sign     = fdsu_result_sign;
assign fdsu_yy_op0_norm        = fdsu_op0_norm;
assign fdsu_yy_op1_norm        = fdsu_op1_norm;
assign fdsu_yy_of_rm_lfn       = fdsu_of_rm_lfn;
assign fdsu_yy_div             = fdsu_div;
assign fdsu_yy_sqrt            = fdsu_sqrt;
assign fdsu_yy_rm[2:0]         = fdsu_rm[2:0];

assign fdsu_yy_expnt_rst[9:0] = fdsu_expnt_rst[9:0];
assign ex2_expnt_adder_op0[9:0] = fdsu_expnt_rst[9:0];

assign fdsu_yy_result_inf = fdsu_result_inf;
assign fdsu_yy_result_lfn = fdsu_result_lfn;
assign fdsu_yy_of         = fdsu_of;
assign fdsu_yy_uf         = fdsu_uf;
assign fdsu_yy_potnt_of   = fdsu_potnt_of;
assign fdsu_yy_potnt_uf   = fdsu_potnt_uf;

assign ex1_pipedown = ctrl_iter_start || ctrl_xx_ex1_warm_up;
assign ex1_pipedown_gate = ctrl_iter_start_gate || ctrl_xx_ex1_warm_up;
assign ex2_pipedown = ctrl_srt_itering && srt_last_round || ctrl_xx_ex2_warm_up;
assign ex3_pipedown = ctrl_round || ctrl_xx_ex3_warm_up;
// &Force("output", "ex1_pipedown"); @589
// &Force("output", "ex1_pipedown_gate"); @590
// &Force("output", "ex2_pipedown"); @591
// &Force("output", "ex3_pipedown"); @592

assign srt_sm_on = ctrl_srt_itering;

assign fdsu_fpu_ex1_cmplt = fdsu_ex1_inst_vld;
assign fdsu_fpu_ex1_cmplt_dp =  ctrl_xx_ex1_cmplt_dp && idu_fpu_ex1_eu_sel[2];
assign fdsu_fpu_ex1_stall = ctrl_fdsu_ex1_stall;
assign fdsu_frbus_wb_vld  = ctrl_result_vld;
// &Force("bus","idu_fpu_ex1_eu_sel",2,0); @600
assign fdsu_fpu_no_op = !fdsu_busy;
assign ex1_op1_sel = ctrl_wfi2;
assign ex1_save_op0 = ctrl_sm_start && ex1_op0_id && ex1_op1_id_vld;
assign ex1_save_op0_gate = ctrl_sm_start_gate && ex1_op0_id && ex1_op1_id_vld;
// &Force("output", "ex1_save_op0"); @605
// &Force("output", "ex1_save_op0_gate"); @606

assign fdsu_fpu_debug_info[4:0] = {wb_cur_state[1:0], fdsu_cur_state[2:0]};

// &ModuleEnd; @610
endmodule



/*Copyright 2020-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// &ModuleBeg; @23
module pa_fdsu_ff1(
  fanc_shift_num,
  frac_bin_val,
  frac_num
);

// &Ports; @24
input   [51:0]  frac_num;
output  [51:0]  fanc_shift_num;
output  [12:0]  frac_bin_val;

// &Regs; @25
reg     [51:0]  fanc_shift_num;
reg     [12:0]  frac_bin_val;

// &Wires; @26
wire    [51:0]  frac_num;


// &CombBeg; @28
always @( frac_num[51:0])
begin
casez(frac_num[51:0])
  52'b1???????????????????????????????????????????????????: frac_bin_val[12:0] = 13'h0;
  52'b01??????????????????????????????????????????????????: frac_bin_val[12:0] = 13'h1fff;
  52'b001?????????????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ffe;
  52'b0001????????????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ffd;
  52'b00001???????????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ffc;
  52'b000001??????????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ffb;
  52'b0000001?????????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ffa;
  52'b00000001????????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff9;
  52'b000000001???????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff8;
  52'b0000000001??????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff7;
  52'b00000000001?????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff6;
  52'b000000000001????????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff5;
  52'b0000000000001???????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff4;
  52'b00000000000001??????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff3;
  52'b000000000000001?????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff2;
  52'b0000000000000001????????????????????????????????????: frac_bin_val[12:0] = 13'h1ff1;
  52'b00000000000000001???????????????????????????????????: frac_bin_val[12:0] = 13'h1ff0;
  52'b000000000000000001??????????????????????????????????: frac_bin_val[12:0] = 13'h1fef;
  52'b0000000000000000001?????????????????????????????????: frac_bin_val[12:0] = 13'h1fee;
  52'b00000000000000000001????????????????????????????????: frac_bin_val[12:0] = 13'h1fed;
  52'b000000000000000000001???????????????????????????????: frac_bin_val[12:0] = 13'h1fec;
  52'b0000000000000000000001??????????????????????????????: frac_bin_val[12:0] = 13'h1feb;
  52'b00000000000000000000001?????????????????????????????: frac_bin_val[12:0] = 13'h1fea;
  52'b000000000000000000000001????????????????????????????: frac_bin_val[12:0] = 13'h1fe9;
  52'b0000000000000000000000001???????????????????????????: frac_bin_val[12:0] = 13'h1fe8;
  52'b00000000000000000000000001??????????????????????????: frac_bin_val[12:0] = 13'h1fe7;
  52'b000000000000000000000000001?????????????????????????: frac_bin_val[12:0] = 13'h1fe6;
  52'b0000000000000000000000000001????????????????????????: frac_bin_val[12:0] = 13'h1fe5;
  52'b00000000000000000000000000001???????????????????????: frac_bin_val[12:0] = 13'h1fe4;
  52'b000000000000000000000000000001??????????????????????: frac_bin_val[12:0] = 13'h1fe3;
  52'b0000000000000000000000000000001?????????????????????: frac_bin_val[12:0] = 13'h1fe2;
  52'b00000000000000000000000000000001????????????????????: frac_bin_val[12:0] = 13'h1fe1;
  52'b000000000000000000000000000000001???????????????????: frac_bin_val[12:0] = 13'h1fe0;
  52'b0000000000000000000000000000000001??????????????????: frac_bin_val[12:0] = 13'h1fdf;
  52'b00000000000000000000000000000000001?????????????????: frac_bin_val[12:0] = 13'h1fde;
  52'b000000000000000000000000000000000001????????????????: frac_bin_val[12:0] = 13'h1fdd;
  52'b0000000000000000000000000000000000001???????????????: frac_bin_val[12:0] = 13'h1fdc;
  52'b00000000000000000000000000000000000001??????????????: frac_bin_val[12:0] = 13'h1fdb;
  52'b000000000000000000000000000000000000001?????????????: frac_bin_val[12:0] = 13'h1fda;
  52'b0000000000000000000000000000000000000001????????????: frac_bin_val[12:0] = 13'h1fd9;
  52'b00000000000000000000000000000000000000001???????????: frac_bin_val[12:0] = 13'h1fd8;
  52'b000000000000000000000000000000000000000001??????????: frac_bin_val[12:0] = 13'h1fd7;
  52'b0000000000000000000000000000000000000000001?????????: frac_bin_val[12:0] = 13'h1fd6;
  52'b00000000000000000000000000000000000000000001????????: frac_bin_val[12:0] = 13'h1fd5;
  52'b000000000000000000000000000000000000000000001???????: frac_bin_val[12:0] = 13'h1fd4;
  52'b0000000000000000000000000000000000000000000001??????: frac_bin_val[12:0] = 13'h1fd3;
  52'b00000000000000000000000000000000000000000000001?????: frac_bin_val[12:0] = 13'h1fd2;
  52'b000000000000000000000000000000000000000000000001????: frac_bin_val[12:0] = 13'h1fd1;
  52'b0000000000000000000000000000000000000000000000001???: frac_bin_val[12:0] = 13'h1fd0;
  52'b00000000000000000000000000000000000000000000000001??: frac_bin_val[12:0] = 13'h1fcf;
  52'b000000000000000000000000000000000000000000000000001?: frac_bin_val[12:0] = 13'h1fce;
  52'b0000000000000000000000000000000000000000000000000001: frac_bin_val[12:0] = 13'h1fcd;
  52'b0000000000000000000000000000000000000000000000000000: frac_bin_val[12:0] = 13'h1fcc;
  default                                                 : frac_bin_val[12:0] = 13'h000;
endcase
// &CombEnd; @85
end

// &CombBeg; @87
always @( frac_num[51:0])
begin
casez(frac_num[51:0])
  52'b1???????????????????????????????????????????????????: fanc_shift_num[51:0] = frac_num[51:0];
  52'b01??????????????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[50:0],1'b0};
  52'b001?????????????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[49:0],2'b0};
  52'b0001????????????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[48:0],3'b0};
  52'b00001???????????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[47:0],4'b0};
  52'b000001??????????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[46:0],5'b0};
  52'b0000001?????????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[45:0],6'b0};
  52'b00000001????????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[44:0],7'b0};
  52'b000000001???????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[43:0],8'b0};
  52'b0000000001??????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[42:0],9'b0};
  52'b00000000001?????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[41:0],10'b0};
  52'b000000000001????????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[40:0],11'b0};
  52'b0000000000001???????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[39:0],12'b0};
  52'b00000000000001??????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[38:0],13'b0};
  52'b000000000000001?????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[37:0],14'b0};
  52'b0000000000000001????????????????????????????????????: fanc_shift_num[51:0] = {frac_num[36:0],15'b0};
  52'b00000000000000001???????????????????????????????????: fanc_shift_num[51:0] = {frac_num[35:0],16'b0};
  52'b000000000000000001??????????????????????????????????: fanc_shift_num[51:0] = {frac_num[34:0],17'b0};
  52'b0000000000000000001?????????????????????????????????: fanc_shift_num[51:0] = {frac_num[33:0],18'b0};
  52'b00000000000000000001????????????????????????????????: fanc_shift_num[51:0] = {frac_num[32:0],19'b0};
  52'b000000000000000000001???????????????????????????????: fanc_shift_num[51:0] = {frac_num[31:0],20'b0};
  52'b0000000000000000000001??????????????????????????????: fanc_shift_num[51:0] = {frac_num[30:0],21'b0};
  52'b00000000000000000000001?????????????????????????????: fanc_shift_num[51:0] = {frac_num[29:0],22'b0};
  52'b000000000000000000000001????????????????????????????: fanc_shift_num[51:0] = {frac_num[28:0],23'b0};
  52'b0000000000000000000000001???????????????????????????: fanc_shift_num[51:0] = {frac_num[27:0],24'b0};
  52'b00000000000000000000000001??????????????????????????: fanc_shift_num[51:0] = {frac_num[26:0],25'b0};
  52'b000000000000000000000000001?????????????????????????: fanc_shift_num[51:0] = {frac_num[25:0],26'b0};
  52'b0000000000000000000000000001????????????????????????: fanc_shift_num[51:0] = {frac_num[24:0],27'b0};
  52'b00000000000000000000000000001???????????????????????: fanc_shift_num[51:0] = {frac_num[23:0],28'b0};
  52'b000000000000000000000000000001??????????????????????: fanc_shift_num[51:0] = {frac_num[22:0],29'b0};
  52'b0000000000000000000000000000001?????????????????????: fanc_shift_num[51:0] = {frac_num[21:0],30'b0};
  52'b00000000000000000000000000000001????????????????????: fanc_shift_num[51:0] = {frac_num[20:0],31'b0};
  52'b000000000000000000000000000000001???????????????????: fanc_shift_num[51:0] = {frac_num[19:0],32'b0};
  52'b0000000000000000000000000000000001??????????????????: fanc_shift_num[51:0] = {frac_num[18:0],33'b0};
  52'b00000000000000000000000000000000001?????????????????: fanc_shift_num[51:0] = {frac_num[17:0],34'b0};
  52'b000000000000000000000000000000000001????????????????: fanc_shift_num[51:0] = {frac_num[16:0],35'b0};
  52'b0000000000000000000000000000000000001???????????????: fanc_shift_num[51:0] = {frac_num[15:0],36'b0};
  52'b00000000000000000000000000000000000001??????????????: fanc_shift_num[51:0] = {frac_num[14:0],37'b0};
  52'b000000000000000000000000000000000000001?????????????: fanc_shift_num[51:0] = {frac_num[13:0],38'b0};
  52'b0000000000000000000000000000000000000001????????????: fanc_shift_num[51:0] = {frac_num[12:0],39'b0};
  52'b00000000000000000000000000000000000000001???????????: fanc_shift_num[51:0] = {frac_num[11:0],40'b0};
  52'b000000000000000000000000000000000000000001??????????: fanc_shift_num[51:0] = {frac_num[10:0],41'b0};
  52'b0000000000000000000000000000000000000000001?????????: fanc_shift_num[51:0] = {frac_num[9:0],42'b0};
  52'b00000000000000000000000000000000000000000001????????: fanc_shift_num[51:0] = {frac_num[8:0],43'b0};
  52'b000000000000000000000000000000000000000000001???????: fanc_shift_num[51:0] = {frac_num[7:0],44'b0};
  52'b0000000000000000000000000000000000000000000001??????: fanc_shift_num[51:0] = {frac_num[6:0],45'b0};
  52'b00000000000000000000000000000000000000000000001?????: fanc_shift_num[51:0] = {frac_num[5:0],46'b0};
  52'b000000000000000000000000000000000000000000000001????: fanc_shift_num[51:0] = {frac_num[4:0],47'b0};
  52'b0000000000000000000000000000000000000000000000001???: fanc_shift_num[51:0] = {frac_num[3:0],48'b0};
  52'b00000000000000000000000000000000000000000000000001??: fanc_shift_num[51:0] = {frac_num[2:0],49'b0};
  52'b000000000000000000000000000000000000000000000000001?: fanc_shift_num[51:0] = {frac_num[1:0],50'b0};
  52'b0000000000000000000000000000000000000000000000000001: fanc_shift_num[51:0] = {frac_num[0:0],51'b0};
  52'b0000000000000000000000000000000000000000000000000000: fanc_shift_num[51:0] = {52'b0};
  default                                                 : fanc_shift_num[51:0] = {52'b0};
endcase
// &CombEnd; @144
end

// &ModuleEnd; @146
endmodule


/*Copyright 2020-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// &ModuleBeg; @23
module pa_fdsu_pack_single(
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

// &Ports; @24
input           fdsu_ex4_denorm_to_tiny_frac;
input   [25:0]  fdsu_ex4_frac;
input           fdsu_ex4_nx;
input   [1 :0]  fdsu_ex4_potnt_norm;
input           fdsu_ex4_result_nor;
input   [9 :0]  fdsu_yy_expnt_rst;
input           fdsu_yy_of;
input           fdsu_yy_of_rm_lfn;
input           fdsu_yy_potnt_of;
input           fdsu_yy_potnt_uf;
input           fdsu_yy_result_inf;
input           fdsu_yy_result_lfn;
input           fdsu_yy_result_sign;
input           fdsu_yy_rslt_denorm;
input           fdsu_yy_uf;
input   [4 :0]  fdsu_yy_wb_freg;
output  [31:0]  fdsu_frbus_data;
output  [4 :0]  fdsu_frbus_fflags;
output  [4 :0]  fdsu_frbus_freg;

// &Regs; @25
reg     [22:0]  ex4_frac_23;
reg     [31:0]  ex4_result;
reg     [22:0]  ex4_single_denorm_frac;
reg     [9 :0]  expnt_add_op1;

// &Wires; @26
wire            ex4_cor_nx;
wire            ex4_cor_uf;
wire            ex4_denorm_potnt_norm;
wire    [31:0]  ex4_denorm_result;
wire    [9 :0]  ex4_expnt_rst;
wire    [4 :0]  ex4_expt;
wire            ex4_final_rst_norm;
wire    [25:0]  ex4_frac;
wire            ex4_of_plus;
wire            ex4_result_inf;
wire            ex4_result_lfn;
wire            ex4_rslt_denorm;
wire    [31:0]  ex4_rst_inf;
wire    [31:0]  ex4_rst_lfn;
wire            ex4_rst_nor;
wire    [31:0]  ex4_rst_norm;
wire            ex4_uf_plus;
wire            fdsu_ex4_denorm_to_tiny_frac;
wire            fdsu_ex4_dz;
wire    [9 :0]  fdsu_ex4_expnt_rst;
wire    [25:0]  fdsu_ex4_frac;
wire            fdsu_ex4_nv;
wire            fdsu_ex4_nx;
wire            fdsu_ex4_of;
wire            fdsu_ex4_of_rst_lfn;
wire    [1 :0]  fdsu_ex4_potnt_norm;
wire            fdsu_ex4_potnt_of;
wire            fdsu_ex4_potnt_uf;
wire            fdsu_ex4_result_inf;
wire            fdsu_ex4_result_lfn;
wire            fdsu_ex4_result_nor;
wire            fdsu_ex4_result_sign;
wire            fdsu_ex4_rslt_denorm;
wire            fdsu_ex4_uf;
wire    [31:0]  fdsu_frbus_data;
wire    [4 :0]  fdsu_frbus_fflags;
wire    [4 :0]  fdsu_frbus_freg;
wire    [9 :0]  fdsu_yy_expnt_rst;
wire            fdsu_yy_of;
wire            fdsu_yy_of_rm_lfn;
wire            fdsu_yy_potnt_of;
wire            fdsu_yy_potnt_uf;
wire            fdsu_yy_result_inf;
wire            fdsu_yy_result_lfn;
wire            fdsu_yy_result_sign;
wire            fdsu_yy_rslt_denorm;
wire            fdsu_yy_uf;
wire    [4 :0]  fdsu_yy_wb_freg;


assign fdsu_ex4_result_sign     = fdsu_yy_result_sign;
assign fdsu_ex4_of_rst_lfn      = fdsu_yy_of_rm_lfn;
assign fdsu_ex4_result_inf      = fdsu_yy_result_inf;
assign fdsu_ex4_result_lfn      = fdsu_yy_result_lfn;
assign fdsu_ex4_of              = fdsu_yy_of;
assign fdsu_ex4_uf              = fdsu_yy_uf;
assign fdsu_ex4_potnt_of        = fdsu_yy_potnt_of;
assign fdsu_ex4_potnt_uf        = fdsu_yy_potnt_uf;
assign fdsu_ex4_nv              = 1'b0;
assign fdsu_ex4_dz              = 1'b0;
assign fdsu_ex4_expnt_rst[9:0] = fdsu_yy_expnt_rst[9:0];
assign fdsu_ex4_rslt_denorm     = fdsu_yy_rslt_denorm;
//============================EX4 STAGE=====================
assign ex4_frac[25:0] = fdsu_ex4_frac[25:0];
//exponent adder
// &CombBeg; @43
always @( ex4_frac[25:24])
begin
casez(ex4_frac[25:24])
  2'b00   : expnt_add_op1[9:0] = 10'h1ff;  //the expnt sub 1
  2'b01   : expnt_add_op1[9:0] = 10'h0;    //the expnt stay the origi
  2'b1?   : expnt_add_op1[9:0] = 10'h1;    // the exptn add 1
  default : expnt_add_op1[9:0] = 10'b0;
endcase
// &CombEnd; @50
end
assign ex4_expnt_rst[9:0] = fdsu_ex4_expnt_rst[9:0] +
                             expnt_add_op1[9:0];

//==========================Result Pack=====================

// result denormal pack
// shift to the denormal number
// &CombBeg; @58
always @( fdsu_ex4_expnt_rst[9:0]
       or fdsu_ex4_denorm_to_tiny_frac
       or ex4_frac[25:1])
begin
case(fdsu_ex4_expnt_rst[9:0])
  10'h1:   ex4_single_denorm_frac[22:0] = {      ex4_frac[23:1]}; //-1022 1
  10'h0:   ex4_single_denorm_frac[22:0] = {      ex4_frac[24:2]}; //-1023 0
  10'h3ff:ex4_single_denorm_frac[22:0] = {      ex4_frac[25:3]}; //-1024 -1
  10'h3fe:ex4_single_denorm_frac[22:0] = {1'b0, ex4_frac[25:4]}; //-1025 -2
  10'h3fd:ex4_single_denorm_frac[22:0] = {2'b0, ex4_frac[25:5]}; //-1026 -3
  10'h3fc:ex4_single_denorm_frac[22:0] = {3'b0, ex4_frac[25:6]}; //-1027 -4
  10'h3fb:ex4_single_denorm_frac[22:0] = {4'b0, ex4_frac[25:7]}; //-1028 -5
  10'h3fa:ex4_single_denorm_frac[22:0] = {5'b0, ex4_frac[25:8]}; //-1029 -6
  10'h3f9:ex4_single_denorm_frac[22:0] = {6'b0, ex4_frac[25:9]}; //-1030 -7
  10'h3f8:ex4_single_denorm_frac[22:0] = {7'b0, ex4_frac[25:10]}; //-1031 -8
  10'h3f7:ex4_single_denorm_frac[22:0] = {8'b0, ex4_frac[25:11]}; //-1032 -9
  10'h3f6:ex4_single_denorm_frac[22:0] = {9'b0, ex4_frac[25:12]}; //-1033 -10
  10'h3f5:ex4_single_denorm_frac[22:0] = {10'b0,ex4_frac[25:13]}; //-1034 -11
  10'h3f4:ex4_single_denorm_frac[22:0] = {11'b0,ex4_frac[25:14]}; //-1035 -12
  10'h3f3:ex4_single_denorm_frac[22:0] = {12'b0,ex4_frac[25:15]}; //-1036 -13
  10'h3f2:ex4_single_denorm_frac[22:0] = {13'b0,ex4_frac[25:16]}; // -1037
  10'h3f1:ex4_single_denorm_frac[22:0] = {14'b0,ex4_frac[25:17]}; //-1038
  10'h3f0:ex4_single_denorm_frac[22:0] = {15'b0,ex4_frac[25:18]}; //-1039
  10'h3ef:ex4_single_denorm_frac[22:0] = {16'b0,ex4_frac[25:19]}; //-1040
  10'h3ee:ex4_single_denorm_frac[22:0] = {17'b0,ex4_frac[25:20]}; //-1041
  10'h3ed:ex4_single_denorm_frac[22:0] = {18'b0,ex4_frac[25:21]}; //-1042
  10'h3ec:ex4_single_denorm_frac[22:0] = {19'b0,ex4_frac[25:22]}; //-1043
  10'h3eb:ex4_single_denorm_frac[22:0] = {20'b0,ex4_frac[25:23]}; //-1044
  10'h3ea:ex4_single_denorm_frac[22:0] = {21'b0,ex4_frac[25:24]}; //-1044
  default :ex4_single_denorm_frac[22:0] = fdsu_ex4_denorm_to_tiny_frac ? 23'b1 : 23'b0; //-1045
endcase
// &CombEnd; @86
end
//here when denormal number round to add1, it will become normal number
assign ex4_denorm_potnt_norm    = (fdsu_ex4_potnt_norm[1] && ex4_frac[24]) ||
                                  (fdsu_ex4_potnt_norm[0] && ex4_frac[25]) ;
assign ex4_rslt_denorm          = fdsu_ex4_rslt_denorm && !ex4_denorm_potnt_norm;
assign ex4_denorm_result[31:0]  = {fdsu_ex4_result_sign,
                                        8'h0,ex4_single_denorm_frac[22:0]};


//ex4 overflow/underflow plus
assign ex4_rst_nor = fdsu_ex4_result_nor;
assign ex4_of_plus = fdsu_ex4_potnt_of  &&
                     (|ex4_frac[25:24])  &&
                     ex4_rst_nor;
assign ex4_uf_plus = fdsu_ex4_potnt_uf  &&
                     (~|ex4_frac[25:24]) &&
                     ex4_rst_nor;
//ex4 overflow round result
assign ex4_result_lfn = (ex4_of_plus &&  fdsu_ex4_of_rst_lfn) ||
                        fdsu_ex4_result_lfn;
assign ex4_result_inf = (ex4_of_plus && !fdsu_ex4_of_rst_lfn) ||
                        fdsu_ex4_result_inf;
//Special Result Form
// result largest finity number
assign ex4_rst_lfn[31:0]      = {fdsu_ex4_result_sign,8'hfe,{23{1'b1}}};
//result infinity
assign ex4_rst_inf[31:0]  = {fdsu_ex4_result_sign,8'hff,23'b0};
//result normal
// &CombBeg; @114
always @( ex4_frac[25:0])
begin
casez(ex4_frac[25:24])
  2'b00   : ex4_frac_23[22:0]  = ex4_frac[22:0];
  2'b01   : ex4_frac_23[22:0]  = ex4_frac[23:1];
  2'b1?   : ex4_frac_23[22:0]  = ex4_frac[24:2];
  default : ex4_frac_23[22:0]  = 23'b0;
endcase
// &CombEnd; @121
end
assign ex4_rst_norm[31:0] = {fdsu_ex4_result_sign,
                                  ex4_expnt_rst[7:0],
                                  ex4_frac_23[22:0]};
assign ex4_cor_uf            = (fdsu_ex4_uf || ex4_denorm_potnt_norm || ex4_uf_plus)
                               && fdsu_ex4_nx;
assign ex4_cor_nx            =  fdsu_ex4_nx
                                || fdsu_ex4_of
                                || ex4_of_plus;

assign ex4_expt[4:0]           = {
                                  fdsu_ex4_nv,
                                  fdsu_ex4_dz,
                                  fdsu_ex4_of | ex4_of_plus,
                                  ex4_cor_uf,
                                  ex4_cor_nx};

assign ex4_final_rst_norm      = !ex4_result_inf        &&
                                 !ex4_result_lfn        &&
                                 !ex4_rslt_denorm;
// &CombBeg; @141
always @( ex4_denorm_result[31:0]
       or ex4_result_lfn
       or ex4_result_inf
       or ex4_final_rst_norm
       or ex4_rst_norm[31:0]
       or ex4_rst_lfn[31:0]
       or ex4_rst_inf[31:0]
       or ex4_rslt_denorm)
begin
case({ex4_rslt_denorm,
      ex4_result_inf,
      ex4_result_lfn,
      ex4_final_rst_norm})
  4'b1000 : ex4_result[31:0]  = ex4_denorm_result[31:0];
  4'b0100 : ex4_result[31:0]  = ex4_rst_inf[31:0];
  4'b0010 : ex4_result[31:0]  = ex4_rst_lfn[31:0];
  4'b0001 : ex4_result[31:0]  = ex4_rst_norm[31:0];
  default   : ex4_result[31:0]  = 32'b0;
endcase
// &CombEnd; @152
end

//==========================================================
//                     Result Generate
//==========================================================
assign fdsu_frbus_freg[4:0]   = fdsu_yy_wb_freg[4:0];
assign fdsu_frbus_data[31:0]  = ex4_result[31:0];
assign fdsu_frbus_fflags[4:0] = ex4_expt[4:0];

// &ModuleEnd; @161
endmodule



/*Copyright 2020-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// &ModuleBeg; @23
module pa_fdsu_prepare(
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

// &Ports; @24
input   [2 :0]  dp_xx_ex1_rm;
input           ex1_op0_id;
input           ex1_op1_id;
input           ex1_op1_sel;
input   [12:0]  ex1_oper_id_expnt_f;
input   [51:0]  ex1_oper_id_frac_f;
input           fdsu_ex1_sel;
input   [9 :0]  idu_fpu_ex1_func;
input   [31:0]  idu_fpu_ex1_srcf0;
input   [31:0]  idu_fpu_ex1_srcf1;
output          ex1_div;
output  [23:0]  ex1_divisor;
output  [12:0]  ex1_expnt_adder_op0;
output  [12:0]  ex1_expnt_adder_op1;
output          ex1_of_result_lfn;
output          ex1_op0_sign;
output          ex1_op1_id_vld;
output  [12:0]  ex1_oper_id_expnt;
output  [51:0]  ex1_oper_id_frac;
output  [31:0]  ex1_remainder;
output          ex1_result_sign;
output  [2 :0]  ex1_rm;
output          ex1_sqrt;

// &Regs; @25
reg     [12:0]  ex1_expnt_adder_op1;
reg             ex1_of_result_lfn;

// &Wires; @26
wire            div_sign;
wire    [2 :0]  dp_xx_ex1_rm;
wire            ex1_div;
wire    [52:0]  ex1_div_noid_nor_srt_op0;
wire    [52:0]  ex1_div_noid_nor_srt_op1;
wire    [52:0]  ex1_div_nor_srt_op0;
wire    [52:0]  ex1_div_nor_srt_op1;
wire    [12:0]  ex1_div_op0_expnt;
wire    [12:0]  ex1_div_op1_expnt;
wire    [52:0]  ex1_div_srt_op0;
wire    [52:0]  ex1_div_srt_op1;
wire    [23:0]  ex1_divisor;
wire            ex1_double;
wire    [12:0]  ex1_expnt_adder_op0;
wire            ex1_op0_id;
wire            ex1_op0_id_nor;
wire            ex1_op0_sign;
wire            ex1_op1_id;
wire            ex1_op1_id_nor;
wire            ex1_op1_id_vld;
wire            ex1_op1_sel;
wire            ex1_op1_sign;
wire    [63:0]  ex1_oper0;
wire    [51:0]  ex1_oper0_frac;
wire    [12:0]  ex1_oper0_id_expnt;
wire    [51:0]  ex1_oper0_id_frac;
wire    [63:0]  ex1_oper1;
wire    [51:0]  ex1_oper1_frac;
wire    [12:0]  ex1_oper1_id_expnt;
wire    [51:0]  ex1_oper1_id_frac;
wire    [51:0]  ex1_oper_frac;
wire    [12:0]  ex1_oper_id_expnt;
wire    [12:0]  ex1_oper_id_expnt_f;
wire    [51:0]  ex1_oper_id_frac;
wire    [51:0]  ex1_oper_id_frac_f;
wire    [31:0]  ex1_remainder;
wire            ex1_result_sign;
wire    [2 :0]  ex1_rm;
wire            ex1_single;
wire            ex1_sqrt;
wire            ex1_sqrt_expnt_odd;
wire            ex1_sqrt_op0_expnt_0;
wire    [12:0]  ex1_sqrt_op1_expnt;
wire    [52:0]  ex1_sqrt_srt_op0;
wire            fdsu_ex1_sel;
wire    [9 :0]  idu_fpu_ex1_func;
wire    [31:0]  idu_fpu_ex1_srcf0;
wire    [31:0]  idu_fpu_ex1_srcf1;
wire    [59:0]  sqrt_remainder;
wire            sqrt_sign;


assign ex1_sqrt                    = idu_fpu_ex1_func[0];
assign ex1_div                     = idu_fpu_ex1_func[1];
assign ex1_oper0[63:0]             = {32'b0, idu_fpu_ex1_srcf0[31:0] & {32{fdsu_ex1_sel}}};
assign ex1_oper1[63:0]             = {32'b0, idu_fpu_ex1_srcf1[31:0] & {32{fdsu_ex1_sel}}};
assign ex1_double                  = 1'b0;
assign ex1_single                  = 1'b1;
// &Force("bus", "idu_fpu_ex1_func", 9, 0); @43
assign ex1_op0_id_nor              = ex1_op0_id;
assign ex1_op1_id_nor              = ex1_op1_id;

//Sign bit prepare
assign ex1_op0_sign                = ex1_double && ex1_oper0[63]
                                  || ex1_single && ex1_oper0[31];
assign ex1_op1_sign                = ex1_double && ex1_oper1[63]
                                  || ex1_single && ex1_oper1[31];
assign div_sign                    = ex1_op0_sign ^ ex1_op1_sign;
assign sqrt_sign                   = ex1_op0_sign;
assign ex1_result_sign             = (ex1_div)
                                   ? div_sign
                                   : sqrt_sign;

//=====================find first one=======================
// this is for the denormal number
assign ex1_oper_frac[51:0] = ex1_op1_sel ? ex1_oper1_frac[51:0]
                                         : ex1_oper0_frac[51:0];

// &Instance("pa_fdsu_ff1", "x_frac_expnt"); @63
pa_fdsu_ff1  x_frac_expnt (
  .fanc_shift_num          (ex1_oper_id_frac[51:0] ),
  .frac_bin_val            (ex1_oper_id_expnt[12:0]),
  .frac_num                (ex1_oper_frac[51:0]    )
);

// &Connect(.frac_num(ex1_oper_frac[51:0])); @64
// &Connect(.frac_bin_val(ex1_oper_id_expnt[12:0])); @65
// &Connect(.fanc_shift_num(ex1_oper_id_frac[51:0])); @66
// &Force("output", "ex1_oper_id_expnt"); &Force("bus", "ex1_oper_id_expnt", 12, 0); @67
// &Force("output", "ex1_oper_id_frac"); &Force("bus", "ex1_oper_id_frac", 51, 0); @68

assign ex1_oper0_id_expnt[12:0] = ex1_op1_sel ? ex1_oper_id_expnt_f[12:0]
                                              : ex1_oper_id_expnt[12:0];
assign ex1_oper0_id_frac[51:0]  = ex1_op1_sel ? ex1_oper_id_frac_f[51:0]
                                              : ex1_oper_id_frac[51:0];
assign ex1_oper1_id_expnt[12:0] = ex1_oper_id_expnt[12:0];
assign ex1_oper1_id_frac[51:0]  = ex1_oper_id_frac[51:0];

assign ex1_oper0_frac[51:0] = {52{ex1_double}} & ex1_oper0[51:0]
                            | {52{ex1_single}} & {ex1_oper0[22:0],29'b0};
assign ex1_oper1_frac[51:0] = {52{ex1_double}} & ex1_oper1[51:0]
                            | {52{ex1_single}} & {ex1_oper1[22:0],29'b0};

//=====================exponent add=========================
//exponent number 0
assign ex1_div_op0_expnt[12:0]     = {13{ex1_double}} & {2'b0,ex1_oper0[62:52]}
                                   | {13{ex1_single}} & {5'b0,ex1_oper0[30:23]};
assign ex1_expnt_adder_op0[12:0]   = ex1_op0_id_nor ? ex1_oper0_id_expnt[12:0]
                                                : ex1_div_op0_expnt[12:0];
//exponent number 1
assign ex1_div_op1_expnt[12:0]  = {13{ex1_double}} & {2'b0,ex1_oper1[62:52]}
                                | {13{ex1_single}} & {5'b0,ex1_oper1[30:23]};
assign ex1_sqrt_op1_expnt[12:0] = {13{ex1_double}} & {3'b0,{10{1'b1}}} //'d1023
                                | {13{ex1_single}} & {6'b0,{7{1'b1}}}; //'d127
// &CombBeg; @93
always @( ex1_oper1_id_expnt[12:0]
       or ex1_div
       or ex1_op1_id_nor
       or ex1_sqrt_op1_expnt[12:0]
       or ex1_sqrt
       or ex1_div_op1_expnt[12:0])
begin
case({ex1_div,ex1_sqrt})
  2'b10:   ex1_expnt_adder_op1[12:0] = ex1_op1_id_nor ? ex1_oper1_id_expnt[12:0]
                                                  : ex1_div_op1_expnt[12:0];
  2'b01:   ex1_expnt_adder_op1[12:0] = ex1_sqrt_op1_expnt[12:0];
  default: ex1_expnt_adder_op1[12:0] = 13'b0;
endcase
// &CombEnd; @100
end

//ex1_sqrt_expnt_odd
//fraction will shift left by 1
// adder_op0/1 timing is bad.
// assign ex1_sqrt_expnt_odd          = ex1_expnt_adder_op0[0] ^ ex1_expnt_adder_op1[0];

// sqrt_odd is only used when is sqrt.
assign ex1_sqrt_op0_expnt_0        = ex1_op0_id_nor ? ex1_oper_id_expnt[0]
                                                    : ex1_div_op0_expnt[0];
// ex1_expnt_adder_op1 is always 1'b1, so adder_op0[0] should be 0.
assign ex1_sqrt_expnt_odd          = !ex1_sqrt_op0_expnt_0;

assign ex1_rm[2:0]       = dp_xx_ex1_rm[2:0];
//RNE : Always inc 1 because round to nearest of 1.111...11
//RTZ : Always not inc 1
//RUP : Always not inc 1 when posetive
//RDN : Always not inc 1 when negative
//RMM : Always inc 1 because round to max magnitude
// &CombBeg; @119
always @( ex1_rm[2:0]
       or ex1_result_sign)
begin
case(ex1_rm[2:0])
  3'b000  : ex1_of_result_lfn = 1'b0;
  3'b001  : ex1_of_result_lfn = 1'b1;
  3'b010  : ex1_of_result_lfn = !ex1_result_sign;
  3'b011  : ex1_of_result_lfn = ex1_result_sign;
  3'b100  : ex1_of_result_lfn = 1'b0;
  default: ex1_of_result_lfn = 1'b0;
endcase
// &CombEnd; @128
end

//EX1 Remainder
//div  : 1/8  <= x < 1/4
//sqrt : 1/16 <= x < 1/4
assign ex1_remainder[31:0] = {32{ex1_div }} & {5'b0,ex1_div_srt_op0[52:28],2'b0} |
                             {32{ex1_sqrt}} & sqrt_remainder[59:28];

//EX1 Divisor
//1/2 <= y < 1
assign ex1_divisor[23:0]   = ex1_div_srt_op1[52:29];

//ex1_div_srt_op0
assign ex1_div_srt_op0[52:0]     = ex1_div_nor_srt_op0[52:0];
//ex1_div_srt_op1
assign ex1_div_srt_op1[52:0]     =  ex1_div_nor_srt_op1[52:0];
//ex1_div_nor_srt_op0
assign ex1_div_noid_nor_srt_op0[52:0] = {53{ex1_double}} & {1'b1,ex1_oper0[51:0]}
                                      | {53{ex1_single}} & {1'b1,ex1_oper0[22:0],29'b0};
assign ex1_div_nor_srt_op0[52:0] = ex1_op0_id_nor ? {ex1_oper0_id_frac[51:0],1'b0}
                                                  : ex1_div_noid_nor_srt_op0[52:0];
//ex1_div_nor_srt_op1
assign ex1_div_noid_nor_srt_op1[52:0] = {53{ex1_double}} & {1'b1,ex1_oper1[51:0]}
                                      | {53{ex1_single}} & {1'b1,ex1_oper1[22:0],29'b0};
assign ex1_div_nor_srt_op1[52:0] = ex1_op1_id_nor ? {ex1_oper1_id_frac[51:0],1'b0}
                                                  : ex1_div_noid_nor_srt_op1[52:0];
//sqrt_remainder
assign sqrt_remainder[59:0]      = (ex1_sqrt_expnt_odd)
                                 ? {5'b0,ex1_sqrt_srt_op0[52:0],2'b0}
                                 : {6'b0,ex1_sqrt_srt_op0[52:0],1'b0};
//ex1_sqrt_srt_op0
assign ex1_sqrt_srt_op0[52:0]    = ex1_div_srt_op0[52:0];

//========================Pipe to EX2=======================
//exponent register cal result
// &Force("output", "ex1_expnt_adder_op0"); &Force("bus", "ex1_expnt_adder_op0", 12, 0); @173
// &Force("output", "ex1_expnt_adder_op1"); &Force("bus", "ex1_expnt_adder_op1", 12, 0); @174
// &Force("output", "ex1_double"); @175
// &Force("output", "ex1_expnt_adder_op0"); &Force("bus", "ex1_expnt_adder_op0", 12, 0); @177
// &Force("output", "ex1_expnt_adder_op1"); &Force("bus", "ex1_expnt_adder_op1", 12, 0); @178
// &Force("output", "ex1_result_sign"); @180
// &Force("output", "ex1_div"); @181
// &Force("output", "ex1_sqrt"); @182
// &Force("output", "ex1_rm"); &Force("bus", "ex1_rm", 2, 0); @183
// &Force("output", "ex1_op0_sign"); @184

assign ex1_op1_id_vld = ex1_op1_id_nor && ex1_div;

// &ModuleEnd; @188
endmodule



/*Copyright 2020-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// &ModuleBeg; @23
module pa_fdsu_round_single(
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

// &Ports; @24
input           cp0_fpu_icg_en;
input           cp0_yy_clk_en;
input           ex3_pipedown;
input           fdsu_ex3_id_srt_skip;
input           fdsu_ex3_rem_sign;
input           fdsu_ex3_rem_zero;
input   [23:0]  fdsu_ex3_result_denorm_round_add_num;
input   [9 :0]  fdsu_yy_expnt_rst;
input           fdsu_yy_result_inf;
input           fdsu_yy_result_lfn;
input           fdsu_yy_result_sign;
input   [2 :0]  fdsu_yy_rm;
input           fdsu_yy_rslt_denorm;
input           forever_cpuclk;
input           pad_yy_icg_scan_en;
input   [29:0]  total_qt_rt_30;
output  [9 :0]  ex3_expnt_adjust_result;
output  [25:0]  ex3_frac_final_rst;
output          ex3_rslt_denorm;
output          fdsu_ex4_denorm_to_tiny_frac;
output          fdsu_ex4_nx;
output  [1 :0]  fdsu_ex4_potnt_norm;
output          fdsu_ex4_result_nor;

// &Regs; @25
reg             denorm_to_tiny_frac;
reg             fdsu_ex4_denorm_to_tiny_frac;
reg             fdsu_ex4_nx;
reg     [1 :0]  fdsu_ex4_potnt_norm;
reg             fdsu_ex4_result_nor;
reg     [25:0]  frac_add1_op1;
reg             frac_add_1;
reg             frac_orig;
reg     [25:0]  frac_sub1_op1;
reg             frac_sub_1;
reg     [27:0]  qt_result_single_denorm_for_round;
reg             single_denorm_lst_frac;

// &Wires; @26
wire            cp0_fpu_icg_en;
wire            cp0_yy_clk_en;
wire            ex3_denorm_eq;
wire            ex3_denorm_gr;
wire            ex3_denorm_lst_frac;
wire            ex3_denorm_nx;
wire            ex3_denorm_plus;
wire            ex3_denorm_potnt_norm;
wire            ex3_denorm_zero;
wire    [9 :0]  ex3_expnt_adjst;
wire    [9 :0]  ex3_expnt_adjust_result;
wire    [25:0]  ex3_frac_final_rst;
wire            ex3_nx;
wire            ex3_pipe_clk;
wire            ex3_pipe_clk_en;
wire            ex3_pipedown;
wire    [1 :0]  ex3_potnt_norm;
wire            ex3_qt_eq;
wire            ex3_qt_gr;
wire            ex3_qt_sing_lo3_not0;
wire            ex3_qt_sing_lo4_not0;
wire            ex3_qt_zero;
wire            ex3_rslt_denorm;
wire            ex3_rst_eq_1;
wire            ex3_rst_nor;
wire            ex3_single_denorm_eq;
wire            ex3_single_denorm_gr;
wire            ex3_single_denorm_zero;
wire            ex3_single_low_not_zero;
wire    [9 :0]  fdsu_ex3_expnt_rst;
wire            fdsu_ex3_id_srt_skip;
wire            fdsu_ex3_rem_sign;
wire            fdsu_ex3_rem_zero;
wire    [23:0]  fdsu_ex3_result_denorm_round_add_num;
wire            fdsu_ex3_result_inf;
wire            fdsu_ex3_result_lfn;
wire            fdsu_ex3_result_sign;
wire    [2 :0]  fdsu_ex3_rm;
wire            fdsu_ex3_rslt_denorm;
wire    [9 :0]  fdsu_yy_expnt_rst;
wire            fdsu_yy_result_inf;
wire            fdsu_yy_result_lfn;
wire            fdsu_yy_result_sign;
wire    [2 :0]  fdsu_yy_rm;
wire            fdsu_yy_rslt_denorm;
wire            forever_cpuclk;
wire    [25:0]  frac_add1_op1_with_denorm;
wire    [25:0]  frac_add1_rst;
wire            frac_denorm_rdn_add_1;
wire            frac_denorm_rdn_sub_1;
wire            frac_denorm_rmm_add_1;
wire            frac_denorm_rne_add_1;
wire            frac_denorm_rtz_sub_1;
wire            frac_denorm_rup_add_1;
wire            frac_denorm_rup_sub_1;
wire    [25:0]  frac_final_rst;
wire            frac_rdn_add_1;
wire            frac_rdn_sub_1;
wire            frac_rmm_add_1;
wire            frac_rne_add_1;
wire            frac_rtz_sub_1;
wire            frac_rup_add_1;
wire            frac_rup_sub_1;
wire    [25:0]  frac_sub1_op1_with_denorm;
wire    [25:0]  frac_sub1_rst;
wire            pad_yy_icg_scan_en;
wire    [29:0]  total_qt_rt_30;


assign fdsu_ex3_result_sign     = fdsu_yy_result_sign;
assign fdsu_ex3_expnt_rst[9:0]  = fdsu_yy_expnt_rst[9:0];
assign fdsu_ex3_result_inf      = fdsu_yy_result_inf;
assign fdsu_ex3_result_lfn      = fdsu_yy_result_lfn;
assign fdsu_ex3_rm[2:0]         = fdsu_yy_rm[2:0];
assign fdsu_ex3_rslt_denorm     = fdsu_yy_rslt_denorm;
//=======================Round Rule=========================
//1/8 <= x < 1/4, 1/2 <= y < 1, => 1/8 < z < 1/2
//q[29:0] represent the fraction part result of quotient, q[29] for 1/2
//Thus the first "1" in 30 bit quotient will be in q[28] or q[27]
//For Single Float
//15 round to get 30 bit quotient, 23+1 bit as valid result, other for round
//if q[28] is 1, q[28:5] as 1.xxxx valid result, [4:0] for round
//if q[28] is 0, q[27:4] as 1.xxxx valid result, [3:0] for round
// &Force("bus","total_qt_rt_30",29,0); @42
assign ex3_qt_sing_lo4_not0 = |total_qt_rt_30[3:0];
assign ex3_qt_sing_lo3_not0 = |total_qt_rt_30[2:0];
//the quotient round bits great than "10000"(ronnd bits 10..0)
assign ex3_qt_gr          = (total_qt_rt_30[28])
                            ?  total_qt_rt_30[4] && ex3_qt_sing_lo4_not0
                            :  total_qt_rt_30[3] && ex3_qt_sing_lo3_not0;

//the quotient round bits is equal to "10000"(ronnd bits 10..0)
assign ex3_qt_eq          = (total_qt_rt_30[28])
                            ?  total_qt_rt_30[4] && !ex3_qt_sing_lo4_not0
                            :  total_qt_rt_30[3] && !ex3_qt_sing_lo3_not0;
//the quotient round bits is zero
assign ex3_qt_zero        = (total_qt_rt_30[28])
                            ? ~|total_qt_rt_30[4:0]
                            : ~|total_qt_rt_30[3:0];
//quotient is 1.00000..00 need special dealt with in the following
assign ex3_rst_eq_1    = total_qt_rt_30[28] && ~|total_qt_rt_30[27:5];
// for denormal result, first select the quotation num for rounding
//  specially for the result e=-126 and e=-1022,the denorm depends on the
//  MSB of the quotient
assign ex3_denorm_plus       = !total_qt_rt_30[28] && (fdsu_ex3_expnt_rst[9:0] == 10'h382);
assign ex3_denorm_potnt_norm = total_qt_rt_30[28] && (fdsu_ex3_expnt_rst[9:0] == 10'h381);
assign ex3_rslt_denorm            = ex3_denorm_plus || fdsu_ex3_rslt_denorm;
// &Force("output", "ex3_rslt_denorm"); @66

//denomal result, check for rounding further optimization can be done in
//future
// &CombBeg; @70
always @( total_qt_rt_30[28:0]
       or fdsu_ex3_expnt_rst[9:0])
begin
case(fdsu_ex3_expnt_rst[9:0])
  10'h382:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[4:0],23'b0}; //-126 1
                single_denorm_lst_frac =  total_qt_rt_30[5];
			 		end//-1022 1
  10'h381:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[5:0],22'b0}; //-127 0
                single_denorm_lst_frac =  total_qt_rt_30[6];
			 		end//-1022 1
  10'h380:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[6:0],21'b0}; //-128 -1
                single_denorm_lst_frac =  total_qt_rt_30[7];
			 		end//-1022 1
  10'h37f:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[7:0],20'b0}; //-129 -2
                single_denorm_lst_frac =  total_qt_rt_30[8];
			 		end//-1022 1
  10'h37e:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[8:0],19'b0}; //-130 -3
                single_denorm_lst_frac =  total_qt_rt_30[9];
			 		end//-1022 1
  10'h37d:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[9:0],18'b0}; //-131 -4
                single_denorm_lst_frac =  total_qt_rt_30[10];
			 		end//-1022 1
  10'h37c:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[10:0],17'b0}; //-132 -5
                single_denorm_lst_frac =  total_qt_rt_30[11];
			 		end//-1022 1
  10'h37b:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[11:0],16'b0}; //-133 -6
                single_denorm_lst_frac =  total_qt_rt_30[12];
			 		end//-1022 1
  10'h37a:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[12:0],15'b0}; //-134 -7
                single_denorm_lst_frac =  total_qt_rt_30[13];
			 		end//-1022 1
  10'h379:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[13:0],14'b0}; //-135 -8
                single_denorm_lst_frac =  total_qt_rt_30[14];
			 		end//-1022 1
  10'h378:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[14:0],13'b0}; //-136 -9
                single_denorm_lst_frac =  total_qt_rt_30[15];
			 		end//-1022 1
  10'h377:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[15:0],12'b0}; //-137 -10
                single_denorm_lst_frac =  total_qt_rt_30[16];
			 		end//-1022 1
  10'h376:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[16:0],11'b0}; //-138 -11
                single_denorm_lst_frac =  total_qt_rt_30[17];
			 		end//-1022 1
  10'h375:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[17:0],10'b0}; //-139 -12
                single_denorm_lst_frac =  total_qt_rt_30[18];
			 		end//-1022 1
  10'h374:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[18:0],9'b0}; //-140 -13
                single_denorm_lst_frac =  total_qt_rt_30[19];
			 		end//-1022 1
  10'h373:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[19:0],8'b0}; // -141
                single_denorm_lst_frac =  total_qt_rt_30[20];
			 		end//-1022 1
  10'h372:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[20:0],7'b0};//-142
                single_denorm_lst_frac =  total_qt_rt_30[21];
			 		end//-1022 1
  10'h371:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[21:0],6'b0};//-143
                single_denorm_lst_frac =  total_qt_rt_30[22];
			 		end//-1022 1
  10'h370:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[22:0],5'b0}; //-144
                single_denorm_lst_frac =  total_qt_rt_30[23];
			 		end//-1022 1
  10'h36f:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[23:0],4'b0}; //-145
                single_denorm_lst_frac =  total_qt_rt_30[24];
			 		end//-1022 1
  10'h36e:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[24:0],3'b0}; //-146
                single_denorm_lst_frac =  total_qt_rt_30[25];
			 		end//-1022 1
  10'h36d:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[25:0],2'b0}; //-147
                single_denorm_lst_frac =  total_qt_rt_30[26];
			 		end//-1022 1
  10'h36c:begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[26:0],1'b0}; //-148
                single_denorm_lst_frac =  total_qt_rt_30[27];
			 		end//-1022 1
  10'h36b: begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[27:0]};
                 single_denorm_lst_frac = total_qt_rt_30[28] ;
						end//-1022 1
  default:  begin qt_result_single_denorm_for_round[27:0] = {total_qt_rt_30[28:1]};
                 single_denorm_lst_frac = 1'b0;
						end//-1022 1
endcase
// &CombEnd; @148
end
//rounding evaluation for single denormalize number
assign ex3_single_denorm_eq      = qt_result_single_denorm_for_round[27]
                                   &&  !ex3_single_low_not_zero;
assign ex3_single_low_not_zero   = |qt_result_single_denorm_for_round[26:0];
assign ex3_single_denorm_gr      = qt_result_single_denorm_for_round[27]
                                   &&  ex3_single_low_not_zero;
assign ex3_single_denorm_zero    = !qt_result_single_denorm_for_round[27]
                                   && !ex3_single_low_not_zero;

//rounding check fo denormalize result
assign ex3_denorm_eq             = ex3_single_denorm_eq;
assign ex3_denorm_gr             = ex3_single_denorm_gr;
assign ex3_denorm_zero           = ex3_single_denorm_zero;
assign ex3_denorm_lst_frac       = single_denorm_lst_frac;
//Different Round Mode with different rounding rule
//Here we call rounding bit as "rb", remainder as "rem"
//RNE :
//  1.+1 : rb>10000 || rb==10000 && rem>0
//  2. 0 : Rest Condition
//  3.-1 : Never occur
//RTZ :
//  1.+1 : Never occur
//  2. 0 : Rest Condition
//  3.-1 : rb=10000 && rem<0
//RDN :
//  1.+1 : Q>0 Never occur   ; Q<0 Rest condition
//  2. 0 : Q>0 Rest condition; Q<0 Rem<0 && rb=0
//  3.-1 : Q>0 Rem<0 && rb=0 ; Q<0 Never occur
//RUP :
//  1.+1 : Q>0 Rest Condition; Q<0 Never occur
//  2. 0 : Q>0 Rem<0 && rb=0 ; Q<0 Rest condition
//  3.-1 : Q>0 Never occur   ; Q<0 Rem<0 && rb=0
//RMM :
//  1.+1 : rb>10000 || rb==10000 && rem>0
//  2. 0 : Rest Condition
//  3.-1 : Never occur
assign frac_rne_add_1 = ex3_qt_gr ||
                       (ex3_qt_eq && !fdsu_ex3_rem_sign);
assign frac_rtz_sub_1 = ex3_qt_zero && fdsu_ex3_rem_sign;
assign frac_rup_add_1 = !fdsu_ex3_result_sign &&
                       (!ex3_qt_zero ||
                       (!fdsu_ex3_rem_sign && !fdsu_ex3_rem_zero));
assign frac_rup_sub_1 = fdsu_ex3_result_sign &&
                       (ex3_qt_zero && fdsu_ex3_rem_sign);
assign frac_rdn_add_1 = fdsu_ex3_result_sign &&
                       (!ex3_qt_zero ||
                       (!fdsu_ex3_rem_sign && !fdsu_ex3_rem_zero));
assign frac_rdn_sub_1 = !fdsu_ex3_result_sign &&
                       (ex3_qt_zero && fdsu_ex3_rem_sign);
assign frac_rmm_add_1 = ex3_qt_gr ||
                       (ex3_qt_eq && !fdsu_ex3_rem_sign);
//denormal result
assign frac_denorm_rne_add_1 = ex3_denorm_gr ||
                               (ex3_denorm_eq &&
                               ((fdsu_ex3_rem_zero &&
                                ex3_denorm_lst_frac) ||
                               (!fdsu_ex3_rem_zero &&
                                !fdsu_ex3_rem_sign)));
assign frac_denorm_rtz_sub_1 = ex3_denorm_zero && fdsu_ex3_rem_sign;
assign frac_denorm_rup_add_1 = !fdsu_ex3_result_sign &&
                               (!ex3_denorm_zero ||
                               (!fdsu_ex3_rem_sign && !fdsu_ex3_rem_zero));
assign frac_denorm_rup_sub_1 = fdsu_ex3_result_sign &&
                       (ex3_denorm_zero && fdsu_ex3_rem_sign);
assign frac_denorm_rdn_add_1 = fdsu_ex3_result_sign &&
                       (!ex3_denorm_zero ||
                       (!fdsu_ex3_rem_sign && !fdsu_ex3_rem_zero));
assign frac_denorm_rdn_sub_1 = !fdsu_ex3_result_sign &&
                       (ex3_denorm_zero && fdsu_ex3_rem_sign);
assign frac_denorm_rmm_add_1 = ex3_denorm_gr ||
                       (ex3_denorm_eq && !fdsu_ex3_rem_sign);

//RM select
// &CombBeg; @222
always @( fdsu_ex3_rm[2:0]
       or frac_denorm_rdn_add_1
       or frac_rne_add_1
       or frac_denorm_rdn_sub_1
       or fdsu_ex3_result_sign
       or frac_rup_add_1
       or frac_denorm_rup_sub_1
       or frac_rdn_sub_1
       or frac_rtz_sub_1
       or frac_rdn_add_1
       or fdsu_ex3_id_srt_skip
       or frac_denorm_rtz_sub_1
       or ex3_rslt_denorm
       or frac_rup_sub_1
       or frac_denorm_rmm_add_1
       or frac_denorm_rup_add_1
       or frac_denorm_rne_add_1
       or frac_rmm_add_1)
begin
case(fdsu_ex3_rm[2:0])
  3'b000://round to nearst,ties to even
  begin
    frac_add_1          =  ex3_rslt_denorm ? frac_denorm_rne_add_1 : frac_rne_add_1;
    frac_sub_1          =  1'b0;
    frac_orig           =  ex3_rslt_denorm ? !frac_denorm_rne_add_1 : !frac_rne_add_1;
    denorm_to_tiny_frac =  fdsu_ex3_id_srt_skip ? 1'b0 : frac_denorm_rne_add_1;
  end
  3'b001:// round to 0
  begin
    frac_add_1           =  1'b0;
    frac_sub_1           =  ex3_rslt_denorm ? frac_denorm_rtz_sub_1 : frac_rtz_sub_1;
    frac_orig            =  ex3_rslt_denorm ? !frac_denorm_rtz_sub_1 : !frac_rtz_sub_1;
    denorm_to_tiny_frac  = 1'b0;
  end
  3'b010://round to -inf
  begin
    frac_add_1          =  ex3_rslt_denorm ? frac_denorm_rdn_add_1 : frac_rdn_add_1;
    frac_sub_1          =  ex3_rslt_denorm ? frac_denorm_rdn_sub_1 : frac_rdn_sub_1;
    frac_orig           =  ex3_rslt_denorm ? !frac_denorm_rdn_add_1 && !frac_denorm_rdn_sub_1
                                           : !frac_rdn_add_1 && !frac_rdn_sub_1;
    denorm_to_tiny_frac = fdsu_ex3_id_srt_skip ? fdsu_ex3_result_sign
                                                : frac_denorm_rdn_add_1;
  end
  3'b011://round to +inf
  begin
    frac_add_1          =  ex3_rslt_denorm ? frac_denorm_rup_add_1 : frac_rup_add_1;
    frac_sub_1          =  ex3_rslt_denorm ? frac_denorm_rup_sub_1 : frac_rup_sub_1;
    frac_orig           =  ex3_rslt_denorm ? !frac_denorm_rup_add_1 && !frac_denorm_rup_sub_1
                                           : !frac_rup_add_1 && !frac_rup_sub_1;
    denorm_to_tiny_frac = fdsu_ex3_id_srt_skip ? !fdsu_ex3_result_sign
                                                : frac_denorm_rup_add_1;
  end
  3'b100://round to nearest,ties to max magnitude
  begin
    frac_add_1          = ex3_rslt_denorm ? frac_denorm_rmm_add_1 : frac_rmm_add_1;
    frac_sub_1          = 1'b0;
    frac_orig           = ex3_rslt_denorm ? !frac_denorm_rmm_add_1 : !frac_rmm_add_1;
    denorm_to_tiny_frac = fdsu_ex3_id_srt_skip ? 1'b0 : frac_denorm_rmm_add_1;
  end
  default:
  begin
    frac_add_1          = 1'b0;
    frac_sub_1          = 1'b0;
    frac_orig           = 1'b0;
    denorm_to_tiny_frac = 1'b0;
  end
endcase
// &CombEnd; @271
end
//Add 1 or Sub 1 constant
// &CombBeg; @273
always @( total_qt_rt_30[28])
begin
case(total_qt_rt_30[28])
  1'b0:
  begin
    frac_add1_op1[25:0] = {2'b0,24'b1};
    frac_sub1_op1[25:0] = {2'b11,{24{1'b1}}};
  end
  1'b1:
  begin
    frac_add1_op1[25:0] = {25'b1,1'b0};
    frac_sub1_op1[25:0] = {{25{1'b1}},1'b0};
  end
  default:
  begin
    frac_add1_op1[25:0] = 26'b0;
    frac_sub1_op1[25:0] = 26'b0;
  end
endcase
// &CombEnd; @291
end

//Add 1 or Sub1 final result
//Conner case when quotient is 0.010000...00 and remainder is negative,
//The real quotient is actually 0.00fff..ff,
//The final result will need to sub 1 when
//RN : Never occur
//RP : sign of quotient is -
//RM : sign of quotient is +
assign frac_add1_rst[25:0]             = {1'b0,total_qt_rt_30[28:4]} +
                                         frac_add1_op1_with_denorm[25:0];
assign frac_add1_op1_with_denorm[25:0] = ex3_rslt_denorm ?
                                  {1'b0,fdsu_ex3_result_denorm_round_add_num[23:0],1'b0} :
                                  frac_add1_op1[25:0];
assign frac_sub1_rst[25:0]             = (ex3_rst_eq_1)
                                       ? {3'b0,{23{1'b1}}}
                                       : {1'b0,total_qt_rt_30[28:4]} +
                                         frac_sub1_op1_with_denorm[25:0] + {25'b0, ex3_rslt_denorm};
assign frac_sub1_op1_with_denorm[25:0] = ex3_rslt_denorm ?
                                ~{1'b0,fdsu_ex3_result_denorm_round_add_num[23:0],1'b0} :
                                frac_sub1_op1[25:0];
assign frac_final_rst[25:0]           = (frac_add1_rst[25:0]         & {26{frac_add_1}}) |
                                        (frac_sub1_rst[25:0]         & {26{frac_sub_1}}) |
                                        ({1'b0,total_qt_rt_30[28:4]} & {26{frac_orig}});

//===============Pipe down signal prepare===================
// assign ex3_rst_nor = !fdsu_ex3_result_zero &&
//                      !fdsu_ex3_result_qnan &&
//                      !fdsu_ex3_result_inf  &&
//                      !fdsu_ex3_result_lfn;
assign ex3_rst_nor = !fdsu_ex3_result_inf  &&
                     !fdsu_ex3_result_lfn;
assign ex3_nx      = ex3_rst_nor &&
                    (!ex3_qt_zero || !fdsu_ex3_rem_zero || ex3_denorm_nx);
assign ex3_denorm_nx = ex3_rslt_denorm && (!ex3_denorm_zero ||  !fdsu_ex3_rem_zero);
//Adjust expnt
//Div:Actural expnt should plus 1 when op0 is id, sub 1 when op1 id
assign ex3_expnt_adjst[9:0] = 10'h7f;

assign ex3_expnt_adjust_result[9:0] = fdsu_ex3_expnt_rst[9:0] +
                                       ex3_expnt_adjst[9:0];
//this information is for the packing, which determin the result is normal
//numer or not;
assign ex3_potnt_norm[1:0]    = {ex3_denorm_plus,ex3_denorm_potnt_norm};
//=======================Pipe to EX4========================
//gate clk
// &Instance("gated_clk_cell","x_ex3_pipe_clk"); @337
gated_clk_cell  x_ex3_pipe_clk (
  .clk_in             (forever_cpuclk    ),
  .clk_out            (ex3_pipe_clk      ),
  .external_en        (1'b0              ),
  .global_en          (cp0_yy_clk_en     ),
  .local_en           (ex3_pipe_clk_en   ),
  .module_en          (cp0_fpu_icg_en    ),
  .pad_yy_icg_scan_en (pad_yy_icg_scan_en)
);

// &Connect( .clk_in         (forever_cpuclk), @338
//           .clk_out        (ex3_pipe_clk),//Out Clock @339
//           .external_en    (1'b0), @340
//           .global_en      (cp0_yy_clk_en), @341
//           .local_en       (ex3_pipe_clk_en),//Local Condition @342
//           .module_en      (cp0_fpu_icg_en) @343
//         ); @344
assign ex3_pipe_clk_en = ex3_pipedown;

always @(posedge ex3_pipe_clk)
begin
  if(ex3_pipedown)
  begin
    fdsu_ex4_result_nor      <= ex3_rst_nor;
    fdsu_ex4_nx              <= ex3_nx;
    fdsu_ex4_denorm_to_tiny_frac
                              <= denorm_to_tiny_frac;
    fdsu_ex4_potnt_norm[1:0] <= ex3_potnt_norm[1:0];
  end
  else
  begin
    fdsu_ex4_result_nor      <= fdsu_ex4_result_nor;
    fdsu_ex4_nx              <= fdsu_ex4_nx;
    fdsu_ex4_denorm_to_tiny_frac
                              <= fdsu_ex4_denorm_to_tiny_frac;
    fdsu_ex4_potnt_norm[1:0] <= fdsu_ex4_potnt_norm[1:0];
  end
end

// ex3_frac Pipedown to ex4 use srt_divisor.
assign ex3_frac_final_rst[25:0] = frac_final_rst[25:0];
// &Force("output","fdsu_ex4_result_nor"); @397
// &Force("output","fdsu_ex4_nx"); @398
// &Force("output","fdsu_ex4_denorm_to_tiny_frac"); @399
// &Force("output","fdsu_ex4_potnt_norm"); @400


// &ModuleEnd; @403
endmodule



/*Copyright 2020-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// &ModuleBeg; @23
module pa_fdsu_special(
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

// &Ports; @24
input          cp0_fpu_xx_dqnan;
input   [2:0]  dp_xx_ex1_cnan;
input   [2:0]  dp_xx_ex1_id;
input   [2:0]  dp_xx_ex1_inf;
input   [2:0]  dp_xx_ex1_qnan;
input   [2:0]  dp_xx_ex1_snan;
input   [2:0]  dp_xx_ex1_zero;
input          ex1_div;
input          ex1_op0_sign;
input          ex1_result_sign;
input          ex1_sqrt;
output         ex1_op0_id;
output         ex1_op0_norm;
output         ex1_op1_id;
output         ex1_op1_norm;
output         ex1_srt_skip;
output  [4:0]  fdsu_fpu_ex1_fflags;
output  [7:0]  fdsu_fpu_ex1_special_sel;
output  [3:0]  fdsu_fpu_ex1_special_sign;

// &Regs; @25
reg            ex1_result_cnan;
reg            ex1_result_qnan_op0;
reg            ex1_result_qnan_op1;

// &Wires; @26
wire           cp0_fpu_xx_dqnan;
wire    [2:0]  dp_xx_ex1_cnan;
wire    [2:0]  dp_xx_ex1_id;
wire    [2:0]  dp_xx_ex1_inf;
wire    [2:0]  dp_xx_ex1_qnan;
wire    [2:0]  dp_xx_ex1_snan;
wire    [2:0]  dp_xx_ex1_zero;
wire           ex1_div;
wire           ex1_div_dz;
wire           ex1_div_nv;
wire           ex1_div_rst_inf;
wire           ex1_div_rst_qnan;
wire           ex1_div_rst_zero;
wire           ex1_dz;
wire    [4:0]  ex1_fflags;
wire           ex1_nv;
wire           ex1_op0_cnan;
wire           ex1_op0_id;
wire           ex1_op0_inf;
wire           ex1_op0_is_qnan;
wire           ex1_op0_is_snan;
wire           ex1_op0_norm;
wire           ex1_op0_qnan;
wire           ex1_op0_sign;
wire           ex1_op0_snan;
wire           ex1_op0_tt_zero;
wire           ex1_op0_zero;
wire           ex1_op1_cnan;
wire           ex1_op1_id;
wire           ex1_op1_inf;
wire           ex1_op1_is_qnan;
wire           ex1_op1_is_snan;
wire           ex1_op1_norm;
wire           ex1_op1_qnan;
wire           ex1_op1_snan;
wire           ex1_op1_tt_zero;
wire           ex1_op1_zero;
wire           ex1_result_inf;
wire           ex1_result_lfn;
wire           ex1_result_qnan;
wire           ex1_result_sign;
wire           ex1_result_zero;
wire           ex1_rst_default_qnan;
wire    [7:0]  ex1_special_sel;
wire    [3:0]  ex1_special_sign;
wire           ex1_sqrt;
wire           ex1_sqrt_nv;
wire           ex1_sqrt_rst_inf;
wire           ex1_sqrt_rst_qnan;
wire           ex1_sqrt_rst_zero;
wire           ex1_srt_skip;
wire    [4:0]  fdsu_fpu_ex1_fflags;
wire    [7:0]  fdsu_fpu_ex1_special_sel;
wire    [3:0]  fdsu_fpu_ex1_special_sign;


//infinity number
// &Force("bus", "dp_xx_ex1_inf", 2, 0); @29
assign  ex1_op0_inf                = dp_xx_ex1_inf[0];
assign  ex1_op1_inf                = dp_xx_ex1_inf[1];

//zero
// &Force("bus", "dp_xx_ex1_zero", 2, 0); @34
assign ex1_op0_zero                = dp_xx_ex1_zero[0];
assign ex1_op1_zero                = dp_xx_ex1_zero[1];

//denormalize number
// &Force("bus", "dp_xx_ex1_id", 2, 0); @39
assign ex1_op0_id                  = dp_xx_ex1_id[0];
assign ex1_op1_id                  = dp_xx_ex1_id[1];

//cNaN
// &Force("bus", "dp_xx_ex1_cnan", 2, 0); @44
assign ex1_op0_cnan                = dp_xx_ex1_cnan[0];
assign ex1_op1_cnan                = dp_xx_ex1_cnan[1];

//sNaN
// &Force("bus", "dp_xx_ex1_snan", 2, 0); @49
assign ex1_op0_snan                = dp_xx_ex1_snan[0];
assign ex1_op1_snan                = dp_xx_ex1_snan[1];

//qNaN
// &Force("bus", "dp_xx_ex1_qnan", 2, 0); @54
assign ex1_op0_qnan                = dp_xx_ex1_qnan[0];
assign ex1_op1_qnan                = dp_xx_ex1_qnan[1];


//======================EX1 expt detect=====================
//ex1_id_detect
//any opration is zero
// no input denormalize exception anymore
//
//ex1_nv_detect
//div_nv
//  1.any operation is sNaN
//  2.0/0(include DN flush to zero)
//  3.inf/inf
//sqrt_nv
//  1.any operation is sNaN
//  2.operation sign is 1 && operation is not zero/qNaN
assign ex1_nv      = ex1_div  && ex1_div_nv  ||
                     ex1_sqrt && ex1_sqrt_nv;
//ex1_div_nv
assign ex1_div_nv  = ex1_op0_snan ||
                     ex1_op1_snan ||
                    (ex1_op0_tt_zero && ex1_op1_tt_zero)||
                    (ex1_op0_inf && ex1_op1_inf);
assign ex1_op0_tt_zero = ex1_op0_zero;
assign ex1_op1_tt_zero = ex1_op1_zero;
//ex1_sqrt_nv
assign ex1_sqrt_nv = ex1_op0_snan ||
                     ex1_op0_sign &&
                    (ex1_op0_norm ||
                     ex1_op0_inf );

// This 'norm' also include denorm.
assign ex1_op0_norm = !ex1_op0_inf && !ex1_op0_zero && !ex1_op0_snan && !ex1_op0_qnan && !ex1_op0_cnan;
assign ex1_op1_norm = !ex1_op1_inf && !ex1_op1_zero && !ex1_op1_snan && !ex1_op1_qnan && !ex1_op1_cnan;

//ex1_of_detect
//div_of
//  1.only detect id overflow case
//assign ex1_of      = ex1_div && ex1_div_of;
//assign ex1_div_of  = ex1_op1_id_fm1 &&
//                     ex1_op0_norm &&
//                     ex1_div_id_of;
//
////ex1_uf_detect
////div_uf
////  1.only detect id underflow case
//assign ex1_uf      = ex1_div && ex1_div_uf;
//assign ex1_div_uf  = ex1_op0_id &&
//                     ex1_op1_norm &&
//                     ex1_div_id_uf;
//ex1_dz_detect
//div_dz
//  1.op0 is normal && op1 zero
assign ex1_dz      = ex1_div && ex1_div_dz;
assign ex1_div_dz  = ex1_op1_tt_zero && ex1_op0_norm;

//===================special cal result=====================
//ex1 result is zero
//div_zero
//  1.op0 is zero && op1 is normal
//  2.op0 is zero/normal && op1 is inf
//sqrt_zero
//  1.op0 is zero
assign ex1_result_zero   = ex1_div_rst_zero  && ex1_div  ||
                           ex1_sqrt_rst_zero && ex1_sqrt;
assign ex1_div_rst_zero  = (ex1_op0_tt_zero && ex1_op1_norm ) ||
                           // (!ex1_expnt0_max && !ex1_op0_cnan && ex1_op1_inf);
                           (!ex1_op0_inf && !ex1_op0_qnan && !ex1_op0_snan && !ex1_op0_cnan && ex1_op1_inf);
assign ex1_sqrt_rst_zero = ex1_op0_tt_zero;

//ex1 result is qNaN
//ex1_nv
//div_qnan
//  1.op0 is qnan || op1 is qnan
//sqrt_qnan
//  1.op0 is qnan
assign ex1_result_qnan   = ex1_div_rst_qnan  && ex1_div  ||
                           ex1_sqrt_rst_qnan && ex1_sqrt ||
                           ex1_nv;
assign ex1_div_rst_qnan  = ex1_op0_qnan ||
                           ex1_op1_qnan;
assign ex1_sqrt_rst_qnan = ex1_op0_qnan;

//ex1_rst_default_qnan
//0/0, inf/inf, sqrt negative should get default qNaN
assign ex1_rst_default_qnan = (ex1_div && ex1_op0_zero && ex1_op1_zero) ||
                              (ex1_div && ex1_op0_inf  && ex1_op1_inf)  ||
                              (ex1_sqrt&& ex1_op0_sign && (ex1_op0_norm || ex1_op0_inf));

//ex1 result is inf
//ex1_dz
//
//div_inf
//  1.op0 is inf && op1 is normal/zero
//sqrt_inf
//  1.op0 is inf
assign ex1_result_inf    = ex1_div_rst_inf  && ex1_div  ||
                           ex1_sqrt_rst_inf && ex1_sqrt ||
                           ex1_dz ;
// assign ex1_div_rst_inf   = ex1_op0_inf && !ex1_expnt1_max && !ex1_op1_cnan;
assign ex1_div_rst_inf   = ex1_op0_inf && !ex1_op1_inf && !ex1_op1_qnan && !ex1_op1_snan && !ex1_op1_cnan;
assign ex1_sqrt_rst_inf  = ex1_op0_inf && !ex1_op0_sign;

//ex1 result is lfn
//ex1_of && round result toward not inc 1
assign ex1_result_lfn = 1'b0;

//Default_qnan/Standard_qnan Select
assign ex1_op0_is_snan      = ex1_op0_snan;
assign ex1_op1_is_snan      = ex1_op1_snan && ex1_div;
assign ex1_op0_is_qnan      = ex1_op0_qnan;
assign ex1_op1_is_qnan      = ex1_op1_qnan && ex1_div;

// &CombBeg; @169
always @( ex1_op0_is_snan
       or ex1_op0_cnan
       or ex1_result_qnan
       or ex1_op0_is_qnan
       or ex1_rst_default_qnan
       or cp0_fpu_xx_dqnan
       or ex1_op1_cnan
       or ex1_op1_is_qnan
       or ex1_op1_is_snan)
begin
if(ex1_rst_default_qnan)
begin
  ex1_result_qnan_op0  = 1'b0;
  ex1_result_qnan_op1  = 1'b0;
  ex1_result_cnan      = ex1_result_qnan;
end
else if(ex1_op0_is_snan && cp0_fpu_xx_dqnan)
begin
  ex1_result_qnan_op0  = ex1_result_qnan;
  ex1_result_qnan_op1  = 1'b0;
  ex1_result_cnan      = 1'b0;
end
else if(ex1_op1_is_snan && cp0_fpu_xx_dqnan)
begin
  ex1_result_qnan_op0  = 1'b0;
  ex1_result_qnan_op1  = ex1_result_qnan;
  ex1_result_cnan      = 1'b0;
end
else if(ex1_op0_is_qnan && cp0_fpu_xx_dqnan)
begin
  ex1_result_qnan_op0  = ex1_result_qnan && !ex1_op0_cnan;
  ex1_result_qnan_op1  = 1'b0;
  ex1_result_cnan      = ex1_result_qnan &&  ex1_op0_cnan;
end
else if(ex1_op1_is_qnan && cp0_fpu_xx_dqnan)
begin
  ex1_result_qnan_op0  = 1'b0;
  ex1_result_qnan_op1  = ex1_result_qnan && !ex1_op1_cnan;
  ex1_result_cnan      = ex1_result_qnan &&  ex1_op1_cnan;
end
else
begin
  ex1_result_qnan_op0  = 1'b0;
  ex1_result_qnan_op1  = 1'b0;
  ex1_result_cnan      = ex1_result_qnan;
end
// &CombEnd; @206
end


//Special result should skip SRT logic
assign ex1_srt_skip = ex1_result_zero ||
                      ex1_result_qnan ||
                      ex1_result_lfn  ||
                      ex1_result_inf;
// fflags:
// NV, DZ, OF, UF, NX
assign ex1_fflags[4:0] = {ex1_nv, ex1_dz, 3'b0};
// Special Sel[7:0]:
// qnan_src2, qnan_src1, qnan_src0, cnan, lfn, inf, zero, src2
assign ex1_special_sel[7:0] = {1'b0, ex1_result_qnan_op1, ex1_result_qnan_op0,
                               ex1_result_cnan, ex1_result_lfn, ex1_result_inf,
                               ex1_result_zero, 1'b0};
// Special Sign[3:0]
// lfn, inf, zero, src2
assign ex1_special_sign[3:0] = {ex1_result_sign, ex1_result_sign, ex1_result_sign, 1'b0};

//==========================================================
//                      Output Signal
//==========================================================
assign fdsu_fpu_ex1_fflags[4:0]       = ex1_fflags[4:0];
assign fdsu_fpu_ex1_special_sel[7:0]  = ex1_special_sel[7:0];
assign fdsu_fpu_ex1_special_sign[3:0] = ex1_special_sign[3:0];

// &Force("output", "ex1_op0_norm"); @233
// &Force("output", "ex1_op1_norm"); @234

// &ModuleEnd; @236
endmodule



/*Copyright 2020-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// &ModuleBeg; @23
module pa_fdsu_srt_single(
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

// &Ports; @24
input           cp0_fpu_icg_en;
input           cp0_yy_clk_en;
input   [23:0]  ex1_divisor;
input   [12:0]  ex1_expnt_adder_op1;
input   [51:0]  ex1_oper_id_frac;
input           ex1_pipedown;
input           ex1_pipedown_gate;
input   [31:0]  ex1_remainder;
input           ex1_save_op0;
input           ex1_save_op0_gate;
input   [9 :0]  ex2_expnt_adder_op0;
input           ex2_pipe_clk;
input           ex2_pipedown;
input           ex2_srt_first_round;
input   [25:0]  ex3_frac_final_rst;
input           ex3_pipedown;
input           fdsu_yy_div;
input           fdsu_yy_of_rm_lfn;
input           fdsu_yy_op0_norm;
input           fdsu_yy_op1_norm;
input           fdsu_yy_sqrt;
input           forever_cpuclk;
input           pad_yy_icg_scan_en;
input           srt_sm_on;
output  [51:0]  ex1_oper_id_frac_f;
output          ex2_of;
output          ex2_potnt_of;
output          ex2_potnt_uf;
output          ex2_result_inf;
output          ex2_result_lfn;
output          ex2_rslt_denorm;
output  [9 :0]  ex2_srt_expnt_rst;
output          ex2_uf;
output          ex2_uf_srt_skip;
output          fdsu_ex3_id_srt_skip;
output          fdsu_ex3_rem_sign;
output          fdsu_ex3_rem_zero;
output  [23:0]  fdsu_ex3_result_denorm_round_add_num;
output  [25:0]  fdsu_ex4_frac;
output          srt_remainder_zero;
output  [29:0]  total_qt_rt_30;

// &Regs; @25
reg     [31:0]  cur_rem;
reg     [7 :0]  digit_bound_1;
reg     [7 :0]  digit_bound_2;
reg     [23:0]  ex2_result_denorm_round_add_num;
reg             fdsu_ex3_id_srt_skip;
reg             fdsu_ex3_rem_sign;
reg             fdsu_ex3_rem_zero;
reg     [23:0]  fdsu_ex3_result_denorm_round_add_num;
reg     [29:0]  qt_rt_const_shift_std;
reg     [7 :0]  qtrt_sel_rem;
reg     [31:0]  rem_add1_op1;
reg     [31:0]  rem_add2_op1;
reg     [25:0]  srt_divisor;
reg     [31:0]  srt_remainder;
reg     [29:0]  total_qt_rt_30;
reg     [29:0]  total_qt_rt_30_next;
reg     [29:0]  total_qt_rt_minus_30;
reg     [29:0]  total_qt_rt_minus_30_next;

// &Wires; @26
wire    [7 :0]  bound1_cmp_result;
wire            bound1_cmp_sign;
wire    [7 :0]  bound2_cmp_result;
wire            bound2_cmp_sign;
wire    [3 :0]  bound_sel;
wire            cp0_fpu_icg_en;
wire            cp0_yy_clk_en;
wire    [31:0]  cur_doub_rem_1;
wire    [31:0]  cur_doub_rem_2;
wire    [31:0]  cur_rem_1;
wire    [31:0]  cur_rem_2;
wire    [31:0]  div_qt_1_rem_add_op1;
wire    [31:0]  div_qt_2_rem_add_op1;
wire    [31:0]  div_qt_r1_rem_add_op1;
wire    [31:0]  div_qt_r2_rem_add_op1;
wire    [23:0]  ex1_divisor;
wire            ex1_ex2_pipe_clk;
wire            ex1_ex2_pipe_clk_en;
wire    [12:0]  ex1_expnt_adder_op1;
wire    [51:0]  ex1_oper_id_frac;
wire    [51:0]  ex1_oper_id_frac_f;
wire            ex1_pipedown;
wire            ex1_pipedown_gate;
wire    [31:0]  ex1_remainder;
wire            ex1_save_op0;
wire            ex1_save_op0_gate;
wire            ex2_div_of;
wire            ex2_div_uf;
wire    [9 :0]  ex2_expnt_adder_op0;
wire    [9 :0]  ex2_expnt_adder_op1;
wire            ex2_expnt_of;
wire    [9 :0]  ex2_expnt_result;
wire            ex2_expnt_uf;
wire            ex2_id_nor_srt_skip;
wire            ex2_of;
wire            ex2_of_plus;
wire            ex2_pipe_clk;
wire            ex2_pipedown;
wire            ex2_potnt_of;
wire            ex2_potnt_of_pre;
wire            ex2_potnt_uf;
wire            ex2_potnt_uf_pre;
wire            ex2_result_inf;
wire            ex2_result_lfn;
wire            ex2_rslt_denorm;
wire    [9 :0]  ex2_sqrt_expnt_result;
wire    [9 :0]  ex2_srt_expnt_rst;
wire            ex2_srt_first_round;
wire            ex2_uf;
wire            ex2_uf_plus;
wire            ex2_uf_srt_skip;
wire    [25:0]  ex3_frac_final_rst;
wire            ex3_pipedown;
wire            fdsu_ex2_div;
wire    [9 :0]  fdsu_ex2_expnt_rst;
wire            fdsu_ex2_of_rm_lfn;
wire            fdsu_ex2_op0_norm;
wire            fdsu_ex2_op1_norm;
wire            fdsu_ex2_result_lfn;
wire            fdsu_ex2_sqrt;
wire    [25:0]  fdsu_ex4_frac;
wire            fdsu_yy_div;
wire            fdsu_yy_of_rm_lfn;
wire            fdsu_yy_op0_norm;
wire            fdsu_yy_op1_norm;
wire            fdsu_yy_sqrt;
wire            forever_cpuclk;
wire            pad_yy_icg_scan_en;
wire            qt_clk;
wire            qt_clk_en;
wire    [29:0]  qt_rt_const_pre_sel_q1;
wire    [29:0]  qt_rt_const_pre_sel_q2;
wire    [29:0]  qt_rt_const_q1;
wire    [29:0]  qt_rt_const_q2;
wire    [29:0]  qt_rt_const_q3;
wire    [29:0]  qt_rt_const_shift_std_next;
wire    [29:0]  qt_rt_mins_const_pre_sel_q1;
wire    [29:0]  qt_rt_mins_const_pre_sel_q2;
wire            rem_sign;
wire    [31:0]  sqrt_qt_1_rem_add_op1;
wire    [31:0]  sqrt_qt_2_rem_add_op1;
wire    [31:0]  sqrt_qt_r1_rem_add_op1;
wire    [31:0]  sqrt_qt_r2_rem_add_op1;
wire            srt_div_clk;
wire            srt_div_clk_en;
wire    [31:0]  srt_remainder_nxt;
wire    [31:0]  srt_remainder_shift;
wire            srt_remainder_sign;
wire            srt_remainder_zero;
wire            srt_sm_on;
wire    [29:0]  total_qt_rt_pre_sel;


assign fdsu_ex2_div             = fdsu_yy_div;
assign fdsu_ex2_sqrt            = fdsu_yy_sqrt;
assign fdsu_ex2_op0_norm        = fdsu_yy_op0_norm;
assign fdsu_ex2_op1_norm        = fdsu_yy_op1_norm;
assign fdsu_ex2_of_rm_lfn       = fdsu_yy_of_rm_lfn;
assign fdsu_ex2_result_lfn      = 1'b0;

//==========================================================
//                    EX2 Expnt Generate
//==========================================================
//expnt0 sub expnt1
assign ex2_expnt_result[9:0] =  ex2_expnt_adder_op0[9:0] -
                                 ex2_expnt_adder_op1[9:0];

//===================sqrt exponent prepare==================
//sqrt exponent prepare
//afert E sub, div E by 2
assign ex2_sqrt_expnt_result[9:0] = {ex2_expnt_result[9],
                                      ex2_expnt_result[9:1]};

assign ex2_srt_expnt_rst[9:0] = (fdsu_ex2_sqrt)
                               ? ex2_sqrt_expnt_result[9:0]
                               : ex2_expnt_result[9:0];
// &Force("output", "ex2_srt_expnt_rst"); &Force("bus", "ex2_srt_expnt_rst", 9, 0); @51
assign fdsu_ex2_expnt_rst[9:0] = ex2_srt_expnt_rst[9:0];


//====================EX2 Expt info=========================
//EX1 only detect of/uf under id condition
//EX2 will deal with other condition

//When input is normal, overflow when E1-E2 > 128/1024
assign ex2_expnt_of = ~fdsu_ex2_expnt_rst[9] && (fdsu_ex2_expnt_rst[8]
                                                      || (fdsu_ex2_expnt_rst[7]  &&
                                                          |fdsu_ex2_expnt_rst[6:0]));
//potential overflow when E1-E2 = 128/1024
assign ex2_potnt_of_pre = ~fdsu_ex2_expnt_rst[9]  &&
                           ~fdsu_ex2_expnt_rst[8]  &&
                            fdsu_ex2_expnt_rst[7]  &&
                          ~|fdsu_ex2_expnt_rst[6:0];
assign ex2_potnt_of      = ex2_potnt_of_pre &&
                           fdsu_ex2_op0_norm &&
                           fdsu_ex2_op1_norm &&
                           fdsu_ex2_div;

//When input is normal, underflow when E1-E2 <= -127/-1023
assign ex2_expnt_uf = fdsu_ex2_expnt_rst[9] &&(fdsu_ex2_expnt_rst[8:0] <= 9'h181);
//potential underflow when E1-E2 = -126/-1022
assign ex2_potnt_uf_pre = &fdsu_ex2_expnt_rst[9:7]   &&
                          ~|fdsu_ex2_expnt_rst[6:2]   &&
                            fdsu_ex2_expnt_rst[1]     &&
                           !fdsu_ex2_expnt_rst[0];
assign ex2_potnt_uf      = (ex2_potnt_uf_pre &&
                            fdsu_ex2_op0_norm &&
                            fdsu_ex2_op1_norm &&
                            fdsu_ex2_div)     ||
                           (ex2_potnt_uf_pre   &&
                            fdsu_ex2_op0_norm);

//========================EX2 Overflow======================
//ex2 overflow when
//  1.op0 & op1 both norm && expnt overflow
//  2.ex1_id_of
// &Force("output","ex2_of"); @91
assign ex2_of      = ex2_of_plus;
assign ex2_of_plus = ex2_div_of  && fdsu_ex2_div;
assign ex2_div_of  = fdsu_ex2_op0_norm &&
                     fdsu_ex2_op1_norm &&
                     ex2_expnt_of;

//=======================EX2 Underflow======================
//ex2 underflow when
//  1.op0 & op1 both norm && expnt underflow
//  2.ex1_id_uf
//  and detect when to skip the srt, here, we have further optmization
assign ex2_uf      = ex2_uf_plus;
assign ex2_uf_plus = ex2_div_uf  && fdsu_ex2_div;
assign ex2_div_uf  = fdsu_ex2_op0_norm &&
                     fdsu_ex2_op1_norm &&
                     ex2_expnt_uf;
assign ex2_id_nor_srt_skip =  fdsu_ex2_expnt_rst[9]
                                     && (fdsu_ex2_expnt_rst[8:0]<9'h16a);
assign ex2_uf_srt_skip            = ex2_id_nor_srt_skip;
assign ex2_rslt_denorm            = ex2_uf;
//===============ex2 round prepare for denormal round======
// &CombBeg; @113
always @( fdsu_ex2_expnt_rst[9:0])
begin
case(fdsu_ex2_expnt_rst[9:0])
  10'h382:ex2_result_denorm_round_add_num[23:0] = 24'h1; //-126 1
  10'h381:ex2_result_denorm_round_add_num[23:0] = 24'h2; //-127 0
  10'h380:ex2_result_denorm_round_add_num[23:0] = 24'h4; //-128 -1
  10'h37f:ex2_result_denorm_round_add_num[23:0] = 24'h8; //-129 -2
  10'h37e:ex2_result_denorm_round_add_num[23:0] = 24'h10; //-130 -3
  10'h37d:ex2_result_denorm_round_add_num[23:0] = 24'h20; //-131 -4
  10'h37c:ex2_result_denorm_round_add_num[23:0] = 24'h40; //-132 -5
  10'h37b:ex2_result_denorm_round_add_num[23:0] = 24'h80; //-133 -6
  10'h37a:ex2_result_denorm_round_add_num[23:0] = 24'h100; //-134 -7
  10'h379:ex2_result_denorm_round_add_num[23:0] = 24'h200; //-135 -8
  10'h378:ex2_result_denorm_round_add_num[23:0] = 24'h400; //-136 -9
  10'h377:ex2_result_denorm_round_add_num[23:0] = 24'h800; //-137 -10
  10'h376:ex2_result_denorm_round_add_num[23:0] = 24'h1000; //-138 -11
  10'h375:ex2_result_denorm_round_add_num[23:0] = 24'h2000; //-139 -12
  10'h374:ex2_result_denorm_round_add_num[23:0] = 24'h4000; //-140 -13
  10'h373:ex2_result_denorm_round_add_num[23:0] = 24'h8000; // -141 -14
  10'h372:ex2_result_denorm_round_add_num[23:0] = 24'h10000;//-142  -15
  10'h371:ex2_result_denorm_round_add_num[23:0] = 24'h20000;//-143 -16
  10'h370:ex2_result_denorm_round_add_num[23:0] = 24'h40000; //-144 -17
  10'h36f:ex2_result_denorm_round_add_num[23:0] = 24'h80000; //-145 -18
  10'h36e:ex2_result_denorm_round_add_num[23:0] = 24'h100000; //-146 -19
  10'h36d:ex2_result_denorm_round_add_num[23:0] = 24'h200000; //-147 -20
  10'h36c:ex2_result_denorm_round_add_num[23:0] = 24'h400000; //-148 -21
  10'h36b:ex2_result_denorm_round_add_num[23:0] = 24'h800000; //-148 -22
  default: ex2_result_denorm_round_add_num[23:0] = 24'h0;  // -23
endcase
// &CombEnd; @141
end

//===================special result========================
assign ex2_result_inf  = ex2_of_plus && !fdsu_ex2_of_rm_lfn;
assign ex2_result_lfn  = fdsu_ex2_result_lfn ||
                         ex2_of_plus &&  fdsu_ex2_of_rm_lfn;



//====================Pipe to EX3===========================
always @(posedge ex1_ex2_pipe_clk)
begin
  if(ex1_pipedown)
  begin
    fdsu_ex3_result_denorm_round_add_num[23:0]
                              <= {14'b0, ex1_expnt_adder_op1[9:0]};
  end
  else if(ex2_pipedown)
  begin
    fdsu_ex3_result_denorm_round_add_num[23:0]
                              <= ex2_result_denorm_round_add_num[23:0];
  end
  else
  begin
    fdsu_ex3_result_denorm_round_add_num[23:0]
                              <= fdsu_ex3_result_denorm_round_add_num[23:0];
  end
end
assign ex2_expnt_adder_op1 = fdsu_ex3_result_denorm_round_add_num[9:0];
// &Force("bus", "ex1_expnt_adder_op1", 12, 0); @193

assign ex1_ex2_pipe_clk_en = ex1_pipedown_gate || ex2_pipedown;
// &Instance("gated_clk_cell", "x_ex1_ex2_pipe_clk"); @196
gated_clk_cell  x_ex1_ex2_pipe_clk (
  .clk_in              (forever_cpuclk     ),
  .clk_out             (ex1_ex2_pipe_clk   ),
  .external_en         (1'b0               ),
  .global_en           (cp0_yy_clk_en      ),
  .local_en            (ex1_ex2_pipe_clk_en),
  .module_en           (cp0_fpu_icg_en     ),
  .pad_yy_icg_scan_en  (pad_yy_icg_scan_en )
);

// &Connect(.clk_in      (forever_cpuclk), @197
//          .external_en (1'b0), @198
//          .global_en   (cp0_yy_clk_en), @199
//          .module_en   (cp0_fpu_icg_en), @200
//          .local_en    (ex1_ex2_pipe_clk_en), @201
//          .clk_out     (ex1_ex2_pipe_clk)); @202

always @(posedge ex2_pipe_clk)
begin
  if(ex2_pipedown)
  begin
    fdsu_ex3_rem_sign        <= srt_remainder_sign;
    fdsu_ex3_rem_zero        <= srt_remainder_zero;
    fdsu_ex3_id_srt_skip     <= ex2_id_nor_srt_skip;
  end
  else
  begin
    fdsu_ex3_rem_sign        <= fdsu_ex3_rem_sign;
    fdsu_ex3_rem_zero        <= fdsu_ex3_rem_zero;
    fdsu_ex3_id_srt_skip    <=  fdsu_ex3_id_srt_skip;
  end
end

// &Force("output","fdsu_ex3_rem_sign"); @243
// &Force("output","fdsu_ex3_rem_zero"); @244
// &Force("output","fdsu_ex3_result_denorm_round_add_num"); @245
// &Force("output","fdsu_ex3_id_srt_skip"); @246

//==========================================================
//    SRT Remainder & Divisor for Quotient/Root Generate
//==========================================================

//===================Remainder Generate=====================
//gate clk
// &Instance("gated_clk_cell","x_srt_rem_clk");
// // &Connect( .clk_in         (forever_cpuclk), @255
// //           .clk_out        (srt_rem_clk),//Out Clock @256
// //           .external_en    (1'b0), @257
// //           .global_en      (cp0_yy_clk_en), @258
// //           .local_en       (srt_rem_clk_en),//Local Condition @259
// //           .module_en      (cp0_fpu_icg_en) @260
// //         ); @261
// assign srt_rem_clk_en = ex1_pipedown ||
//                         srt_sm_on;

always @(posedge qt_clk)
begin
  if (ex1_pipedown)
    srt_remainder[31:0] <= ex1_remainder[31:0];
  else if (srt_sm_on)
    srt_remainder[31:0] <= srt_remainder_nxt[31:0];
  else
    srt_remainder[31:0] <= srt_remainder[31:0];
end

//=====================Divisor Generate=====================
//gate clk
// &Instance("gated_clk_cell","x_srt_div_clk"); @291
gated_clk_cell  x_srt_div_clk (
  .clk_in             (forever_cpuclk    ),
  .clk_out            (srt_div_clk       ),
  .external_en        (1'b0              ),
  .global_en          (cp0_yy_clk_en     ),
  .local_en           (srt_div_clk_en    ),
  .module_en          (cp0_fpu_icg_en    ),
  .pad_yy_icg_scan_en (pad_yy_icg_scan_en)
);

// &Connect( .clk_in         (forever_cpuclk), @292
//           .clk_out        (srt_div_clk),//Out Clock @293
//           .external_en    (1'b0), @294
//           .global_en      (cp0_yy_clk_en), @295
//           .local_en       (srt_div_clk_en),//Local Condition @296
//           .module_en      (cp0_fpu_icg_en) @297
//         ); @298
assign srt_div_clk_en = ex1_pipedown_gate
                     || ex1_save_op0_gate
                     || ex3_pipedown;
// final_rst saved in srt_divisor.
// srt_divisor is 26 bits, final_rst is 24 bits.
always @(posedge srt_div_clk)
begin
  if (ex1_save_op0)
    srt_divisor[25:0] <= {3'b0, {ex1_oper_id_frac[51:29]}};
  else if (ex1_pipedown)
    srt_divisor[25:0] <= {2'b0, ex1_divisor[23:0]};
  else if (ex3_pipedown)
    srt_divisor[25:0] <= ex3_frac_final_rst[25:0];
  else
    srt_divisor[25:0] <= srt_divisor[25:0];
end
assign ex1_oper_id_frac_f[51:0] = {srt_divisor[22:0], 29'b0};
// &Force("bus", "ex1_oper_id_frac", 51, 0); @332
assign fdsu_ex4_frac[25:0] = srt_divisor[25:0];

//=======================Bound Select=======================
//---------------------------------------+
// K   | 8 | 9 | 10| 11| 12| 13| 14|15,16|
//---------------------------------------+
//32S1 | 7 | 7 | 8 | 9 | 9 | 10| 11|  12 |
//---------------------------------------+
//32S2 | 25| 28| 31| 33| 36| 39| 41|  47 |
//---------------------------------------+

//bound_sel[3:0]
//For div,  use divisor high four bit as K
//For sqrt, use 2qi high four bit as K next round and
//          use 1010 as K first round
assign bound_sel[3:0] = (fdsu_ex2_div)
                      ? srt_divisor[23:20]
                      : (ex2_srt_first_round)
                        ? 4'b1010
                        : total_qt_rt_30[28:25];
//Select bound as look up table
//   K = bound_sel[3:0]
//32S1 = digit_bound_1[7:0]
//32s2 = digit_bound_2[7:0]
// &CombBeg; @357
always @( bound_sel[3:0])
begin
case(bound_sel[3:0])
4'b0000:       //when first interation get "10", choose k=16
   begin
     digit_bound_1[7:0] = 8'b11110100;//-12
     digit_bound_2[7:0] = 8'b11010001;//-47
   end
4'b1000:
   begin
     digit_bound_1[7:0] = 8'b11111001;//-7
     digit_bound_2[7:0] = 8'b11100111;//-25
   end
4'b1001:
   begin
     digit_bound_1[7:0] = 8'b11111001;//-7
     digit_bound_2[7:0] = 8'b11100100;//-28
   end
4'b1010:
   begin
     digit_bound_1[7:0] = 8'b11111000;//-8
     digit_bound_2[7:0] = 8'b11100001;//-31
   end
4'b1011:
   begin
     digit_bound_1[7:0] = 8'b11110111;//-9
     digit_bound_2[7:0] = 8'b11011111;//-33
   end
4'b1100:
   begin
     digit_bound_1[7:0] = 8'b11110111;//-9
     digit_bound_2[7:0] = 8'b11011100;//-36
   end
4'b1101:
   begin
     digit_bound_1[7:0] = 8'b11110110;//-10
     digit_bound_2[7:0] = 8'b11011001;//-39
   end
4'b1110:
   begin
     digit_bound_1[7:0] = 8'b11110101;//-11
     digit_bound_2[7:0] = 8'b11010111;//-41
   end
4'b1111:
   begin
     digit_bound_1[7:0] = 8'b11110100;//-12
     digit_bound_2[7:0] = 8'b11010001;//-47
   end
default:
   begin
     digit_bound_1[7:0] = 8'b11111001;//-7
     digit_bound_2[7:0] = 8'b11100111;//-25
   end
endcase
// &CombEnd; @410
end

//==============Prepare for quotient generate===============
assign bound1_cmp_result[7:0] = qtrt_sel_rem[7:0] + digit_bound_1[7:0];
assign bound2_cmp_result[7:0] = qtrt_sel_rem[7:0] + digit_bound_2[7:0];
assign bound1_cmp_sign        = bound1_cmp_result[7];
assign bound2_cmp_sign        = bound2_cmp_result[7];
assign rem_sign               = srt_remainder[29];

//qtrt_sel_rem is use to select quotient
//Only when sqrt first round use 8R0 select quotient(special rule)
//4R0 is used to select quotient on other condition
//For negative remaider, we use ~rem not (~rem + 1)
//Because  bound1 <=  rem   <   bound2, when positive rem
//        -bound2 <=  rem   <  -bound1, when negative rem
//Thus     bound1 <  -rem   <=  bound2, when negative rem
//Thus     bound1 <= -rem-1 <   bound2, when negative rem
//Thus     bound1 <= ~rem   <   bound2, when negative rem
//srt_remainder[29] used as sign bit
// &CombBeg; @429
always @( ex2_srt_first_round
       or fdsu_ex2_sqrt
       or srt_remainder[29:21])
begin
if(ex2_srt_first_round && fdsu_ex2_sqrt)
  qtrt_sel_rem[7:0] = {srt_remainder[29],   srt_remainder[27:21]};
else
  qtrt_sel_rem[7:0] =  srt_remainder[29] ? ~srt_remainder[29:22]
                                         :  srt_remainder[29:22];
// &CombEnd; @435
end

//==========================================================
//     on fly round method to generate total quotient
//==========================================================
//gate clk
// &Instance("gated_clk_cell","x_qt_clk"); @441
gated_clk_cell  x_qt_clk (
  .clk_in             (forever_cpuclk    ),
  .clk_out            (qt_clk            ),
  .external_en        (1'b0              ),
  .global_en          (cp0_yy_clk_en     ),
  .local_en           (qt_clk_en         ),
  .module_en          (cp0_fpu_icg_en    ),
  .pad_yy_icg_scan_en (pad_yy_icg_scan_en)
);

// &Connect( .clk_in         (forever_cpuclk), @442
//           .clk_out        (qt_clk),//Out Clock @443
//           .external_en    (1'b0), @444
//           .global_en      (cp0_yy_clk_en), @445
//           .local_en       (qt_clk_en),//Local Condition @446
//           .module_en      (cp0_fpu_icg_en) @447
//         ); @448
assign qt_clk_en = srt_sm_on ||
                   ex1_pipedown_gate;

//qt_rt_const_shift_std[29:0] is const data for on fly round
//                which is used to record the times of round
//
//total_qt_rt[29:0]       is total quotient
//total_qt_rt_minus[29:0] is total quotient minus
//                which is used to generate quotient rapidly
always @(posedge qt_clk)
begin
  if(ex1_pipedown)
  begin
    qt_rt_const_shift_std[29:0] <= {1'b0,1'b1,28'b0};
    total_qt_rt_30[29:0]        <= 30'b0;
    total_qt_rt_minus_30[29:0]  <= 30'b0;
  end
  else if(srt_sm_on)
  begin
    qt_rt_const_shift_std[29:0] <= qt_rt_const_shift_std_next[29:0];
    total_qt_rt_30[29:0]        <= total_qt_rt_30_next[29:0];
    total_qt_rt_minus_30[29:0]  <= total_qt_rt_minus_30_next[29:0];
  end
  else
  begin
    qt_rt_const_shift_std[29:0] <= qt_rt_const_shift_std[29:0];
    total_qt_rt_30[29:0]        <= total_qt_rt_30[29:0];
    total_qt_rt_minus_30[29:0]  <= total_qt_rt_minus_30[29:0];
  end
end
// &Force("output","total_qt_rt_30"); @508

//qt_rt_const_q1/q2/q3 for shift 1/2/3 in
assign qt_rt_const_q1[29:0] =  qt_rt_const_shift_std[29:0];
assign qt_rt_const_q2[29:0] = {qt_rt_const_shift_std[28:0],1'b0};
assign qt_rt_const_q3[29:0] =  qt_rt_const_q1[29:0] |
                               qt_rt_const_q2[29:0];
//qt_rt_const update value
assign qt_rt_const_shift_std_next[29:0] = {2'b0, qt_rt_const_shift_std[29:2]};

//========total_qt_rt & total_qt_rt_minus update value======
//q(i+1) is the total quotient/root after the (i+1) digit
//is calculated
//                 q(i+1)             qm(i+1)
//d(i+1)=-2     qm(i)+2*shift      qm(i)+1*shift
//d(i+1)=-1     qm(i)+3*shift      qm(i)+2*shift
//d(i+1)=0      q(i)               qm(i)+3*shift
//d(i+1)=1      q(i)+1*shift       q(i)
//d(i+1)=2      q(i)+2*shift       q(i)+1*shift
//Note:
//shift = 4^(-i-1), qm(i+1)=q(i+1)-shift

//pre select for quotient
assign total_qt_rt_pre_sel[29:0]         = (rem_sign) ?
                                           total_qt_rt_minus_30[29:0] :
                                           total_qt_rt_30[29:0];
//when the quotient is 2 or -2
assign qt_rt_const_pre_sel_q2[29:0]      = qt_rt_const_q2[29:0];
assign qt_rt_mins_const_pre_sel_q2[29:0] = qt_rt_const_q1[29:0];
//when the quotient is 1 or -1
assign qt_rt_const_pre_sel_q1[29:0]      = (rem_sign) ?
                                           qt_rt_const_q3[29:0] ://-1
                                           qt_rt_const_q1[29:0]; //1
assign qt_rt_mins_const_pre_sel_q1[29:0] = (rem_sign) ?
                                           qt_rt_const_q2[29:0] : //-1
                                           30'b0;

//After bound compare, the final selection
// &CombBeg; @546
always @( qt_rt_const_q3[29:0]
       or qt_rt_mins_const_pre_sel_q1[29:0]
       or bound1_cmp_sign
       or total_qt_rt_30[29:0]
       or qt_rt_mins_const_pre_sel_q2[29:0]
       or total_qt_rt_minus_30[29:0]
       or bound2_cmp_sign
       or qt_rt_const_pre_sel_q2[29:0]
       or qt_rt_const_pre_sel_q1[29:0]
       or total_qt_rt_pre_sel[29:0])
begin
casez({bound1_cmp_sign,bound2_cmp_sign})
  2'b00:// the quotient is -2 or 2
  begin
    total_qt_rt_30_next[29:0]       = total_qt_rt_pre_sel[29:0] |
                                      qt_rt_const_pre_sel_q2[29:0];
    total_qt_rt_minus_30_next[29:0] = total_qt_rt_pre_sel[29:0] |
                                      qt_rt_mins_const_pre_sel_q2[29:0];
  end
  2'b01:// quotient is -1 or 1
  begin
    total_qt_rt_30_next[29:0]       = total_qt_rt_pre_sel[29:0] |
                                      qt_rt_const_pre_sel_q1[29:0];
    total_qt_rt_minus_30_next[29:0] = total_qt_rt_pre_sel[29:0] |
                                      qt_rt_mins_const_pre_sel_q1[29:0];
  end
  2'b1?: // quotient is 0
  begin
    total_qt_rt_30_next[29:0]       = total_qt_rt_30[29:0];
    total_qt_rt_minus_30_next[29:0] = total_qt_rt_minus_30[29:0] |
                                      qt_rt_const_q3[29:0];
  end
  default:
  begin
    total_qt_rt_30_next[29:0]       = 30'b0;
    total_qt_rt_minus_30_next[29:0] = 30'b0;
  end
endcase
// &CombEnd; @574
end

//==========================================================
//      on fly round method to generate cur remainder
//==========================================================
//Division emainder add value
//Quoit 1
assign div_qt_1_rem_add_op1[31:0]   = ~{3'b0,srt_divisor[23:0],5'b0};
//Quoit 2
assign div_qt_2_rem_add_op1[31:0]   = ~{2'b0,srt_divisor[23:0],6'b0};
//Quoit -1
assign div_qt_r1_rem_add_op1[31:0]  =  {3'b0,srt_divisor[23:0],5'b0};
//Quoit -2
assign div_qt_r2_rem_add_op1[31:0]  =  {2'b0,srt_divisor[23:0],6'b0};

//Sqrt remainder add value op1
//Quoit 1
assign sqrt_qt_1_rem_add_op1[31:0]  = ~({2'b0,total_qt_rt_30[29:0]} |
                                        {3'b0,qt_rt_const_q1[29:1]});
//Quoit 2
assign sqrt_qt_2_rem_add_op1[31:0]  = ~({1'b0,total_qt_rt_30[29:0],1'b0} |
                                        {1'b0,qt_rt_const_q1[29:0],1'b0});
//Quoit -1
assign sqrt_qt_r1_rem_add_op1[31:0] =   {2'b0,total_qt_rt_minus_30[29:0]} |
                                        {1'b0,qt_rt_const_q1[29:0],1'b0}  |
                                        {2'b0,qt_rt_const_q1[29:0]}       |
                                        {3'b0,qt_rt_const_q1[29:1]};
//Quoit -2
assign sqrt_qt_r2_rem_add_op1[31:0] =   {1'b0,
                                         total_qt_rt_minus_30[29:0],1'b0} |
                                        {qt_rt_const_q1[29:0],2'b0}       |
                                        {1'b0,qt_rt_const_q1[29:0],1'b0};
//Remainder Adder select logic
// &CombBeg; @607
always @( div_qt_2_rem_add_op1[31:0]
       or sqrt_qt_r2_rem_add_op1[31:0]
       or sqrt_qt_r1_rem_add_op1[31:0]
       or rem_sign
       or div_qt_r2_rem_add_op1[31:0]
       or div_qt_1_rem_add_op1[31:0]
       or sqrt_qt_2_rem_add_op1[31:0]
       or fdsu_ex2_sqrt
       or div_qt_r1_rem_add_op1[31:0]
       or sqrt_qt_1_rem_add_op1[31:0])
begin
case({rem_sign,fdsu_ex2_sqrt})
  2'b01:
  begin
        rem_add1_op1[31:0] = sqrt_qt_1_rem_add_op1[31:0];
        rem_add2_op1[31:0] = sqrt_qt_2_rem_add_op1[31:0];
  end
  2'b00:
  begin
        rem_add1_op1[31:0] = div_qt_1_rem_add_op1[31:0];
        rem_add2_op1[31:0] = div_qt_2_rem_add_op1[31:0];
  end
  2'b11:
  begin
        rem_add1_op1[31:0] = sqrt_qt_r1_rem_add_op1[31:0];
        rem_add2_op1[31:0] = sqrt_qt_r2_rem_add_op1[31:0];
  end
  2'b10:
  begin
        rem_add1_op1[31:0] = div_qt_r1_rem_add_op1[31:0];
        rem_add2_op1[31:0] = div_qt_r2_rem_add_op1[31:0];
  end
  default :
  begin
        rem_add1_op1[31:0] = 32'b0;
        rem_add2_op1[31:0] = 32'b0;
  end
  endcase
// &CombEnd; @635
end
assign srt_remainder_shift[31:0] = {srt_remainder[31],
                                    srt_remainder[28:0],2'b0};
//Remainder add
assign cur_doub_rem_1[31:0]      = srt_remainder_shift[31:0] +
                                   rem_add1_op1[31:0]    +
                                   {31'b0, ~rem_sign};
assign cur_doub_rem_2[31:0]      = srt_remainder_shift[31:0] +
                                   rem_add2_op1[31:0]    +
                                   {31'b0, ~rem_sign};
assign cur_rem_1[31:0]           = cur_doub_rem_1[31:0];
assign cur_rem_2[31:0]           = cur_doub_rem_2[31:0];
//Generate srt remainder update value
// &CombBeg; @648
always @( cur_rem_2[31:0]
       or bound1_cmp_sign
       or srt_remainder_shift[31:0]
       or bound2_cmp_sign
       or cur_rem_1[31:0])
begin
case({bound1_cmp_sign,bound2_cmp_sign})
  2'b00:   cur_rem[31:0]         = cur_rem_2[31:0];  //+-2
  2'b01:   cur_rem[31:0]         = cur_rem_1[31:0];  //+-1
  default: cur_rem[31:0]         = srt_remainder_shift[31:0]; //0
endcase
// &CombEnd; @654
end
assign srt_remainder_nxt[31:0]   = cur_rem[31:0];

//Remainder is zero signal in EX3
assign srt_remainder_zero        = ~|srt_remainder[31:0];
// &Force("output","srt_remainder_zero"); @659
assign srt_remainder_sign        =   srt_remainder[31];

// &Force("output", "ex2_uf"); @662
// &ModuleEnd; @663
endmodule



/*Copyright 2020-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// &ModuleBeg; @23
module pa_fdsu_top(
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

// &Ports; @24
input           cp0_fpu_icg_en;
input           cp0_fpu_xx_dqnan;
input           cp0_yy_clk_en;
input           cpurst_b;
input           ctrl_fdsu_ex1_sel;
input           ctrl_xx_ex1_cmplt_dp;
input           ctrl_xx_ex1_inst_vld;
input           ctrl_xx_ex1_stall;
input           ctrl_xx_ex1_warm_up;
input           ctrl_xx_ex2_warm_up;
input           ctrl_xx_ex3_warm_up;
input   [2 :0]  dp_xx_ex1_cnan;
input   [2 :0]  dp_xx_ex1_id;
input   [2 :0]  dp_xx_ex1_inf;
input   [2 :0]  dp_xx_ex1_qnan;
input   [2 :0]  dp_xx_ex1_rm;
input   [2 :0]  dp_xx_ex1_snan;
input   [2 :0]  dp_xx_ex1_zero;
input           forever_cpuclk;
input           frbus_fdsu_wb_grant;
input   [4 :0]  idu_fpu_ex1_dst_freg;
input   [2 :0]  idu_fpu_ex1_eu_sel;
input   [9 :0]  idu_fpu_ex1_func;
input   [31:0]  idu_fpu_ex1_srcf0;
input   [31:0]  idu_fpu_ex1_srcf1;
input           pad_yy_icg_scan_en;
input           rtu_xx_ex1_cancel;
input           rtu_xx_ex2_cancel;
input           rtu_yy_xx_async_flush;
input           rtu_yy_xx_flush;
output  [4 :0]  fdsu_fpu_debug_info;
output          fdsu_fpu_ex1_cmplt;
output          fdsu_fpu_ex1_cmplt_dp;
output  [4 :0]  fdsu_fpu_ex1_fflags;
output  [7 :0]  fdsu_fpu_ex1_special_sel;
output  [3 :0]  fdsu_fpu_ex1_special_sign;
output          fdsu_fpu_ex1_stall;
output          fdsu_fpu_no_op;
output  [31:0]  fdsu_frbus_data;
output  [4 :0]  fdsu_frbus_fflags;
output  [4 :0]  fdsu_frbus_freg;
output          fdsu_frbus_wb_vld;

// &Regs; @25

// &Wires; @26
wire            cp0_fpu_icg_en;
wire            cp0_fpu_xx_dqnan;
wire            cp0_yy_clk_en;
wire            cpurst_b;
wire            ctrl_fdsu_ex1_sel;
wire            ctrl_xx_ex1_cmplt_dp;
wire            ctrl_xx_ex1_inst_vld;
wire            ctrl_xx_ex1_stall;
wire            ctrl_xx_ex1_warm_up;
wire            ctrl_xx_ex2_warm_up;
wire            ctrl_xx_ex3_warm_up;
wire    [2 :0]  dp_xx_ex1_cnan;
wire    [2 :0]  dp_xx_ex1_id;
wire    [2 :0]  dp_xx_ex1_inf;
wire    [2 :0]  dp_xx_ex1_qnan;
wire    [2 :0]  dp_xx_ex1_rm;
wire    [2 :0]  dp_xx_ex1_snan;
wire    [2 :0]  dp_xx_ex1_zero;
wire            ex1_div;
wire    [23:0]  ex1_divisor;
wire    [12:0]  ex1_expnt_adder_op0;
wire    [12:0]  ex1_expnt_adder_op1;
wire            ex1_of_result_lfn;
wire            ex1_op0_id;
wire            ex1_op0_norm;
wire            ex1_op0_sign;
wire            ex1_op1_id;
wire            ex1_op1_id_vld;
wire            ex1_op1_norm;
wire            ex1_op1_sel;
wire    [12:0]  ex1_oper_id_expnt;
wire    [12:0]  ex1_oper_id_expnt_f;
wire    [51:0]  ex1_oper_id_frac;
wire    [51:0]  ex1_oper_id_frac_f;
wire            ex1_pipedown;
wire            ex1_pipedown_gate;
wire    [31:0]  ex1_remainder;
wire            ex1_result_sign;
wire    [2 :0]  ex1_rm;
wire            ex1_save_op0;
wire            ex1_save_op0_gate;
wire            ex1_sqrt;
wire            ex1_srt_skip;
wire    [9 :0]  ex2_expnt_adder_op0;
wire            ex2_of;
wire            ex2_pipe_clk;
wire            ex2_pipedown;
wire            ex2_potnt_of;
wire            ex2_potnt_uf;
wire            ex2_result_inf;
wire            ex2_result_lfn;
wire            ex2_rslt_denorm;
wire    [9 :0]  ex2_srt_expnt_rst;
wire            ex2_srt_first_round;
wire            ex2_uf;
wire            ex2_uf_srt_skip;
wire    [9 :0]  ex3_expnt_adjust_result;
wire    [25:0]  ex3_frac_final_rst;
wire            ex3_pipedown;
wire            ex3_rslt_denorm;
wire            fdsu_ex1_sel;
wire            fdsu_ex3_id_srt_skip;
wire            fdsu_ex3_rem_sign;
wire            fdsu_ex3_rem_zero;
wire    [23:0]  fdsu_ex3_result_denorm_round_add_num;
wire            fdsu_ex4_denorm_to_tiny_frac;
wire    [25:0]  fdsu_ex4_frac;
wire            fdsu_ex4_nx;
wire    [1 :0]  fdsu_ex4_potnt_norm;
wire            fdsu_ex4_result_nor;
wire    [4 :0]  fdsu_fpu_debug_info;
wire            fdsu_fpu_ex1_cmplt;
wire            fdsu_fpu_ex1_cmplt_dp;
wire    [4 :0]  fdsu_fpu_ex1_fflags;
wire    [7 :0]  fdsu_fpu_ex1_special_sel;
wire    [3 :0]  fdsu_fpu_ex1_special_sign;
wire            fdsu_fpu_ex1_stall;
wire            fdsu_fpu_no_op;
wire    [31:0]  fdsu_frbus_data;
wire    [4 :0]  fdsu_frbus_fflags;
wire    [4 :0]  fdsu_frbus_freg;
wire            fdsu_frbus_wb_vld;
wire            fdsu_yy_div;
wire    [9 :0]  fdsu_yy_expnt_rst;
wire            fdsu_yy_of;
wire            fdsu_yy_of_rm_lfn;
wire            fdsu_yy_op0_norm;
wire            fdsu_yy_op1_norm;
wire            fdsu_yy_potnt_of;
wire            fdsu_yy_potnt_uf;
wire            fdsu_yy_result_inf;
wire            fdsu_yy_result_lfn;
wire            fdsu_yy_result_sign;
wire    [2 :0]  fdsu_yy_rm;
wire            fdsu_yy_rslt_denorm;
wire            fdsu_yy_sqrt;
wire            fdsu_yy_uf;
wire    [4 :0]  fdsu_yy_wb_freg;
wire            forever_cpuclk;
wire            frbus_fdsu_wb_grant;
wire    [4 :0]  idu_fpu_ex1_dst_freg;
wire    [2 :0]  idu_fpu_ex1_eu_sel;
wire    [9 :0]  idu_fpu_ex1_func;
wire    [31:0]  idu_fpu_ex1_srcf0;
wire    [31:0]  idu_fpu_ex1_srcf1;
wire            pad_yy_icg_scan_en;
wire            rtu_xx_ex1_cancel;
wire            rtu_xx_ex2_cancel;
wire            rtu_yy_xx_async_flush;
wire            rtu_yy_xx_flush;
wire            srt_remainder_zero;
wire            srt_sm_on;
wire    [29:0]  total_qt_rt_30;



// &Instance("pa_fdsu_special"); @29
pa_fdsu_special  x_pa_fdsu_special (
  .cp0_fpu_xx_dqnan          (cp0_fpu_xx_dqnan         ),
  .dp_xx_ex1_cnan            (dp_xx_ex1_cnan           ),
  .dp_xx_ex1_id              (dp_xx_ex1_id             ),
  .dp_xx_ex1_inf             (dp_xx_ex1_inf            ),
  .dp_xx_ex1_qnan            (dp_xx_ex1_qnan           ),
  .dp_xx_ex1_snan            (dp_xx_ex1_snan           ),
  .dp_xx_ex1_zero            (dp_xx_ex1_zero           ),
  .ex1_div                   (ex1_div                  ),
  .ex1_op0_id                (ex1_op0_id               ),
  .ex1_op0_norm              (ex1_op0_norm             ),
  .ex1_op0_sign              (ex1_op0_sign             ),
  .ex1_op1_id                (ex1_op1_id               ),
  .ex1_op1_norm              (ex1_op1_norm             ),
  .ex1_result_sign           (ex1_result_sign          ),
  .ex1_sqrt                  (ex1_sqrt                 ),
  .ex1_srt_skip              (ex1_srt_skip             ),
  .fdsu_fpu_ex1_fflags       (fdsu_fpu_ex1_fflags      ),
  .fdsu_fpu_ex1_special_sel  (fdsu_fpu_ex1_special_sel ),
  .fdsu_fpu_ex1_special_sign (fdsu_fpu_ex1_special_sign)
);

// &Instance("pa_fdsu_prepare"); @30
pa_fdsu_prepare  x_pa_fdsu_prepare (
  .dp_xx_ex1_rm        (dp_xx_ex1_rm       ),
  .ex1_div             (ex1_div            ),
  .ex1_divisor         (ex1_divisor        ),
  .ex1_expnt_adder_op0 (ex1_expnt_adder_op0),
  .ex1_expnt_adder_op1 (ex1_expnt_adder_op1),
  .ex1_of_result_lfn   (ex1_of_result_lfn  ),
  .ex1_op0_id          (ex1_op0_id         ),
  .ex1_op0_sign        (ex1_op0_sign       ),
  .ex1_op1_id          (ex1_op1_id         ),
  .ex1_op1_id_vld      (ex1_op1_id_vld     ),
  .ex1_op1_sel         (ex1_op1_sel        ),
  .ex1_oper_id_expnt   (ex1_oper_id_expnt  ),
  .ex1_oper_id_expnt_f (ex1_oper_id_expnt_f),
  .ex1_oper_id_frac    (ex1_oper_id_frac   ),
  .ex1_oper_id_frac_f  (ex1_oper_id_frac_f ),
  .ex1_remainder       (ex1_remainder      ),
  .ex1_result_sign     (ex1_result_sign    ),
  .ex1_rm              (ex1_rm             ),
  .ex1_sqrt            (ex1_sqrt           ),
  .fdsu_ex1_sel        (fdsu_ex1_sel       ),
  .idu_fpu_ex1_func    (idu_fpu_ex1_func   ),
  .idu_fpu_ex1_srcf0   (idu_fpu_ex1_srcf0  ),
  .idu_fpu_ex1_srcf1   (idu_fpu_ex1_srcf1  )
);

// &Instance("pa_fdsu_srt"); @32
// &Instance("pa_fdsu_round"); @33
// &Instance("pa_fdsu_pack"); @34
// &Instance("pa_fdsu_srt_single", "x_pa_fdsu_srt"); @36
pa_fdsu_srt_single  x_pa_fdsu_srt (
  .cp0_fpu_icg_en                       (cp0_fpu_icg_en                      ),
  .cp0_yy_clk_en                        (cp0_yy_clk_en                       ),
  .ex1_divisor                          (ex1_divisor                         ),
  .ex1_expnt_adder_op1                  (ex1_expnt_adder_op1                 ),
  .ex1_oper_id_frac                     (ex1_oper_id_frac                    ),
  .ex1_oper_id_frac_f                   (ex1_oper_id_frac_f                  ),
  .ex1_pipedown                         (ex1_pipedown                        ),
  .ex1_pipedown_gate                    (ex1_pipedown_gate                   ),
  .ex1_remainder                        (ex1_remainder                       ),
  .ex1_save_op0                         (ex1_save_op0                        ),
  .ex1_save_op0_gate                    (ex1_save_op0_gate                   ),
  .ex2_expnt_adder_op0                  (ex2_expnt_adder_op0                 ),
  .ex2_of                               (ex2_of                              ),
  .ex2_pipe_clk                         (ex2_pipe_clk                        ),
  .ex2_pipedown                         (ex2_pipedown                        ),
  .ex2_potnt_of                         (ex2_potnt_of                        ),
  .ex2_potnt_uf                         (ex2_potnt_uf                        ),
  .ex2_result_inf                       (ex2_result_inf                      ),
  .ex2_result_lfn                       (ex2_result_lfn                      ),
  .ex2_rslt_denorm                      (ex2_rslt_denorm                     ),
  .ex2_srt_expnt_rst                    (ex2_srt_expnt_rst                   ),
  .ex2_srt_first_round                  (ex2_srt_first_round                 ),
  .ex2_uf                               (ex2_uf                              ),
  .ex2_uf_srt_skip                      (ex2_uf_srt_skip                     ),
  .ex3_frac_final_rst                   (ex3_frac_final_rst                  ),
  .ex3_pipedown                         (ex3_pipedown                        ),
  .fdsu_ex3_id_srt_skip                 (fdsu_ex3_id_srt_skip                ),
  .fdsu_ex3_rem_sign                    (fdsu_ex3_rem_sign                   ),
  .fdsu_ex3_rem_zero                    (fdsu_ex3_rem_zero                   ),
  .fdsu_ex3_result_denorm_round_add_num (fdsu_ex3_result_denorm_round_add_num),
  .fdsu_ex4_frac                        (fdsu_ex4_frac                       ),
  .fdsu_yy_div                          (fdsu_yy_div                         ),
  .fdsu_yy_of_rm_lfn                    (fdsu_yy_of_rm_lfn                   ),
  .fdsu_yy_op0_norm                     (fdsu_yy_op0_norm                    ),
  .fdsu_yy_op1_norm                     (fdsu_yy_op1_norm                    ),
  .fdsu_yy_sqrt                         (fdsu_yy_sqrt                        ),
  .forever_cpuclk                       (forever_cpuclk                      ),
  .pad_yy_icg_scan_en                   (pad_yy_icg_scan_en                  ),
  .srt_remainder_zero                   (srt_remainder_zero                  ),
  .srt_sm_on                            (srt_sm_on                           ),
  .total_qt_rt_30                       (total_qt_rt_30                      )
);

// &Instance("pa_fdsu_round_single", "x_pa_fdsu_round"); @37
pa_fdsu_round_single  x_pa_fdsu_round (
  .cp0_fpu_icg_en                       (cp0_fpu_icg_en                      ),
  .cp0_yy_clk_en                        (cp0_yy_clk_en                       ),
  .ex3_expnt_adjust_result              (ex3_expnt_adjust_result             ),
  .ex3_frac_final_rst                   (ex3_frac_final_rst                  ),
  .ex3_pipedown                         (ex3_pipedown                        ),
  .ex3_rslt_denorm                      (ex3_rslt_denorm                     ),
  .fdsu_ex3_id_srt_skip                 (fdsu_ex3_id_srt_skip                ),
  .fdsu_ex3_rem_sign                    (fdsu_ex3_rem_sign                   ),
  .fdsu_ex3_rem_zero                    (fdsu_ex3_rem_zero                   ),
  .fdsu_ex3_result_denorm_round_add_num (fdsu_ex3_result_denorm_round_add_num),
  .fdsu_ex4_denorm_to_tiny_frac         (fdsu_ex4_denorm_to_tiny_frac        ),
  .fdsu_ex4_nx                          (fdsu_ex4_nx                         ),
  .fdsu_ex4_potnt_norm                  (fdsu_ex4_potnt_norm                 ),
  .fdsu_ex4_result_nor                  (fdsu_ex4_result_nor                 ),
  .fdsu_yy_expnt_rst                    (fdsu_yy_expnt_rst                   ),
  .fdsu_yy_result_inf                   (fdsu_yy_result_inf                  ),
  .fdsu_yy_result_lfn                   (fdsu_yy_result_lfn                  ),
  .fdsu_yy_result_sign                  (fdsu_yy_result_sign                 ),
  .fdsu_yy_rm                           (fdsu_yy_rm                          ),
  .fdsu_yy_rslt_denorm                  (fdsu_yy_rslt_denorm                 ),
  .forever_cpuclk                       (forever_cpuclk                      ),
  .pad_yy_icg_scan_en                   (pad_yy_icg_scan_en                  ),
  .total_qt_rt_30                       (total_qt_rt_30                      )
);

// &Instance("pa_fdsu_pack_single", "x_pa_fdsu_pack"); @38
pa_fdsu_pack_single  x_pa_fdsu_pack (
  .fdsu_ex4_denorm_to_tiny_frac (fdsu_ex4_denorm_to_tiny_frac),
  .fdsu_ex4_frac                (fdsu_ex4_frac               ),
  .fdsu_ex4_nx                  (fdsu_ex4_nx                 ),
  .fdsu_ex4_potnt_norm          (fdsu_ex4_potnt_norm         ),
  .fdsu_ex4_result_nor          (fdsu_ex4_result_nor         ),
  .fdsu_frbus_data              (fdsu_frbus_data             ),
  .fdsu_frbus_fflags            (fdsu_frbus_fflags           ),
  .fdsu_frbus_freg              (fdsu_frbus_freg             ),
  .fdsu_yy_expnt_rst            (fdsu_yy_expnt_rst           ),
  .fdsu_yy_of                   (fdsu_yy_of                  ),
  .fdsu_yy_of_rm_lfn            (fdsu_yy_of_rm_lfn           ),
  .fdsu_yy_potnt_of             (fdsu_yy_potnt_of            ),
  .fdsu_yy_potnt_uf             (fdsu_yy_potnt_uf            ),
  .fdsu_yy_result_inf           (fdsu_yy_result_inf          ),
  .fdsu_yy_result_lfn           (fdsu_yy_result_lfn          ),
  .fdsu_yy_result_sign          (fdsu_yy_result_sign         ),
  .fdsu_yy_rslt_denorm          (fdsu_yy_rslt_denorm         ),
  .fdsu_yy_uf                   (fdsu_yy_uf                  ),
  .fdsu_yy_wb_freg              (fdsu_yy_wb_freg             )
);


// &Instance("pa_fdsu_ctrl"); @41
pa_fdsu_ctrl  x_pa_fdsu_ctrl (
  .cp0_fpu_icg_en          (cp0_fpu_icg_en         ),
  .cp0_yy_clk_en           (cp0_yy_clk_en          ),
  .cpurst_b                (cpurst_b               ),
  .ctrl_fdsu_ex1_sel       (ctrl_fdsu_ex1_sel      ),
  .ctrl_xx_ex1_cmplt_dp    (ctrl_xx_ex1_cmplt_dp   ),
  .ctrl_xx_ex1_inst_vld    (ctrl_xx_ex1_inst_vld   ),
  .ctrl_xx_ex1_stall       (ctrl_xx_ex1_stall      ),
  .ctrl_xx_ex1_warm_up     (ctrl_xx_ex1_warm_up    ),
  .ctrl_xx_ex2_warm_up     (ctrl_xx_ex2_warm_up    ),
  .ctrl_xx_ex3_warm_up     (ctrl_xx_ex3_warm_up    ),
  .ex1_div                 (ex1_div                ),
  .ex1_expnt_adder_op0     (ex1_expnt_adder_op0    ),
  .ex1_of_result_lfn       (ex1_of_result_lfn      ),
  .ex1_op0_id              (ex1_op0_id             ),
  .ex1_op0_norm            (ex1_op0_norm           ),
  .ex1_op1_id_vld          (ex1_op1_id_vld         ),
  .ex1_op1_norm            (ex1_op1_norm           ),
  .ex1_op1_sel             (ex1_op1_sel            ),
  .ex1_oper_id_expnt       (ex1_oper_id_expnt      ),
  .ex1_oper_id_expnt_f     (ex1_oper_id_expnt_f    ),
  .ex1_pipedown            (ex1_pipedown           ),
  .ex1_pipedown_gate       (ex1_pipedown_gate      ),
  .ex1_result_sign         (ex1_result_sign        ),
  .ex1_rm                  (ex1_rm                 ),
  .ex1_save_op0            (ex1_save_op0           ),
  .ex1_save_op0_gate       (ex1_save_op0_gate      ),
  .ex1_sqrt                (ex1_sqrt               ),
  .ex1_srt_skip            (ex1_srt_skip           ),
  .ex2_expnt_adder_op0     (ex2_expnt_adder_op0    ),
  .ex2_of                  (ex2_of                 ),
  .ex2_pipe_clk            (ex2_pipe_clk           ),
  .ex2_pipedown            (ex2_pipedown           ),
  .ex2_potnt_of            (ex2_potnt_of           ),
  .ex2_potnt_uf            (ex2_potnt_uf           ),
  .ex2_result_inf          (ex2_result_inf         ),
  .ex2_result_lfn          (ex2_result_lfn         ),
  .ex2_rslt_denorm         (ex2_rslt_denorm        ),
  .ex2_srt_expnt_rst       (ex2_srt_expnt_rst      ),
  .ex2_srt_first_round     (ex2_srt_first_round    ),
  .ex2_uf                  (ex2_uf                 ),
  .ex2_uf_srt_skip         (ex2_uf_srt_skip        ),
  .ex3_expnt_adjust_result (ex3_expnt_adjust_result),
  .ex3_pipedown            (ex3_pipedown           ),
  .ex3_rslt_denorm         (ex3_rslt_denorm        ),
  .fdsu_ex1_sel            (fdsu_ex1_sel           ),
  .fdsu_fpu_debug_info     (fdsu_fpu_debug_info    ),
  .fdsu_fpu_ex1_cmplt      (fdsu_fpu_ex1_cmplt     ),
  .fdsu_fpu_ex1_cmplt_dp   (fdsu_fpu_ex1_cmplt_dp  ),
  .fdsu_fpu_ex1_stall      (fdsu_fpu_ex1_stall     ),
  .fdsu_fpu_no_op          (fdsu_fpu_no_op         ),
  .fdsu_frbus_wb_vld       (fdsu_frbus_wb_vld      ),
  .fdsu_yy_div             (fdsu_yy_div            ),
  .fdsu_yy_expnt_rst       (fdsu_yy_expnt_rst      ),
  .fdsu_yy_of              (fdsu_yy_of             ),
  .fdsu_yy_of_rm_lfn       (fdsu_yy_of_rm_lfn      ),
  .fdsu_yy_op0_norm        (fdsu_yy_op0_norm       ),
  .fdsu_yy_op1_norm        (fdsu_yy_op1_norm       ),
  .fdsu_yy_potnt_of        (fdsu_yy_potnt_of       ),
  .fdsu_yy_potnt_uf        (fdsu_yy_potnt_uf       ),
  .fdsu_yy_result_inf      (fdsu_yy_result_inf     ),
  .fdsu_yy_result_lfn      (fdsu_yy_result_lfn     ),
  .fdsu_yy_result_sign     (fdsu_yy_result_sign    ),
  .fdsu_yy_rm              (fdsu_yy_rm             ),
  .fdsu_yy_rslt_denorm     (fdsu_yy_rslt_denorm    ),
  .fdsu_yy_sqrt            (fdsu_yy_sqrt           ),
  .fdsu_yy_uf              (fdsu_yy_uf             ),
  .fdsu_yy_wb_freg         (fdsu_yy_wb_freg        ),
  .forever_cpuclk          (forever_cpuclk         ),
  .frbus_fdsu_wb_grant     (frbus_fdsu_wb_grant    ),
  .idu_fpu_ex1_dst_freg    (idu_fpu_ex1_dst_freg   ),
  .idu_fpu_ex1_eu_sel      (idu_fpu_ex1_eu_sel     ),
  .pad_yy_icg_scan_en      (pad_yy_icg_scan_en     ),
  .rtu_xx_ex1_cancel       (rtu_xx_ex1_cancel      ),
  .rtu_xx_ex2_cancel       (rtu_xx_ex2_cancel      ),
  .rtu_yy_xx_async_flush   (rtu_yy_xx_async_flush  ),
  .rtu_yy_xx_flush         (rtu_yy_xx_flush        ),
  .srt_remainder_zero      (srt_remainder_zero     ),
  .srt_sm_on               (srt_sm_on              )
);



// &ModuleEnd; @44
endmodule


/*Copyright 2020-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

module pa_fpu_dp(
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

input           cp0_fpu_icg_en;
input   [2 :0]  cp0_fpu_xx_rm;
input           cp0_yy_clk_en;
input           ctrl_xx_ex1_inst_vld;
input           ctrl_xx_ex1_stall;
input           ctrl_xx_ex1_warm_up;
input   [4 :0]  fdsu_fpu_ex1_fflags;
input   [7 :0]  fdsu_fpu_ex1_special_sel;
input   [3 :0]  fdsu_fpu_ex1_special_sign;
input           forever_cpuclk;
input   [2 :0]  idu_fpu_ex1_eu_sel;
input   [9 :0]  idu_fpu_ex1_func;
input           idu_fpu_ex1_gateclk_vld;
input   [2 :0]  idu_fpu_ex1_rm;
input   [31:0]  idu_fpu_ex1_srcf0;
input   [31:0]  idu_fpu_ex1_srcf1;
input   [31:0]  idu_fpu_ex1_srcf2;
input           pad_yy_icg_scan_en;
output  [31:0]  dp_frbus_ex2_data;
output  [4 :0]  dp_frbus_ex2_fflags;
output  [2 :0]  dp_xx_ex1_cnan;
output  [2 :0]  dp_xx_ex1_id;
output  [2 :0]  dp_xx_ex1_inf;
output  [2 :0]  dp_xx_ex1_norm;
output  [2 :0]  dp_xx_ex1_qnan;
output  [2 :0]  dp_xx_ex1_snan;
output  [2 :0]  dp_xx_ex1_zero;
output          ex2_inst_wb;

reg     [4 :0]  ex1_fflags;
reg     [31:0]  ex1_special_data;
reg     [8 :0]  ex1_special_sel;
reg     [3 :0]  ex1_special_sign;
reg     [4 :0]  ex2_fflags;
reg     [31:0]  ex2_result;
reg     [31:0]  ex2_special_data;
reg     [6 :0]  ex2_special_sel;
reg     [3 :0]  ex2_special_sign;

wire            cp0_fpu_icg_en;
wire    [2 :0]  cp0_fpu_xx_rm;
wire            cp0_yy_clk_en;
wire            ctrl_xx_ex1_inst_vld;
wire            ctrl_xx_ex1_stall;
wire            ctrl_xx_ex1_warm_up;
wire    [31:0]  dp_frbus_ex2_data;
wire    [4 :0]  dp_frbus_ex2_fflags;
wire    [2 :0]  dp_xx_ex1_cnan;
wire    [2 :0]  dp_xx_ex1_id;
wire    [2 :0]  dp_xx_ex1_inf;
wire    [2 :0]  dp_xx_ex1_norm;
wire    [2 :0]  dp_xx_ex1_qnan;
wire    [2 :0]  dp_xx_ex1_snan;
wire    [2 :0]  dp_xx_ex1_zero;
wire    [2 :0]  ex1_decode_rm;
wire            ex1_double;
wire    [2 :0]  ex1_eu_sel;
wire    [9 :0]  ex1_func;
wire    [2 :0]  ex1_global_rm;
wire    [2 :0]  ex1_rm;
wire            ex1_single;
wire    [31:0]  ex1_special_data_final;
wire    [63:0]  ex1_src0;
wire    [63:0]  ex1_src1;
wire    [63:0]  ex1_src2;
wire            ex1_src2_vld;
wire    [2 :0]  ex1_src_cnan;
wire    [2 :0]  ex1_src_id;
wire    [2 :0]  ex1_src_inf;
wire    [2 :0]  ex1_src_norm;
wire    [2 :0]  ex1_src_qnan;
wire    [2 :0]  ex1_src_snan;
wire    [2 :0]  ex1_src_zero;
wire            ex2_data_clk;
wire            ex2_data_clk_en;
wire            ex2_inst_wb;
wire    [4 :0]  fdsu_fpu_ex1_fflags;
wire    [7 :0]  fdsu_fpu_ex1_special_sel;
wire    [3 :0]  fdsu_fpu_ex1_special_sign;
wire            forever_cpuclk;
wire    [2 :0]  idu_fpu_ex1_eu_sel;
wire    [9 :0]  idu_fpu_ex1_func;
wire            idu_fpu_ex1_gateclk_vld;
wire    [2 :0]  idu_fpu_ex1_rm;
wire    [31:0]  idu_fpu_ex1_srcf0;
wire    [31:0]  idu_fpu_ex1_srcf1;
wire    [31:0]  idu_fpu_ex1_srcf2;
wire            pad_yy_icg_scan_en;


parameter DOUBLE_WIDTH =64;
parameter SINGLE_WIDTH =32;
parameter FUNC_WIDTH   =10;
//==========================================================
//                     EX1 special data path
//==========================================================
assign ex1_eu_sel[2:0]            = idu_fpu_ex1_eu_sel[2:0];  //3'h4
assign ex1_func[FUNC_WIDTH-1:0]   = idu_fpu_ex1_func[FUNC_WIDTH-1:0];
assign ex1_global_rm[2:0]         = cp0_fpu_xx_rm[2:0];
assign ex1_decode_rm[2:0]         = idu_fpu_ex1_rm[2:0];

assign ex1_rm[2:0]                = (ex1_decode_rm[2:0]==3'b111)
                                  ?  ex1_global_rm[2:0] : ex1_decode_rm[2:0];

assign ex1_src2_vld               = idu_fpu_ex1_eu_sel[1] && ex1_func[0];

assign ex1_src0[DOUBLE_WIDTH-1:0] = { {SINGLE_WIDTH{1'b1}},idu_fpu_ex1_srcf0[SINGLE_WIDTH-1:0]};
assign ex1_src1[DOUBLE_WIDTH-1:0] = { {SINGLE_WIDTH{1'b1}},idu_fpu_ex1_srcf1[SINGLE_WIDTH-1:0]};
assign ex1_src2[DOUBLE_WIDTH-1:0] = ex1_src2_vld ? { {SINGLE_WIDTH{1'b1}},idu_fpu_ex1_srcf2[SINGLE_WIDTH-1:0]}
                                                 : { {SINGLE_WIDTH{1'b1}},{SINGLE_WIDTH{1'b0}} };

assign ex1_double = 1'b0;
assign ex1_single = 1'b1;

//==========================================================
//                EX1 special src data judge
//==========================================================
pa_fpu_src_type  x_pa_fpu_ex1_srcf0_type (
  .inst_double     (ex1_double     ),
  .inst_single     (ex1_single     ),
  .src_cnan        (ex1_src_cnan[0]),
  .src_id          (ex1_src_id[0]  ),
  .src_in          (ex1_src0       ),
  .src_inf         (ex1_src_inf[0] ),
  .src_norm        (ex1_src_norm[0]),
  .src_qnan        (ex1_src_qnan[0]),
  .src_snan        (ex1_src_snan[0]),
  .src_zero        (ex1_src_zero[0])
);

pa_fpu_src_type  x_pa_fpu_ex1_srcf1_type (
  .inst_double     (ex1_double     ),
  .inst_single     (ex1_single     ),
  .src_cnan        (ex1_src_cnan[1]),
  .src_id          (ex1_src_id[1]  ),
  .src_in          (ex1_src1       ),
  .src_inf         (ex1_src_inf[1] ),
  .src_norm        (ex1_src_norm[1]),
  .src_qnan        (ex1_src_qnan[1]),
  .src_snan        (ex1_src_snan[1]),
  .src_zero        (ex1_src_zero[1])
);

pa_fpu_src_type  x_pa_fpu_ex1_srcf2_type (
  .inst_double     (ex1_double     ),
  .inst_single     (ex1_single     ),
  .src_cnan        (ex1_src_cnan[2]),
  .src_id          (ex1_src_id[2]  ),
  .src_in          (ex1_src2       ),
  .src_inf         (ex1_src_inf[2] ),
  .src_norm        (ex1_src_norm[2]),
  .src_qnan        (ex1_src_qnan[2]),
  .src_snan        (ex1_src_snan[2]),
  .src_zero        (ex1_src_zero[2])
);

assign dp_xx_ex1_cnan[2:0] = ex1_src_cnan[2:0];
assign dp_xx_ex1_snan[2:0] = ex1_src_snan[2:0];
assign dp_xx_ex1_qnan[2:0] = ex1_src_qnan[2:0];
assign dp_xx_ex1_norm[2:0] = ex1_src_norm[2:0];
assign dp_xx_ex1_zero[2:0] = ex1_src_zero[2:0];
assign dp_xx_ex1_inf[2:0]  = ex1_src_inf[2:0];
assign dp_xx_ex1_id[2:0]   = ex1_src_id[2:0];

//==========================================================
//                EX1 special result judge
//==========================================================

always @( fdsu_fpu_ex1_special_sign[3:0]
       or fdsu_fpu_ex1_fflags[4:0]
       or ex1_eu_sel[2:0]
       or fdsu_fpu_ex1_special_sel[7:0])
begin
case(ex1_eu_sel[2:0])  //3'h4
   3'b100: begin//FDSU
         ex1_fflags[4:0]       = fdsu_fpu_ex1_fflags[4:0];
         ex1_special_sel[8:0]  ={1'b0,fdsu_fpu_ex1_special_sel[7:0]};
         ex1_special_sign[3:0] = fdsu_fpu_ex1_special_sign[3:0];
         end
default: begin//FDSU
         ex1_fflags[4:0]       = {5{1'b0}};
         ex1_special_sel[8:0]  = {9{1'b0}};
         ex1_special_sign[3:0] = {4{1'b0}};
         end
endcase
end

always @( ex1_special_sel[8:5]
       or ex1_src0[31:0]
       or ex1_src1[31:0]
       or ex1_src2[31:0])
begin
case(ex1_special_sel[8:5])
  4'b0001: ex1_special_data[SINGLE_WIDTH-1:0] = ex1_src0[SINGLE_WIDTH-1:0];
  4'b0010: ex1_special_data[SINGLE_WIDTH-1:0] = ex1_src1[SINGLE_WIDTH-1:0];
  4'b0100: ex1_special_data[SINGLE_WIDTH-1:0] = ex1_src2[SINGLE_WIDTH-1:0];
default  : ex1_special_data[SINGLE_WIDTH-1:0] = ex1_src2[SINGLE_WIDTH-1:0];
endcase
end

assign ex1_special_data_final[SINGLE_WIDTH-1:0] = ex1_special_data[SINGLE_WIDTH-1:0];

//==========================================================
//                     EX1-EX2 data pipedown
//==========================================================
assign ex2_data_clk_en = idu_fpu_ex1_gateclk_vld || ctrl_xx_ex1_warm_up;

gated_clk_cell  x_fpu_data_ex2_gated_clk (
  .clk_in             (forever_cpuclk    ),
  .clk_out            (ex2_data_clk      ),
  .external_en        (1'b0              ),
  .global_en          (cp0_yy_clk_en     ),
  .local_en           (ex2_data_clk_en   ),
  .module_en          (cp0_fpu_icg_en    ),
  .pad_yy_icg_scan_en (pad_yy_icg_scan_en)
);

always @(posedge ex2_data_clk)
begin
  if(ctrl_xx_ex1_inst_vld && !ctrl_xx_ex1_stall || ctrl_xx_ex1_warm_up)
  begin
    ex2_fflags[4:0]       <= ex1_fflags[4:0];
    ex2_special_sign[3:0] <= ex1_special_sign[3:0];
    ex2_special_sel[6:0]  <={ex1_special_sel[8],|ex1_special_sel[7:5],ex1_special_sel[4:0]};
    ex2_special_data[SINGLE_WIDTH-1:0] <= ex1_special_data_final[SINGLE_WIDTH-1:0];
  end
end

assign ex2_inst_wb = (|ex2_special_sel[6:0]);

always @( ex2_special_sel[6:0]
       or ex2_special_data[31:0]
       or ex2_special_sign[3:0])
begin
case(ex2_special_sel[6:0])
  7'b0000_001: ex2_result[SINGLE_WIDTH-1:0]  = { ex2_special_sign[0],ex2_special_data[SINGLE_WIDTH-2:0]};//src2
  7'b0000_010: ex2_result[SINGLE_WIDTH-1:0]  = { ex2_special_sign[1], {31{1'b0}} };//zero
  7'b0000_100: ex2_result[SINGLE_WIDTH-1:0]  = { ex2_special_sign[2], {8{1'b1}},{23{1'b0}} };//inf
  7'b0001_000: ex2_result[SINGLE_WIDTH-1:0]  = { ex2_special_sign[3], {7{1'b1}},1'b0,{23{1'b1}} };//lfn
  7'b0010_000: ex2_result[SINGLE_WIDTH-1:0]  = { 1'b0, {8{1'b1}},1'b1, {22{1'b0}} };//cnan
  7'b0100_000: ex2_result[SINGLE_WIDTH-1:0]  = { ex2_special_data[31],{8{1'b1}}, 1'b1, ex2_special_data[21:0]};//propagate qnan
  7'b1000_000: ex2_result[SINGLE_WIDTH-1:0]  = ex2_special_data[SINGLE_WIDTH-1:0]; //ex1 falu special result
      default: ex2_result[SINGLE_WIDTH-1:0]  = {SINGLE_WIDTH{1'b0}};
endcase
end

assign dp_frbus_ex2_data[SINGLE_WIDTH-1:0]  = ex2_result[SINGLE_WIDTH-1:0];
assign dp_frbus_ex2_fflags[4:0] = ex2_fflags[4:0];

endmodule



/*Copyright 2020-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

module pa_fpu_frbus(
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

input           ctrl_frbus_ex2_wb_req;
input   [31:0]  dp_frbus_ex2_data;
input   [4 :0]  dp_frbus_ex2_fflags;
input   [31:0]  fdsu_frbus_data;
input   [4 :0]  fdsu_frbus_fflags;
input           fdsu_frbus_wb_vld;
output  [31:0]  fpu_idu_fwd_data;
output  [4 :0]  fpu_idu_fwd_fflags;
output          fpu_idu_fwd_vld;

reg     [31:0]  frbus_wb_data;
reg     [4 :0]  frbus_wb_fflags;

wire            ctrl_frbus_ex2_wb_req;
wire    [31:0]  fdsu_frbus_data;
wire    [4 :0]  fdsu_frbus_fflags;
wire            fdsu_frbus_wb_vld;
wire    [31:0]  fpu_idu_fwd_data;
wire    [4 :0]  fpu_idu_fwd_fflags;
wire            fpu_idu_fwd_vld;
wire            frbus_ex2_wb_vld;
wire            frbus_fdsu_wb_vld;
wire            frbus_wb_vld;
wire    [3 :0]  frbus_source_vld;


//==========================================================
//                   Input Signal Rename
//==========================================================
assign frbus_fdsu_wb_vld = fdsu_frbus_wb_vld;
assign frbus_ex2_wb_vld  = ctrl_frbus_ex2_wb_req;
assign frbus_source_vld[3:0]     = {1'b0, 1'b0, frbus_ex2_wb_vld, frbus_fdsu_wb_vld};
assign frbus_wb_vld = frbus_ex2_wb_vld | frbus_fdsu_wb_vld;

always @( frbus_source_vld[3:0]
       or fdsu_frbus_data[31:0]
       or dp_frbus_ex2_data[31:0]
       or fdsu_frbus_fflags[4:0]
       or dp_frbus_ex2_fflags[4:0])
begin
  case(frbus_source_vld[3:0])
    4'b0001: begin // DIV
      frbus_wb_data[31:0] = fdsu_frbus_data[31:0];
      frbus_wb_fflags[4:0]    = fdsu_frbus_fflags[4:0];
    end
    4'b0010: begin // EX2
      frbus_wb_data[31:0] = dp_frbus_ex2_data[31:0];
      frbus_wb_fflags[4:0]    = dp_frbus_ex2_fflags[4:0];
    end
    default: begin
      frbus_wb_data[31:0] = {31{1'b0}};
      frbus_wb_fflags[4:0]    = 5'b0;
    end
  endcase
end

assign fpu_idu_fwd_vld            = frbus_wb_vld;
assign fpu_idu_fwd_fflags[4:0]    = frbus_wb_fflags[4:0];
assign fpu_idu_fwd_data[31:0] = frbus_wb_data[31:0];

endmodule


/*Copyright 2020-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// &ModuleBeg; @24
module pa_fpu_src_type(
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

// &Ports; @25
input           inst_double;
input           inst_single;
input   [63:0]  src_in;
output          src_cnan;
output          src_id;
output          src_inf;
output          src_norm;
output          src_qnan;
output          src_snan;
output          src_zero;

// &Regs; @26

// &Wires; @27
wire            inst_double;
wire            inst_single;
wire    [63:0]  src;
wire            src_cnan;
wire            src_expn_max;
wire            src_expn_zero;
wire            src_frac_msb;
wire            src_frac_zero;
wire            src_id;
wire    [63:0]  src_in;
wire            src_inf;
wire            src_norm;
wire            src_qnan;
wire            src_snan;
wire            src_zero;


// &Depend("cpu_cfig.h"); @29
assign src[63:0] = src_in[63:0];

assign src_cnan  = !(&src[63:32]) && inst_single;

assign src_expn_zero = !(|src[62:52]) && inst_double ||
                       !(|src[30:23]) && inst_single;

assign src_expn_max  =  (&src[62:52]) && inst_double ||
                        (&src[30:23]) && inst_single;

assign src_frac_zero = !(|src[51:0]) && inst_double ||
                       !(|src[22:0]) && inst_single;

assign src_frac_msb  = src[51] && inst_double || src[22] && inst_single;

assign src_snan = src_expn_max  && !src_frac_msb && !src_frac_zero && !src_cnan;
assign src_qnan = src_expn_max  &&  src_frac_msb || src_cnan;
assign src_zero = src_expn_zero &&  src_frac_zero && !src_cnan;
assign src_id   = src_expn_zero && !src_frac_zero && !src_cnan;
assign src_inf  = src_expn_max  &&  src_frac_zero && !src_cnan;
assign src_norm =!(src_expn_zero && src_frac_zero) &&
                 ! src_expn_max  && !src_cnan;

// &Force("output","src_cnan"); @53

// &ModuleEnd; @55
endmodule



// Copyright 2019 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// SPDX-License-Identifier: SHL-0.51

// Author: Stefan Mach <smach@iis.ee.ethz.ch>

// Copyright 2018 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Common register defines for RTL designs
`ifndef COMMON_CELLS_REGISTERS_SVH_
`define COMMON_CELLS_REGISTERS_SVH_

// Abridged Summary of available FF macros:
// `FF:      asynchronous active-low reset (implicit clock and reset)
// `FFAR:    asynchronous active-high reset
// `FFARN:   asynchronous active-low reset
// `FFSR:    synchronous active-high reset
// `FFSRN:   synchronous active-low reset
// `FFNR:    without reset
// `FFL:     load-enable and asynchronous active-low reset (implicit clock and reset)
// `FFLAR:   load-enable and asynchronous active-high reset
// `FFLARN:  load-enable and asynchronous active-low reset
// `FFLARNC: load-enable and asynchronous active-low reset and synchronous active-high clear
// `FFLSR:   load-enable and synchronous active-high reset
// `FFLSRN:  load-enable and synchronous active-low reset
// `FFLNR:   load-enable without reset


// Flip-Flop with asynchronous active-low reset (implicit clock and reset)
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// Implicit:
// clk_i: clock input
// rst_ni: reset input (asynchronous, active low)
`define FF(__q, __d, __reset_value)                  \
  always_ff @(posedge clk_i or negedge rst_ni) begin \
    if (!rst_ni) begin                               \
      __q <= (__reset_value);                        \
    end else begin                                   \
      __q <= (__d);                                  \
    end                                              \
  end

// Flip-Flop with asynchronous active-high reset
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __arst: asynchronous reset
`define FFAR(__q, __d, __reset_value, __clk, __arst)     \
  always_ff @(posedge (__clk) or posedge (__arst)) begin \
    if (__arst) begin                                    \
      __q <= (__reset_value);                            \
    end else begin                                       \
      __q <= (__d);                                      \
    end                                                  \
  end

// Flip-Flop with asynchronous active-low reset
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __arst_n: asynchronous reset
`define FFARN(__q, __d, __reset_value, __clk, __arst_n)    \
  always_ff @(posedge (__clk) or negedge (__arst_n)) begin \
    if (!__arst_n) begin                                   \
      __q <= (__reset_value);                              \
    end else begin                                         \
      __q <= (__d);                                        \
    end                                                    \
  end

// Flip-Flop with synchronous active-high reset
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __reset_clk: reset input
`define FFSR(__q, __d, __reset_value, __clk, __reset_clk) \
  `ifndef VERILATOR                       \
  /``* synopsys sync_set_reset `"__reset_clk`" *``/       \
    `endif                        \
  always_ff @(posedge (__clk)) begin                      \
    __q <= (__reset_clk) ? (__reset_value) : (__d);       \
  end

// Flip-Flop with synchronous active-low reset
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __reset_n_clk: reset input
`define FFSRN(__q, __d, __reset_value, __clk, __reset_n_clk) \
    `ifndef VERILATOR                       \
  /``* synopsys sync_set_reset `"__reset_n_clk`" *``/        \
    `endif                        \
  always_ff @(posedge (__clk)) begin                         \
    __q <= (!__reset_n_clk) ? (__reset_value) : (__d);       \
  end

// Always-enable Flip-Flop without reset
// __q: Q output of FF
// __d: D input of FF
// __clk: clock input
`define FFNR(__q, __d, __clk)        \
  always_ff @(posedge (__clk)) begin \
    __q <= (__d);                    \
  end

// Flip-Flop with load-enable and asynchronous active-low reset (implicit clock and reset)
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __reset_value: value assigned upon reset
// Implicit:
// clk_i: clock input
// rst_ni: reset input (asynchronous, active low)
`define FFL(__q, __d, __load, __reset_value)         \
  always_ff @(posedge clk_i or negedge rst_ni) begin \
    if (!rst_ni) begin                               \
      __q <= (__reset_value);                        \
    end else begin                                   \
      __q <= (__load) ? (__d) : (__q);               \
    end                                              \
  end

// Flip-Flop with load-enable and asynchronous active-high reset
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __arst: asynchronous reset
`define FFLAR(__q, __d, __load, __reset_value, __clk, __arst) \
  always_ff @(posedge (__clk) or posedge (__arst)) begin      \
    if (__arst) begin                                         \
      __q <= (__reset_value);                                 \
    end else begin                                            \
      __q <= (__load) ? (__d) : (__q);                        \
    end                                                       \
  end

// Flip-Flop with load-enable and asynchronous active-low reset
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __arst_n: asynchronous reset
`define FFLARN(__q, __d, __load, __reset_value, __clk, __arst_n) \
  always_ff @(posedge (__clk) or negedge (__arst_n)) begin       \
    if (!__arst_n) begin                                         \
      __q <= (__reset_value);                                    \
    end else begin                                               \
      __q <= (__load) ? (__d) : (__q);                           \
    end                                                          \
  end

// Flip-Flop with load-enable and synchronous active-high reset
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __reset_clk: reset input
`define FFLSR(__q, __d, __load, __reset_value, __clk, __reset_clk)       \
    `ifndef VERILATOR                       \
  /``* synopsys sync_set_reset `"__reset_clk`" *``/                      \
    `endif                        \
  always_ff @(posedge (__clk)) begin                                     \
    __q <= (__reset_clk) ? (__reset_value) : ((__load) ? (__d) : (__q)); \
  end

// Flip-Flop with load-enable and synchronous active-low reset
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __reset_n_clk: reset input
`define FFLSRN(__q, __d, __load, __reset_value, __clk, __reset_n_clk)       \
    `ifndef VERILATOR                       \
  /``* synopsys sync_set_reset `"__reset_n_clk`" *``/                       \
    `endif                        \
  always_ff @(posedge (__clk)) begin                                        \
    __q <= (!__reset_n_clk) ? (__reset_value) : ((__load) ? (__d) : (__q)); \
  end

// Flip-Flop with load-enable and asynchronous active-low reset and synchronous clear
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __clear: assign reset value into FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __arst_n: asynchronous reset
`define FFLARNC(__q, __d, __load, __clear, __reset_value, __clk, __arst_n) \
    `ifndef VERILATOR                       \
  /``* synopsys sync_set_reset `"__clear`" *``/                       \
    `endif                        \
  always_ff @(posedge (__clk) or negedge (__arst_n)) begin                 \
    if (!__arst_n) begin                                                   \
      __q <= (__reset_value);                                              \
    end else begin                                                         \
      __q <= (__clear) ? (__reset_value) : (__load) ? (__d) : (__q);       \
    end                                                                    \
  end

// Load-enable Flip-Flop without reset
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __clk: clock input
`define FFLNR(__q, __d, __load, __clk) \
  always_ff @(posedge (__clk)) begin   \
    __q <= (__load) ? (__d) : (__q);   \
  end

`endif

module fpnew_fma #(
  parameter fpnew_pkg::fp_format_e   FpFormat    = fpnew_pkg::fp_format_e'(0),
  parameter int unsigned             NumPipeRegs = 0,
  parameter fpnew_pkg::pipe_config_t PipeConfig  = fpnew_pkg::BEFORE,
  parameter type                     TagType     = logic,
  parameter type                     AuxType     = logic,
  // Do not change
  localparam int unsigned WIDTH = fpnew_pkg::fp_width(FpFormat),
  localparam int unsigned ExtRegEnaWidth = NumPipeRegs == 0 ? 1 : NumPipeRegs
) (
  input logic                      clk_i,
  input logic                      rst_ni,
  // Input signals
  input logic [2:0][WIDTH-1:0]     operands_i, // 3 operands
  input logic [2:0]                is_boxed_i, // 3 operands
  input fpnew_pkg::roundmode_e     rnd_mode_i,
  input fpnew_pkg::operation_e     op_i,
  input logic                      op_mod_i,
  input TagType                    tag_i,
  input logic                      mask_i,
  input AuxType                    aux_i,
  // Input Handshake
  input  logic                     in_valid_i,
  output logic                     in_ready_o,
  input  logic                     flush_i,
  // Output signals
  output logic [WIDTH-1:0]         result_o,
  output fpnew_pkg::status_t       status_o,
  output logic                     extension_bit_o,
  output TagType                   tag_o,
  output logic                     mask_o,
  output AuxType                   aux_o,
  // Output handshake
  output logic                     out_valid_o,
  input  logic                     out_ready_i,
  // Indication of valid data in flight
  output logic                     busy_o,
  // External register enable override
  input  logic [ExtRegEnaWidth-1:0] reg_ena_i
);

  // ----------
  // Constants
  // ----------
  localparam int unsigned EXP_BITS = fpnew_pkg::exp_bits(FpFormat);
  localparam int unsigned MAN_BITS = fpnew_pkg::man_bits(FpFormat);
  localparam int unsigned BIAS     = fpnew_pkg::bias(FpFormat);
  // Precision bits 'p' include the implicit bit
  localparam int unsigned PRECISION_BITS = MAN_BITS + 1;
  // The lower 2p+3 bits of the internal FMA result will be needed for leading-zero detection
  localparam int unsigned LOWER_SUM_WIDTH  = 2 * PRECISION_BITS + 3;
  localparam int unsigned LZC_RESULT_WIDTH = $clog2(LOWER_SUM_WIDTH);
  // Internal exponent width of FMA must accomodate all meaningful exponent values in order to avoid
  // datapath leakage. This is either given by the exponent bits or the width of the LZC result.
  // In most reasonable FP formats the internal exponent will be wider than the LZC result.
  localparam int unsigned EXP_WIDTH = unsigned'(fpnew_pkg::maximum(EXP_BITS + 2, LZC_RESULT_WIDTH));
  // Shift amount width: maximum internal mantissa size is 3p+4 bits
  localparam int unsigned SHIFT_AMOUNT_WIDTH = $clog2(3 * PRECISION_BITS + 5);
  // Pipelines
  localparam NUM_INP_REGS = PipeConfig == fpnew_pkg::BEFORE
                            ? NumPipeRegs
                            : (PipeConfig == fpnew_pkg::DISTRIBUTED
                               ? ((NumPipeRegs + 1) / 3) // Second to get distributed regs
                               : 0); // no regs here otherwise
  localparam NUM_MID_REGS = PipeConfig == fpnew_pkg::INSIDE
                          ? NumPipeRegs
                          : (PipeConfig == fpnew_pkg::DISTRIBUTED
                             ? ((NumPipeRegs + 2) / 3) // First to get distributed regs
                             : 0); // no regs here otherwise
  localparam NUM_OUT_REGS = PipeConfig == fpnew_pkg::AFTER
                            ? NumPipeRegs
                            : (PipeConfig == fpnew_pkg::DISTRIBUTED
                               ? (NumPipeRegs / 3) // Last to get distributed regs
                               : 0); // no regs here otherwise

  // ----------------
  // Type definition
  // ----------------
  typedef struct packed {
    logic                sign;
    logic [EXP_BITS-1:0] exponent;
    logic [MAN_BITS-1:0] mantissa;
  } fp_t;

  // ---------------
  // Input pipeline
  // ---------------
  // Input pipeline signals, index i holds signal after i register stages
  logic                  [0:NUM_INP_REGS][2:0][WIDTH-1:0] inp_pipe_operands_q;
  logic                  [0:NUM_INP_REGS][2:0]            inp_pipe_is_boxed_q;
  fpnew_pkg::roundmode_e [0:NUM_INP_REGS]                 inp_pipe_rnd_mode_q;
  fpnew_pkg::operation_e [0:NUM_INP_REGS]                 inp_pipe_op_q;
  logic                  [0:NUM_INP_REGS]                 inp_pipe_op_mod_q;
  TagType                [0:NUM_INP_REGS]                 inp_pipe_tag_q;
  logic                  [0:NUM_INP_REGS]                 inp_pipe_mask_q;
  AuxType                [0:NUM_INP_REGS]                 inp_pipe_aux_q;
  logic                  [0:NUM_INP_REGS]                 inp_pipe_valid_q;
  // Ready signal is combinatorial for all stages
  logic [0:NUM_INP_REGS] inp_pipe_ready;

  // Input stage: First element of pipeline is taken from inputs
  assign inp_pipe_operands_q[0] = operands_i;
  assign inp_pipe_is_boxed_q[0] = is_boxed_i;
  assign inp_pipe_rnd_mode_q[0] = rnd_mode_i;
  assign inp_pipe_op_q[0]       = op_i;
  assign inp_pipe_op_mod_q[0]   = op_mod_i;
  assign inp_pipe_tag_q[0]      = tag_i;
  assign inp_pipe_mask_q[0]     = mask_i;
  assign inp_pipe_aux_q[0]      = aux_i;
  assign inp_pipe_valid_q[0]    = in_valid_i;
  // Input stage: Propagate pipeline ready signal to updtream circuitry
  assign in_ready_o = inp_pipe_ready[0];
  // Generate the register stages
  for (genvar i = 0; i < NUM_INP_REGS; i++) begin : gen_input_pipeline
    // Internal register enable for this stage
    logic reg_ena;
    // Determine the ready signal of the current stage - advance the pipeline:
    // 1. if the next stage is ready for our data
    // 2. if the next stage only holds a bubble (not valid) -> we can pop it
    assign inp_pipe_ready[i] = inp_pipe_ready[i+1] | ~inp_pipe_valid_q[i+1];
    // Valid: enabled by ready signal, synchronous clear with the flush signal
    `FFLARNC(inp_pipe_valid_q[i+1], inp_pipe_valid_q[i], inp_pipe_ready[i], flush_i, 1'b0, clk_i, rst_ni)
    // Enable register if pipleine ready and a valid data item is present
    assign reg_ena = (inp_pipe_ready[i] & inp_pipe_valid_q[i]) | reg_ena_i[i];
    // Generate the pipeline registers within the stages, use enable-registers
    `FFL(inp_pipe_operands_q[i+1], inp_pipe_operands_q[i], reg_ena, '0)
    `FFL(inp_pipe_is_boxed_q[i+1], inp_pipe_is_boxed_q[i], reg_ena, '0)
    `FFL(inp_pipe_rnd_mode_q[i+1], inp_pipe_rnd_mode_q[i], reg_ena, fpnew_pkg::RNE)
    `FFL(inp_pipe_op_q[i+1],       inp_pipe_op_q[i],       reg_ena, fpnew_pkg::FMADD)
    `FFL(inp_pipe_op_mod_q[i+1],   inp_pipe_op_mod_q[i],   reg_ena, '0)
    `FFL(inp_pipe_tag_q[i+1],      inp_pipe_tag_q[i],      reg_ena, TagType'('0))
    `FFL(inp_pipe_mask_q[i+1],     inp_pipe_mask_q[i],     reg_ena, '0)
    `FFL(inp_pipe_aux_q[i+1],      inp_pipe_aux_q[i],      reg_ena, AuxType'('0))
  end

  // -----------------
  // Input processing
  // -----------------
  fpnew_pkg::fp_info_t [2:0] info_q;

  // Classify input
  fpnew_classifier #(
    .FpFormat    ( FpFormat ),
    .NumOperands ( 3        )
    ) i_class_inputs (
    .operands_i ( inp_pipe_operands_q[NUM_INP_REGS] ),
    .is_boxed_i ( inp_pipe_is_boxed_q[NUM_INP_REGS] ),
    .info_o     ( info_q                            )
  );

  fp_t                 operand_a, operand_b, operand_c;
  fpnew_pkg::fp_info_t info_a,    info_b,    info_c;

  // Operation selection and operand adjustment
  // | \c op_q  | \c op_mod_q | Operation Adjustment
  // |:--------:|:-----------:|---------------------
  // | FMADD    | \c 0        | FMADD: none
  // | FMADD    | \c 1        | FMSUB: Invert sign of operand C
  // | FNMSUB   | \c 0        | FNMSUB: Invert sign of operand A
  // | FNMSUB   | \c 1        | FNMADD: Invert sign of operands A and C
  // | ADD      | \c 0        | ADD: Set operand A to +1.0
  // | ADD      | \c 1        | SUB: Set operand A to +1.0, invert sign of operand C
  // | MUL      | \c 0        | MUL: Set operand C to +0.0 or -0.0 depending on the rounding mode
  // | *others* | \c -        | *invalid*
  // \note \c op_mod_q always inverts the sign of the addend.
  always_comb begin : op_select

    // Default assignments - packing-order-agnostic
    operand_a = inp_pipe_operands_q[NUM_INP_REGS][0];
    operand_b = inp_pipe_operands_q[NUM_INP_REGS][1];
    operand_c = inp_pipe_operands_q[NUM_INP_REGS][2];
    info_a    = info_q[0];
    info_b    = info_q[1];
    info_c    = info_q[2];

    // op_mod_q inverts sign of operand C
    operand_c.sign = operand_c.sign ^ inp_pipe_op_mod_q[NUM_INP_REGS];

    unique case (inp_pipe_op_q[NUM_INP_REGS])
      fpnew_pkg::FMADD:  ; // do nothing
      fpnew_pkg::FNMSUB: operand_a.sign = ~operand_a.sign; // invert sign of product
      fpnew_pkg::ADD: begin // Set multiplicand to +1
        operand_a = '{sign: 1'b0, exponent: BIAS, mantissa: '0};
        info_a    = '{is_normal: 1'b1, is_boxed: 1'b1, default: 1'b0}; //normal, boxed value.
      end
      fpnew_pkg::MUL: begin // Set addend to +0 or -0, depending whether the rounding mode is RDN
        if (inp_pipe_rnd_mode_q[NUM_INP_REGS] == fpnew_pkg::RDN)
          operand_c = '{sign: 1'b0, exponent: '0, mantissa: '0};
        else
          operand_c = '{sign: 1'b1, exponent: '0, mantissa: '0};
        info_c    = '{is_zero: 1'b1, is_boxed: 1'b1, default: 1'b0}; //zero, boxed value.
      end
      default: begin // propagate don't cares
        operand_a  = '{default: fpnew_pkg::DONT_CARE};
        operand_b  = '{default: fpnew_pkg::DONT_CARE};
        operand_c  = '{default: fpnew_pkg::DONT_CARE};
        info_a     = '{default: fpnew_pkg::DONT_CARE};
        info_b     = '{default: fpnew_pkg::DONT_CARE};
        info_c     = '{default: fpnew_pkg::DONT_CARE};
      end
    endcase
  end

  // ---------------------
  // Input classification
  // ---------------------
  logic any_operand_inf;
  logic any_operand_nan;
  logic signalling_nan;
  logic effective_subtraction;
  logic tentative_sign;

  // Reduction for special case handling
  assign any_operand_inf = (| {info_a.is_inf,        info_b.is_inf,        info_c.is_inf});
  assign any_operand_nan = (| {info_a.is_nan,        info_b.is_nan,        info_c.is_nan});
  assign signalling_nan  = (| {info_a.is_signalling, info_b.is_signalling, info_c.is_signalling});
  // Effective subtraction in FMA occurs when product and addend signs differ
  assign effective_subtraction = operand_a.sign ^ operand_b.sign ^ operand_c.sign;
  // The tentative sign of the FMA shall be the sign of the product
  assign tentative_sign = operand_a.sign ^ operand_b.sign;

  // ----------------------
  // Special case handling
  // ----------------------
  fp_t                special_result;
  fpnew_pkg::status_t special_status;
  logic               result_is_special;

  always_comb begin : special_cases
    // Default assignments
    special_result    = '{sign: 1'b0, exponent: '1, mantissa: 2**(MAN_BITS-1)}; // canonical qNaN
    special_status    = '0;
    result_is_special = 1'b0;

    // Handle potentially mixed nan & infinity input => important for the case where infinity and
    // zero are multiplied and added to a qnan.
    // RISC-V mandates raising the NV exception in these cases:
    // (inf * 0) + c or (0 * inf) + c INVALID, no matter c (even quiet NaNs)
    if ((info_a.is_inf && info_b.is_zero) || (info_a.is_zero && info_b.is_inf)) begin
      result_is_special = 1'b1; // bypass FMA, output is the canonical qNaN
      special_status.NV = 1'b1; // invalid operation
    // NaN Inputs cause canonical quiet NaN at the output and maybe invalid OP
    end else if (any_operand_nan) begin
      result_is_special = 1'b1;           // bypass FMA, output is the canonical qNaN
      special_status.NV = signalling_nan; // raise the invalid operation flag if signalling
    // Special cases involving infinity
    end else if (any_operand_inf) begin
      result_is_special = 1'b1; // bypass FMA
      // Effective addition of opposite infinities (±inf - ±inf) is invalid!
      if ((info_a.is_inf || info_b.is_inf) && info_c.is_inf && effective_subtraction)
        special_status.NV = 1'b1; // invalid operation
      // Handle cases where output will be inf because of inf product input
      else if (info_a.is_inf || info_b.is_inf) begin
        // Result is infinity with the sign of the product
        special_result    = '{sign: operand_a.sign ^ operand_b.sign, exponent: '1, mantissa: '0};
      // Handle cases where the addend is inf
      end else if (info_c.is_inf) begin
        // Result is inifinity with sign of the addend (= operand_c)
        special_result    = '{sign: operand_c.sign, exponent: '1, mantissa: '0};
      end
    end
  end

  // ---------------------------
  // Initial exponent data path
  // ---------------------------
  logic signed [EXP_WIDTH-1:0] exponent_a, exponent_b, exponent_c;
  logic signed [EXP_WIDTH-1:0] exponent_addend, exponent_product, exponent_difference;
  logic signed [EXP_WIDTH-1:0] tentative_exponent;

  // Zero-extend exponents into signed container - implicit width extension
  assign exponent_a = signed'({1'b0, operand_a.exponent});
  assign exponent_b = signed'({1'b0, operand_b.exponent});
  assign exponent_c = signed'({1'b0, operand_c.exponent});

  // Calculate internal exponents from encoded values. Real exponents are (ex = Ex - bias + 1 - nx)
  // with Ex the encoded exponent and nx the implicit bit. Internal exponents stay biased.
  assign exponent_addend = signed'(exponent_c + $signed({1'b0, ~info_c.is_normal})); // 0 as subnorm
  // Biased product exponent is the sum of encoded exponents minus the bias.
  assign exponent_product = (info_a.is_zero || info_b.is_zero)
                            ? 2 - signed'(BIAS) // in case the product is zero, set minimum exp.
                            : signed'(exponent_a + info_a.is_subnormal
                                      + exponent_b + info_b.is_subnormal
                                      - signed'(BIAS));
  // Exponent difference is the addend exponent minus the product exponent
  assign exponent_difference = exponent_addend - exponent_product;
  // The tentative exponent will be the larger of the product or addend exponent
  assign tentative_exponent = (exponent_difference > 0) ? exponent_addend : exponent_product;

  // Shift amount for addend based on exponents (unsigned as only right shifts)
  logic [SHIFT_AMOUNT_WIDTH-1:0] addend_shamt;

  always_comb begin : addend_shift_amount
    // Product-anchored case, saturated shift (addend is only in the sticky bit)
    if (exponent_difference <= signed'(-2 * PRECISION_BITS - 1))
      addend_shamt = 3 * PRECISION_BITS + 4;
    // Addend and product will have mutual bits to add
    else if (exponent_difference <= signed'(PRECISION_BITS + 2))
      addend_shamt = unsigned'(signed'(PRECISION_BITS) + 3 - exponent_difference);
    // Addend-anchored case, saturated shift (product is only in the sticky bit)
    else
      addend_shamt = 0;
  end

  // ------------------
  // Product data path
  // ------------------
  logic [PRECISION_BITS-1:0]   mantissa_a, mantissa_b, mantissa_c;
  logic [2*PRECISION_BITS-1:0] product;             // the p*p product is 2p bits wide
  logic [3*PRECISION_BITS+3:0] product_shifted;     // addends are 3p+4 bit wide (including G/R)

  // Add implicit bits to mantissae
  assign mantissa_a = {info_a.is_normal, operand_a.mantissa};
  assign mantissa_b = {info_b.is_normal, operand_b.mantissa};
  assign mantissa_c = {info_c.is_normal, operand_c.mantissa};

  // Mantissa multiplier (a*b)
  assign product = mantissa_a * mantissa_b;

  // Product is placed into a 3p+4 bit wide vector, padded with 2 bits for round and sticky:
  // | 000...000 | product | RS |
  //  <-  p+2  -> <-  2p -> < 2>
  assign product_shifted = product << 2; // constant shift

  // -----------------
  // Addend data path
  // -----------------
  logic [3*PRECISION_BITS+3:0] addend_after_shift;  // upper 3p+4 bits are needed to go on
  logic [PRECISION_BITS-1:0]   addend_sticky_bits;  // up to p bit of shifted addend are sticky
  logic                        sticky_before_add;   // they are compressed into a single sticky bit
  logic [3*PRECISION_BITS+3:0] addend_shifted;      // addends are 3p+4 bit wide (including G/R)
  logic                        inject_carry_in;     // inject carry for subtractions if needed

  // In parallel, the addend is right-shifted according to the exponent difference. Up to p bits
  // are shifted out and compressed into a sticky bit.
  // BEFORE THE SHIFT:
  // | mantissa_c | 000..000 |
  //  <-    p   -> <- 3p+4 ->
  // AFTER THE SHIFT:
  // | 000..........000 | mantissa_c | 000...............0GR |  sticky bits  |
  //  <- addend_shamt -> <-    p   -> <- 2p+4-addend_shamt -> <-  up to p  ->
  assign {addend_after_shift, addend_sticky_bits} =
      (mantissa_c << (3 * PRECISION_BITS + 4)) >> addend_shamt;

  assign sticky_before_add     = (| addend_sticky_bits);
  // assign addend_after_shift[0] = sticky_before_add;

  // In case of a subtraction, the addend is inverted
  assign addend_shifted  = (effective_subtraction) ? ~addend_after_shift : addend_after_shift;
  assign inject_carry_in = effective_subtraction & ~sticky_before_add;

  // ------
  // Adder
  // ------
  logic [3*PRECISION_BITS+4:0] sum_raw;   // added one bit for the carry
  logic                        sum_carry; // observe carry bit from sum for sign fixing
  logic [3*PRECISION_BITS+3:0] sum;       // discard carry as sum won't overflow
  logic                        final_sign;

  //Mantissa adder (ab+c). In normal addition, it cannot overflow.
  assign sum_raw = product_shifted + addend_shifted + inject_carry_in;
  assign sum_carry = sum_raw[3*PRECISION_BITS+4];

  // Complement negative sum (can only happen in subtraction -> overflows for positive results)
  assign sum        = (effective_subtraction && ~sum_carry) ? -sum_raw : sum_raw;

  // In case of a mispredicted subtraction result, do a sign flip
  assign final_sign = (effective_subtraction && (sum_carry == tentative_sign))
                      ? 1'b1
                      : (effective_subtraction ? 1'b0 : tentative_sign);

  // ---------------
  // Internal pipeline
  // ---------------
  // Pipeline output signals as non-arrays
  logic                          effective_subtraction_q;
  logic signed [EXP_WIDTH-1:0]   exponent_product_q;
  logic signed [EXP_WIDTH-1:0]   exponent_difference_q;
  logic signed [EXP_WIDTH-1:0]   tentative_exponent_q;
  logic [SHIFT_AMOUNT_WIDTH-1:0] addend_shamt_q;
  logic                          sticky_before_add_q;
  logic [3*PRECISION_BITS+3:0]   sum_q;
  logic                          final_sign_q;
  fpnew_pkg::roundmode_e         rnd_mode_q;
  logic                          result_is_special_q;
  fp_t                           special_result_q;
  fpnew_pkg::status_t            special_status_q;
  // Internal pipeline signals, index i holds signal after i register stages
  logic                  [0:NUM_MID_REGS]                         mid_pipe_eff_sub_q;
  logic signed           [0:NUM_MID_REGS][EXP_WIDTH-1:0]          mid_pipe_exp_prod_q;
  logic signed           [0:NUM_MID_REGS][EXP_WIDTH-1:0]          mid_pipe_exp_diff_q;
  logic signed           [0:NUM_MID_REGS][EXP_WIDTH-1:0]          mid_pipe_tent_exp_q;
  logic                  [0:NUM_MID_REGS][SHIFT_AMOUNT_WIDTH-1:0] mid_pipe_add_shamt_q;
  logic                  [0:NUM_MID_REGS]                         mid_pipe_sticky_q;
  logic                  [0:NUM_MID_REGS][3*PRECISION_BITS+3:0]   mid_pipe_sum_q;
  logic                  [0:NUM_MID_REGS]                         mid_pipe_final_sign_q;
  fpnew_pkg::roundmode_e [0:NUM_MID_REGS]                         mid_pipe_rnd_mode_q;
  logic                  [0:NUM_MID_REGS]                         mid_pipe_res_is_spec_q;
  fp_t                   [0:NUM_MID_REGS]                         mid_pipe_spec_res_q;
  fpnew_pkg::status_t    [0:NUM_MID_REGS]                         mid_pipe_spec_stat_q;
  TagType                [0:NUM_MID_REGS]                         mid_pipe_tag_q;
  logic                  [0:NUM_MID_REGS]                         mid_pipe_mask_q;
  AuxType                [0:NUM_MID_REGS]                         mid_pipe_aux_q;
  logic                  [0:NUM_MID_REGS]                         mid_pipe_valid_q;
  // Ready signal is combinatorial for all stages
  logic [0:NUM_MID_REGS] mid_pipe_ready;

  // Input stage: First element of pipeline is taken from upstream logic
  assign mid_pipe_eff_sub_q[0]     = effective_subtraction;
  assign mid_pipe_exp_prod_q[0]    = exponent_product;
  assign mid_pipe_exp_diff_q[0]    = exponent_difference;
  assign mid_pipe_tent_exp_q[0]    = tentative_exponent;
  assign mid_pipe_add_shamt_q[0]   = addend_shamt;
  assign mid_pipe_sticky_q[0]      = sticky_before_add;
  assign mid_pipe_sum_q[0]         = sum;
  assign mid_pipe_final_sign_q[0]  = final_sign;
  assign mid_pipe_rnd_mode_q[0]    = inp_pipe_rnd_mode_q[NUM_INP_REGS];
  assign mid_pipe_res_is_spec_q[0] = result_is_special;
  assign mid_pipe_spec_res_q[0]    = special_result;
  assign mid_pipe_spec_stat_q[0]   = special_status;
  assign mid_pipe_tag_q[0]         = inp_pipe_tag_q[NUM_INP_REGS];
  assign mid_pipe_mask_q[0]        = inp_pipe_mask_q[NUM_INP_REGS];
  assign mid_pipe_aux_q[0]         = inp_pipe_aux_q[NUM_INP_REGS];
  assign mid_pipe_valid_q[0]       = inp_pipe_valid_q[NUM_INP_REGS];
  // Input stage: Propagate pipeline ready signal to input pipe
  assign inp_pipe_ready[NUM_INP_REGS] = mid_pipe_ready[0];

  // Generate the register stages
  for (genvar i = 0; i < NUM_MID_REGS; i++) begin : gen_inside_pipeline
    // Internal register enable for this stage
    logic reg_ena;
    // Determine the ready signal of the current stage - advance the pipeline:
    // 1. if the next stage is ready for our data
    // 2. if the next stage only holds a bubble (not valid) -> we can pop it
    assign mid_pipe_ready[i] = mid_pipe_ready[i+1] | ~mid_pipe_valid_q[i+1];
    // Valid: enabled by ready signal, synchronous clear with the flush signal
    `FFLARNC(mid_pipe_valid_q[i+1], mid_pipe_valid_q[i], mid_pipe_ready[i], flush_i, 1'b0, clk_i, rst_ni)
    // Enable register if pipleine ready and a valid data item is present
    assign reg_ena = (mid_pipe_ready[i] & mid_pipe_valid_q[i]) | reg_ena_i[NUM_INP_REGS + i];
    // Generate the pipeline registers within the stages, use enable-registers
    `FFL(mid_pipe_eff_sub_q[i+1],     mid_pipe_eff_sub_q[i],     reg_ena, '0)
    `FFL(mid_pipe_exp_prod_q[i+1],    mid_pipe_exp_prod_q[i],    reg_ena, '0)
    `FFL(mid_pipe_exp_diff_q[i+1],    mid_pipe_exp_diff_q[i],    reg_ena, '0)
    `FFL(mid_pipe_tent_exp_q[i+1],    mid_pipe_tent_exp_q[i],    reg_ena, '0)
    `FFL(mid_pipe_add_shamt_q[i+1],   mid_pipe_add_shamt_q[i],   reg_ena, '0)
    `FFL(mid_pipe_sticky_q[i+1],      mid_pipe_sticky_q[i],      reg_ena, '0)
    `FFL(mid_pipe_sum_q[i+1],         mid_pipe_sum_q[i],         reg_ena, '0)
    `FFL(mid_pipe_final_sign_q[i+1],  mid_pipe_final_sign_q[i],  reg_ena, '0)
    `FFL(mid_pipe_rnd_mode_q[i+1],    mid_pipe_rnd_mode_q[i],    reg_ena, fpnew_pkg::RNE)
    `FFL(mid_pipe_res_is_spec_q[i+1], mid_pipe_res_is_spec_q[i], reg_ena, '0)
    `FFL(mid_pipe_spec_res_q[i+1],    mid_pipe_spec_res_q[i],    reg_ena, '0)
    `FFL(mid_pipe_spec_stat_q[i+1],   mid_pipe_spec_stat_q[i],   reg_ena, '0)
    `FFL(mid_pipe_tag_q[i+1],         mid_pipe_tag_q[i],         reg_ena, TagType'('0))
    `FFL(mid_pipe_mask_q[i+1],        mid_pipe_mask_q[i],        reg_ena, '0)
    `FFL(mid_pipe_aux_q[i+1],         mid_pipe_aux_q[i],         reg_ena, AuxType'('0))
  end
  // Output stage: assign selected pipe outputs to signals for later use
  assign effective_subtraction_q = mid_pipe_eff_sub_q[NUM_MID_REGS];
  assign exponent_product_q      = mid_pipe_exp_prod_q[NUM_MID_REGS];
  assign exponent_difference_q   = mid_pipe_exp_diff_q[NUM_MID_REGS];
  assign tentative_exponent_q    = mid_pipe_tent_exp_q[NUM_MID_REGS];
  assign addend_shamt_q          = mid_pipe_add_shamt_q[NUM_MID_REGS];
  assign sticky_before_add_q     = mid_pipe_sticky_q[NUM_MID_REGS];
  assign sum_q                   = mid_pipe_sum_q[NUM_MID_REGS];
  assign final_sign_q            = mid_pipe_final_sign_q[NUM_MID_REGS];
  assign rnd_mode_q              = mid_pipe_rnd_mode_q[NUM_MID_REGS];
  assign result_is_special_q     = mid_pipe_res_is_spec_q[NUM_MID_REGS];
  assign special_result_q        = mid_pipe_spec_res_q[NUM_MID_REGS];
  assign special_status_q        = mid_pipe_spec_stat_q[NUM_MID_REGS];

  // --------------
  // Normalization
  // --------------
  logic        [LOWER_SUM_WIDTH-1:0]  sum_lower;              // lower 2p+3 bits of sum are searched
  logic        [LZC_RESULT_WIDTH-1:0] leading_zero_count;     // the number of leading zeroes
  logic signed [LZC_RESULT_WIDTH:0]   leading_zero_count_sgn; // signed leading-zero count
  logic                               lzc_zeroes;             // in case only zeroes found

  logic        [SHIFT_AMOUNT_WIDTH-1:0] norm_shamt; // Normalization shift amount
  logic signed [EXP_WIDTH-1:0]          normalized_exponent;

  logic [3*PRECISION_BITS+4:0] sum_shifted;       // result after first normalization shift
  logic [PRECISION_BITS:0]     final_mantissa;    // final mantissa before rounding with round bit
  logic [2*PRECISION_BITS+2:0] sum_sticky_bits;   // remaining 2p+3 sticky bits after normalization
  logic                        sticky_after_norm; // sticky bit after normalization

  logic signed [EXP_WIDTH-1:0] final_exponent;

  assign sum_lower = sum_q[LOWER_SUM_WIDTH-1:0];

  // Leading zero counter for cancellations
  lzc #(
    .WIDTH ( LOWER_SUM_WIDTH ),
    .MODE  ( 1               ) // MODE = 1 counts leading zeroes
  ) i_lzc (
    .in_i    ( sum_lower          ),
    .cnt_o   ( leading_zero_count ),
    .empty_o ( lzc_zeroes         )
  );

  assign leading_zero_count_sgn = signed'({1'b0, leading_zero_count});

  // Normalization shift amount based on exponents and LZC (unsigned as only left shifts)
  always_comb begin : norm_shift_amount
    // Product-anchored case or cancellations require LZC
    if ((exponent_difference_q <= 0) || (effective_subtraction_q && (exponent_difference_q <= 2))) begin
      // Normal result (biased exponent > 0 and not a zero)
      if ((exponent_product_q - leading_zero_count_sgn + 1 >= 0) && !lzc_zeroes) begin
        // Undo initial product shift, remove the counted zeroes
        norm_shamt          = PRECISION_BITS + 2 + leading_zero_count;
        normalized_exponent = exponent_product_q - leading_zero_count_sgn + 1; // account for shift
      // Subnormal result
      end else begin
        // Cap the shift distance to align mantissa with minimum exponent
        norm_shamt          = unsigned'(signed'(PRECISION_BITS) + 2 + exponent_product_q);
        normalized_exponent = 0; // subnormals encoded as 0
      end
    // Addend-anchored case
    end else begin
      norm_shamt          = addend_shamt_q; // Undo the initial shift
      normalized_exponent = tentative_exponent_q;
    end
  end

  // Do the large normalization shift
  assign sum_shifted       = sum_q << norm_shamt;

  // The addend-anchored case needs a 1-bit normalization since the leading-one can be to the left
  // or right of the (non-carry) MSB of the sum.
  always_comb begin : small_norm
    // Default assignment, discarding carry bit
    {final_mantissa, sum_sticky_bits} = sum_shifted;
    final_exponent                    = normalized_exponent;

    // The normalized sum has overflown, align right and fix exponent
    if (sum_shifted[3*PRECISION_BITS+4]) begin // check the carry bit
      {final_mantissa, sum_sticky_bits} = sum_shifted >> 1;
      final_exponent                    = normalized_exponent + 1;
    // The normalized sum is normal, nothing to do
    end else if (sum_shifted[3*PRECISION_BITS+3]) begin // check the sum MSB
      // do nothing
    // The normalized sum is still denormal, align left - unless the result is not already subnormal
    end else if (normalized_exponent > 1) begin
      {final_mantissa, sum_sticky_bits} = sum_shifted << 1;
      final_exponent                    = normalized_exponent - 1;
    // Otherwise we're denormal
    end else begin
      final_exponent = '0;
    end
  end

  // Update the sticky bit with the shifted-out bits
  assign sticky_after_norm = (| {sum_sticky_bits}) | sticky_before_add_q;

  // ----------------------------
  // Rounding and classification
  // ----------------------------
  logic                         pre_round_sign;
  logic [EXP_BITS-1:0]          pre_round_exponent;
  logic [MAN_BITS-1:0]          pre_round_mantissa;
  logic [EXP_BITS+MAN_BITS-1:0] pre_round_abs; // absolute value of result before rounding
  logic [1:0]                   round_sticky_bits;

  logic of_before_round, of_after_round; // overflow
  logic uf_before_round, uf_after_round; // underflow
  logic result_zero;

  logic                         rounded_sign;
  logic [EXP_BITS+MAN_BITS-1:0] rounded_abs; // absolute value of result after rounding

  // Classification before round. RISC-V mandates checking underflow AFTER rounding!
  assign of_before_round = final_exponent >= 2**(EXP_BITS)-1; // infinity exponent is all ones
  assign uf_before_round = final_exponent == 0;               // exponent for subnormals capped to 0

  // Assemble result before rounding. In case of overflow, the largest normal value is set.
  assign pre_round_sign     = final_sign_q;
  assign pre_round_exponent = (of_before_round) ? 2**EXP_BITS-2 : unsigned'(final_exponent[EXP_BITS-1:0]);
  assign pre_round_mantissa = (of_before_round) ? '1 : final_mantissa[MAN_BITS:1]; // bit 0 is R bit
  assign pre_round_abs      = {pre_round_exponent, pre_round_mantissa};

  // In case of overflow, the round and sticky bits are set for proper rounding
  assign round_sticky_bits  = (of_before_round) ? 2'b11 : {final_mantissa[0], sticky_after_norm};

  // Perform the rounding
  fpnew_rounding #(
    .AbsWidth ( EXP_BITS + MAN_BITS )
  ) i_fpnew_rounding (
    .abs_value_i             ( pre_round_abs           ),
    .sign_i                  ( pre_round_sign          ),
    .round_sticky_bits_i     ( round_sticky_bits       ),
    .rnd_mode_i              ( rnd_mode_q              ),
    .effective_subtraction_i ( effective_subtraction_q ),
    .abs_rounded_o           ( rounded_abs             ),
    .sign_o                  ( rounded_sign            ),
    .exact_zero_o            ( result_zero             )
  );

  // Classification after rounding
  assign uf_after_round = (rounded_abs[EXP_BITS+MAN_BITS-1:MAN_BITS] == '0) // denormal
        || ((pre_round_abs[EXP_BITS+MAN_BITS-1:MAN_BITS] == '0) && (rounded_abs[EXP_BITS+MAN_BITS-1:MAN_BITS] == 1) &&
           ((round_sticky_bits != 2'b11) || (!sum_sticky_bits[MAN_BITS*2 + 4] && ((rnd_mode_i == fpnew_pkg::RNE) || (rnd_mode_i == fpnew_pkg::RMM)))));
  assign of_after_round = rounded_abs[EXP_BITS+MAN_BITS-1:MAN_BITS] == '1; // exponent all ones

  // -----------------
  // Result selection
  // -----------------
  logic [WIDTH-1:0]     regular_result;
  fpnew_pkg::status_t   regular_status;

  // Assemble regular result
  assign regular_result    = {rounded_sign, rounded_abs};
  assign regular_status.NV = 1'b0; // only valid cases are handled in regular path
  assign regular_status.DZ = 1'b0; // no divisions
  assign regular_status.OF = of_before_round | of_after_round;   // rounding can introduce overflow
  assign regular_status.UF = uf_after_round & regular_status.NX; // only inexact results raise UF
  assign regular_status.NX = (| round_sticky_bits) | of_before_round | of_after_round;

  // Final results for output pipeline
  fp_t                result_d;
  fpnew_pkg::status_t status_d;

  // Select output depending on special case detection
  assign result_d = result_is_special_q ? special_result_q : regular_result;
  assign status_d = result_is_special_q ? special_status_q : regular_status;

  // ----------------
  // Output Pipeline
  // ----------------
  // Output pipeline signals, index i holds signal after i register stages
  fp_t                [0:NUM_OUT_REGS] out_pipe_result_q;
  fpnew_pkg::status_t [0:NUM_OUT_REGS] out_pipe_status_q;
  TagType             [0:NUM_OUT_REGS] out_pipe_tag_q;
  logic               [0:NUM_OUT_REGS] out_pipe_mask_q;
  AuxType             [0:NUM_OUT_REGS] out_pipe_aux_q;
  logic               [0:NUM_OUT_REGS] out_pipe_valid_q;
  // Ready signal is combinatorial for all stages
  logic [0:NUM_OUT_REGS] out_pipe_ready;

  // Input stage: First element of pipeline is taken from inputs
  assign out_pipe_result_q[0] = result_d;
  assign out_pipe_status_q[0] = status_d;
  assign out_pipe_tag_q[0]    = mid_pipe_tag_q[NUM_MID_REGS];
  assign out_pipe_mask_q[0]   = mid_pipe_mask_q[NUM_MID_REGS];
  assign out_pipe_aux_q[0]    = mid_pipe_aux_q[NUM_MID_REGS];
  assign out_pipe_valid_q[0]  = mid_pipe_valid_q[NUM_MID_REGS];
  // Input stage: Propagate pipeline ready signal to inside pipe
  assign mid_pipe_ready[NUM_MID_REGS] = out_pipe_ready[0];
  // Generate the register stages
  for (genvar i = 0; i < NUM_OUT_REGS; i++) begin : gen_output_pipeline
    // Internal register enable for this stage
    logic reg_ena;
    // Determine the ready signal of the current stage - advance the pipeline:
    // 1. if the next stage is ready for our data
    // 2. if the next stage only holds a bubble (not valid) -> we can pop it
    assign out_pipe_ready[i] = out_pipe_ready[i+1] | ~out_pipe_valid_q[i+1];
    // Valid: enabled by ready signal, synchronous clear with the flush signal
    `FFLARNC(out_pipe_valid_q[i+1], out_pipe_valid_q[i], out_pipe_ready[i], flush_i, 1'b0, clk_i, rst_ni)
    // Enable register if pipleine ready and a valid data item is present
    assign reg_ena = (out_pipe_ready[i] & out_pipe_valid_q[i]) | reg_ena_i[NUM_INP_REGS + NUM_MID_REGS + i];
    // Generate the pipeline registers within the stages, use enable-registers
    `FFL(out_pipe_result_q[i+1], out_pipe_result_q[i], reg_ena, '0)
    `FFL(out_pipe_status_q[i+1], out_pipe_status_q[i], reg_ena, '0)
    `FFL(out_pipe_tag_q[i+1],    out_pipe_tag_q[i],    reg_ena, TagType'('0))
    `FFL(out_pipe_mask_q[i+1],   out_pipe_mask_q[i],   reg_ena, '0)
    `FFL(out_pipe_aux_q[i+1],    out_pipe_aux_q[i],    reg_ena, AuxType'('0))
  end
  // Output stage: Ready travels backwards from output side, driven by downstream circuitry
  assign out_pipe_ready[NUM_OUT_REGS] = out_ready_i;
  // Output stage: assign module outputs
  assign result_o        = out_pipe_result_q[NUM_OUT_REGS];
  assign status_o        = out_pipe_status_q[NUM_OUT_REGS];
  assign extension_bit_o = 1'b1; // always NaN-Box result
  assign tag_o           = out_pipe_tag_q[NUM_OUT_REGS];
  assign mask_o          = out_pipe_mask_q[NUM_OUT_REGS];
  assign aux_o           = out_pipe_aux_q[NUM_OUT_REGS];
  assign out_valid_o     = out_pipe_valid_q[NUM_OUT_REGS];
  assign busy_o          = (| {inp_pipe_valid_q, mid_pipe_valid_q, out_pipe_valid_q});
endmodule
// Copyright 2019 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// SPDX-License-Identifier: SHL-0.51

// Author: Stefan Mach <smach@iis.ee.ethz.ch>

// Copyright 2018 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Common register defines for RTL designs
`ifndef COMMON_CELLS_REGISTERS_SVH_
`define COMMON_CELLS_REGISTERS_SVH_

// Abridged Summary of available FF macros:
// `FF:      asynchronous active-low reset (implicit clock and reset)
// `FFAR:    asynchronous active-high reset
// `FFARN:   asynchronous active-low reset
// `FFSR:    synchronous active-high reset
// `FFSRN:   synchronous active-low reset
// `FFNR:    without reset
// `FFL:     load-enable and asynchronous active-low reset (implicit clock and reset)
// `FFLAR:   load-enable and asynchronous active-high reset
// `FFLARN:  load-enable and asynchronous active-low reset
// `FFLARNC: load-enable and asynchronous active-low reset and synchronous active-high clear
// `FFLSR:   load-enable and synchronous active-high reset
// `FFLSRN:  load-enable and synchronous active-low reset
// `FFLNR:   load-enable without reset


// Flip-Flop with asynchronous active-low reset (implicit clock and reset)
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// Implicit:
// clk_i: clock input
// rst_ni: reset input (asynchronous, active low)
`define FF(__q, __d, __reset_value)                  \
  always_ff @(posedge clk_i or negedge rst_ni) begin \
    if (!rst_ni) begin                               \
      __q <= (__reset_value);                        \
    end else begin                                   \
      __q <= (__d);                                  \
    end                                              \
  end

// Flip-Flop with asynchronous active-high reset
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __arst: asynchronous reset
`define FFAR(__q, __d, __reset_value, __clk, __arst)     \
  always_ff @(posedge (__clk) or posedge (__arst)) begin \
    if (__arst) begin                                    \
      __q <= (__reset_value);                            \
    end else begin                                       \
      __q <= (__d);                                      \
    end                                                  \
  end

// Flip-Flop with asynchronous active-low reset
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __arst_n: asynchronous reset
`define FFARN(__q, __d, __reset_value, __clk, __arst_n)    \
  always_ff @(posedge (__clk) or negedge (__arst_n)) begin \
    if (!__arst_n) begin                                   \
      __q <= (__reset_value);                              \
    end else begin                                         \
      __q <= (__d);                                        \
    end                                                    \
  end

// Flip-Flop with synchronous active-high reset
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __reset_clk: reset input
`define FFSR(__q, __d, __reset_value, __clk, __reset_clk) \
  `ifndef VERILATOR                       \
  /``* synopsys sync_set_reset `"__reset_clk`" *``/       \
    `endif                        \
  always_ff @(posedge (__clk)) begin                      \
    __q <= (__reset_clk) ? (__reset_value) : (__d);       \
  end

// Flip-Flop with synchronous active-low reset
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __reset_n_clk: reset input
`define FFSRN(__q, __d, __reset_value, __clk, __reset_n_clk) \
    `ifndef VERILATOR                       \
  /``* synopsys sync_set_reset `"__reset_n_clk`" *``/        \
    `endif                        \
  always_ff @(posedge (__clk)) begin                         \
    __q <= (!__reset_n_clk) ? (__reset_value) : (__d);       \
  end

// Always-enable Flip-Flop without reset
// __q: Q output of FF
// __d: D input of FF
// __clk: clock input
`define FFNR(__q, __d, __clk)        \
  always_ff @(posedge (__clk)) begin \
    __q <= (__d);                    \
  end

// Flip-Flop with load-enable and asynchronous active-low reset (implicit clock and reset)
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __reset_value: value assigned upon reset
// Implicit:
// clk_i: clock input
// rst_ni: reset input (asynchronous, active low)
`define FFL(__q, __d, __load, __reset_value)         \
  always_ff @(posedge clk_i or negedge rst_ni) begin \
    if (!rst_ni) begin                               \
      __q <= (__reset_value);                        \
    end else begin                                   \
      __q <= (__load) ? (__d) : (__q);               \
    end                                              \
  end

// Flip-Flop with load-enable and asynchronous active-high reset
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __arst: asynchronous reset
`define FFLAR(__q, __d, __load, __reset_value, __clk, __arst) \
  always_ff @(posedge (__clk) or posedge (__arst)) begin      \
    if (__arst) begin                                         \
      __q <= (__reset_value);                                 \
    end else begin                                            \
      __q <= (__load) ? (__d) : (__q);                        \
    end                                                       \
  end

// Flip-Flop with load-enable and asynchronous active-low reset
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __arst_n: asynchronous reset
`define FFLARN(__q, __d, __load, __reset_value, __clk, __arst_n) \
  always_ff @(posedge (__clk) or negedge (__arst_n)) begin       \
    if (!__arst_n) begin                                         \
      __q <= (__reset_value);                                    \
    end else begin                                               \
      __q <= (__load) ? (__d) : (__q);                           \
    end                                                          \
  end

// Flip-Flop with load-enable and synchronous active-high reset
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __reset_clk: reset input
`define FFLSR(__q, __d, __load, __reset_value, __clk, __reset_clk)       \
    `ifndef VERILATOR                       \
  /``* synopsys sync_set_reset `"__reset_clk`" *``/                      \
    `endif                        \
  always_ff @(posedge (__clk)) begin                                     \
    __q <= (__reset_clk) ? (__reset_value) : ((__load) ? (__d) : (__q)); \
  end

// Flip-Flop with load-enable and synchronous active-low reset
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __reset_n_clk: reset input
`define FFLSRN(__q, __d, __load, __reset_value, __clk, __reset_n_clk)       \
    `ifndef VERILATOR                       \
  /``* synopsys sync_set_reset `"__reset_n_clk`" *``/                       \
    `endif                        \
  always_ff @(posedge (__clk)) begin                                        \
    __q <= (!__reset_n_clk) ? (__reset_value) : ((__load) ? (__d) : (__q)); \
  end

// Flip-Flop with load-enable and asynchronous active-low reset and synchronous clear
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __clear: assign reset value into FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __arst_n: asynchronous reset
`define FFLARNC(__q, __d, __load, __clear, __reset_value, __clk, __arst_n) \
    `ifndef VERILATOR                       \
  /``* synopsys sync_set_reset `"__clear`" *``/                       \
    `endif                        \
  always_ff @(posedge (__clk) or negedge (__arst_n)) begin                 \
    if (!__arst_n) begin                                                   \
      __q <= (__reset_value);                                              \
    end else begin                                                         \
      __q <= (__clear) ? (__reset_value) : (__load) ? (__d) : (__q);       \
    end                                                                    \
  end

// Load-enable Flip-Flop without reset
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __clk: clock input
`define FFLNR(__q, __d, __load, __clk) \
  always_ff @(posedge (__clk)) begin   \
    __q <= (__load) ? (__d) : (__q);   \
  end

`endif

module fpnew_noncomp #(
  parameter fpnew_pkg::fp_format_e   FpFormat    = fpnew_pkg::fp_format_e'(0),
  parameter int unsigned             NumPipeRegs = 0,
  parameter fpnew_pkg::pipe_config_t PipeConfig  = fpnew_pkg::BEFORE,
  parameter type                     TagType     = logic,
  parameter type                     AuxType     = logic,
  // Do not change
  localparam int unsigned WIDTH = fpnew_pkg::fp_width(FpFormat),
  localparam int unsigned ExtRegEnaWidth = NumPipeRegs == 0 ? 1 : NumPipeRegs
) (
  input logic                  clk_i,
  input logic                  rst_ni,
  // Input signals
  input logic [1:0][WIDTH-1:0]     operands_i, // 2 operands
  input logic [1:0]                is_boxed_i, // 2 operands
  input fpnew_pkg::roundmode_e     rnd_mode_i,
  input fpnew_pkg::operation_e     op_i,
  input logic                      op_mod_i,
  input TagType                    tag_i,
  input logic                      mask_i,
  input AuxType                    aux_i,
  // Input Handshake
  input  logic                     in_valid_i,
  output logic                     in_ready_o,
  input  logic                     flush_i,
  // Output signals
  output logic [WIDTH-1:0]         result_o,
  output fpnew_pkg::status_t       status_o,
  output logic                     extension_bit_o,
  output fpnew_pkg::classmask_e    class_mask_o,
  output logic                     is_class_o,
  output TagType                   tag_o,
  output logic                     mask_o,
  output AuxType                   aux_o,
  // Output handshake
  output logic                     out_valid_o,
  input  logic                     out_ready_i,
  // Indication of valid data in flight
  output logic                     busy_o,
  // External register enable override
  input  logic [ExtRegEnaWidth-1:0] reg_ena_i
);

  // ----------
  // Constants
  // ----------
  localparam int unsigned EXP_BITS = fpnew_pkg::exp_bits(FpFormat);
  localparam int unsigned MAN_BITS = fpnew_pkg::man_bits(FpFormat);
  // Pipelines
  localparam NUM_INP_REGS = (PipeConfig == fpnew_pkg::BEFORE || PipeConfig == fpnew_pkg::INSIDE)
                            ? NumPipeRegs
                            : (PipeConfig == fpnew_pkg::DISTRIBUTED
                               ? ((NumPipeRegs + 1) / 2) // First to get distributed regs
                               : 0); // no regs here otherwise
  localparam NUM_OUT_REGS = PipeConfig == fpnew_pkg::AFTER
                            ? NumPipeRegs
                            : (PipeConfig == fpnew_pkg::DISTRIBUTED
                               ? (NumPipeRegs / 2) // Last to get distributed regs
                               : 0); // no regs here otherwise

  // ----------------
  // Type definition
  // ----------------
  typedef struct packed {
    logic                sign;
    logic [EXP_BITS-1:0] exponent;
    logic [MAN_BITS-1:0] mantissa;
  } fp_t;

  // ---------------
  // Input pipeline
  // ---------------
  // Input pipeline signals, index i holds signal after i register stages
  logic                  [0:NUM_INP_REGS][1:0][WIDTH-1:0] inp_pipe_operands_q;
  logic                  [0:NUM_INP_REGS][1:0]            inp_pipe_is_boxed_q;
  fpnew_pkg::roundmode_e [0:NUM_INP_REGS]                 inp_pipe_rnd_mode_q;
  fpnew_pkg::operation_e [0:NUM_INP_REGS]                 inp_pipe_op_q;
  logic                  [0:NUM_INP_REGS]                 inp_pipe_op_mod_q;
  TagType                [0:NUM_INP_REGS]                 inp_pipe_tag_q;
  logic                  [0:NUM_INP_REGS]                 inp_pipe_mask_q;
  AuxType                [0:NUM_INP_REGS]                 inp_pipe_aux_q;
  logic                  [0:NUM_INP_REGS]                 inp_pipe_valid_q;
  // Ready signal is combinatorial for all stages
  logic [0:NUM_INP_REGS] inp_pipe_ready;

  // Input stage: First element of pipeline is taken from inputs
  assign inp_pipe_operands_q[0] = operands_i;
  assign inp_pipe_is_boxed_q[0] = is_boxed_i;
  assign inp_pipe_rnd_mode_q[0] = rnd_mode_i;
  assign inp_pipe_op_q[0]       = op_i;
  assign inp_pipe_op_mod_q[0]   = op_mod_i;
  assign inp_pipe_tag_q[0]      = tag_i;
  assign inp_pipe_mask_q[0]     = mask_i;
  assign inp_pipe_aux_q[0]      = aux_i;
  assign inp_pipe_valid_q[0]    = in_valid_i;
  // Input stage: Propagate pipeline ready signal to updtream circuitry
  assign in_ready_o = inp_pipe_ready[0];
  // Generate the register stages
  for (genvar i = 0; i < NUM_INP_REGS; i++) begin : gen_input_pipeline
    // Internal register enable for this stage
    logic reg_ena;
    // Determine the ready signal of the current stage - advance the pipeline:
    // 1. if the next stage is ready for our data
    // 2. if the next stage only holds a bubble (not valid) -> we can pop it
    assign inp_pipe_ready[i] = inp_pipe_ready[i+1] | ~inp_pipe_valid_q[i+1];
    // Valid: enabled by ready signal, synchronous clear with the flush signal
    `FFLARNC(inp_pipe_valid_q[i+1], inp_pipe_valid_q[i], inp_pipe_ready[i], flush_i, 1'b0, clk_i, rst_ni)
    // Enable register if pipleine ready and a valid data item is present
    assign reg_ena = (inp_pipe_ready[i] & inp_pipe_valid_q[i]) | reg_ena_i[i];
    // Generate the pipeline registers within the stages, use enable-registers
    `FFL(inp_pipe_operands_q[i+1], inp_pipe_operands_q[i], reg_ena, '0)
    `FFL(inp_pipe_is_boxed_q[i+1], inp_pipe_is_boxed_q[i], reg_ena, '0)
    `FFL(inp_pipe_rnd_mode_q[i+1], inp_pipe_rnd_mode_q[i], reg_ena, fpnew_pkg::RNE)
    `FFL(inp_pipe_op_q[i+1],       inp_pipe_op_q[i],       reg_ena, fpnew_pkg::FMADD)
    `FFL(inp_pipe_op_mod_q[i+1],   inp_pipe_op_mod_q[i],   reg_ena, '0)
    `FFL(inp_pipe_tag_q[i+1],      inp_pipe_tag_q[i],      reg_ena, TagType'('0))
    `FFL(inp_pipe_mask_q[i+1],     inp_pipe_mask_q[i],     reg_ena, '0)
    `FFL(inp_pipe_aux_q[i+1],      inp_pipe_aux_q[i],      reg_ena, AuxType'('0))
  end

  // ---------------------
  // Input classification
  // ---------------------
  fpnew_pkg::fp_info_t [1:0] info_q;

  // Classify input
  fpnew_classifier #(
    .FpFormat    ( FpFormat ),
    .NumOperands ( 2        )
    ) i_class_a (
    .operands_i ( inp_pipe_operands_q[NUM_INP_REGS] ),
    .is_boxed_i ( inp_pipe_is_boxed_q[NUM_INP_REGS] ),
    .info_o     ( info_q                            )
  );

  fp_t                 operand_a, operand_b;
  fpnew_pkg::fp_info_t info_a,    info_b;

  // Packing-order-agnostic assignments
  assign operand_a = inp_pipe_operands_q[NUM_INP_REGS][0];
  assign operand_b = inp_pipe_operands_q[NUM_INP_REGS][1];
  assign info_a    = info_q[0];
  assign info_b    = info_q[1];

  logic any_operand_inf;
  logic any_operand_nan;
  logic signalling_nan;

  // Reduction for special case handling
  assign any_operand_inf = (| {info_a.is_inf,        info_b.is_inf});
  assign any_operand_nan = (| {info_a.is_nan,        info_b.is_nan});
  assign signalling_nan  = (| {info_a.is_signalling, info_b.is_signalling});

  logic operands_equal, operand_a_smaller;

  // Equality checks for zeroes too
  assign operands_equal    = (operand_a == operand_b) || (info_a.is_zero && info_b.is_zero);
  // Invert result if non-zero signs involved (unsigned comparison)
  assign operand_a_smaller = (operand_a < operand_b) ^ (operand_a.sign || operand_b.sign);

  // ---------------
  // Sign Injection
  // ---------------
  fp_t                sgnj_result;
  fpnew_pkg::status_t sgnj_status;
  logic               sgnj_extension_bit;

  // Sign Injection - operation is encoded in rnd_mode_q:
  // RNE = SGNJ, RTZ = SGNJN, RDN = SGNJX, RUP = Passthrough (no NaN-box check)
  always_comb begin : sign_injections
    logic sign_a, sign_b; // internal signs
    // Default assignment
    sgnj_result = operand_a; // result based on operand a

    // NaN-boxing check will treat invalid inputs as canonical NaNs
    if (!info_a.is_boxed) sgnj_result = '{sign: 1'b0, exponent: '1, mantissa: 2**(MAN_BITS-1)};

    // Internal signs are treated as positive in case of non-NaN-boxed values
    sign_a = operand_a.sign & info_a.is_boxed;
    sign_b = operand_b.sign & info_b.is_boxed;

    // Do the sign injection based on rm field
    unique case (inp_pipe_rnd_mode_q[NUM_INP_REGS])
      fpnew_pkg::RNE: sgnj_result.sign = sign_b;          // SGNJ
      fpnew_pkg::RTZ: sgnj_result.sign = ~sign_b;         // SGNJN
      fpnew_pkg::RDN: sgnj_result.sign = sign_a ^ sign_b; // SGNJX
      fpnew_pkg::RUP: sgnj_result      = operand_a;       // passthrough
      default: sgnj_result = '{default: fpnew_pkg::DONT_CARE}; // don't care
    endcase
  end

  assign sgnj_status = '0;        // sign injections never raise exceptions

  // op_mod_q enables integer sign-extension of result (for storing to integer regfile)
  assign sgnj_extension_bit = inp_pipe_op_mod_q[NUM_INP_REGS] ? sgnj_result.sign : 1'b1;

  // ------------------
  // Minimum / Maximum
  // ------------------
  fp_t                minmax_result;
  fpnew_pkg::status_t minmax_status;
  logic               minmax_extension_bit;

  // Minimum/Maximum - operation is encoded in rnd_mode_q:
  // RNE = MIN, RTZ = MAX
  always_comb begin : min_max
    // Default assignment
    minmax_status = '0;

    // Min/Max use quiet comparisons - only sNaN are invalid
    minmax_status.NV = signalling_nan;

    // Both NaN inputs cause a NaN output
    if (info_a.is_nan && info_b.is_nan)
      minmax_result = '{sign: 1'b0, exponent: '1, mantissa: 2**(MAN_BITS-1)}; // canonical qNaN
    // If one operand is NaN, the non-NaN operand is returned
    else if (info_a.is_nan) minmax_result = operand_b;
    else if (info_b.is_nan) minmax_result = operand_a;
    // Otherwise decide according to the operation
    else begin
      unique case (inp_pipe_rnd_mode_q[NUM_INP_REGS])
        fpnew_pkg::RNE: minmax_result = operand_a_smaller ? operand_a : operand_b; // MIN
        fpnew_pkg::RTZ: minmax_result = operand_a_smaller ? operand_b : operand_a; // MAX
        default: minmax_result = '{default: fpnew_pkg::DONT_CARE}; // don't care
      endcase
    end
  end

  assign minmax_extension_bit = 1'b1; // NaN-box as result is always a float value

  // ------------
  // Comparisons
  // ------------
  fp_t                cmp_result;
  fpnew_pkg::status_t cmp_status;
  logic               cmp_extension_bit;

  // Comparisons - operation is encoded in rnd_mode_q:
  // RNE = LE, RTZ = LT, RDN = EQ
  // op_mod_q inverts boolean outputs
  always_comb begin : comparisons
    // Default assignment
    cmp_result = '0; // false
    cmp_status = '0; // no flags

    // Signalling NaNs always compare as false and are illegal
    if (signalling_nan) cmp_status.NV = 1'b1; // invalid operation
    // Otherwise do comparisons
    else begin
      unique case (inp_pipe_rnd_mode_q[NUM_INP_REGS])
        fpnew_pkg::RNE: begin // Less than or equal
          if (any_operand_nan) cmp_status.NV = 1'b1; // Signalling comparison: NaNs are invalid
          else cmp_result = (operand_a_smaller | operands_equal) ^ inp_pipe_op_mod_q[NUM_INP_REGS];
        end
        fpnew_pkg::RTZ: begin // Less than
          if (any_operand_nan) cmp_status.NV = 1'b1; // Signalling comparison: NaNs are invalid
          else cmp_result = (operand_a_smaller & ~operands_equal) ^ inp_pipe_op_mod_q[NUM_INP_REGS];
        end
        fpnew_pkg::RDN: begin // Equal
          if (any_operand_nan) cmp_result = inp_pipe_op_mod_q[NUM_INP_REGS]; // NaN always not equal
          else cmp_result = operands_equal ^ inp_pipe_op_mod_q[NUM_INP_REGS];
        end
        default: cmp_result = '{default: fpnew_pkg::DONT_CARE}; // don't care
      endcase
    end
  end

  assign cmp_extension_bit = 1'b0; // Comparisons always produce booleans in integer registers

  // ---------------
  // Classification
  // ---------------
  fpnew_pkg::status_t    class_status;
  logic                  class_extension_bit;
  fpnew_pkg::classmask_e class_mask_d; // the result is actually here

  // Classification - always return the classification mask on the dedicated port
  always_comb begin : classify
    if (info_a.is_normal) begin
      class_mask_d = operand_a.sign       ? fpnew_pkg::NEGNORM    : fpnew_pkg::POSNORM;
    end else if (info_a.is_subnormal) begin
      class_mask_d = operand_a.sign       ? fpnew_pkg::NEGSUBNORM : fpnew_pkg::POSSUBNORM;
    end else if (info_a.is_zero) begin
      class_mask_d = operand_a.sign       ? fpnew_pkg::NEGZERO    : fpnew_pkg::POSZERO;
    end else if (info_a.is_inf) begin
      class_mask_d = operand_a.sign       ? fpnew_pkg::NEGINF     : fpnew_pkg::POSINF;
    end else if (info_a.is_nan) begin
      class_mask_d = info_a.is_signalling ? fpnew_pkg::SNAN       : fpnew_pkg::QNAN;
    end else begin
      class_mask_d = fpnew_pkg::QNAN; // default value
    end
  end

  assign class_status        = '0;   // classification does not set flags
  assign class_extension_bit = 1'b0; // classification always produces results in integer registers

  // -----------------
  // Result selection
  // -----------------
  fp_t                   result_d;
  fpnew_pkg::status_t    status_d;
  logic                  extension_bit_d;
  logic                  is_class_d;

  // Select result
  always_comb begin : select_result
    unique case (inp_pipe_op_q[NUM_INP_REGS])
      fpnew_pkg::SGNJ: begin
        result_d        = sgnj_result;
        status_d        = sgnj_status;
        extension_bit_d = sgnj_extension_bit;
      end
      fpnew_pkg::MINMAX: begin
        result_d        = minmax_result;
        status_d        = minmax_status;
        extension_bit_d = minmax_extension_bit;
      end
      fpnew_pkg::CMP: begin
        result_d        = cmp_result;
        status_d        = cmp_status;
        extension_bit_d = cmp_extension_bit;
      end
      fpnew_pkg::CLASSIFY: begin
        result_d        = '{default: fpnew_pkg::DONT_CARE}; // unused
        status_d        = class_status;
        extension_bit_d = class_extension_bit;
      end
      default: begin
        result_d        = '{default: fpnew_pkg::DONT_CARE}; // dont care
        status_d        = '{default: fpnew_pkg::DONT_CARE}; // dont care
        extension_bit_d = fpnew_pkg::DONT_CARE;             // dont care
      end
    endcase
  end

  assign is_class_d = (inp_pipe_op_q[NUM_INP_REGS] == fpnew_pkg::CLASSIFY);

  // ----------------
  // Output Pipeline
  // ----------------
  // Output pipeline signals, index i holds signal after i register stages
  fp_t                   [0:NUM_OUT_REGS] out_pipe_result_q;
  fpnew_pkg::status_t    [0:NUM_OUT_REGS] out_pipe_status_q;
  logic                  [0:NUM_OUT_REGS] out_pipe_extension_bit_q;
  fpnew_pkg::classmask_e [0:NUM_OUT_REGS] out_pipe_class_mask_q;
  logic                  [0:NUM_OUT_REGS] out_pipe_is_class_q;
  TagType                [0:NUM_OUT_REGS] out_pipe_tag_q;
  logic                  [0:NUM_OUT_REGS] out_pipe_mask_q;
  AuxType                [0:NUM_OUT_REGS] out_pipe_aux_q;
  logic                  [0:NUM_OUT_REGS] out_pipe_valid_q;
  // Ready signal is combinatorial for all stages
  logic [0:NUM_OUT_REGS] out_pipe_ready;

  // Input stage: First element of pipeline is taken from inputs
  assign out_pipe_result_q[0]        = result_d;
  assign out_pipe_status_q[0]        = status_d;
  assign out_pipe_extension_bit_q[0] = extension_bit_d;
  assign out_pipe_class_mask_q[0]    = class_mask_d;
  assign out_pipe_is_class_q[0]      = is_class_d;
  assign out_pipe_tag_q[0]           = inp_pipe_tag_q[NUM_INP_REGS];
  assign out_pipe_mask_q[0]          = inp_pipe_mask_q[NUM_INP_REGS];
  assign out_pipe_aux_q[0]           = inp_pipe_aux_q[NUM_INP_REGS];
  assign out_pipe_valid_q[0]         = inp_pipe_valid_q[NUM_INP_REGS];
  // Input stage: Propagate pipeline ready signal to inside pipe
  assign inp_pipe_ready[NUM_INP_REGS] = out_pipe_ready[0];
  // Generate the register stages
  for (genvar i = 0; i < NUM_OUT_REGS; i++) begin : gen_output_pipeline
    // Internal register enable for this stage
    logic reg_ena;
    // Determine the ready signal of the current stage - advance the pipeline:
    // 1. if the next stage is ready for our data
    // 2. if the next stage only holds a bubble (not valid) -> we can pop it
    assign out_pipe_ready[i] = out_pipe_ready[i+1] | ~out_pipe_valid_q[i+1];
    // Valid: enabled by ready signal, synchronous clear with the flush signal
    `FFLARNC(out_pipe_valid_q[i+1], out_pipe_valid_q[i], out_pipe_ready[i], flush_i, 1'b0, clk_i, rst_ni)
    // Enable register if pipleine ready and a valid data item is present
    assign reg_ena = (out_pipe_ready[i] & out_pipe_valid_q[i]) | reg_ena_i[NUM_INP_REGS + i];
    // Generate the pipeline registers within the stages, use enable-registers
    `FFL(out_pipe_result_q[i+1],        out_pipe_result_q[i],        reg_ena, '0)
    `FFL(out_pipe_status_q[i+1],        out_pipe_status_q[i],        reg_ena, '0)
    `FFL(out_pipe_extension_bit_q[i+1], out_pipe_extension_bit_q[i], reg_ena, '0)
    `FFL(out_pipe_class_mask_q[i+1],    out_pipe_class_mask_q[i],    reg_ena, fpnew_pkg::QNAN)
    `FFL(out_pipe_is_class_q[i+1],      out_pipe_is_class_q[i],      reg_ena, '0)
    `FFL(out_pipe_tag_q[i+1],           out_pipe_tag_q[i],           reg_ena, TagType'('0))
    `FFL(out_pipe_mask_q[i+1],          out_pipe_mask_q[i],          reg_ena, '0)
    `FFL(out_pipe_aux_q[i+1],           out_pipe_aux_q[i],           reg_ena, AuxType'('0))
  end
  // Output stage: Ready travels backwards from output side, driven by downstream circuitry
  assign out_pipe_ready[NUM_OUT_REGS] = out_ready_i;
  // Output stage: assign module outputs
  assign result_o        = out_pipe_result_q[NUM_OUT_REGS];
  assign status_o        = out_pipe_status_q[NUM_OUT_REGS];
  assign extension_bit_o = out_pipe_extension_bit_q[NUM_OUT_REGS];
  assign class_mask_o    = out_pipe_class_mask_q[NUM_OUT_REGS];
  assign is_class_o      = out_pipe_is_class_q[NUM_OUT_REGS];
  assign tag_o           = out_pipe_tag_q[NUM_OUT_REGS];
  assign mask_o          = out_pipe_mask_q[NUM_OUT_REGS];
  assign aux_o           = out_pipe_aux_q[NUM_OUT_REGS];
  assign out_valid_o     = out_pipe_valid_q[NUM_OUT_REGS];
  assign busy_o          = (| {inp_pipe_valid_q, out_pipe_valid_q});
endmodule
// Copyright 2019 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// SPDX-License-Identifier: SHL-0.51

// Author: Stefan Mach <smach@iis.ee.ethz.ch>

module fpnew_opgroup_fmt_slice #(
  parameter fpnew_pkg::opgroup_e     OpGroup       = fpnew_pkg::ADDMUL,
  parameter fpnew_pkg::fp_format_e   FpFormat      = fpnew_pkg::fp_format_e'(0),
  // FPU configuration
  parameter int unsigned             Width         = 32,
  parameter logic                    EnableVectors = 1'b1,
  parameter int unsigned             NumPipeRegs   = 0,
  parameter fpnew_pkg::pipe_config_t PipeConfig    = fpnew_pkg::BEFORE,
  parameter logic                    ExtRegEna     = 1'b0,
  parameter type                     TagType       = logic,
  parameter int unsigned             TrueSIMDClass = 0,
  // Do not change
  localparam int unsigned NUM_OPERANDS = fpnew_pkg::num_operands(OpGroup),
  localparam int unsigned NUM_LANES    = fpnew_pkg::num_lanes(Width, FpFormat, EnableVectors),
  localparam type         MaskType     = logic [NUM_LANES-1:0],
  localparam int unsigned ExtRegEnaWidth = NumPipeRegs == 0 ? 1 : NumPipeRegs
) (
  input logic                               clk_i,
  input logic                               rst_ni,
  // Input signals
  input logic [NUM_OPERANDS-1:0][Width-1:0] operands_i,
  input logic [NUM_OPERANDS-1:0]            is_boxed_i,
  input fpnew_pkg::roundmode_e              rnd_mode_i,
  input fpnew_pkg::operation_e              op_i,
  input logic                               op_mod_i,
  input logic                               vectorial_op_i,
  input TagType                             tag_i,
  input MaskType                            simd_mask_i,
  // Input Handshake
  input  logic                              in_valid_i,
  output logic                              in_ready_o,
  input  logic                              flush_i,
  // Output signals
  output logic [Width-1:0]                  result_o,
  output fpnew_pkg::status_t                status_o,
  output logic                              extension_bit_o,
  output TagType                            tag_o,
  // Output handshake
  output logic                              out_valid_o,
  input  logic                              out_ready_i,
  // Indication of valid data in flight
  output logic                              busy_o,
  // External register enable override
  input  logic [ExtRegEnaWidth-1:0]         reg_ena_i
);

  localparam int unsigned FP_WIDTH  = fpnew_pkg::fp_width(FpFormat);
  localparam int unsigned SIMD_WIDTH = unsigned'(Width/NUM_LANES);


  logic [NUM_LANES-1:0] lane_in_ready, lane_out_valid; // Handshake signals for the lanes
  logic                 vectorial_op;

  logic [NUM_LANES*FP_WIDTH-1:0] slice_result;
  logic [Width-1:0]              slice_regular_result, slice_class_result, slice_vec_class_result;

  fpnew_pkg::status_t    [NUM_LANES-1:0] lane_status;
  logic                  [NUM_LANES-1:0] lane_ext_bit; // only the first one is actually used
  fpnew_pkg::classmask_e [NUM_LANES-1:0] lane_class_mask;
  TagType                [NUM_LANES-1:0] lane_tags; // only the first one is actually used
  logic                  [NUM_LANES-1:0] lane_masks;
  logic                  [NUM_LANES-1:0] lane_vectorial, lane_busy, lane_is_class; // dito

  logic result_is_vector, result_is_class;

  // -----------
  // Input Side
  // -----------
  assign in_ready_o   = lane_in_ready[0]; // Upstream ready is given by first lane
  assign vectorial_op = vectorial_op_i & EnableVectors; // only do vectorial stuff if enabled

  // ---------------
  // Generate Lanes
  // ---------------
  for (genvar lane = 0; lane < int'(NUM_LANES); lane++) begin : gen_num_lanes
    logic [FP_WIDTH-1:0] local_result; // lane-local results
    logic                local_sign;

    // Generate instances only if needed, lane 0 always generated
    if ((lane == 0) || EnableVectors) begin : active_lane
      logic in_valid, out_valid, out_ready; // lane-local handshake

      logic [NUM_OPERANDS-1:0][FP_WIDTH-1:0] local_operands; // lane-local operands
      logic [FP_WIDTH-1:0]                   op_result;      // lane-local results
      fpnew_pkg::status_t                    op_status;

      assign in_valid = in_valid_i & ((lane == 0) | vectorial_op); // upper lanes only for vectors
      // Slice out the operands for this lane
      always_comb begin : prepare_input
        for (int i = 0; i < int'(NUM_OPERANDS); i++) begin
          local_operands[i] = operands_i[i][(unsigned'(lane)+1)*FP_WIDTH-1:unsigned'(lane)*FP_WIDTH];
        end
      end

      // Instantiate the operation from the selected opgroup
      if (OpGroup == fpnew_pkg::ADDMUL) begin : lane_instance
        fpnew_fma #(
          .FpFormat    ( FpFormat    ),
          .NumPipeRegs ( NumPipeRegs ),
          .PipeConfig  ( PipeConfig  ),
          .TagType     ( TagType     ),
          .AuxType     ( logic       )
        ) i_fma (
          .clk_i,
          .rst_ni,
          .operands_i      ( local_operands               ),
          .is_boxed_i      ( is_boxed_i[NUM_OPERANDS-1:0] ),
          .rnd_mode_i,
          .op_i,
          .op_mod_i,
          .tag_i,
          .mask_i          ( simd_mask_i[lane]    ),
          .aux_i           ( vectorial_op         ), // Remember whether operation was vectorial
          .in_valid_i      ( in_valid             ),
          .in_ready_o      ( lane_in_ready[lane]  ),
          .flush_i,
          .result_o        ( op_result            ),
          .status_o        ( op_status            ),
          .extension_bit_o ( lane_ext_bit[lane]   ),
          .tag_o           ( lane_tags[lane]      ),
          .mask_o          ( lane_masks[lane]     ),
          .aux_o           ( lane_vectorial[lane] ),
          .out_valid_o     ( out_valid            ),
          .out_ready_i     ( out_ready            ),
          .busy_o          ( lane_busy[lane]      ),
          .reg_ena_i
        );
        assign lane_is_class[lane]   = 1'b0;
        assign lane_class_mask[lane] = fpnew_pkg::NEGINF;
      end else if (OpGroup == fpnew_pkg::DIVSQRT) begin : lane_instance
        // fpnew_divsqrt #(
        //   .FpFormat   (FpFormat),
        //   .NumPipeRegs(NumPipeRegs),
        //   .PipeConfig (PipeConfig),
        //   .TagType    (TagType),
        //   .AuxType    (logic)
        // ) i_divsqrt (
        //   .clk_i,
        //   .rst_ni,
        //   .operands_i      ( local_operands               ),
        //   .is_boxed_i      ( is_boxed_i[NUM_OPERANDS-1:0] ),
        //   .rnd_mode_i,
        //   .op_i,
        //   .op_mod_i,
        //   .tag_i,
        //   .aux_i           ( vectorial_op         ), // Remember whether operation was vectorial
        //   .in_valid_i      ( in_valid             ),
        //   .in_ready_o      ( lane_in_ready[lane]  ),
        //   .flush_i,
        //   .result_o        ( op_result            ),
        //   .status_o        ( op_status            ),
        //   .extension_bit_o ( lane_ext_bit[lane]   ),
        //   .tag_o           ( lane_tags[lane]      ),
        //   .aux_o           ( lane_vectorial[lane] ),
        //   .out_valid_o     ( out_valid            ),
        //   .out_ready_i     ( out_ready            ),
        //   .busy_o          ( lane_busy[lane]      ),
        //   .reg_ena_i
        // );
        // assign lane_is_class[lane] = 1'b0;
      end else if (OpGroup == fpnew_pkg::NONCOMP) begin : lane_instance
        fpnew_noncomp #(
          .FpFormat   (FpFormat),
          .NumPipeRegs(NumPipeRegs),
          .PipeConfig (PipeConfig),
          .TagType    (TagType),
          .AuxType    (logic)
        ) i_noncomp (
          .clk_i,
          .rst_ni,
          .operands_i      ( local_operands               ),
          .is_boxed_i      ( is_boxed_i[NUM_OPERANDS-1:0] ),
          .rnd_mode_i,
          .op_i,
          .op_mod_i,
          .tag_i,
          .mask_i          ( simd_mask_i[lane]     ),
          .aux_i           ( vectorial_op          ), // Remember whether operation was vectorial
          .in_valid_i      ( in_valid              ),
          .in_ready_o      ( lane_in_ready[lane]   ),
          .flush_i,
          .result_o        ( op_result             ),
          .status_o        ( op_status             ),
          .extension_bit_o ( lane_ext_bit[lane]    ),
          .class_mask_o    ( lane_class_mask[lane] ),
          .is_class_o      ( lane_is_class[lane]   ),
          .tag_o           ( lane_tags[lane]       ),
          .mask_o          ( lane_masks[lane]      ),
          .aux_o           ( lane_vectorial[lane]  ),
          .out_valid_o     ( out_valid             ),
          .out_ready_i     ( out_ready             ),
          .busy_o          ( lane_busy[lane]       ),
          .reg_ena_i
        );
      end // ADD OTHER OPTIONS HERE

      // Handshakes are only done if the lane is actually used
      assign out_ready            = out_ready_i & ((lane == 0) | result_is_vector);
      assign lane_out_valid[lane] = out_valid   & ((lane == 0) | result_is_vector);

      // Properly NaN-box or sign-extend the slice result if not in use
      assign local_result      = (lane_out_valid[lane] | ExtRegEna) ? op_result : '{default: lane_ext_bit[0]};
      assign lane_status[lane] = (lane_out_valid[lane] | ExtRegEna) ? op_status : '0;

    // Otherwise generate constant sign-extension
    end else begin
      assign lane_out_valid[lane] = 1'b0; // unused lane
      assign lane_in_ready[lane]  = 1'b0; // unused lane
      assign local_result         = '{default: lane_ext_bit[0]}; // sign-extend/nan box
      assign lane_status[lane]    = '0;
      assign lane_busy[lane]      = 1'b0;
      assign lane_is_class[lane]  = 1'b0;
    end

    // Insert lane result into slice result
    assign slice_result[(unsigned'(lane)+1)*FP_WIDTH-1:unsigned'(lane)*FP_WIDTH] = local_result;

    // Create Classification results
    if (TrueSIMDClass && SIMD_WIDTH >= 10) begin : vectorial_true_class // true vectorial class blocks are 10bits in size
      assign slice_vec_class_result[lane*SIMD_WIDTH +: 10] = lane_class_mask[lane];
      assign slice_vec_class_result[(lane+1)*SIMD_WIDTH-1 -: SIMD_WIDTH-10] = '0;
    end else if ((lane+1)*8 <= Width) begin : vectorial_class // vectorial class blocks are 8bits in size
      assign local_sign = (lane_class_mask[lane] == fpnew_pkg::NEGINF ||
                           lane_class_mask[lane] == fpnew_pkg::NEGNORM ||
                           lane_class_mask[lane] == fpnew_pkg::NEGSUBNORM ||
                           lane_class_mask[lane] == fpnew_pkg::NEGZERO);
      // Write the current block segment
      assign slice_vec_class_result[(lane+1)*8-1:lane*8] = {
        local_sign,  // BIT 7
        ~local_sign, // BIT 6
        lane_class_mask[lane] == fpnew_pkg::QNAN, // BIT 5
        lane_class_mask[lane] == fpnew_pkg::SNAN, // BIT 4
        lane_class_mask[lane] == fpnew_pkg::POSZERO
            || lane_class_mask[lane] == fpnew_pkg::NEGZERO, // BIT 3
        lane_class_mask[lane] == fpnew_pkg::POSSUBNORM
            || lane_class_mask[lane] == fpnew_pkg::NEGSUBNORM, // BIT 2
        lane_class_mask[lane] == fpnew_pkg::POSNORM
            || lane_class_mask[lane] == fpnew_pkg::NEGNORM, // BIT 1
        lane_class_mask[lane] == fpnew_pkg::POSINF
            || lane_class_mask[lane] == fpnew_pkg::NEGINF // BIT 0
      };
    end
  end

  // ------------
  // Output Side
  // ------------
  assign result_is_vector = lane_vectorial[0];
  assign result_is_class  = lane_is_class[0];

  assign slice_regular_result = $signed({extension_bit_o, slice_result});

  localparam int unsigned CLASS_VEC_BITS = (NUM_LANES*8 > Width) ? 8 * (Width / 8) : NUM_LANES*8;

  // Pad out unused vec_class bits if each classify result is on 8 bits
  if (!(TrueSIMDClass && SIMD_WIDTH >= 10)) begin
    if (CLASS_VEC_BITS < Width) begin : pad_vectorial_class
      assign slice_vec_class_result[Width-1:CLASS_VEC_BITS] = '0;
    end
  end

  // localparam logic [Width-1:0] CLASS_VEC_MASK = 2**CLASS_VEC_BITS - 1;

  assign slice_class_result = result_is_vector ? slice_vec_class_result : lane_class_mask[0];

  // Select the proper result
  assign result_o = result_is_class ? slice_class_result : slice_regular_result;

  assign extension_bit_o                              = lane_ext_bit[0]; // upper lanes unused
  assign tag_o                                        = lane_tags[0];    // upper lanes unused
  assign busy_o                                       = (| lane_busy);
  assign out_valid_o                                  = lane_out_valid[0]; // upper lanes unused


  // Collapse the lane status
  always_comb begin : output_processing
    // Collapse the status
    automatic fpnew_pkg::status_t temp_status;
    temp_status = '0;
    for (int i = 0; i < int'(NUM_LANES); i++)
      temp_status |= lane_status[i] & {5{lane_masks[i]}};
    status_o = temp_status;
  end
endmodule
// Copyright 2019 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// SPDX-License-Identifier: SHL-0.51

// Author: Stefan Mach <smach@iis.ee.ethz.ch>

// Copyright 2018 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Common register defines for RTL designs
`ifndef COMMON_CELLS_REGISTERS_SVH_
`define COMMON_CELLS_REGISTERS_SVH_

// Abridged Summary of available FF macros:
// `FF:      asynchronous active-low reset (implicit clock and reset)
// `FFAR:    asynchronous active-high reset
// `FFARN:   asynchronous active-low reset
// `FFSR:    synchronous active-high reset
// `FFSRN:   synchronous active-low reset
// `FFNR:    without reset
// `FFL:     load-enable and asynchronous active-low reset (implicit clock and reset)
// `FFLAR:   load-enable and asynchronous active-high reset
// `FFLARN:  load-enable and asynchronous active-low reset
// `FFLARNC: load-enable and asynchronous active-low reset and synchronous active-high clear
// `FFLSR:   load-enable and synchronous active-high reset
// `FFLSRN:  load-enable and synchronous active-low reset
// `FFLNR:   load-enable without reset


// Flip-Flop with asynchronous active-low reset (implicit clock and reset)
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// Implicit:
// clk_i: clock input
// rst_ni: reset input (asynchronous, active low)
`define FF(__q, __d, __reset_value)                  \
  always_ff @(posedge clk_i or negedge rst_ni) begin \
    if (!rst_ni) begin                               \
      __q <= (__reset_value);                        \
    end else begin                                   \
      __q <= (__d);                                  \
    end                                              \
  end

// Flip-Flop with asynchronous active-high reset
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __arst: asynchronous reset
`define FFAR(__q, __d, __reset_value, __clk, __arst)     \
  always_ff @(posedge (__clk) or posedge (__arst)) begin \
    if (__arst) begin                                    \
      __q <= (__reset_value);                            \
    end else begin                                       \
      __q <= (__d);                                      \
    end                                                  \
  end

// Flip-Flop with asynchronous active-low reset
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __arst_n: asynchronous reset
`define FFARN(__q, __d, __reset_value, __clk, __arst_n)    \
  always_ff @(posedge (__clk) or negedge (__arst_n)) begin \
    if (!__arst_n) begin                                   \
      __q <= (__reset_value);                              \
    end else begin                                         \
      __q <= (__d);                                        \
    end                                                    \
  end

// Flip-Flop with synchronous active-high reset
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __reset_clk: reset input
`define FFSR(__q, __d, __reset_value, __clk, __reset_clk) \
  `ifndef VERILATOR                       \
  /``* synopsys sync_set_reset `"__reset_clk`" *``/       \
    `endif                        \
  always_ff @(posedge (__clk)) begin                      \
    __q <= (__reset_clk) ? (__reset_value) : (__d);       \
  end

// Flip-Flop with synchronous active-low reset
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __reset_n_clk: reset input
`define FFSRN(__q, __d, __reset_value, __clk, __reset_n_clk) \
    `ifndef VERILATOR                       \
  /``* synopsys sync_set_reset `"__reset_n_clk`" *``/        \
    `endif                        \
  always_ff @(posedge (__clk)) begin                         \
    __q <= (!__reset_n_clk) ? (__reset_value) : (__d);       \
  end

// Always-enable Flip-Flop without reset
// __q: Q output of FF
// __d: D input of FF
// __clk: clock input
`define FFNR(__q, __d, __clk)        \
  always_ff @(posedge (__clk)) begin \
    __q <= (__d);                    \
  end

// Flip-Flop with load-enable and asynchronous active-low reset (implicit clock and reset)
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __reset_value: value assigned upon reset
// Implicit:
// clk_i: clock input
// rst_ni: reset input (asynchronous, active low)
`define FFL(__q, __d, __load, __reset_value)         \
  always_ff @(posedge clk_i or negedge rst_ni) begin \
    if (!rst_ni) begin                               \
      __q <= (__reset_value);                        \
    end else begin                                   \
      __q <= (__load) ? (__d) : (__q);               \
    end                                              \
  end

// Flip-Flop with load-enable and asynchronous active-high reset
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __arst: asynchronous reset
`define FFLAR(__q, __d, __load, __reset_value, __clk, __arst) \
  always_ff @(posedge (__clk) or posedge (__arst)) begin      \
    if (__arst) begin                                         \
      __q <= (__reset_value);                                 \
    end else begin                                            \
      __q <= (__load) ? (__d) : (__q);                        \
    end                                                       \
  end

// Flip-Flop with load-enable and asynchronous active-low reset
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __arst_n: asynchronous reset
`define FFLARN(__q, __d, __load, __reset_value, __clk, __arst_n) \
  always_ff @(posedge (__clk) or negedge (__arst_n)) begin       \
    if (!__arst_n) begin                                         \
      __q <= (__reset_value);                                    \
    end else begin                                               \
      __q <= (__load) ? (__d) : (__q);                           \
    end                                                          \
  end

// Flip-Flop with load-enable and synchronous active-high reset
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __reset_clk: reset input
`define FFLSR(__q, __d, __load, __reset_value, __clk, __reset_clk)       \
    `ifndef VERILATOR                       \
  /``* synopsys sync_set_reset `"__reset_clk`" *``/                      \
    `endif                        \
  always_ff @(posedge (__clk)) begin                                     \
    __q <= (__reset_clk) ? (__reset_value) : ((__load) ? (__d) : (__q)); \
  end

// Flip-Flop with load-enable and synchronous active-low reset
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __reset_n_clk: reset input
`define FFLSRN(__q, __d, __load, __reset_value, __clk, __reset_n_clk)       \
    `ifndef VERILATOR                       \
  /``* synopsys sync_set_reset `"__reset_n_clk`" *``/                       \
    `endif                        \
  always_ff @(posedge (__clk)) begin                                        \
    __q <= (!__reset_n_clk) ? (__reset_value) : ((__load) ? (__d) : (__q)); \
  end

// Flip-Flop with load-enable and asynchronous active-low reset and synchronous clear
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __clear: assign reset value into FF
// __reset_value: value assigned upon reset
// __clk: clock input
// __arst_n: asynchronous reset
`define FFLARNC(__q, __d, __load, __clear, __reset_value, __clk, __arst_n) \
    `ifndef VERILATOR                       \
  /``* synopsys sync_set_reset `"__clear`" *``/                       \
    `endif                        \
  always_ff @(posedge (__clk) or negedge (__arst_n)) begin                 \
    if (!__arst_n) begin                                                   \
      __q <= (__reset_value);                                              \
    end else begin                                                         \
      __q <= (__clear) ? (__reset_value) : (__load) ? (__d) : (__q);       \
    end                                                                    \
  end

// Load-enable Flip-Flop without reset
// __q: Q output of FF
// __d: D input of FF
// __load: load d value into FF
// __clk: clock input
`define FFLNR(__q, __d, __load, __clk) \
  always_ff @(posedge (__clk)) begin   \
    __q <= (__load) ? (__d) : (__q);   \
  end

`endif

module fpnew_opgroup_multifmt_slice #(
  parameter fpnew_pkg::opgroup_e     OpGroup       = fpnew_pkg::CONV,
  parameter int unsigned             Width         = 64,
  // FPU configuration
  parameter fpnew_pkg::fmt_logic_t   FpFmtConfig   = '1,
  parameter fpnew_pkg::ifmt_logic_t  IntFmtConfig  = '1,
  parameter logic                    EnableVectors = 1'b1,
  parameter logic                    PulpDivsqrt   = 1'b1,
  parameter int unsigned             NumPipeRegs   = 0,
  parameter fpnew_pkg::pipe_config_t PipeConfig    = fpnew_pkg::BEFORE,
  parameter logic                    ExtRegEna     = 1'b0,
  parameter type                     TagType       = logic,
  // Do not change
  localparam int unsigned NUM_OPERANDS = fpnew_pkg::num_operands(OpGroup),
  localparam int unsigned NUM_FORMATS  = fpnew_pkg::NUM_FP_FORMATS,
  localparam int unsigned NUM_SIMD_LANES = fpnew_pkg::max_num_lanes(Width, FpFmtConfig, EnableVectors),
  localparam type         MaskType     = logic [NUM_SIMD_LANES-1:0],
  localparam int unsigned ExtRegEnaWidth = NumPipeRegs == 0 ? 1 : NumPipeRegs
) (
  input logic                                     clk_i,
  input logic                                     rst_ni,
  // Input signals
  input logic [NUM_OPERANDS-1:0][Width-1:0]       operands_i,
  input logic [NUM_FORMATS-1:0][NUM_OPERANDS-1:0] is_boxed_i,
  input fpnew_pkg::roundmode_e                    rnd_mode_i,
  input fpnew_pkg::operation_e                    op_i,
  input logic                                     op_mod_i,
  input fpnew_pkg::fp_format_e                    src_fmt_i,
  input fpnew_pkg::fp_format_e                    dst_fmt_i,
  input fpnew_pkg::int_format_e                   int_fmt_i,
  input logic                                     vectorial_op_i,
  input TagType                                   tag_i,
  input MaskType                                  simd_mask_i,
  // Input Handshake
  input  logic                                    in_valid_i,
  output logic                                    in_ready_o,
  input  logic                                    flush_i,
  // Output signals
  output logic [Width-1:0]                        result_o,
  output fpnew_pkg::status_t                      status_o,
  output logic                                    extension_bit_o,
  output TagType                                  tag_o,
  // Output handshake
  output logic                                    out_valid_o,
  input  logic                                    out_ready_i,
  // Indication of valid data in flight
  output logic                                    busy_o,
  // External register enable override
  input  logic [ExtRegEnaWidth-1:0]               reg_ena_i
);

  if ((OpGroup == fpnew_pkg::DIVSQRT) && !PulpDivsqrt &&
      !((FpFmtConfig[0] == 1) && (FpFmtConfig[1:NUM_FORMATS-1] == '0))) begin
    initial $fatal(1, "T-Head-based DivSqrt unit supported only in FP32-only configurations. \
Set PulpDivsqrt to 1 not to use the PULP DivSqrt unit \
or set Features.FpFmtMask to support only FP32");
  end

  localparam int unsigned MAX_FP_WIDTH   = fpnew_pkg::max_fp_width(FpFmtConfig);
  localparam int unsigned MAX_INT_WIDTH  = fpnew_pkg::max_int_width(IntFmtConfig);
  localparam int unsigned NUM_LANES = fpnew_pkg::max_num_lanes(Width, FpFmtConfig, 1'b1);
  localparam int unsigned NUM_INT_FORMATS = fpnew_pkg::NUM_INT_FORMATS;
  // We will send the format information along with the data
  localparam int unsigned FMT_BITS =
      fpnew_pkg::maximum($clog2(NUM_FORMATS), $clog2(NUM_INT_FORMATS));
  localparam int unsigned AUX_BITS = FMT_BITS + 2; // also add vectorial and integer flags

  logic [NUM_LANES-1:0] lane_in_ready, lane_out_valid, divsqrt_done, divsqrt_ready; // Handshake signals for the lanes
  logic                 vectorial_op;
  logic [FMT_BITS-1:0]  dst_fmt; // destination format to pass along with operation
  logic [AUX_BITS-1:0]  aux_data;

  // additional flags for CONV
  logic       dst_fmt_is_int, dst_is_cpk;
  logic [1:0] dst_vec_op; // info for vectorial results (for packing)
  logic [2:0] target_aux_d;
  logic       is_up_cast, is_down_cast;

  logic [NUM_FORMATS-1:0][Width-1:0]     fmt_slice_result;
  logic [NUM_INT_FORMATS-1:0][Width-1:0] ifmt_slice_result;

  logic [Width-1:0] conv_target_d, conv_target_q; // vectorial conversions update a register

  fpnew_pkg::status_t [NUM_LANES-1:0]   lane_status;
  logic   [NUM_LANES-1:0]               lane_ext_bit; // only the first one is actually used
  TagType [NUM_LANES-1:0]               lane_tags; // only the first one is actually used
  logic   [NUM_LANES-1:0]               lane_masks;
  logic   [NUM_LANES-1:0][AUX_BITS-1:0] lane_aux; // only the first one is actually used
  logic   [NUM_LANES-1:0]               lane_busy; // dito

  logic                result_is_vector;
  logic [FMT_BITS-1:0] result_fmt;
  logic                result_fmt_is_int, result_is_cpk;
  logic [1:0]          result_vec_op; // info for vectorial results (for packing)

  logic simd_synch_rdy, simd_synch_done;

  // -----------
  // Input Side
  // -----------
  assign in_ready_o   = lane_in_ready[0]; // Upstream ready is given by first lane
  assign vectorial_op = vectorial_op_i & EnableVectors; // only do vectorial stuff if enabled

  // Cast-and-Pack ops are encoded in operation and modifier
  assign dst_fmt_is_int = (OpGroup == fpnew_pkg::CONV) & (op_i == fpnew_pkg::F2I);
  assign dst_is_cpk     = (OpGroup == fpnew_pkg::CONV) & (op_i == fpnew_pkg::CPKAB ||
                                                          op_i == fpnew_pkg::CPKCD);
  assign dst_vec_op     = (OpGroup == fpnew_pkg::CONV) & {(op_i == fpnew_pkg::CPKCD), op_mod_i};

  assign is_up_cast   = (fpnew_pkg::fp_width(dst_fmt_i) > fpnew_pkg::fp_width(src_fmt_i));
  assign is_down_cast = (fpnew_pkg::fp_width(dst_fmt_i) < fpnew_pkg::fp_width(src_fmt_i));

  // The destination format is the int format for F2I casts
  assign dst_fmt    = dst_fmt_is_int ? int_fmt_i : dst_fmt_i;

  // The data sent along consists of the vectorial flag and format bits
  assign aux_data      = {dst_fmt_is_int, vectorial_op, dst_fmt};
  assign target_aux_d  = {dst_vec_op, dst_is_cpk};

  // CONV passes one operand for assembly after the unit: opC for cpk, opB for others
  if (OpGroup == fpnew_pkg::CONV) begin : conv_target
    assign conv_target_d = dst_is_cpk ? operands_i[2] : operands_i[1];
  end else begin : not_conv_target
    assign conv_target_d = '0;
  end

  // For 2-operand units, prepare boxing info
  logic [NUM_FORMATS-1:0]      is_boxed_1op;
  logic [NUM_FORMATS-1:0][1:0] is_boxed_2op;

  always_comb begin : boxed_2op
    for (int fmt = 0; fmt < NUM_FORMATS; fmt++) begin
      is_boxed_1op[fmt] = is_boxed_i[fmt][0];
      is_boxed_2op[fmt] = is_boxed_i[fmt][1:0];
    end
  end

  // ---------------
  // Generate Lanes
  // ---------------
  for (genvar lane = 0; lane < int'(NUM_LANES); lane++) begin : gen_num_lanes
    localparam int unsigned LANE = unsigned'(lane); // unsigned to please the linter
    // Get a mask of active formats for this lane
    localparam fpnew_pkg::fmt_logic_t ACTIVE_FORMATS =
        fpnew_pkg::get_lane_formats(Width, FpFmtConfig, LANE);
    localparam fpnew_pkg::ifmt_logic_t ACTIVE_INT_FORMATS =
        fpnew_pkg::get_lane_int_formats(Width, FpFmtConfig, IntFmtConfig, LANE);
    localparam int unsigned MAX_WIDTH = fpnew_pkg::max_fp_width(ACTIVE_FORMATS);

    // Cast-specific parameters
    localparam fpnew_pkg::fmt_logic_t CONV_FORMATS =
        fpnew_pkg::get_conv_lane_formats(Width, FpFmtConfig, LANE);
    localparam fpnew_pkg::ifmt_logic_t CONV_INT_FORMATS =
        fpnew_pkg::get_conv_lane_int_formats(Width, FpFmtConfig, IntFmtConfig, LANE);
    localparam int unsigned CONV_WIDTH = fpnew_pkg::max_fp_width(CONV_FORMATS);

    // Lane parameters from Opgroup
    localparam fpnew_pkg::fmt_logic_t LANE_FORMATS = (OpGroup == fpnew_pkg::CONV)
                                                     ? CONV_FORMATS : ACTIVE_FORMATS;
    localparam int unsigned LANE_WIDTH = (OpGroup == fpnew_pkg::CONV) ? CONV_WIDTH : MAX_WIDTH;

    logic [LANE_WIDTH-1:0] local_result; // lane-local results

    // Generate instances only if needed, lane 0 always generated
    if ((lane == 0) || EnableVectors) begin : active_lane
      logic in_valid, out_valid, out_ready; // lane-local handshake

      logic [NUM_OPERANDS-1:0][LANE_WIDTH-1:0] local_operands;  // lane-local oprands
      logic [LANE_WIDTH-1:0]                   op_result;       // lane-local results
      fpnew_pkg::status_t                      op_status;

      assign in_valid = in_valid_i & ((lane == 0) | vectorial_op); // upper lanes only for vectors

      // Slice out the operands for this lane, upper bits are ignored in the unit
      always_comb begin : prepare_input
        for (int unsigned i = 0; i < NUM_OPERANDS; i++) begin
          if (i == 2) begin
            local_operands[i] = operands_i[i] >> LANE*fpnew_pkg::fp_width(dst_fmt_i);
          end else begin
            local_operands[i] = operands_i[i] >> LANE*fpnew_pkg::fp_width(src_fmt_i);
          end
        end

        // override operand 0 for some conversions
        if (OpGroup == fpnew_pkg::CONV) begin
          // Source is an integer
          if (op_i == fpnew_pkg::I2F) begin
            local_operands[0] = operands_i[0] >> LANE*fpnew_pkg::int_width(int_fmt_i);
          // vectorial F2F up casts
          end else if (op_i == fpnew_pkg::F2F) begin
            if (vectorial_op && op_mod_i && is_up_cast) begin // up cast with upper half
              local_operands[0] = operands_i[0] >> LANE*fpnew_pkg::fp_width(src_fmt_i) +
                                                   MAX_FP_WIDTH/2;
            end
          // CPK
          end else if (dst_is_cpk) begin
            if (lane == 1) begin
              local_operands[0] = operands_i[1][LANE_WIDTH-1:0]; // using opB as second argument
            end
          end
        end
      end

      // Instantiate the operation from the selected opgroup
      if (OpGroup == fpnew_pkg::ADDMUL) begin : lane_instance
        fpnew_fma_multi #(
          .FpFmtConfig ( LANE_FORMATS         ),
          .NumPipeRegs ( NumPipeRegs          ),
          .PipeConfig  ( PipeConfig           ),
          .TagType     ( TagType              ),
          .AuxType     ( logic [AUX_BITS-1:0] )
        ) i_fpnew_fma_multi (
          .clk_i,
          .rst_ni,
          .operands_i      ( local_operands  ),
          .is_boxed_i,
          .rnd_mode_i,
          .op_i,
          .op_mod_i,
          .src_fmt_i,
          .dst_fmt_i,
          .tag_i,
          .mask_i          ( simd_mask_i[lane]   ),
          .aux_i           ( aux_data            ),
          .in_valid_i      ( in_valid            ),
          .in_ready_o      ( lane_in_ready[lane] ),
          .flush_i,
          .result_o        ( op_result           ),
          .status_o        ( op_status           ),
          .extension_bit_o ( lane_ext_bit[lane]  ),
          .tag_o           ( lane_tags[lane]     ),
          .mask_o          ( lane_masks[lane]    ),
          .aux_o           ( lane_aux[lane]      ),
          .out_valid_o     ( out_valid           ),
          .out_ready_i     ( out_ready           ),
          .busy_o          ( lane_busy[lane]     ),
          .reg_ena_i
        );

      end else if (OpGroup == fpnew_pkg::DIVSQRT) begin : lane_instance
        if (!PulpDivsqrt && LANE_FORMATS[0] && (LANE_FORMATS[1:fpnew_pkg::NUM_FP_FORMATS-1] == '0)) begin
          // The T-head-based DivSqrt unit is supported only in FP32-only configurations
          fpnew_divsqrt_th_32 #(
            .NumPipeRegs ( NumPipeRegs          ),
            .PipeConfig  ( PipeConfig           ),
            .TagType     ( TagType              ),
            .AuxType     ( logic [AUX_BITS-1:0] )
          ) i_fpnew_divsqrt_multi_th (
            .clk_i,
            .rst_ni,
            .operands_i      ( local_operands[1:0] ), // 2 operands
            .is_boxed_i      ( is_boxed_2op        ), // 2 operands
            .rnd_mode_i,
            .op_i,
            .tag_i,
            .mask_i          ( simd_mask_i[lane]   ),
            .aux_i           ( aux_data            ),
            .in_valid_i      ( in_valid            ),
            .in_ready_o      ( lane_in_ready[lane] ),
            .flush_i,
            .result_o        ( op_result           ),
            .status_o        ( op_status           ),
            .extension_bit_o ( lane_ext_bit[lane]  ),
            .tag_o           ( lane_tags[lane]     ),
            .mask_o          ( lane_masks[lane]    ),
            .aux_o           ( lane_aux[lane]      ),
            .out_valid_o     ( out_valid           ),
            .out_ready_i     ( out_ready           ),
            .busy_o          ( lane_busy[lane]     ),
            .reg_ena_i
          );
        end else begin
          fpnew_divsqrt_multi #(
            .FpFmtConfig ( LANE_FORMATS         ),
            .NumPipeRegs ( NumPipeRegs          ),
            .PipeConfig  ( PipeConfig           ),
            .TagType     ( TagType              ),
            .AuxType     ( logic [AUX_BITS-1:0] )
          ) i_fpnew_divsqrt_multi (
            .clk_i,
            .rst_ni,
            .operands_i       ( local_operands[1:0] ), // 2 operands
            .is_boxed_i       ( is_boxed_2op        ), // 2 operands
            .rnd_mode_i,
            .op_i,
            .dst_fmt_i,
            .tag_i,
            .mask_i           ( simd_mask_i[lane]   ),
            .aux_i            ( aux_data            ),
            .vectorial_op_i   ( vectorial_op        ),
            .in_valid_i       ( in_valid            ),
            .in_ready_o       ( lane_in_ready[lane] ),
            .divsqrt_done_o   ( divsqrt_done[lane]  ),
            .simd_synch_done_i( simd_synch_done     ),
            .divsqrt_ready_o  ( divsqrt_ready[lane] ),
            .simd_synch_rdy_i ( simd_synch_rdy      ),
            .flush_i,
            .result_o         ( op_result           ),
            .status_o         ( op_status           ),
            .extension_bit_o  ( lane_ext_bit[lane]  ),
            .tag_o            ( lane_tags[lane]     ),
            .mask_o           ( lane_masks[lane]    ),
            .aux_o            ( lane_aux[lane]      ),
            .out_valid_o      ( out_valid           ),
            .out_ready_i      ( out_ready           ),
            .busy_o           ( lane_busy[lane]     ),
            .reg_ena_i
          );
        end
      end else if (OpGroup == fpnew_pkg::NONCOMP) begin : lane_instance

      end else if (OpGroup == fpnew_pkg::CONV) begin : lane_instance
        fpnew_cast_multi #(
          .FpFmtConfig  ( LANE_FORMATS         ),
          .IntFmtConfig ( CONV_INT_FORMATS     ),
          .NumPipeRegs  ( NumPipeRegs          ),
          .PipeConfig   ( PipeConfig           ),
          .TagType      ( TagType              ),
          .AuxType      ( logic [AUX_BITS-1:0] )
        ) i_fpnew_cast_multi (
          .clk_i,
          .rst_ni,
          .operands_i      ( local_operands[0]   ),
          .is_boxed_i      ( is_boxed_1op        ),
          .rnd_mode_i,
          .op_i,
          .op_mod_i,
          .src_fmt_i,
          .dst_fmt_i,
          .int_fmt_i,
          .tag_i,
          .mask_i          ( simd_mask_i[lane]   ),
          .aux_i           ( aux_data            ),
          .in_valid_i      ( in_valid            ),
          .in_ready_o      ( lane_in_ready[lane] ),
          .flush_i,
          .result_o        ( op_result           ),
          .status_o        ( op_status           ),
          .extension_bit_o ( lane_ext_bit[lane]  ),
          .tag_o           ( lane_tags[lane]     ),
          .mask_o          ( lane_masks[lane]    ),
          .aux_o           ( lane_aux[lane]      ),
          .out_valid_o     ( out_valid           ),
          .out_ready_i     ( out_ready           ),
          .busy_o          ( lane_busy[lane]     ),
          .reg_ena_i
        );
      end // ADD OTHER OPTIONS HERE

      // Handshakes are only done if the lane is actually used
      assign out_ready            = out_ready_i & ((lane == 0) | result_is_vector);
      assign lane_out_valid[lane] = out_valid & ((lane == 0) | result_is_vector);

      // Properly NaN-box or sign-extend the slice result if not in use
      assign local_result      = (lane_out_valid[lane] | ExtRegEna) ? op_result : '{default: lane_ext_bit[0]};
      assign lane_status[lane] = (lane_out_valid[lane] | ExtRegEna) ? op_status : '0;

    // Otherwise generate constant sign-extension
    end else begin : inactive_lane
      assign lane_out_valid[lane] = 1'b0; // unused lane
      assign lane_in_ready[lane]  = 1'b0; // unused lane
      assign lane_aux[lane]       = 1'b0; // unused lane
      assign lane_masks[lane]     = 1'b1; // unused lane
      assign lane_tags[lane]      = 1'b0; // unused lane
      assign divsqrt_done[lane]   = 1'b0; // unused lane
      assign divsqrt_ready[lane]  = 1'b0; // unused lane
      assign lane_ext_bit[lane]   = 1'b1; // NaN-box unused lane
      assign local_result         = {(LANE_WIDTH){lane_ext_bit[0]}}; // sign-extend/nan box
      assign lane_status[lane]    = '0;
      assign lane_busy[lane]      = 1'b0;
    end

    // Generate result packing depending on float format
    for (genvar fmt = 0; fmt < NUM_FORMATS; fmt++) begin : pack_fp_result
      // Set up some constants
      localparam int unsigned FP_WIDTH = fpnew_pkg::fp_width(fpnew_pkg::fp_format_e'(fmt));
      // only for active formats within the lane
      if (ACTIVE_FORMATS[fmt]) begin
        assign fmt_slice_result[fmt][(LANE+1)*FP_WIDTH-1:LANE*FP_WIDTH] =
            local_result[FP_WIDTH-1:0];
      end else if ((LANE+1)*FP_WIDTH <= Width) begin
        assign fmt_slice_result[fmt][(LANE+1)*FP_WIDTH-1:LANE*FP_WIDTH] =
            '{default: lane_ext_bit[LANE]};
      end else if (LANE*FP_WIDTH < Width) begin
        assign fmt_slice_result[fmt][Width-1:LANE*FP_WIDTH] =
            '{default: lane_ext_bit[LANE]};
      end
    end

    // Generate result packing depending on integer format
    if (OpGroup == fpnew_pkg::CONV) begin : int_results_enabled
      for (genvar ifmt = 0; ifmt < NUM_INT_FORMATS; ifmt++) begin : pack_int_result
        // Set up some constants
        localparam int unsigned INT_WIDTH = fpnew_pkg::int_width(fpnew_pkg::int_format_e'(ifmt));
        if (ACTIVE_INT_FORMATS[ifmt]) begin
          assign ifmt_slice_result[ifmt][(LANE+1)*INT_WIDTH-1:LANE*INT_WIDTH] =
            local_result[INT_WIDTH-1:0];
        end else if ((LANE+1)*INT_WIDTH <= Width) begin
          assign ifmt_slice_result[ifmt][(LANE+1)*INT_WIDTH-1:LANE*INT_WIDTH] = '0;
        end else if (LANE*INT_WIDTH < Width) begin
          assign ifmt_slice_result[ifmt][Width-1:LANE*INT_WIDTH] = '0;
        end
      end
    end
  end

  // Extend slice result if needed
  for (genvar fmt = 0; fmt < NUM_FORMATS; fmt++) begin : extend_fp_result
    // Set up some constants
    localparam int unsigned FP_WIDTH = fpnew_pkg::fp_width(fpnew_pkg::fp_format_e'(fmt));
    if (NUM_LANES*FP_WIDTH < Width)
      assign fmt_slice_result[fmt][Width-1:NUM_LANES*FP_WIDTH] = '{default: lane_ext_bit[0]};
  end

  for (genvar ifmt = 0; ifmt < NUM_INT_FORMATS; ifmt++) begin : extend_or_mute_int_result
    // Mute int results if unused
    if (OpGroup != fpnew_pkg::CONV) begin : mute_int_result
      assign ifmt_slice_result[ifmt] = '0;

    // Extend slice result if needed
    end else begin : extend_int_result
      // Set up some constants
      localparam int unsigned INT_WIDTH = fpnew_pkg::int_width(fpnew_pkg::int_format_e'(ifmt));
      if (NUM_LANES*INT_WIDTH < Width)
        assign ifmt_slice_result[ifmt][Width-1:NUM_LANES*INT_WIDTH] = '0;
    end
  end

  // Bypass lanes with target operand for vectorial casts
  if (OpGroup == fpnew_pkg::CONV) begin : target_regs
    // Bypass pipeline signals, index i holds signal after i register stages
    logic [0:NumPipeRegs][Width-1:0] byp_pipe_target_q;
    logic [0:NumPipeRegs][2:0]       byp_pipe_aux_q;
    logic [0:NumPipeRegs]            byp_pipe_valid_q;
    // Ready signal is combinatorial for all stages
    logic [0:NumPipeRegs] byp_pipe_ready;

    // Input stage: First element of pipeline is taken from inputs
    assign byp_pipe_target_q[0]  = conv_target_d;
    assign byp_pipe_aux_q[0]     = target_aux_d;
    assign byp_pipe_valid_q[0]   = in_valid_i & vectorial_op;
    // Generate the register stages
    for (genvar i = 0; i < NumPipeRegs; i++) begin : gen_bypass_pipeline
      // Internal register enable for this stage
      logic reg_ena;
      // Determine the ready signal of the current stage - advance the pipeline:
      // 1. if the next stage is ready for our data
      // 2. if the next stage only holds a bubble (not valid) -> we can pop it
      assign byp_pipe_ready[i] = byp_pipe_ready[i+1] | ~byp_pipe_valid_q[i+1];
      // Valid: enabled by ready signal, synchronous clear with the flush signal
      `FFLARNC(byp_pipe_valid_q[i+1], byp_pipe_valid_q[i], byp_pipe_ready[i], flush_i, 1'b0, clk_i, rst_ni)
      // Enable register if pipleine ready and a valid data item is present
      assign reg_ena = (byp_pipe_ready[i] & byp_pipe_valid_q[i]) | reg_ena_i[i];
      // Generate the pipeline registers within the stages, use enable-registers
      `FFL(byp_pipe_target_q[i+1],  byp_pipe_target_q[i],  reg_ena, '0)
      `FFL(byp_pipe_aux_q[i+1],     byp_pipe_aux_q[i],     reg_ena, '0)
    end
    // Output stage: Ready travels backwards from output side, driven by downstream circuitry
    assign byp_pipe_ready[NumPipeRegs] = out_ready_i & result_is_vector;
    // Output stage: assign module outputs
    assign conv_target_q = byp_pipe_target_q[NumPipeRegs];

    // decode the aux data
    assign {result_vec_op, result_is_cpk} = byp_pipe_aux_q[NumPipeRegs];
  end else begin : no_conv
    assign {result_vec_op, result_is_cpk} = '0;
    assign conv_target_q = '0;
  end

  if (PulpDivsqrt && !ExtRegEna) begin
    // Synch lanes if there is more than one
    assign simd_synch_rdy  = EnableVectors ? &divsqrt_ready : divsqrt_ready[0];
    assign simd_synch_done = EnableVectors ? &divsqrt_done  : divsqrt_done[0];
  end else begin
    // Unused (alternative divider only supported for scalar FP32 divsqrt)
    assign simd_synch_rdy  = '0;
    assign simd_synch_done = '0;
  end

  // ------------
  // Output Side
  // ------------
  assign {result_fmt_is_int, result_is_vector, result_fmt} = lane_aux[0];

  assign result_o = result_fmt_is_int
                    ? ifmt_slice_result[result_fmt]
                    : fmt_slice_result[result_fmt];

  assign extension_bit_o = lane_ext_bit[0]; // don't care about upper ones
  assign tag_o           = lane_tags[0];    // don't care about upper ones
  assign busy_o          = (| lane_busy);

  assign out_valid_o     = lane_out_valid[0]; // don't care about upper ones

  // Collapse the status
  always_comb begin : output_processing
    // Collapse the status
    automatic fpnew_pkg::status_t temp_status;
    temp_status = '0;
    for (int i = 0; i < int'(NUM_LANES); i++)
      temp_status |= lane_status[i] & {5{lane_masks[i]}};
    status_o = temp_status;
  end

endmodule
// Copyright 2019 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// SPDX-License-Identifier: SHL-0.51

// Author: Stefan Mach <smach@iis.ee.ethz.ch>

module fpnew_rounding #(
  parameter int unsigned AbsWidth=2 // Width of the abolute value, without sign bit
) (
  // Input value
  input logic [AbsWidth-1:0]   abs_value_i,             // absolute value without sign
  input logic                  sign_i,
  // Rounding information
  input logic [1:0]            round_sticky_bits_i,     // round and sticky bits {RS}
  input fpnew_pkg::roundmode_e rnd_mode_i,
  input logic                  effective_subtraction_i, // sign of inputs affects rounding of zeroes
  // Output value
  output logic [AbsWidth-1:0]  abs_rounded_o,           // absolute value without sign
  output logic                 sign_o,
  // Output classification
  output logic                 exact_zero_o             // output is an exact zero
);

  logic round_up; // Rounding decision

  // Take the rounding decision according to RISC-V spec
  // RoundMode | Mnemonic | Meaning
  // :--------:|:--------:|:-------
  //    000    |   RNE    | Round to Nearest, ties to Even
  //    001    |   RTZ    | Round towards Zero
  //    010    |   RDN    | Round Down (towards -\infty)
  //    011    |   RUP    | Round Up (towards \infty)
  //    100    |   RMM    | Round to Nearest, ties to Max Magnitude
  //    101    |   ROD    | Round towards odd (this mode is not define in RISC-V FP-SPEC)
  //  others   |          | *invalid*
  always_comb begin : rounding_decision
    unique case (rnd_mode_i)
      fpnew_pkg::RNE: // Decide accoring to round/sticky bits
        unique case (round_sticky_bits_i)
          2'b00,
          2'b01: round_up = 1'b0;           // < ulp/2 away, round down
          2'b10: round_up = abs_value_i[0]; // = ulp/2 away, round towards even result
          2'b11: round_up = 1'b1;           // > ulp/2 away, round up
          default: round_up = fpnew_pkg::DONT_CARE;
        endcase
      fpnew_pkg::RTZ: round_up = 1'b0; // always round down
      fpnew_pkg::RDN: round_up = (| round_sticky_bits_i) ? sign_i  : 1'b0; // to 0 if +, away if -
      fpnew_pkg::RUP: round_up = (| round_sticky_bits_i) ? ~sign_i : 1'b0; // to 0 if -, away if +
      fpnew_pkg::RMM: round_up = round_sticky_bits_i[1]; // round down if < ulp/2 away, else up
      fpnew_pkg::ROD: round_up = ~abs_value_i[0] & (| round_sticky_bits_i);
      default: round_up = fpnew_pkg::DONT_CARE; // propagate x
    endcase
  end

  // Perform the rounding, exponent change and overflow to inf happens automagically
  assign abs_rounded_o = abs_value_i + round_up;

  // True zero result is a zero result without dirty round/sticky bits
  assign exact_zero_o = (abs_value_i == '0) && (round_sticky_bits_i == '0);

  // In case of effective subtraction (thus signs of addition operands must have differed) and a
  // true zero result, the result sign is '-' in case of RDN and '+' for other modes.
  assign sign_o = (exact_zero_o && effective_subtraction_i)
                  ? (rnd_mode_i == fpnew_pkg::RDN)
                  : sign_i;

endmodule
// Copyright 2019 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// SPDX-License-Identifier: SHL-0.51

// Author: Stefan Mach <smach@iis.ee.ethz.ch>

module fpnew_top #(
  // FPU configuration
  parameter fpnew_pkg::fpu_features_t       Features       = fpnew_pkg::RV64D_Xsflt,
  parameter fpnew_pkg::fpu_implementation_t Implementation = fpnew_pkg::DEFAULT_NOREGS,
  // PulpDivSqrt = 0 enables T-head-based DivSqrt unit. Supported only for FP32-only instances of Fpnew
  parameter logic                           PulpDivsqrt    = 1'b1,
  parameter type                            TagType        = logic,
  parameter int unsigned                    TrueSIMDClass  = 0,
  parameter int unsigned                    EnableSIMDMask = 0,
  // Do not change
  localparam int unsigned NumLanes     = fpnew_pkg::max_num_lanes(Features.Width, Features.FpFmtMask, Features.EnableVectors),
  localparam type         MaskType     = logic [NumLanes-1:0],
  localparam int unsigned WIDTH        = Features.Width,
  localparam int unsigned NUM_OPERANDS = 3
) (
  input logic                               clk_i,
  input logic                               rst_ni,
  // Input signals
  input logic [NUM_OPERANDS-1:0][WIDTH-1:0] operands_i,
  input fpnew_pkg::roundmode_e              rnd_mode_i,
  input fpnew_pkg::operation_e              op_i,
  input logic                               op_mod_i,
  input fpnew_pkg::fp_format_e              src_fmt_i,
  input fpnew_pkg::fp_format_e              dst_fmt_i,
  input fpnew_pkg::int_format_e             int_fmt_i,
  input logic                               vectorial_op_i,
  input TagType                             tag_i,
  input MaskType                            simd_mask_i,
  // Input Handshake
  input  logic                              in_valid_i,
  output logic                              in_ready_o,
  input  logic                              flush_i,
  // Output signals
  output logic [WIDTH-1:0]                  result_o,
  output fpnew_pkg::status_t                status_o,
  output TagType                            tag_o,
  // Output handshake
  output logic                              out_valid_o,
  input  logic                              out_ready_i,
  // Indication of valid data in flight
  output logic                              busy_o
);

  localparam int unsigned NUM_OPGROUPS = fpnew_pkg::NUM_OPGROUPS;
  localparam int unsigned NUM_FORMATS  = fpnew_pkg::NUM_FP_FORMATS;

  // ----------------
  // Type Definition
  // ----------------
  typedef struct packed {
    logic [WIDTH-1:0]   result;
    fpnew_pkg::status_t status;
    TagType             tag;
  } output_t;

  // Handshake signals for the blocks
  logic [NUM_OPGROUPS-1:0] opgrp_in_ready, opgrp_out_valid, opgrp_out_ready, opgrp_ext, opgrp_busy;
  output_t [NUM_OPGROUPS-1:0] opgrp_outputs;

  logic [NUM_FORMATS-1:0][NUM_OPERANDS-1:0] is_boxed;

  // -----------
  // Input Side
  // -----------
  assign in_ready_o = in_valid_i & opgrp_in_ready[fpnew_pkg::get_opgroup(op_i)];

  // NaN-boxing check
  for (genvar fmt = 0; fmt < int'(NUM_FORMATS); fmt++) begin : gen_nanbox_check
    localparam int unsigned FP_WIDTH = fpnew_pkg::fp_width(fpnew_pkg::fp_format_e'(fmt));
    // NaN boxing is only generated if it's enabled and needed
    if (Features.EnableNanBox && (FP_WIDTH < WIDTH)) begin : check
      for (genvar op = 0; op < int'(NUM_OPERANDS); op++) begin : operands
        assign is_boxed[fmt][op] = (!vectorial_op_i)
                                   ? operands_i[op][WIDTH-1:FP_WIDTH] == '1
                                   : 1'b1;
      end
    end else begin : no_check
      assign is_boxed[fmt] = '1;
    end
  end

  // Filter out the mask if not used
  MaskType simd_mask;
  assign simd_mask = simd_mask_i | ~{NumLanes{logic'(EnableSIMDMask)}};

  // -------------------------
  // Generate Operation Blocks
  // -------------------------
  for (genvar opgrp = 0; opgrp < int'(NUM_OPGROUPS); opgrp++) begin : gen_operation_groups
    localparam int unsigned NUM_OPS = fpnew_pkg::num_operands(fpnew_pkg::opgroup_e'(opgrp));

    logic in_valid;
    logic [NUM_FORMATS-1:0][NUM_OPS-1:0] input_boxed;

    assign in_valid = in_valid_i & (fpnew_pkg::get_opgroup(op_i) == fpnew_pkg::opgroup_e'(opgrp));

    // slice out input boxing
    always_comb begin : slice_inputs
      for (int unsigned fmt = 0; fmt < NUM_FORMATS; fmt++)
        input_boxed[fmt] = is_boxed[fmt][NUM_OPS-1:0];
    end

    fpnew_opgroup_block #(
      .OpGroup       ( fpnew_pkg::opgroup_e'(opgrp)    ),
      .Width         ( WIDTH                           ),
      .EnableVectors ( Features.EnableVectors          ),
      .PulpDivsqrt   ( PulpDivsqrt                     ),
      .FpFmtMask     ( Features.FpFmtMask              ),
      .IntFmtMask    ( Features.IntFmtMask             ),
      .FmtPipeRegs   ( Implementation.PipeRegs[opgrp]  ),
      .FmtUnitTypes  ( Implementation.UnitTypes[opgrp] ),
      .PipeConfig    ( Implementation.PipeConfig       ),
      .TagType       ( TagType                         ),
      .TrueSIMDClass ( TrueSIMDClass                   )
    ) i_opgroup_block (
      .clk_i,
      .rst_ni,
      .operands_i      ( operands_i[NUM_OPS-1:0] ),
      .is_boxed_i      ( input_boxed             ),
      .rnd_mode_i,
      .op_i,
      .op_mod_i,
      .src_fmt_i,
      .dst_fmt_i,
      .int_fmt_i,
      .vectorial_op_i,
      .tag_i,
      .simd_mask_i     ( simd_mask             ),
      .in_valid_i      ( in_valid              ),
      .in_ready_o      ( opgrp_in_ready[opgrp] ),
      .flush_i,
      .result_o        ( opgrp_outputs[opgrp].result ),
      .status_o        ( opgrp_outputs[opgrp].status ),
      .extension_bit_o ( opgrp_ext[opgrp]            ),
      .tag_o           ( opgrp_outputs[opgrp].tag    ),
      .out_valid_o     ( opgrp_out_valid[opgrp]      ),
      .out_ready_i     ( opgrp_out_ready[opgrp]      ),
      .busy_o          ( opgrp_busy[opgrp]           )
    );
  end

  // ------------------
  // Arbitrate Outputs
  // ------------------
  output_t arbiter_output;

  // Round-Robin arbiter to decide which result to use
  rr_arb_tree #(
    .NumIn     ( NUM_OPGROUPS ),
    .DataType  ( output_t     ),
    .AxiVldRdy ( 1'b1         )
  ) i_arbiter (
    .clk_i,
    .rst_ni,
    .flush_i,
    .rr_i   ( '0             ),
    .req_i  ( opgrp_out_valid ),
    .gnt_o  ( opgrp_out_ready ),
    .data_i ( opgrp_outputs   ),
    .gnt_i  ( out_ready_i     ),
    .req_o  ( out_valid_o     ),
    .data_o ( arbiter_output  ),
    .idx_o  ( /* unused */    )
  );

  // Unpack output
  assign result_o        = arbiter_output.result;
  assign status_o        = arbiter_output.status;
  assign tag_o           = arbiter_output.tag;

  assign busy_o = (| opgrp_busy);

endmodule
