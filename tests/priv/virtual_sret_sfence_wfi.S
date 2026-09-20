# sret, sfence.vma and wfi from VU-mode always raise a virtual-instruction exception (22),
# from VS-mode with hstatus.VTSR, VTVM and VTW. mstatus.TW=1 makes wfi below M-mode an illegal
# instruction (2), also with V=1 (TW before VTW). With TW=0 wfi waits in M-, HS- and VS-mode
# (here it returns at once: a VS software interrupt is pending and enabled in mie, but not taken
# as vsstatus.SIE=0), and is an illegal instruction in U-mode.
# expect: a0=0000000000161616 a1=0000000000161616 a2=0000000002020202 a3=0000000000000200
#include "head.inc"
  GSTAGE_IDENTITY
  # A wrongly executed sret continues at the next probe
  lla t0, vs1_after
  csrw vsepc, t0
  # hstatus: VTSR, VTW, VTVM
  li t0, 0x700000
  csrs hstatus, t0
  ENTER_VS vs1
vs1:
  PROBE8 a0, sret
vs1_after:
  PROBE8 a0, sfence.vma
  PROBE8 a0, wfi
  TO_M m1
m1:
  li t0, 0x700000
  csrc hstatus, t0
  lla t0, vu1_after
  csrw vsepc, t0
  ENTER_VU vu1
vu1:
  PROBE8 a1, sret
vu1_after:
  PROBE8 a1, sfence.vma
  PROBE8 a1, wfi
  TO_M m2
m2:
  # mstatus.TW
  li t0, 1 << 21
  csrs mstatus, t0
  ENTER_VS vs2
vs2:
  PROBE8 a2, wfi
  SRET_U vu2
vu2:
  PROBE8 a2, wfi
  TO_M m3
m3:
  ENTER_HS hs1
hs1:
  PROBE8 a2, wfi
  SRET_U u1
u1:
  PROBE8 a2, wfi
  TO_M m4
m4:
  li t0, 1 << 21
  csrc mstatus, t0
  # VSSIP pending (hvip), enabled in mie and delegated to VS-mode, vsstatus.SIE=0
  li t0, 4
  csrs hideleg, t0
  csrs mie, t0
  csrs hvip, t0
  li t0, 2
  csrc vsstatus, t0
  PROBE8 a3, wfi
  ENTER_HS hs2
hs2:
  PROBE8 a3, wfi
  SRET_U u2
u2:
  PROBE8 a3, wfi
  TO_M m5
m5:
  ENTER_VS vs3
vs3:
  PROBE8 a3, wfi
  TO_M m6
m6:
  li t0, 4
  csrc hvip, t0
  j done
#include "tail.inc"
