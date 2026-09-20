# Every G-stage access counts as a U-mode access, so a G-stage leaf needs U=1 (and U=0 faults)
# expect: a0=0000000000000297 s4=0000000000000015 s2=00000000C0000000 s3=0000000030000000 a1=0000000000000001 a2=0000000000000001
#include "head.inc"
  GSTAGE_IDENTITY               # U=1 for the code
  GSTAGE_ALIAS 0xcf             # the alias without U: V R W X A D
  ENTER_VS guest
guest:
  li t0, 0x80000000
  lwu a0, 0(t0)                 # the first instruction (auipc t0,0) through the U=1 mapping
  li t0, 0xC0000000
  lw t1, 0(t0)                  # U=0: load guest-page fault, htval/mtval2 = GPA >> 2
  srli a1, s6, 38               # mstatus.GVA
  andi a1, a1, 1
  srli a2, s6, 39               # mstatus.MPV
  andi a2, a2, 1
  j done
#include "tail.inc"
