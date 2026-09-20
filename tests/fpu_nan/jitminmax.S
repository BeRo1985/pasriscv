# Signed zero ordering, operand aliasing and the Zfa minimum/maximum forms, all through
# the JIT. Every iteration is XORed against the expected value and the differences are
# accumulated, so a single deviating iteration fails the case no matter which engine
# happened to execute the last one.
#
# Failure bitmask at 0x80100000, one bit per case, then syscon poweroff.
  .equ RESULT_ADDR, 0x80100000
  .equ SYSCON_ADDR, 0x11100000
  .equ LOOPS,       2000

  .section .text.init,"ax",@progbits
  .globl _start
  .align 2
_start:
  li      t0, 3
  slli    t0, t0, 13
  csrs    mstatus, t0
  li      t0, 0x0e
  csrw    0x7d0, t0

  li      s1, 0                   # failure mask
  li      s3, 1                   # current bit

  fmv.w.x fs0, zero               # +0.0f
  li      t0, 0x80000000
  fmv.w.x fs1, t0                 # -0.0f
  li      t0, 0x3f800000
  fmv.w.x fs2, t0                 # 1.0f

  # ---- 1: fmin.s(-0, +0) = -0 ----
  li      s6, 0
  li      t3, 0xffffffff80000000
  li      s2, LOOPS
1:
  fmin.s  ft2, fs1, fs0
  fmv.x.w t5, ft2
  xor     t5, t5, t3
  or      s6, s6, t5
  addi    s2, s2, -1
  bnez    s2, 1b
  li      t3, 0
  jal     ra, check

  # ---- 2: fmin.s(+0, -0) = -0 as well ----
  li      s6, 0
  li      t3, 0xffffffff80000000
  li      s2, LOOPS
2:
  fmin.s  ft2, fs0, fs1
  fmv.x.w t5, ft2
  xor     t5, t5, t3
  or      s6, s6, t5
  addi    s2, s2, -1
  bnez    s2, 2b
  li      t3, 0
  jal     ra, check

  # ---- 3: fmax.s(-0, +0) = +0 ----
  li      s6, 0
  li      t3, 0
  li      s2, LOOPS
3:
  fmax.s  ft2, fs1, fs0
  fmv.x.w t5, ft2
  xor     t5, t5, t3
  or      s6, s6, t5
  addi    s2, s2, -1
  bnez    s2, 3b
  li      t3, 0
  jal     ra, check

  # ---- 4: fmax.s(+0, -0) = +0 as well ----
  li      s6, 0
  li      t3, 0
  li      s2, LOOPS
4:
  fmax.s  ft2, fs0, fs1
  fmv.x.w t5, ft2
  xor     t5, t5, t3
  or      s6, s6, t5
  addi    s2, s2, -1
  bnez    s2, 4b
  li      t3, 0
  jal     ra, check

  # ---- 5: destination aliases the second operand ----
  li      s6, 0
  li      t3, 0x3f000000
  li      s2, LOOPS
5:
  li      t0, 0x3f000000
  fmv.w.x ft3, t0                 # 0.5f
  fmin.s  ft3, fs2, ft3           # rd == rs2; moving rs1 into rd first would
                                  # clobber rs2 and yield 1.0f instead of 0.5f
  fmv.x.w t5, ft3
  xor     t5, t5, t3
  or      s6, s6, t5
  addi    s2, s2, -1
  bnez    s2, 5b
  li      t3, 0
  jal     ra, check

  # ---- 6: fminm.s, the Zfa form, on ordinary operands ----
  li      s6, 0
  li      t3, 0
  li      s2, LOOPS
6:
  fminm.s ft2, fs2, fs0
  fmv.x.w t5, ft2
  xor     t5, t5, t3
  or      s6, s6, t5
  addi    s2, s2, -1
  bnez    s2, 6b
  li      t3, 0
  jal     ra, check

  # ---- 7: fmaxm.s on ordinary operands ----
  li      s6, 0
  li      t3, 0x3f800000
  li      s2, LOOPS
7:
  fmaxm.s ft2, fs2, fs0
  fmv.x.w t5, ft2
  xor     t5, t5, t3
  or      s6, s6, t5
  addi    s2, s2, -1
  bnez    s2, 7b
  li      t3, 0
  jal     ra, check

  # ---- 8: fmin.d(-0, +0) = -0 ----
  fmv.d.x fa0, zero
  li      t0, 0x8000000000000000
  fmv.d.x fa1, t0
  li      s6, 0
  li      t3, 0x8000000000000000
  li      s2, LOOPS
8:
  fmin.d  fa2, fa1, fa0
  fmv.x.d t5, fa2
  xor     t5, t5, t3
  or      s6, s6, t5
  addi    s2, s2, -1
  bnez    s2, 8b
  li      t3, 0
  jal     ra, check

  # ---- 9: fmin.d(+0, -0) = -0 as well ----
  li      s6, 0
  li      t3, 0x8000000000000000
  li      s2, LOOPS
9:
  fmin.d  fa2, fa0, fa1
  fmv.x.d t5, fa2
  xor     t5, t5, t3
  or      s6, s6, t5
  addi    s2, s2, -1
  bnez    s2, 9b
  li      t3, 0
  jal     ra, check

  # ---- 10: fmax.d(+0, -0) = +0 ----
  li      s6, 0
  li      t3, 0
  li      s2, LOOPS
10:
  fmax.d  fa2, fa0, fa1
  fmv.x.d t5, fa2
  xor     t5, t5, t3
  or      s6, s6, t5
  addi    s2, s2, -1
  bnez    s2, 10b
  li      t3, 0
  jal     ra, check

  li      t0, RESULT_ADDR
  sd      s1, 0(t0)
  mv      a0, s1
  la      t0, tohost
  li      t1, 1
  sd      t1, 0(t0)
  li      t0, SYSCON_ADDR
  li      t1, 0x5555
  sw      t1, 0(t0)
11:
  j       11b

check:
  beq     s6, t3, 1f
  or      s1, s1, s3
1:
  slli    s3, s3, 1
  ret

  .section .tohost,"aw",@progbits
  .align 6
  .globl tohost
tohost:
  .dword 0
  .align 6
  .globl fromhost
fromhost:
  .dword 0
