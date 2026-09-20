# M-mode data accesses with MPRV=1 and MPV=1 are translated in two stages as if V=1 in the mode
# of MPP (here vsatp Bare and the G-stage), with guest-page faults and mstatus.GVA
# expect: a0=0000000000000297 a1=0000000000000017 a2=0000000030000000 a3=0000000000000001
#include "head.inc"
  GSTAGE_IDENTITY
  GSTAGE_ALIAS 0xdb             # V R X U A D, not writable
  li t0, 0x1800
  csrc mstatus, t0
  li t0, 0x0800
  csrs mstatus, t0              # MPP=S
  li t0, 1
  slli t0, t0, 39
  csrs mstatus, t0              # MPV=1
  li t0, 0x20000
  csrs mstatus, t0              # MPRV=1
  li t0, 0xC0000000
  lwu a0, 0(t0)                 # through the G-stage alias: the first instruction
  li s4, 0
  sw zero, 0(t0)                # not writable: store guest-page fault
  mv a1, s4
  mv a2, s3
  srli a3, s6, 38
  andi a3, a3, 1
  j done
#include "tail.inc"
