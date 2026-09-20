# Smctr: not taken branches. This is the only transfer type with an enable bit
# rather than an inhibit bit, so it stays silent unless mctrctl.NTBREN is set.
#
# The sequence is run hot first so the blocks are natively compiled, which means
# the entries checked below come from emitted code, not from the interpreter.
#
#   a0 = 0   everything matched
#   a0 = 1   a not taken branch was recorded although NTBREN was clear
#   a0 = 2   nothing was recorded with NTBREN set
#   a0 = 3   the entry has the wrong type
#   a0 = 4   the entry does not point at the branch
#   a0 = 5   the target is not the fall through address

  .section .text.init,"ax",@progbits
  .globl _start
  .align 2
_start:
  li      a0, 0
  la      t0, trap_handler
  csrw    mtvec, t0

  li      t0, 4
  csrw    sctrdepth, t0

  # Warm the not taken branch so the JIT compiles this block
  li      s2, 200
warm_loop:
  li      t0, 1
  li      t1, 2
  beq     t0, t1, fail_unreachable    # never taken
  addi    s2, s2, -1
  bnez    s2, warm_loop

  csrw    sctrstatus, zero

  # Recording on, but NTBREN still clear: the not taken branch must stay silent
  li      t0, 4                       # mctrctl.M only
  csrw    mctrctl, t0
  li      t0, 1
  li      t1, 2
  beq     t0, t1, fail_unreachable
  csrw    mctrctl, zero
  csrr    t2, sctrstatus
  andi    t2, t2, 0xff
  bnez    t2, bad_silent

  # Now with NTBREN, bit 36
  li      t0, 1
  slli    t0, t0, 36
  ori     t0, t0, 4                   # plus mctrctl.M
  csrw    mctrctl, t0
  li      t0, 1
  li      t1, 2
ntb_branch:
  beq     t0, t1, fail_unreachable
ntb_fallthrough:
  csrw    mctrctl, zero

  csrr    t2, sctrstatus
  andi    t2, t2, 0xff
  beqz    t2, bad_nothing

  li      t0, 0x200
  csrw    siselect, t0
  csrr    t1, sireg3
  andi    t1, t1, 0xf
  li      t2, 4                       # not taken branch
  bne     t1, t2, bad_type
  csrr    t3, sireg
  la      t4, ntb_branch
  ori     t4, t4, 1
  bne     t3, t4, bad_source
  csrr    t3, sireg2
  la      t4, ntb_fallthrough
  bne     t3, t4, bad_target

  li      a0, 0
  j       exit_htif

fail_unreachable:
  li      a0, 10
  j       exit_htif
bad_silent:
  li      a0, 1
  j       exit_htif
bad_nothing:
  li      a0, 2
  j       exit_htif
bad_type:
  li      a0, 3
  j       exit_htif
bad_source:
  li      a0, 4
  j       exit_htif
bad_target:
  li      a0, 5
  j       exit_htif

  .align 2
trap_handler:
  csrr    a0, mepc
  la      t0, _start
  sub     a0, a0, t0
  addi    a0, a0, 1000
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
