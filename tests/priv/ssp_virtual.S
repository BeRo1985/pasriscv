# Zicfiss gating with V=1 (menvcfg.SSE=1). With henvcfg.SSE=0 ssp and ssamoswap raise a
# virtual-instruction exception (22) in VS- and VU-mode, and senvcfg.SSE reads as zero with V=1
# while a write there leaves the bit alone. With henvcfg.SSE=1 VS-mode reaches ssp (ssamoswap with
# vsatp Bare is a store/AMO access fault, 7), VU-mode needs senvcfg.SSE as well (else 22).
# expect: a0=0000000000001616 a1=0000000000000000 a2=0000000000001616 s0=0000000000000000 a3=0000000000000007 a4=0000000000001616 a5=0000000000000000
#include "head.inc"
  GSTAGE_IDENTITY
  lla s7, ssdata
  li t1, 0x77
  li t0, 8
  csrs menvcfg, t0
  ENTER_VS vs1
vs1:
  PROBE8 a0, csrr t0, ssp
  PROBE8 a0, ssamoswap.d t0, t1, (s7)
  li t0, 8
  csrs senvcfg, t0
  csrr t2, senvcfg
  andi a1, t2, 8
  SRET_U vu1
vu1:
  PROBE8 a2, csrr t0, ssp
  PROBE8 a2, ssamoswap.d t0, t1, (s7)
  TO_M m1
m1:
  csrr t2, senvcfg
  andi s0, t2, 8
  li t0, 8
  csrs henvcfg, t0
  ENTER_VS vs2
vs2:
  PROBE8 a3, csrr t0, ssp
  PROBE8 a3, ssamoswap.d t0, t1, (s7)
  SRET_U vu2
vu2:
  PROBE8 a4, csrr t0, ssp
  PROBE8 a4, ssamoswap.d t0, t1, (s7)
  TO_M m2
m2:
  li t0, 8
  csrs senvcfg, t0
  ENTER_VU vu3
vu3:
  PROBE8 a5, csrr t0, ssp
  TO_M m3
m3:
  j done
  .align 3
ssdata:
  .dword 0x1111
#include "tail.inc"
