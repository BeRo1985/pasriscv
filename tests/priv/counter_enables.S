# cycle, time, instret and hpmcounter3..31 below M-mode are gated by mcounteren (else an
# illegal-instruction exception, 2), in U-mode also by scounteren (2), with V=1 by hcounteren
# and in VU-mode by scounteren (virtual-instruction exception, 22). A write to them is illegal.
# The counter enables are 32 bits wide, and the RV32 upper halves (cycleh, mcycleh, ...) do not
# exist on RV64, also not for M-mode.
# expect: a0=0000000002020202 a1=0000000000020202 a2=0000000000000202 a3=0000000000000002 a4=0000000000161602 a5=0000000000160016 a6=0000000000020202 a7=00000000FFFFFFFF s0=0000000000001602
#include "head.inc"
  GSTAGE_IDENTITY
  csrw mcounteren, zero
  csrw scounteren, zero
  csrw hcounteren, zero
  # M-mode: its counters regardless of the enables, but no upper halves
  PROBE8 a6, csrr t0, cycle
  PROBE8 a6, csrr t0, 0xc80
  PROBE8 a6, csrr t0, 0xb80
  PROBE8 a6, csrr t0, 0xc83
  li t0, -1
  csrw mcounteren, t0
  csrr a7, mcounteren
  csrw mcounteren, zero
  # S-mode with mcounteren=0
  ENTER_HS s1
s1:
  PROBE8 a0, rdcycle t0
  PROBE8 a0, rdtime t0
  PROBE8 a0, rdinstret t0
  PROBE8 a0, csrr t0, hpmcounter3
  TO_M m1
m1:
  # mcounteren: CY and TM
  li t0, 3
  csrw mcounteren, t0
  ENTER_HS s2
s2:
  PROBE8 a1, rdcycle t0
  PROBE8 a1, rdtime t0
  PROBE8 a1, rdinstret t0
  PROBE8 a1, csrr t0, hpmcounter3
  # csrrw zero, cycle, zero
  PROBE8 a1, .insn i 0x73, 1, x0, x0, -1024
  # U-mode with scounteren=0
  SRET_U u1
u1:
  PROBE8 a2, rdcycle t0
  PROBE8 a2, rdtime t0
  TO_M m2
m2:
  # scounteren: CY
  li t0, 1
  csrw scounteren, t0
  ENTER_U u2
u2:
  PROBE8 a3, rdcycle t0
  PROBE8 a3, rdtime t0
  TO_M m3
m3:
  # VS-mode with hcounteren=0
  ENTER_VS vs1
vs1:
  PROBE8 a4, rdcycle t0
  PROBE8 a4, rdtime t0
  PROBE8 a4, rdinstret t0
  TO_M m4
m4:
  # hcounteren: CY
  li t0, 1
  csrw hcounteren, t0
  ENTER_VS vs2
vs2:
  PROBE8 a5, rdcycle t0
  PROBE8 a5, rdtime t0
  # VU-mode with scounteren=CY
  SRET_U vu1
vu1:
  PROBE8 a5, rdcycle t0
  PROBE8 a5, rdtime t0
  TO_M m5
m5:
  # VU-mode with scounteren=0, then with mcounteren=0
  csrw scounteren, zero
  ENTER_VU vu2
vu2:
  PROBE8 s0, rdcycle t0
  TO_M m6
m6:
  csrw mcounteren, zero
  ENTER_VU vu3
vu3:
  PROBE8 s0, rdcycle t0
  TO_M m7
m7:
  j done
#include "tail.inc"
