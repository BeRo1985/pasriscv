# An HS-level interrupt is always taken while V=1, sstatus.SIE of the host and vsstatus.SIE of
# the guest do not block it (the old code let vsstatus.SIE=0 of the guest block the host)
# expect: a0=8000000000000001 a1=0000000000000003 a2=0000000000000001 a3=0000000000000000 a4=0000000000000000
#include "head.inc"
  li t0, 0x2
  csrw mideleg, t0              # SSI to HS-mode
  csrs mie, t0
  csrs mip, t0                  # SSIP pending
  csrw vsstatus, zero           # vsstatus.SIE=0
  csrci mstatus, 2              # sstatus.SIE=0 of the host
  lla t0, hs_trap
  csrw stvec, t0
  GSTAGE_IDENTITY
  ENTER_VS guest
guest:
  nop
  li a3, 0xdead
  j done
hs_trap:
  csrr a0, scause
  csrr t0, hstatus
  srli a1, t0, 7                # SPV and SPVP
  andi a1, a1, 3
  srli a4, t0, 6                # GVA
  andi a4, a4, 1
  csrr t0, sstatus
  srli a2, t0, 8                # SPP
  andi a2, a2, 1
  j done
#include "tail.inc"
