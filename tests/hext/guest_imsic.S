# The guest interrupt file drives hgeip (and through hstatus.VGEIN VSEIP, through hgeie SGEIP),
# not the SEIP of the host. Without a valid VGEIN, sireg (IMSIC registers) and stopei raise a
# virtual-instruction exception in VS-mode instead of reaching the file of the host, and the
# iprio array does not exist at VS level
# aia
# expect: a0=0000000000000002 a1=0000000000000400 a2=0000000000001400 a3=0000000000000000 a4=0000000000000016 a5=0000000000000016 a6=0000000000000016
#include "head.inc"
  # Smstateen: without the bits for the indirect window (60), AIA (59) and IMSIC (58) every access
  # below M-mode to those CSRs is an illegal instruction, which would hide the rule under test
  li t0, 7
  slli t0, t0, 58
  csrs mstateen0, t0
  csrs hstateen0, t0
  li t0, 1 << 12
  csrs hstatus, t0              # VGEIN=1
  li t0, 0x70
  csrw vsiselect, t0
  li t0, 1
  csrw vsireg, t0               # eidelivery
  li t0, 0xc0
  csrw vsiselect, t0
  li t0, 0x20
  csrw vsireg, t0               # eie0: interrupt 5 enabled
  li t0, 0x80
  csrw vsiselect, t0
  li t0, 0x20
  csrw vsireg, t0               # eip0: interrupt 5 pending
  csrr a0, hgeip
  csrr a1, hip
  li t0, 2
  csrw hgeie, t0
  csrr a2, hip
  csrr a3, mip
  andi a3, a3, 0x200            # SEIP of the host
  li t0, 0x3f000
  csrc hstatus, t0              # VGEIN=0
  li t0, 0x70
  csrw vsiselect, t0
  GSTAGE_IDENTITY
  ENTER_VS guest
guest:
  li s4, 0
  csrr t0, sireg
  mv a4, s4
  li t0, 0x30
  csrw siselect, t0
  li s4, 0
  csrr t0, sireg
  mv a5, s4
  li s4, 0
  csrr t0, stopei
  mv a6, s4
  j done
#include "tail.inc"
