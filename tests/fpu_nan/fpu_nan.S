# NaN handling of the arithmetic FP instructions in the non-strict (host FPU) path.
#
# Two rules are checked, both of which the host violates on its own:
#
#   1. Every NaN an arithmetic FP operation produces must be the canonical NaN.
#      x86 instead propagates the payload of a NaN operand and uses $ffc00000 /
#      $fff8000000000000 (sign bit set) as its own default NaN.
#   2. A quiet NaN operand alone must not raise NV. Only a signaling operand or a
#      genuinely invalid operation (inf-inf, 0*inf, 0/0, sqrt of a negative) may.
#
# The whole block runs in a loop so both the interpreter and the JIT compiled
# version of the code are covered.
#
#   a0 = 0             everything correct
#   a0 = case*100 + 1  wrong result value
#   a0 = case*100 + 10 + observed fflags   wrong flags

  .section .text.init,"ax",@progbits
  .globl _start
  .align 2
_start:
  li      a0, 0
  li      t0, 3
  slli    t0, t0, 13
  csrs    mstatus, t0             # mstatus.FS = Dirty, otherwise FP traps

  li      s2, 64                  # iterations, enough for the JIT to take over
outer:

  # ---- 1: fadd.s with a quiet NaN operand: canonical result, no flags ----
  li      s0, 1
  li      t0, 0x7fc01234
  fmv.w.x ft0, t0
  li      t0, 0x3f800000          # 1.0f
  fmv.w.x ft1, t0
  csrw    fflags, zero
  fadd.s  ft2, ft0, ft1
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  bne     t1, t3, fail_value
  bnez    t2, fail_flags

  # ---- 2: fsub.s ----
  li      s0, 2
  csrw    fflags, zero
  fsub.s  ft2, ft0, ft1
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  bne     t1, t3, fail_value
  bnez    t2, fail_flags

  # ---- 3: fmul.s ----
  li      s0, 3
  csrw    fflags, zero
  fmul.s  ft2, ft0, ft1
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  bne     t1, t3, fail_value
  bnez    t2, fail_flags

  # ---- 4: fdiv.s ----
  li      s0, 4
  csrw    fflags, zero
  fdiv.s  ft2, ft0, ft1
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  bne     t1, t3, fail_value
  bnez    t2, fail_flags

  # ---- 5: fsqrt.s ----
  li      s0, 5
  csrw    fflags, zero
  fsqrt.s ft2, ft0
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  bne     t1, t3, fail_value
  bnez    t2, fail_flags

  # ---- 6: fdiv.s 0/0: canonical NaN with the sign bit clear, NV set ----
  li      s0, 6
  fmv.w.x ft3, zero
  csrw    fflags, zero
  fdiv.s  ft2, ft3, ft3
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  bne     t1, t3, fail_value
  li      t3, 16
  bne     t2, t3, fail_flags

  # ---- 7: fmul.s 0*inf: canonical NaN, NV set ----
  li      s0, 7
  li      t0, 0x7f800000          # +inf
  fmv.w.x ft4, t0
  csrw    fflags, zero
  fmul.s  ft2, ft3, ft4
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  bne     t1, t3, fail_value
  li      t3, 16
  bne     t2, t3, fail_flags

  # ---- 8: fadd.s inf + (-inf): canonical NaN, NV set ----
  li      s0, 8
  li      t0, 0xffffffffff800000  # -inf
  fmv.w.x ft5, t0
  csrw    fflags, zero
  fadd.s  ft2, ft4, ft5
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  bne     t1, t3, fail_value
  li      t3, 16
  bne     t2, t3, fail_flags

  # ---- 9: fmsub.s (0*0) - qNaN: canonical NaN, no flags at all ----
  li      s0, 9
  li      t0, 0x7fc00000
  fmv.w.x ft6, t0
  csrw    fflags, zero
  fmsub.s ft2, ft3, ft3, ft6
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  bne     t1, t3, fail_value
  bnez    t2, fail_flags

  # ---- 10: fmadd.s with a NaN payload addend: canonical NaN, no flags ----
  li      s0, 10
  csrw    fflags, zero
  fmadd.s ft2, ft3, ft3, ft0
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  bne     t1, t3, fail_value
  bnez    t2, fail_flags

  # ---- 11: fadd.d with a quiet NaN operand ----
  li      s0, 11
  li      t0, 0x7ff8000000001234
  fmv.d.x fa0, t0
  li      t0, 0x3ff0000000000000  # 1.0
  fmv.d.x fa1, t0
  csrw    fflags, zero
  fadd.d  fa2, fa0, fa1
  fmv.x.d t1, fa2
  csrr    t2, fflags
  li      t3, 0x7ff8000000000000
  bne     t1, t3, fail_value
  bnez    t2, fail_flags

  # ---- 12: fmul.d ----
  li      s0, 12
  csrw    fflags, zero
  fmul.d  fa2, fa0, fa1
  fmv.x.d t1, fa2
  csrr    t2, fflags
  li      t3, 0x7ff8000000000000
  bne     t1, t3, fail_value
  bnez    t2, fail_flags

  # ---- 13: fdiv.d ----
  li      s0, 13
  csrw    fflags, zero
  fdiv.d  fa2, fa0, fa1
  fmv.x.d t1, fa2
  csrr    t2, fflags
  li      t3, 0x7ff8000000000000
  bne     t1, t3, fail_value
  bnez    t2, fail_flags

  # ---- 14: fsqrt.d ----
  li      s0, 14
  csrw    fflags, zero
  fsqrt.d fa2, fa0
  fmv.x.d t1, fa2
  csrr    t2, fflags
  li      t3, 0x7ff8000000000000
  bne     t1, t3, fail_value
  bnez    t2, fail_flags

  # ---- 15: fdiv.d 0/0: canonical NaN with the sign bit clear, NV set ----
  li      s0, 15
  fmv.d.x fa3, zero
  csrw    fflags, zero
  fdiv.d  fa2, fa3, fa3
  fmv.x.d t1, fa2
  csrr    t2, fflags
  li      t3, 0x7ff8000000000000
  bne     t1, t3, fail_value
  li      t3, 16
  bne     t2, t3, fail_flags

  # ---- 16: fmsub.d (0*0) - qNaN: canonical NaN, no flags ----
  li      s0, 16
  li      t0, 0x7ff8000000000000
  fmv.d.x fa4, t0
  csrw    fflags, zero
  fmsub.d fa2, fa3, fa3, fa4
  fmv.x.d t1, fa2
  csrr    t2, fflags
  li      t3, 0x7ff8000000000000
  bne     t1, t3, fail_value
  bnez    t2, fail_flags

  # ---- 17: a normal computation must stay unaffected ----
  li      s0, 17
  csrw    fflags, zero
  fadd.s  ft2, ft1, ft1           # 1.0f + 1.0f = 2.0f
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x40000000
  bne     t1, t3, fail_value
  bnez    t2, fail_flags

  addi    s2, s2, -1
  bnez    s2, outer

  li      a0, 0
  j       exit_htif

fail_value:
  li      t4, 100
  mul     a0, s0, t4
  addi    a0, a0, 1
  j       exit_htif

fail_flags:
  li      t4, 100
  mul     a0, s0, t4
  addi    a0, a0, 10
  add     a0, a0, t2
  j       exit_htif

  .align 2
exit_htif:
  la      t0, tohost
  li      t1, 1
  sd      t1, 0(t0)
1:
  j       1b

  .section .tohost,"aw",@progbits
  .align 6
  .globl tohost
tohost:
  .dword 0
  .align 6
  .globl fromhost
fromhost:
  .dword 0
