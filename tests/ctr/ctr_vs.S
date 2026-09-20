# Smctr: recording in VS-mode is governed by vsctrctl, not by mctrctl. The test
# runs the identical VS-mode sequence twice, once with vsctrctl clear while
# mctrctl.S is set, where nothing may be recorded, and once the other way round,
# where everything must be. That is exactly the branch in UpdateCTRState which
# picks vsctrctl while V=1.
#
#   a0 = 0    everything matched
#   a0 = 1    VS recorded although only mctrctl.S was set
#   a0 = 2    VS did not record although vsctrctl.S was set
#   a0 = 3    the entry is not a direct call
#   a0 = 4    the entry does not point at the call

  .section .text.init,"ax",@progbits
  .globl _start
  .align 2
_start:
  li      a0, 0
  la      t0, m_trap
  csrw    mtvec, t0
  li      t0, 4
  csrw    sctrdepth, t0

  li      t0, -1
  csrw    pmpaddr0, t0
  li      t0, 0x1f
  csrw    pmpcfg0, t0

  # Identity map one gigapage for the VS stage, G stage stays bare
  la      t0, root_pt
  li      t2, 0x80000
  slli    t2, t2, 10
  li      t3, 0xcf                # V R W X A D
  or      t2, t2, t3
  sd      t2, 16(t0)              # VPN[2] of 0x80000000 is 2
  sfence.vma
  la      t0, root_pt
  srli    t0, t0, 12
  li      t1, 8
  slli    t1, t1, 60              # Sv39
  or      t0, t0, t1
  csrw    vsatp, t0
  csrw    hgatp, zero
  sfence.vma

  # Round 1: only mctrctl.S, which governs HS-mode and must not reach VS
  li      s5, 0
  li      t0, 2                   # mctrctl.S
  csrw    mctrctl, t0
  csrw    vsctrctl, zero
  csrw    sctrstatus, zero
  jal     ra, enter_vs
  csrr    t0, sctrstatus
  andi    t0, t0, 0xff
  bnez    t0, bad_recorded

  # Round 2: the other way round
  li      s5, 1
  csrw    mctrctl, zero
  li      t0, 2                   # vsctrctl.S
  csrw    vsctrctl, t0
  csrw    sctrstatus, zero
  jal     ra, enter_vs
  csrw    vsctrctl, zero

  csrr    t0, sctrstatus
  andi    t0, t0, 0xff
  beqz    t0, bad_nothing

  # newest is the return of the VS call, before it the call itself
  li      t0, 0x201
  csrw    siselect, t0
  csrr    t1, sireg3
  andi    t1, t1, 0xf
  li      t2, 9                   # direct call
  bne     t1, t2, bad_type
  csrr    t3, sireg
  la      t4, vs_call
  ori     t4, t4, 1
  bne     t3, t4, bad_source

  li      a0, 0
  j       exit_htif

# Drops into VS-mode: MPP = S plus MPV, which is mstatus bit 39
  .align 2
enter_vs:
  mv      s6, ra
  la      t0, vs_entry
  csrw    mepc, t0
  li      t0, 3
  slli    t0, t0, 11
  csrc    mstatus, t0
  li      t0, 1
  slli    t0, t0, 11
  csrs    mstatus, t0             # MPP = S
  li      t0, 1
  slli    t0, t0, 39
  csrs    mstatus, t0             # MPV = 1
  mret

  .align 2
vs_entry:
vs_call:
  jal     ra, vs_callee
  ecall

  .align 2
vs_callee:
  ret

  .align 2
m_trap:
  csrr    t0, mcause
  li      t1, 10                  # environment call from VS-mode
  bne     t0, t1, m_unexpected
  li      t0, 1
  slli    t0, t0, 39
  csrc    mstatus, t0             # leave the virtual world again
  mv      ra, s6
  ret

m_unexpected:
  csrr    a0, mcause
  slli    a0, a0, 16
  csrr    t2, mepc
  la      t3, _start
  sub     t2, t2, t3
  or      a0, a0, t2
  li      t3, 100000
  add     a0, a0, t3
  j       exit_htif

bad_recorded:
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

  .align 2
exit_htif:
  la      t0, tohost
  li      t1, 1
  sd      t1, 0(t0)
1:
  j       1b

  .section .pagetables,"aw",@progbits
  .align 12
root_pt:
  .zero 4096

  .section .tohost,"aw",@progbits
  .align 6
  .globl tohost
tohost:
  .dword 0
  .align 6
  .globl fromhost
fromhost:
  .dword 0
