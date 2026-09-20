# NaN and NV behaviour of the arithmetic FP instructions, executed through the JIT.
# Every case runs its operation in a hot loop with no CSR access inside, so the block
# gets compiled; the flags are read afterwards.
#
# The result is a failure bitmask stored at 0x80100000, two bits per case
# (value, flags), then the machine powers itself off through the syscon device.

  .equ RESULT_ADDR, 0x80100000
  .equ SYSCON_ADDR, 0x11100000
  .equ LOOPS,       2000

  .section .text.init,"ax",@progbits
  .globl _start
  .align 2
_start:
  li      t0, 3
  slli    t0, t0, 13
  csrs    mstatus, t0             # mstatus.FS = Dirty

  li      s1, 0                   # failure mask
  li      s3, 1                   # current bit

  li      t0, 0x7fc01234
  fmv.w.x fs0, t0                 # quiet NaN with a payload
  li      t0, 0x3f800000
  fmv.w.x fs1, t0                 # 1.0f
  fmv.w.x fs2, zero               # 0.0f
  li      t0, 0x7f800000
  fmv.w.x fs3, t0                 # +inf

  # ---- 1: fadd.s qNaN + 1.0 ----
  csrw    fflags, zero
  li      s2, LOOPS
1:
  fadd.s  ft2, fs0, fs1
  addi    s2, s2, -1
  bnez    s2, 1b
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  li      t4, 0
  jal     ra, check

  # ---- 2: fmul.s qNaN * 1.0 ----
  csrw    fflags, zero
  li      s2, LOOPS
2:
  fmul.s  ft2, fs0, fs1
  addi    s2, s2, -1
  bnez    s2, 2b
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  li      t4, 0
  jal     ra, check

  # ---- 3: fdiv.s qNaN / 1.0 ----
  csrw    fflags, zero
  li      s2, LOOPS
3:
  fdiv.s  ft2, fs0, fs1
  addi    s2, s2, -1
  bnez    s2, 3b
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  li      t4, 0
  jal     ra, check

  # ---- 4: fsqrt.s qNaN ----
  csrw    fflags, zero
  li      s2, LOOPS
4:
  fsqrt.s ft2, fs0
  addi    s2, s2, -1
  bnez    s2, 4b
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  li      t4, 0
  jal     ra, check

  # ---- 5: fmadd.s (0*0) + qNaN ----
  csrw    fflags, zero
  li      s2, LOOPS
5:
  fmadd.s ft2, fs2, fs2, fs0
  addi    s2, s2, -1
  bnez    s2, 5b
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  li      t4, 0
  jal     ra, check

  # ---- 6: fdiv.s 0/0, canonical NaN and NV ----
  csrw    fflags, zero
  li      s2, LOOPS
6:
  fdiv.s  ft2, fs2, fs2
  addi    s2, s2, -1
  bnez    s2, 6b
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  li      t4, 16
  jal     ra, check

  # ---- 7: fmul.s 0*inf, canonical NaN and NV ----
  csrw    fflags, zero
  li      s2, LOOPS
7:
  fmul.s  ft2, fs2, fs3
  addi    s2, s2, -1
  bnez    s2, 7b
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x7fc00000
  li      t4, 16
  jal     ra, check

  # ---- 8: fadd.d qNaN + 1.0 ----
  li      t0, 0x7ff8000000001234
  fmv.d.x fs4, t0
  li      t0, 0x3ff0000000000000
  fmv.d.x fs5, t0
  fmv.d.x fs6, zero
  csrw    fflags, zero
  li      s2, LOOPS
8:
  fadd.d  ft2, fs4, fs5
  addi    s2, s2, -1
  bnez    s2, 8b
  fmv.x.d t1, ft2
  csrr    t2, fflags
  li      t3, 0x7ff8000000000000
  li      t4, 0
  jal     ra, check

  # ---- 9: fdiv.d 0/0, canonical NaN and NV ----
  csrw    fflags, zero
  li      s2, LOOPS
9:
  fdiv.d  ft2, fs6, fs6
  addi    s2, s2, -1
  bnez    s2, 9b
  fmv.x.d t1, ft2
  csrr    t2, fflags
  li      t3, 0x7ff8000000000000
  li      t4, 16
  jal     ra, check

  # ---- 10: ordinary arithmetic must stay untouched ----
  csrw    fflags, zero
  li      s2, LOOPS
10:
  fadd.s  ft2, fs1, fs1           # 1.0f + 1.0f
  addi    s2, s2, -1
  bnez    s2, 10b
  fmv.x.w t1, ft2
  csrr    t2, fflags
  li      t3, 0x40000000
  li      t4, 0
  jal     ra, check

  # ---- 11: ordinary double arithmetic ----
  csrw    fflags, zero
  li      s2, LOOPS
11:
  fadd.d  ft2, fs5, fs5           # 1.0 + 1.0
  addi    s2, s2, -1
  bnez    s2, 11b
  fmv.x.d t1, ft2
  csrr    t2, fflags
  li      t3, 0x4000000000000000
  li      t4, 0
  jal     ra, check

  li      t0, RESULT_ADDR
  sd      s1, 0(t0)
  mv      a0, s1
  # riscv-tests style exit, so the same binary can also be run by PasRISCVTest
  la      t0, tohost
  li      t1, 1
  sd      t1, 0(t0)
  # and a syscon poweroff for the JIT harness, which has no HTIF
  li      t0, SYSCON_ADDR
  li      t1, 0x5555
  sw      t1, 0(t0)
12:
  j       12b

  .section .tohost,"aw",@progbits
  .align 6
  .globl tohost
tohost:
  .dword 0
  .align 6
  .globl fromhost
fromhost:
  .dword 0

  .section .text.init,"ax",@progbits

# t1 actual value, t3 expected value, t2 actual flags, t4 expected flags
check:
  beq     t1, t3, 1f
  or      s1, s1, s3
1:
  slli    s3, s3, 1
  beq     t2, t4, 2f
  or      s1, s1, s3
2:
  slli    s3, s3, 1
  ret
