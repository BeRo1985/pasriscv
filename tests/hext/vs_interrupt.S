# A VS-level interrupt (hvip.VSSIP) delegated through hideleg is taken in VS-mode with the
# S-level cause (VSSI 2 becomes SSI 1); hip/mip show VSSIP, vsip/sip at V=1 show it as SSIP, and
# mideleg has the VS-level interrupts and SGEI read-only one
# expect: a0=0000000000000004 a1=0000000000000004 a2=0000000000001444 a3=0000000000000000 a4=8000000000000001 a5=0000000000000002 a6=0000000000000002 a7=0000000000000002
#include "head.inc"
  li t0, 0x4
  csrw hideleg, t0              # VSSI to VS-mode
  csrw hvip, t0                 # VSSIP pending
  csrs mie, t0                  # VSSIE
  csrr a0, hip
  csrr a1, mip
  csrr a2, mideleg
  csrr a7, vsip
  lla t0, vs_trap
  csrw vstvec, t0
  li t0, 2
  csrw vsstatus, t0             # vsstatus.SIE=1
  GSTAGE_IDENTITY
  ENTER_VS guest
guest:
  nop
  li a3, 0xdead                 # not reached before the interrupt
  j done
vs_trap:
  csrr a4, scause
  csrr a5, sip
  csrr a6, sie
  j done
#include "tail.inc"
