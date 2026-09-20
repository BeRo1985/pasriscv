# With mtvec/stvec in vectored mode (MODE=1) synchronous exceptions go to BASE, only
# interrupts go to BASE+4*cause. The vector tables send entry 0 to the exception handler, entry 1
# to the SSI handler and every other entry to a handler that marks the wrong vector in a2/a4.
# expect: a0=000000000000000B a1=8000000000000001 a2=0000000000000000 a3=0000000000000008 a4=0000000000000000
#include "head.inc"
  lla t0, mvtab
  ori t0, t0, 1
  csrw mtvec, t0
  # M-mode ecall (cause 11): entry 0
  ecall
  # M-level supervisor software interrupt (cause 1, not delegated): entry 1
  li t0, 2
  csrs mie, t0
  csrs mip, t0
  csrsi mstatus, 8
  nop
  csrci mstatus, 8
  csrc mie, t0
  # U-mode ecall (cause 8) delegated to S-mode with stvec vectored: entry 0 of the S table
  lla t0, mtrap
  csrw mtvec, t0
  lla t0, svtab
  ori t0, t0, 1
  csrw stvec, t0
  li t0, 0x100
  csrs medeleg, t0
  ENTER_U u1
u1:
  ecall
  # back from the S handler: to M-mode for the end (an illegal instruction is not delegated)
  lla s8, m1
  csrr t0, mstatus
m1:
  csrw medeleg, zero
  j done

  .balign 256
mvtab:
  j mexc
  j mssi
  .rept 14
  j mbad
  .endr
mexc:
  csrr a0, mcause
  csrr t6, mepc
  addi t6, t6, 4
  csrw mepc, t6
  mret
mssi:
  csrr a1, mcause
  li t6, 2
  csrc mip, t6
  mret
mbad:
  li a2, 0xbad
  csrr t6, mcause
  bltz t6, 1f
  csrr t6, mepc
  addi t6, t6, 4
  csrw mepc, t6
1:
  li t6, 2
  csrc mip, t6
  mret

  .balign 256
svtab:
  j sexc
  .rept 15
  j sbad
  .endr
sexc:
  csrr a3, scause
  csrr t6, sepc
  addi t6, t6, 4
  csrw sepc, t6
  li t6, 0x100
  csrc sstatus, t6
  sret
sbad:
  li a4, 0xbad
  csrr t6, sepc
  addi t6, t6, 4
  csrw sepc, t6
  sret
#include "tail.inc"
