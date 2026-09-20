# AIA at machine level: mvien and mvip. For an interrupt that mideleg does not delegate but mvien
# claims, S-level gets its own pending bit in mvip and its own enable in sie, while mip and mie of
# M-mode stay out of it. Here that is the supervisor software interrupt.
# a0 = mvien after writing all ones (only SSI, SEI and LCOFI are writable), a1 = sie after trying
# to set SSIE without mvien (read-only zero there), a2 = sie with mvien, a3 = mvip read back,
# a4 = the SSIP bit of mip (M-mode does not see the virtual interrupt), a5 = scause in HS-mode,
# a6 = sip and a7 = sie in the handler.
# expect: a0=0000000000002202 a1=0000000000000000 a2=0000000000000002 a3=0000000000000002 a4=0000000000000000 a5=8000000000000001 a6=0000000000000002 a7=0000000000000002
# aia
#include "head.inc"

  # Nothing is delegated, so without mvien the SSIE bit of sie is read-only zero
  li t0, 0
  csrw mideleg, t0
  li t0, 2
  csrs sie, t0
  csrr a1, sie

  # mvien is WARL: SSI (1), SEI (9) and LCOFI (13) remain
  li t0, -1
  csrw 0x308, t0
  csrr a0, 0x308

  # With mvien the SSIE bit belongs to S-level alone, mie keeps its own SSIE
  li t0, 2
  csrs sie, t0
  csrr a2, sie

  # mvip is the pending register of that interrupt, mip does not follow it
  li t0, 2
  csrw 0x309, t0
  csrr a3, 0x309
  csrr a4, mip
  andi a4, a4, 2

  # HS-mode with sstatus.SIE takes it
  lla t0, strap
  csrw stvec, t0
  ENTER_HS hs
hs:
  csrsi sstatus, 2
  li a5, 0xdead
  j done
strap:
  csrr a5, scause
  csrr a6, sip
  csrr a7, sie
  j done
#include "tail.inc"
