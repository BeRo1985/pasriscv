# Simultaneous interrupts for the same mode are taken in the order MEI, MSI, MTI, SEI, SSI,
# STI, SGEI, VSEI, VSSI, VSTI, LCOFI, not by the highest bit number
# expect: a2=8000000000000003 a0=8000000000000001 a1=8000000000000001
#include "head.inc"
  # MSI (ACLINT msip) and MTI (mtimecmp=0) together: MSI first
  lla t0, mirq
  csrw mtvec, t0
  li t0, 0x02000000
  li t1, 1
  sw t1, 0(t0)                  # msip
  li t0, 0x02004000
  sd zero, 0(t0)                # mtimecmp=0
  li t0, 0x88
  csrw mie, t0
  lla s7, part2
  csrsi mstatus, 8
1: j 1b
mirq:
  csrci mstatus, 8
  csrr a4, mcause
  csrw mie, zero
  li t0, 0x02000000
  sw zero, 0(t0)
  li t0, 0x02004000
  li t1, -1
  sd t1, 0(t0)
  jr s7
part2:
  mv a2, a4
  # SSI and STI (software-writable mip bits) together in M-mode: SSI first
  lla s7, part3
  li t0, 0x22
  csrw mie, t0
  csrs mip, t0
  csrsi mstatus, 8
1: j 1b
part3:
  mv a0, a4
  csrw mip, zero
  lla t0, mtrap
  csrw mtvec, t0
  # VSSI and VSTI (hvip) together in VS-mode: VSSI first, seen as SSI
  li t0, 0x44
  csrw hideleg, t0
  csrw hvip, t0
  csrw mie, t0
  lla t0, vs_trap
  csrw vstvec, t0
  li t0, 2
  csrw vsstatus, t0
  GSTAGE_IDENTITY
  ENTER_VS guest
guest:
  nop
  j done
vs_trap:
  csrr a1, scause
  j done
#include "tail.inc"
