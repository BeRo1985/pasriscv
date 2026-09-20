# Smctr: BPFRZ freezing and the Smstateen gate.
#
# Part 1: with mctrctl.BPFRZ set, a breakpoint exception that traps to M-mode
#         has to set sctrstatus.FROZEN, and a frozen buffer must stop recording.
# Part 2: bit 54 of mstateen0 gates the CTR CSRs for everything below M-mode.
#         S-mode access has to trap while the bit is clear and work once it is set.
#
#   a0 = 0    everything matched
#   a0 = 1    FROZEN was not set by the breakpoint
#   a0 = 2    the frozen buffer kept recording
#   a0 = 3    S-mode reached the CSR although mstateen0.CTR was clear
#   a0 = 4    S-mode was refused although mstateen0.CTR was set
#   a0 = 5    the breakpoint did not trap at all

  .section .text.init,"ax",@progbits
  .globl _start
  .align 2
_start:
  li      a0, 0
  la      t0, m_trap
  csrw    mtvec, t0
  li      t0, 4
  csrw    sctrdepth, t0
  csrw    sctrstatus, zero

  # Grant the whole address space, otherwise S-mode cannot fetch at all
  li      t0, -1
  csrw    pmpaddr0, t0
  li      t0, 0x1f
  csrw    pmpcfg0, t0

  # Part 1: recording on with BPFRZ, bit 11
  li      t0, 1
  slli    t0, t0, 11
  ori     t0, t0, 4               # plus mctrctl.M
  csrw    mctrctl, t0

  li      s2, 0                   # phase
  ebreak
  # the handler returns here
  li      t1, 5
  beq     s2, t1, bad_no_trap

  csrr    t0, sctrstatus
  srli    t1, t0, 31
  andi    t1, t1, 1
  beqz    t1, bad_not_frozen

  # A frozen buffer must not record any more
  csrr    s3, sctrstatus
  jal     ra, callee
  csrr    s4, sctrstatus
  andi    s3, s3, 0xff
  andi    s4, s4, 0xff
  bne     s3, s4, bad_still_recording

  csrw    mctrctl, zero
  csrw    sctrstatus, zero

  # Identity map one Sv39 gigapage so S-mode can execute at all
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
  csrw    satp, t0
  sfence.vma

  # Part 2: S-mode access with mstateen0.CTR clear
  csrw    mstateen0, zero
  li      s2, 1
  la      t0, s_probe
  csrw    mepc, t0
  li      t0, 3
  slli    t0, t0, 11
  csrc    mstatus, t0
  li      t0, 1
  slli    t0, t0, 11
  csrs    mstatus, t0             # MPP = S
  mret

back_from_denied:
  # Now with the bit set, the same access has to succeed
  li      t0, 1
  slli    t0, t0, 54
  csrw    mstateen0, t0
  li      s2, 2
  la      t0, s_probe
  csrw    mepc, t0
  li      t0, 3
  slli    t0, t0, 11
  csrc    mstatus, t0
  li      t0, 1
  slli    t0, t0, 11
  csrs    mstatus, t0
  mret

  .align 2
s_probe:
  csrr    t1, sctrstatus          # traps while the stateen bit is clear
  ecall                           # reached only when the access was allowed

  .align 2
callee:
  ret

  .align 2
m_trap:
  csrr    t0, mcause
  li      t1, 3                   # breakpoint
  beq     t0, t1, trap_breakpoint
  li      t1, 2                   # illegal instruction, the denied probe
  beq     t0, t1, trap_illegal
  li      t1, 9                   # ecall from S-mode, the allowed probe
  beq     t0, t1, trap_ecall
  csrr    a0, mcause
  slli    a0, a0, 16
  csrr    t2, mepc
  la      t3, _start
  sub     t2, t2, t3
  or      a0, a0, t2
  li      t3, 100000
  add     a0, a0, t3
  j       exit_htif

trap_breakpoint:
  csrr    t0, mepc
  addi    t0, t0, 4
  csrw    mepc, t0
  mret

trap_illegal:
  # only expected in phase 1
  li      t1, 1
  bne     s2, t1, bad_denied_late
  j       back_from_denied

trap_ecall:
  # only expected in phase 2
  li      t1, 2
  bne     s2, t1, bad_allowed_early
  li      a0, 0
  j       exit_htif

bad_not_frozen:
  li      a0, 1
  j       exit_htif
bad_still_recording:
  li      a0, 2
  j       exit_htif
bad_allowed_early:
  li      a0, 3
  j       exit_htif
bad_denied_late:
  li      a0, 4
  j       exit_htif
bad_no_trap:
  li      a0, 5
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
