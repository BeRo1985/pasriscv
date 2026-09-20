# HS-mode may access hypervisor CSRs such as hstateen0 (CSR level 2); from VS/VU-mode an access
# HS-mode could do raises a virtual-instruction exception (22): H/VS CSRs from VS and VU, S CSRs
# from VU; a write to a read-only CSR and an M-level CSR stay illegal instructions (2)
# expect: a1=0000000000000000 a2=0000000000000016 a3=0000000000000002 a4=0000000000000002 a5=0000000000000016 a6=0000000000000016
#include "head.inc"
  li t0, 1
  slli t0, t0, 63
  csrs mstateen0, t0            # SE0: lower modes may reach hstateen0/sstateen0
  GSTAGE_IDENTITY
  ENTER_HS hs
hs:
  li s4, 0
  csrr a0, hstateen0
  mv a1, s4
  li t0, 0x80
  csrs hstatus, t0              # SPV=1
  li t0, 0x100
  csrs sstatus, t0              # SPP=S
  lla t0, vs
  csrw sepc, t0
  sret
vs:
  li s4, 0
  csrr t0, hstatus
  mv a2, s4
  li s4, 0
  csrw hgeip, zero
  mv a3, s4
  li s4, 0
  csrr t0, mstatus
  mv a4, s4
  li t0, 0x100
  csrc sstatus, t0              # vsstatus.SPP=U
  lla t0, vu
  csrw sepc, t0
  sret
vu:
  li s4, 0
  csrr t0, sstatus
  mv a5, s4
  li s4, 0
  csrr t0, hstatus
  mv a6, s4
  j done
#include "tail.inc"
