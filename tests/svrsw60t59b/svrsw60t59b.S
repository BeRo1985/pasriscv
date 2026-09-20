# Svrsw60t59b: PTE bits 60:59 are reserved for supervisor software and must be
# ignored by the implementation, while bit 58 must still be rejected as reserved.
#
# The test identity maps a single Sv39 gigapage covering the whole test image
# (code, page table, tohost and data all live inside 0x80000000..0xC0000000),
# then enters S-mode through that mapping twice:
#
#   phase 0: leaf PTE has bits 60 and 59 set   -> must NOT fault
#   phase 1: leaf PTE has bit 58 set           -> MUST fault
#
# Phase 1 is the counter check. Without it, simply clearing too much of the
# reserved mask would still let phase 0 pass and the test would prove nothing.
#
# Result is reported riscv-tests style: a0 holds 0 on success or the failing
# subtest id, then a write to tohost terminates the run.
#
#   a0 = 0           all good
#   a0 = 2           phase 1 did not fault, so bit 58 is no longer being rejected
#   a0 = 3           phase 0 read back the wrong data through the mapping
#   a0 = 1000+mcause phase 0 trapped instead of running, mcause tells why.
#                    1012 means an instruction page fault, so bits 60:59 are
#                    still treated as reserved. 1001 means an access fault,
#                    which points at PMP setup rather than the page walk.

  .section .text.init,"ax",@progbits
  .globl _start
  .align 2
_start:
  li      a0, 0                   # result, 0 means pass
  li      s0, 0                   # phase, kept across the M/S mode switches

  csrw    medeleg, zero           # keep every trap in M-mode
  la      t0, m_trap
  csrw    mtvec, t0

  # A hart that implements PMP denies every S/U-mode access that matches no
  # PMP entry, so grant the whole address space before ever leaving M-mode.
  # Without this the S-mode fetch below dies with an access fault (mcause 1)
  # long before the page walk is even reached.
  li      t0, -1
  csrw    pmpaddr0, t0
  li      t0, 0x1f                # NAPOT, R W X
  csrw    pmpcfg0, t0

  li      t1, 3
  slli    t1, t1, 59              # PTE bits 60:59, the Svrsw60t59b software bits
  j       build_and_enter

# Builds the root page table with t1 OR'ed into the leaf PTE, turns on Sv39 and
# drops into S-mode at s_entry. M-mode ignores satp, so this runs on physical
# addresses no matter what satp currently holds.
  .align 2
build_and_enter:
  la      t0, root_pt
  li      t2, 0x80000             # PPN of 0x80000000, gigapage aligned
  slli    t2, t2, 10
  li      t3, 0xcf                # V R W X A D
  or      t2, t2, t3
  or      t2, t2, t1
  sd      t2, 16(t0)              # VPN[2] of 0x80000000 is 2, so byte offset 16
  sfence.vma

  la      t0, root_pt
  srli    t0, t0, 12
  li      t1, 8
  slli    t1, t1, 60              # Sv39
  or      t0, t0, t1
  csrw    satp, t0
  sfence.vma

  li      t0, 3
  slli    t0, t0, 11
  csrc    mstatus, t0             # clear MPP
  li      t0, 1
  slli    t0, t0, 11
  csrs    mstatus, t0             # MPP = S-mode

  la      t0, s_entry
  csrw    mepc, t0
  mret

# Reached only when the mapping is accepted. Getting here at all already proves
# the instruction fetch walked the PTE without faulting.
  .align 2
s_entry:
  la      t0, testdata
  ld      t1, 0(t0)
  li      t2, 0x5aa55aa5
  bne     t1, t2, s_bad_data
  ecall                           # hand control back to M-mode

s_bad_data:
  li      a0, 3
  j       exit_htif

  .align 2
m_trap:
  csrr    t0, mcause
  bnez    s0, m_phase1

# Phase 0 expects the S-mode ecall and nothing else. Any fault here means the
# implementation still rejects bits 60:59.
m_phase0:
  li      t1, 9                   # environment call from S-mode
  bne     t0, t1, m_phase0_faulted
  li      s0, 1
  csrw    satp, zero              # back to physical addressing for the rebuild
  sfence.vma
  li      t1, 1
  slli    t1, t1, 58              # a genuinely reserved bit
  j       build_and_enter

m_phase0_faulted:
  csrr    a0, mcause
  addi    a0, a0, 1000
  j       exit_htif

# Phase 1 expects a page fault on the S-mode instruction fetch, since the code
# page itself is mapped through the now invalid PTE.
m_phase1:
  li      t1, 12                  # instruction page fault
  beq     t0, t1, m_phase1_ok
  li      t1, 13                  # load page fault, equally acceptable
  beq     t0, t1, m_phase1_ok
  li      a0, 2
  j       exit_htif

m_phase1_ok:
  li      a0, 0
  j       exit_htif

  .align 2
exit_htif:
  la      t0, tohost
  li      t1, 1                   # bit 0 set terminates the run
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

  .section .pagetables,"aw",@progbits
  .align 12
root_pt:
  .zero 4096

  .section .data
  .align 3
testdata:
  .dword 0x5aa55aa5
