# Smctr: the cycle count in ctrdata. CCV marks it valid, CCM[27:16] is a 12 bit
# mantissa and CCE[31:28] its binary exponent, so the count between two entries
# is CCM shifted left by CCE.
#
# Two calls are recorded with a known number of instructions between them. The
# gap is small enough to fit the mantissa outright, so CCE has to be zero and CCM
# has to equal the instruction count. The sequence runs hot first, so this checks
# the code the JIT emits.
#
#   a0 = 0    everything matched
#   a0 = 1    CCV was not set on the newest entry
#   a0 = 2    CCE was not zero although the gap fits the mantissa
#   a0 = 100+d  the two counts differ by d instead of the sixteen extra nops
#   a0 = 4    the first entry reported a zero count, so nothing was measured

  .section .text.init,"ax",@progbits
  .globl _start
  .align 2
_start:
  li      a0, 0
  la      t0, trap_handler
  csrw    mtvec, t0
  li      t0, 4
  csrw    sctrdepth, t0

  li      s2, 200
warm_loop:
  jal     ra, callee
  addi    s2, s2, -1
  bnez    s2, warm_loop

  csrw    sctrstatus, zero
  li      t0, 4                       # mctrctl.M
  csrw    mctrctl, t0

  # First pair with a short gap, then a second pair with sixteen more
  # instructions in between. Comparing the two counts checks the counter
  # without depending on any constant offset in how cycles are accounted.
  jal     ra, callee
  jal     ra, callee                  # short gap, becomes entry 1 later
  .rept 16
  nop
  .endr
  jal     ra, callee                  # long gap, entry 0
  csrw    mctrctl, zero

  # Every call also produces a return, so the newest entry is the trailing
  # return, entry 1 is the long gap call and entry 3 the short gap one
  li      t0, 0x201
  csrw    siselect, t0
  csrr    t1, sireg3

  srli    t2, t1, 15
  andi    t2, t2, 1
  beqz    t2, bad_ccv                 # CCV

  srli    t2, t1, 28
  andi    t2, t2, 0xf
  bnez    t2, bad_cce                 # CCE must be zero for such a small gap

  srli    t2, t1, 16
  li      t3, 0xfff
  and     s5, t2, t3                  # CCM of the long gap

  # the short gap call
  li      t0, 0x203
  csrw    siselect, t0
  csrr    t1, sireg3
  srli    t2, t1, 16
  li      t3, 0xfff
  and     s6, t2, t3                  # CCM of the short gap
  beqz    s6, bad_first

  # the long gap has to exceed the short one by exactly the sixteen nops
  sub     t2, s5, s6
  li      t3, 16
  bne     t2, t3, bad_ccm

  li      a0, 0
  j       exit_htif

  .align 2
callee:
  ret

bad_ccv:
  li      a0, 1
  j       exit_htif
bad_cce:
  li      a0, 2
  j       exit_htif
bad_ccm:
  addi    a0, t2, 100
  j       exit_htif
bad_first:
  li      a0, 4
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
