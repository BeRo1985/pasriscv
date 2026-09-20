# Isolates rv64ud-p-fcvt_w subtest 20: fcvt.l.d of a double that is far out of
# the int64 range must saturate AND raise the invalid operation flag (NV, 16).
#
# The stock riscv-tests binary checks the value and the flags with two branches
# that share one fail label, so a failure there does not say which half broke.
# This variant reports both separately.
#
#   a0 = 0        value and flags both correct
#   a0 = 1        wrong value
#   a0 = 100+f    value correct, but fflags were f instead of 16
#   a0 = 200+f    flags read back before any FP op were f instead of 0
#   a0 = 4        positive overflow gave the wrong value, not INT64_MAX

  .section .text.init,"ax",@progbits
  .globl _start
  .align 2
_start:
  li      a0, 0

  li      t0, 3
  slli    t0, t0, 13              # mstatus.FS = Dirty, otherwise FP traps
  csrs    mstatus, t0

  csrw    fflags, zero
  csrr    t2, fflags
  bnez    t2, bad_initial

  la      t0, val
  fld     fa0, 0(t0)
  fcvt.l.d t1, fa0, rtz
  csrr    t2, fflags              # read the flags the conversion produced

  li      t3, -1
  slli    t3, t3, 63              # 0x8000000000000000, the saturated result
  bne     t1, t3, bad_value

  mv      s1, t2                  # remember the flags, check them last

  # same again with the positive counterpart, +3e19, which must saturate to
  # INT64_MAX. Trunc() yields the x86 integer indefinite here, so a check on
  # the already converted value cannot tell positive overflow from negative.
  csrw    fflags, zero
  la      t0, valpos
  fld     fa1, 0(t0)
  fcvt.l.d t1, fa1, rtz
  csrr    t2, fflags
  li      t3, -1
  srli    t3, t3, 1               # 0x7fffffffffffffff
  bne     t1, t3, bad_pos_value

  li      t3, 16                  # NV for the negative case
  bne     s1, t3, bad_flags

  li      a0, 0
  j       exit_htif

bad_pos_value:
  li      a0, 4
  j       exit_htif

bad_value:
  li      a0, 1
  j       exit_htif

bad_flags:
  addi    a0, s1, 100
  j       exit_htif

bad_initial:
  addi    a0, t2, 200
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

  .section .data
  .align 3
val:
  .dword 0xc3fa055690d9db80       # -3e19, same input as subtest 20
valpos:
  .dword 0x43fa055690d9db80       # +3e19, the positive counterpart
