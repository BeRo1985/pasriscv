# Smctr/Ssctr: verify that control transfers actually land in the CTR ring buffer
# with the right source, target and type, rather than only checking that nothing
# crashes when recording is switched on.
#
# Runs in M-mode with mctrctl.M set, so every transfer in this program is recorded.
# The buffer is then read back through the indirect interface: siselect 0x200+N
# selects the Nth most recent entry, sireg/sireg2/sireg3 give its ctrsource,
# ctrtarget and ctrdata.
#
# Recorded sequence, oldest to newest, once recording is armed:
#   1. jal ra, target      -> direct call    (9)
#   2. jalr x0, 0(ra)      -> return        (13)
#   3. beq  taken          -> taken branch   (5)
#
# so entry 0 is the branch, entry 1 the return and entry 2 the call.
#
#   a0 = 0    everything matched
#   a0 = 1    sctrdepth did not read back as written
#   a0 = 2    entry 0 has the wrong type      (expected taken branch)
#   a0 = 3    entry 1 has the wrong type      (expected return)
#   a0 = 4    entry 2 has the wrong type      (expected direct call)
#   a0 = 5    entry 2 source is not the jal   (source or valid bit wrong)
#   a0 = 6    entry 2 target is not the callee
#   a0 = 7    entry 1 target is not the return address
#   a0 = 8    nothing was recorded at all     (write pointer still zero)
#   a0 = 9    recording happened while disabled

  .section .text.init,"ax",@progbits
  .globl _start
  .align 2
_start:
  li      a0, 0

  # Any unexpected trap reports its cause instead of looping forever
  la      t0, trap_handler
  csrw    mtvec, t0

  # 256 entries, so the write pointer counts plainly upwards for this test
  li      t0, 4
  csrw    sctrdepth, t0
  csrr    t1, sctrdepth
  bne     t0, t1, bad_depth

  csrw    sctrstatus, zero

  # Nothing may be recorded while every enable bit is still clear
  jal     ra, dummy
  csrr    t0, sctrstatus
  andi    t0, t0, 0xff
  bnez    t0, bad_disabled

  # Arm recording for M-mode
  li      t0, 4                   # mctrctl.M, bit 2
  csrw    mctrctl, t0

recorded_call:
  jal     ra, callee              # entry 2 once all three are in
recorded_branch:
  li      t0, 1
  li      t1, 1
  beq     t0, t1, after_branch    # entry 0
  j       fail_unreachable
after_branch:

  # Stop recording before touching the buffer, so the reads themselves do not
  # push the interesting entries out
  csrw    mctrctl, zero

  csrr    t0, sctrstatus
  andi    t0, t0, 0xff
  beqz    t0, bad_nothing

  # entry 0: the taken branch
  li      t0, 0x200
  csrw    siselect, t0
  csrr    t1, sireg3
  andi    t1, t1, 0xf
  li      t2, 5                   # taken branch
  bne     t1, t2, bad_type0

  # entry 1: the return
  li      t0, 0x201
  csrw    siselect, t0
  csrr    t1, sireg3
  andi    t1, t1, 0xf
  li      t2, 13                  # return
  bne     t1, t2, bad_type1
  csrr    t3, sireg2              # its target is the instruction after the call
  la      t4, recorded_branch
  bne     t3, t4, bad_ret_target

  # entry 2: the call
  li      t0, 0x202
  csrw    siselect, t0
  csrr    t1, sireg3
  andi    t1, t1, 0xf
  li      t2, 9                   # direct call
  bne     t1, t2, bad_type2
  csrr    t3, sireg                # source, with the valid bit in bit 0
  la      t4, recorded_call
  ori     t4, t4, 1
  bne     t3, t4, bad_src2
  csrr    t3, sireg2               # target
  la      t4, callee
  bne     t3, t4, bad_tgt2

  li      a0, 0
  j       exit_htif

  .align 2
callee:
  ret                             # jalr x0, 0(ra), recorded as a return

  .align 2
dummy:
  ret

fail_unreachable:
  li      a0, 10
  j       exit_htif
bad_depth:
  li      a0, 1
  j       exit_htif
bad_type0:
  li      a0, 2
  j       exit_htif
bad_type1:
  li      a0, 3
  j       exit_htif
bad_type2:
  li      a0, 4
  j       exit_htif
bad_src2:
  li      a0, 5
  j       exit_htif
bad_tgt2:
  li      a0, 6
  j       exit_htif
bad_ret_target:
  li      a0, 7
  j       exit_htif
bad_nothing:
  li      a0, 8
  j       exit_htif
bad_disabled:
  li      a0, 9
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
