# Conversions to integers in the strict FPU (soft-float, mpasriscvctl bit 0). From 2^64
# on the result has to saturate (the shift overflowed first), and a negative value converted
# to an unsigned integer gives 0 with NV instead of the maximum, or 0 with NX only when it
# rounds to 0. The same results are checked in the fast path afterwards, there without the flags
# (approximate by design). 16 checks per set, the strict set also checks 16 flag values, plus
# 3 checks for the flags of moves and sign injection and for mpasriscvctl.
# expect: a0=0000000000000033 a1=0000000000000000
#include "head.inc"
#include "fpmacros.inc"

# CHKCVT reg, value, flags, bit, withflags
.macro CHKCVT reg, val, flg, bit, withflags
  CHKX \reg, \val, \bit
  .if \withflags
  CHKFLAGS \flg, \bit
  .else
  fsflags zero
  .endif
.endm

.macro CVTSET withflags
  fsflags zero
  FLID ft0, 0x43f0000000000000              # 2^64
  fcvt.lu.d t0, ft0, rtz
  CHKCVT t0, 0xffffffffffffffff, 0x10, 0, \withflags
  fcvt.l.d t0, ft0, rtz
  CHKCVT t0, 0x7fffffffffffffff, 0x10, 1, \withflags
  FLID ft1, 0xc3f0000000000000              # -2^64
  fcvt.l.d t0, ft1, rtz
  CHKCVT t0, 0x8000000000000000, 0x10, 2, \withflags
  FLID ft2, 0x43f8000000000000              # 1.5*2^64
  fcvt.lu.d t0, ft2, rtz
  CHKCVT t0, 0xffffffffffffffff, 0x10, 3, \withflags
  FLIS ft3, 0x5f800000                      # 2^64 single
  fcvt.lu.s t0, ft3, rtz
  CHKCVT t0, 0xffffffffffffffff, 0x10, 4, \withflags
  fcvt.l.s t0, ft3, rtz
  CHKCVT t0, 0x7fffffffffffffff, 0x10, 5, \withflags
  fcvt.wu.s t0, ft3, rtz
  CHKCVT t0, 0xffffffffffffffff, 0x10, 6, \withflags
  FLID ft4, 0xc202a05f20000000              # -1e10
  fcvt.wu.d t0, ft4, rtz
  CHKCVT t0, 0, 0x10, 7, \withflags
  fcvt.lu.d t0, ft4, rtz
  CHKCVT t0, 0, 0x10, 8, \withflags
  FLID ft5, 0xc008000000000000              # -3.0
  fcvt.wu.d t0, ft5, rtz
  CHKCVT t0, 0, 0x10, 9, \withflags
  FLID ft6, 0xbfe0000000000000              # -0.5
  fcvt.wu.d t0, ft6, rtz
  CHKCVT t0, 0, 0x01, 10, \withflags
  fcvt.lu.d t0, ft6, rne
  CHKCVT t0, 0, 0x01, 11, \withflags
  fcvt.lu.d t0, ft6, rdn
  CHKCVT t0, 0, 0x10, 12, \withflags
  FLID ft7, 0xbff8000000000000              # -1.5
  fcvt.lu.d t0, ft7, rtz
  CHKCVT t0, 0, 0x10, 13, \withflags
  FLIS ft8, 0xd01502f9                      # -1e10 single
  fcvt.wu.s t0, ft8, rtz
  CHKCVT t0, 0, 0x10, 14, \withflags
  fcvt.lu.s t0, ft8, rtz
  CHKCVT t0, 0, 0x10, 15, \withflags
.endm

  li t0, 0x2000
  csrs mstatus, t0
  # Moves and sign injection raise no flags, and must not report host flags left over from
  # the emulator. Setting up the machine leaves a host inexact behind, which the first FP
  # instruction in the single step run took over (the old fmv.d.x as NX), so this comes first.
  fsflags zero
  li t4, 0x3ff0000000000000
  fmv.d.x ft0, t4
  fsgnj.d ft1, ft0, ft0
  fmv.x.d t1, ft1
  frflags t1
  CHKX t1, 0, 18
  csrwi 0x7d0, 1
  # mpasriscvctl reads back single bits (bit 2, FastRMM, depends on the configuration), not
  # all ones, so the csrci below switches strict mode off and nothing else
  csrr t1, 0x7d0
  andi t1, t1, 0xb
  CHKX t1, 1, 16
  CVTSET 1
  csrci 0x7d0, 1
  csrr t1, 0x7d0
  andi t1, t1, 0xb
  CHKX t1, 0, 17
  CVTSET 0
#include "tail.inc"
