# Smctr: trap recording, the MTE gate, and traps out of natively compiled blocks.
#
# Recording is armed for S-mode only, with mctrctl.M deliberately clear. A trap
# from S-mode into M-mode is then only recorded because MTE is set, which is
# exactly what that bit is for. The trapping sequence is run hot beforehand, so
# the block it sits in is natively compiled and the trap leaves JIT code.
#
#   a0 = 0    everything matched
#   a0 = 1    the trap was recorded although MTE was clear
#   a0 = 2    nothing was recorded with MTE set
#   a0 = 3    the entry is not of type exception
#   a0 = 4    the entry does not point at the ecall
#   a0 = 5    the target is not the trap vector

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
  li      t0, 1
  slli    t0, t0, 54
  csrw    mstateen0, t0           # let S-mode reach the CTR state

  la      t0, root_pt
  li      t2, 0x80000
  slli    t2, t2, 10
  li      t3, 0xcf
  or      t2, t2, t3
  sd      t2, 16(t0)
  sfence.vma
  la      t0, root_pt
  srli    t0, t0, 12
  li      t1, 8
  slli    t1, t1, 60
  or      t0, t0, t1
  csrw    satp, t0
  sfence.vma

  # Round 1: S-mode recording on, MTE clear, so the trap must not be recorded
  li      s5, 0
  # S-mode recording with taken branches inhibited, bit 37, so the warm up
  # loop below does not fill the buffer and only the trap can show up
  li      t0, 1
  slli    t0, t0, 37              # TKBRINH
  ori     t0, t0, 2               # plus mctrctl.S
  csrw    mctrctl, t0
  csrw    sctrstatus, zero
  jal     ra, enter_supervisor
  csrr    t0, sctrstatus
  andi    t0, t0, 0xff
  bnez    t0, bad_recorded_without_mte

  # Round 2: same, but with MTE, bit 9
  li      s5, 1
  li      t0, 1
  slli    t0, t0, 37              # TKBRINH
  li      t1, 1
  slli    t1, t1, 9               # MTE
  or      t0, t0, t1
  ori     t0, t0, 2               # plus mctrctl.S
  csrw    mctrctl, t0
  csrw    sctrstatus, zero
  jal     ra, enter_supervisor
  csrw    mctrctl, zero

  csrr    t0, sctrstatus
  andi    t0, t0, 0xff
  beqz    t0, bad_nothing

  # M-mode does not record here, so the trap is the only entry there is
  li      t0, 0x200
  csrw    siselect, t0
  csrr    t1, sireg3
  andi    t1, t1, 0xf
  li      t2, 1                   # exception
  bne     t1, t2, bad_type
  csrr    t3, sireg
  la      t4, s_ecall
  ori     t4, t4, 1
  bne     t3, t4, bad_source
  csrr    t3, sireg2
  la      t4, m_trap
  bne     t3, t4, bad_target

  li      a0, 0
  j       exit_htif

# Drops into S-mode, which runs the hot loop and then traps back with ecall
  .align 2
enter_supervisor:
  mv      s6, ra
  la      t0, s_entry
  csrw    mepc, t0
  li      t0, 3
  slli    t0, t0, 11
  csrc    mstatus, t0
  li      t0, 1
  slli    t0, t0, 11
  csrs    mstatus, t0
  mret

  .align 2
s_entry:
  # Warm this block so the ecall below leaves natively compiled code
  li      s2, 200
s_warm:
  addi    s2, s2, -1
  bnez    s2, s_warm
s_ecall:
  ecall

  .align 2
m_trap:
  csrr    t0, mcause
  li      t1, 9                   # ecall from S-mode
  bne     t0, t1, m_unexpected
  mv      ra, s6
  ret                             # back into the M-mode caller

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

bad_recorded_without_mte:
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
