# Signaling versus quiet comparisons, and the half precision fmin/fmax NaN rules, all
# executed through the JIT (hot loops, no CSR access inside them).
#
# Failure bitmask at 0x80100000, two bits per case (value, flags), then syscon poweroff.
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
  # all harts, keep the RMM fixup, and let the JIT raise NV from the host flag
  li      t0, 0x0e
  csrw    0x7d0, t0

  li      s1, 0
  li      s3, 1

  li      t0, 0x7fc01234
  fmv.w.x fs0, t0                 # single precision quiet NaN with a payload
  li      t0, 0x3f800000
  fmv.w.x fs1, t0                 # 1.0f

  li      t0, 0x7e01
  fmv.h.x fs4, t0                 # half precision quiet NaN with a payload
  li      t0, 0x4000
  fmv.h.x fs5, t0                 # 2.0 in half precision

  # ---- 1: flt.s is a signaling comparison, a quiet NaN must raise NV ----
  csrw    fflags, zero
  li      s2, LOOPS
1:
  flt.s   t1, fs0, fs1
  addi    s2, s2, -1
  bnez    s2, 1b
  csrr    t2, fflags
  li      t3, 0
  li      t4, 16
  jal     ra, check

  # ---- 2: fle.s likewise ----
  csrw    fflags, zero
  li      s2, LOOPS
2:
  fle.s   t1, fs0, fs1
  addi    s2, s2, -1
  bnez    s2, 2b
  csrr    t2, fflags
  li      t3, 0
  li      t4, 16
  jal     ra, check

  # ---- 3: feq.s is quiet, a quiet NaN must not raise anything ----
  csrw    fflags, zero
  li      s2, LOOPS
3:
  feq.s   t1, fs0, fs1
  addi    s2, s2, -1
  bnez    s2, 3b
  csrr    t2, fflags
  li      t3, 0
  li      t4, 0
  jal     ra, check

  # ---- 4: fmin.h with the NaN first, the numeric operand wins ----
  li      s6, 0
  li      t6, 0x4000
  csrw    fflags, zero
  li      s2, LOOPS
4:
  fmin.h  ft2, fs4, fs5
  fmv.x.h t5, ft2
  xor     t5, t5, t6
  or      s6, s6, t5
  addi    s2, s2, -1
  bnez    s2, 4b
  mv      t1, s6
  csrr    t2, fflags
  li      t3, 0
  li      t4, 0
  jal     ra, check

  # ---- 5: fmin.h with the NaN second, same result ----
  li      s6, 0
  li      t6, 0x4000
  csrw    fflags, zero
  li      s2, LOOPS
5:
  fmin.h  ft2, fs5, fs4
  fmv.x.h t5, ft2
  xor     t5, t5, t6
  or      s6, s6, t5
  addi    s2, s2, -1
  bnez    s2, 5b
  mv      t1, s6
  csrr    t2, fflags
  li      t3, 0
  li      t4, 0
  jal     ra, check

  # ---- 6: fmax.h with the NaN second ----
  li      s6, 0
  li      t6, 0x4000
  csrw    fflags, zero
  li      s2, LOOPS
6:
  fmax.h  ft2, fs5, fs4
  fmv.x.h t5, ft2
  xor     t5, t5, t6
  or      s6, s6, t5
  addi    s2, s2, -1
  bnez    s2, 6b
  mv      t1, s6
  csrr    t2, fflags
  li      t3, 0
  li      t4, 0
  jal     ra, check

  # ---- 7: fmin.h with two NaNs gives the canonical half precision NaN ----
  li      s6, 0
  li      t6, 0x7e00
  csrw    fflags, zero
  li      s2, LOOPS
7:
  fmin.h  ft2, fs4, fs4
  fmv.x.h t5, ft2
  xor     t5, t5, t6
  or      s6, s6, t5
  addi    s2, s2, -1
  bnez    s2, 7b
  mv      t1, s6
  csrr    t2, fflags
  li      t3, 0
  li      t4, 0
  jal     ra, check

  # ---- 8: ordinary comparison must stay unaffected ----
  csrw    fflags, zero
  li      s2, LOOPS
8:
  flt.s   t1, fs1, fs1
  addi    s2, s2, -1
  bnez    s2, 8b
  csrr    t2, fflags
  li      t3, 0
  li      t4, 0
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
9:
  j       9b

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

  .section .tohost,"aw",@progbits
  .align 6
  .globl tohost
tohost:
  .dword 0
  .align 6
  .globl fromhost
fromhost:
  .dword 0
