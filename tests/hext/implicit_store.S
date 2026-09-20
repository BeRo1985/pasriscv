# The A/D update of a VS-level PTE is an implicit store to guest physical memory. Through a
# read-only G-stage mapping it is a guest-page fault of the original access type (here the fetch:
# 20) with htinst/mtinst = 0x3020 (implicit 64-bit write) and mtval2 = GPA of the PTE >> 2. Through
# a writable G-stage mapping with D=0 (and ADUE) the G-stage PTE gets its D bit.
# expect: a0=0000000000000014 a1=0000000030080004 a2=0000000000003020 a3=0000000000000001 a4=0000000000000000 a5=0000000000000080 a6=0000000000000040 a7=000000000000000A
#include "head.inc"
  li t0, 1
  slli t0, t0, 61               # ADUE
  csrs menvcfg, t0
  csrs henvcfg, t0
  GSTAGE_IDENTITY
  GSTAGE_ALIAS 0xdb             # V R X U A D, not writable
  li t0, 0x80200010             # VS root[2]: VA 0x80000000 (1 GiB) -> GPA 0x80000000, V R W X, A=D=0
  li t1, 0x2000000f
  sd t1, 0(t0)
  li t1, 0x80000000000C0200     # vsatp: Sv39, root at GPA 0xC0200000 (the read-only alias)
  csrw vsatp, t1
  lla s8, back1
  ENTER_VS guest
guest:
  ecall
back1:
  mv a0, s4
  mv a1, s3
  mv a2, s5
  srli a3, s6, 38
  andi a3, a3, 1
  lla t0, guest
  sub a4, s2, t0
  GSTAGE_ALIAS 0x5f             # V R W X U A, D=0
  lla s8, back2
  ENTER_VS guest
back2:
  li t0, 0x80100018
  ld a5, 0(t0)
  andi a5, a5, 0x80
  li t0, 0x80200010
  ld a6, 0(t0)
  andi a6, a6, 0xc0
  mv a7, s4
  j done
#include "tail.inc"
