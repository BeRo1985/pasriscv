# Smctr: SCTRCLR and RASEMU.
#
# RASEMU turns the buffer into a return address stack: calls push as usual, a
# return pops the most recent call by stepping the write pointer back and
# clearing that entry's ctrsource.V, and everything that is neither a call nor a
# return nor a co-routine swap is inhibited outright.
#
# The sequence below, with recording armed and RASEMU set, is
#   jal ra, callee   -> push,  WRPTR 0 -> 1
#   ret              -> pop,   WRPTR 1 -> 0, entry 0 invalidated
#   beq taken        -> inhibited, nothing happens
# so the write pointer has to end up back at zero.
#
#   a0 = 0   everything matched
#   a0 = 1   sctrclr did not clear the entries
#   a0 = 2   sctrclr did not reset the write pointer
#   a0 = 3   the call did not push
#   a0 = 4   the return did not pop back to zero
#   a0 = 5   the popped entry still has its valid bit set
#   a0 = 6   the inhibited branch moved the write pointer after all

  .section .text.init,"ax",@progbits
  .globl _start
  .align 2
_start:
  li      a0, 0
  la      t0, trap_handler
  csrw    mtvec, t0

  li      t0, 4
  csrw    sctrdepth, t0

  # Warm the sequence so the JIT compiles it, recording still off
  li      s2, 200
warm_loop:
  jal     ra, callee
  li      t0, 1
  li      t1, 1
  beq     t0, t1, warm_next
  j       fail_unreachable
warm_next:
  addi    s2, s2, -1
  bnez    s2, warm_loop

  # Record a few entries plainly, then check that sctrclr wipes them
  li      t0, 4                   # mctrctl.M
  csrw    mctrctl, t0
  jal     ra, callee
  csrw    mctrctl, zero

  .word   0x10400073              # sctrclr, the slot formerly held by sfence.vm

  li      t0, 0x200
  csrw    siselect, t0
  csrr    t1, sireg
  bnez    t1, bad_clear
  csrr    t1, sireg2
  bnez    t1, bad_clear
  csrr    t1, sireg3
  bnez    t1, bad_clear
  csrr    t1, sctrstatus
  andi    t1, t1, 0xff
  bnez    t1, bad_clear_ptr

  # Now with RASEMU on top of the M-mode enable
  li      t0, 0x84                # mctrctl.M | mctrctl.RASEMU (bit 7)
  csrw    mctrctl, t0

  jal     ra, callee              # push
  csrr    s3, sctrstatus          # sampled after the pop that ret performs
  li      t0, 1
  li      t1, 1
  beq     t0, t1, ras_after       # inhibited under RASEMU
ras_after:
  csrr    s4, sctrstatus
  csrw    mctrctl, zero

  # The return already popped, so the pointer is back at zero
  andi    s3, s3, 0xff
  bnez    s3, bad_pop
  # and the inhibited branch must not have moved it
  andi    s4, s4, 0xff
  bnez    s4, bad_inhibited

  # The popped entry must have lost its valid bit
  li      t0, 0x200
  csrw    siselect, t0
  csrr    t1, sireg
  andi    t1, t1, 1
  bnez    t1, bad_valid

  li      a0, 0
  j       exit_htif

  .align 2
callee:
  ret

fail_unreachable:
  li      a0, 10
  j       exit_htif
bad_clear:
  li      a0, 1
  j       exit_htif
bad_clear_ptr:
  li      a0, 2
  j       exit_htif
bad_push:
  li      a0, 3
  j       exit_htif
bad_pop:
  li      a0, 4
  j       exit_htif
bad_valid:
  li      a0, 5
  j       exit_htif
bad_inhibited:
  li      a0, 6
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
