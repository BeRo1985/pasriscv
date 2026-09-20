# Zicfiss gating without paging. M-mode always reaches ssp (bits 2:0 read-only zero), and
# ssamoswap at an effective M-mode is a store/AMO access fault (7). With menvcfg.SSE=0 the
# senvcfg.SSE and henvcfg.SSE fields are read-only zero, ssp and ssamoswap are illegal
# instructions (2) in S-mode (also a misaligned ssamoswap, the enables come first) and sspush,
# sspopchk and ssrdp are Zimop (ssrdp writes zero). With menvcfg.SSE=1 S-mode reaches ssp, and
# every shadow stack access with satp Bare is a store/AMO access fault. U-mode needs senvcfg.SSE
# as well (else illegal instruction, sspush a Zimop).
# expect: a0=0000000000001008 a1=0000000000000000 a2=0000000007020202 a3=0000000000000000 s0=0000000000000008 a5=0000000000070707 s1=0000000000001008 a6=0000000000020200 a7=0000000000000007
#include "head.inc"
  li t0, 0x100f
  csrw ssp, t0
  csrr a0, ssp
  li t0, 8
  csrs senvcfg, t0
  csrs henvcfg, t0
  csrr t1, senvcfg
  csrr t2, henvcfg
  or t1, t1, t2
  andi a1, t1, 8
  lla a4, ssdata
  li t1, 0x77
  PROBE8 a2, ssamoswap.d t0, t1, (a4)
  # S-mode, menvcfg.SSE=0
  ENTER_HS s1
s1:
  PROBE8 a2, csrr t0, ssp
  PROBE8 a2, ssamoswap.d t0, t1, (a4)
  addi t2, a4, 4
  PROBE8 a2, ssamoswap.d t0, t1, (t2)
  li a3, 0x55
  PROBE8 a3, ssrdp a3
  PROBE8 a3, sspush ra
  PROBE8 a3, sspopchk t0
  TO_M m1
m1:
  li t0, 8
  csrs menvcfg, t0
  csrs senvcfg, t0
  csrr t1, senvcfg
  andi s0, t1, 8
  csrc senvcfg, t0
  # S-mode, menvcfg.SSE=1, satp Bare
  ENTER_HS s2
s2:
  PROBE8 a5, csrr t0, ssp
  PROBE8 a5, ssamoswap.d t0, t1, (a4)
  PROBE8 a5, sspush ra
  PROBE8 a5, sspopchk ra
  csrr s1, ssp
  # U-mode, senvcfg.SSE=0
  SRET_U u1
u1:
  PROBE8 a6, csrr t0, ssp
  PROBE8 a6, ssamoswap.d t0, t1, (a4)
  PROBE8 a6, sspush ra
  TO_M m2
m2:
  li t0, 8
  csrs senvcfg, t0
  ENTER_U u2
u2:
  PROBE8 a7, csrr t0, ssp
  PROBE8 a7, ssamoswap.d t0, t1, (a4)
  TO_M m3
m3:
  j done
  .align 3
ssdata:
  .dword 0x1111
#include "tail.inc"
