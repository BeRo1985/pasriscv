# The guest physical address space of Sv39x4 is 41 bits wide, a GPA with a higher bit set is a
# guest-page fault (the old walk ignored those bits and aliased GPA 0x80000000)
# expect: a0=0000000000001111 s4=0000000000000015 s2=0000020080000000 s3=0000008020000000
#include "head.inc"
  GSTAGE_IDENTITY
  ENTER_VS guest
guest:
  li a0, 0x1111
  li t0, 0x20080000000
  ld a0, 0(t0)
  j done
#include "tail.inc"
